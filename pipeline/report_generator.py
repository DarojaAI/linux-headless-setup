"""Report generation pipeline using LangGraph.

Agentic pipeline that:
1. Takes markdown report content + a client template
2. Parses the report into structured sections
3. Fills the template with section data
4. Generates PDF via weasyprint
5. Validates the output before marking ready

Usage:
    from pipeline.report_generator import generate_report
    result = generate_report(
        markdown_path="docs/sample-report-semiconductor-v2.md",
        template_path="templates/Client Report Template.dc.html",
        output_path="docs/semiconductor-report.pdf",
    )
"""

from __future__ import annotations

import re
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Literal

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

@dataclass
class ReportSection:
    """A parsed section from the markdown report."""
    id: str
    title: str
    level: int  # 1 = h1, 2 = h2, etc.
    content: str  # raw markdown content (excluding heading)
    footnotes: list[str] = field(default_factory=list)
    tables: list[list[list[str]]] = field(default_factory=list)


@dataclass
class PipelineState:
    """State passed between LangGraph nodes."""
    # Inputs
    markdown_path: str = ""
    template_path: str = ""
    output_path: str = ""
    output_format: Literal["pdf", "html"] = "pdf"

    # Parsed
    raw_markdown: str = ""
    sections: list[ReportSection] = field(default_factory=list)
    footnotes: list[str] = field(default_factory=list)
    metadata: dict[str, str] = field(default_factory=dict)

    # Generated
    filled_html: str = ""
    pdf_path: str = ""

    # Validation
    validation_errors: list[str] = field(default_factory=list)
    validation_warnings: list[str] = field(default_factory=list)
    is_valid: bool = False

    # Status
    current_node: str = ""
    error: str = ""


# ---------------------------------------------------------------------------
# Node: Parse Markdown
# ---------------------------------------------------------------------------

def _parse_tables(text: str) -> list[list[list[str]]]:
    """Extract markdown tables from text."""
    tables = []
    lines = text.split("\n")
    current_table: list[list[str]] = []
    in_table = False

    for line in lines:
        stripped = line.strip()
        if stripped.startswith("|") and stripped.endswith("|"):
            if re.match(r"^\|[\s\-:|]+\|$", stripped):
                # separator row — skip
                continue
            cells = [c.strip() for c in stripped.split("|")[1:-1]]
            current_table.append(cells)
            in_table = True
        else:
            if in_table and current_table:
                tables.append(current_table)
                current_table = []
                in_table = False

    if current_table:
        tables.append(current_table)

    return tables


def _extract_footnotes(text: str) -> list[str]:
    """Extract footnote definitions from markdown text."""
    fn_pattern = re.compile(r"^\[(\d+|[A-Z]+)\]\s+(.+)$", re.MULTILINE)
    return [m.group(0) for m in fn_pattern.finditer(text)]


def node_parse_markdown(state: PipelineState) -> PipelineState:
    """Parse markdown report into structured sections."""
    state.current_node = "parse_markdown"

    md_path = Path(state.markdown_path)
    if not md_path.exists():
        state.error = f"Markdown file not found: {state.markdown_path}"
        return state

    state.raw_markdown = md_path.read_text(encoding="utf-8")

    # Extract metadata from frontmatter-like lines
    for pattern, key in [
        (r"\*\*Engagement:\*\*\s*(.+)", "engagement"),
        (r"\*\*Methodology:\*\*\s*(.+)", "methodology"),
        (r"\*\*Date:\*\*\s*(.+)", "date"),
        (r"\*\*Status:\*\*\s*(.+)", "status"),
    ]:
        m = re.search(pattern, state.raw_markdown)
        if m:
            state.metadata[key] = m.group(1).strip()

    # Extract all footnotes — match [N] text or [KEY] text at line start
    fn_pattern = re.compile(r"^\[(\d+|[A-Z][A-Z0-9]*)\]\s+(.+)$", re.MULTILINE)
    state.footnotes = [m.group(0) for m in fn_pattern.finditer(state.raw_markdown)]

    # Parse sections by ## headings only (h2 = top-level content sections)
    section_pattern = re.compile(r"^(#{2,3})\s+(.+)$", re.MULTILINE)
    matches = list(section_pattern.finditer(state.raw_markdown))

    for i, match in enumerate(matches):
        level = len(match.group(1))
        title = match.group(2).strip()
        start = match.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(state.raw_markdown)
        content = state.raw_markdown[start:end].strip()

        # Skip empty sections
        if len(content.strip()) < 20:
            continue

        # Generate section id from title
        section_id = re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-")

        section = ReportSection(
            id=section_id,
            title=title,
            level=level,
            content=content,
            tables=_parse_tables(content),
        )
        state.sections.append(section)

    return state


# ---------------------------------------------------------------------------
# Node: Generate HTML
# ---------------------------------------------------------------------------

# Minimal inline CSS for the report (derived from DarojaAI design system)
REPORT_CSS = """
@page { size: A4; margin: 0.85in; }
* { box-sizing: border-box; }
body { font-family: -apple-system, 'Segoe UI', Helvetica, Arial, sans-serif; color: #1C1A16; font-size: 14px; line-height: 1.6; margin: 0; padding: 0; }
h1, h2, h3 { font-weight: 200; letter-spacing: -0.02em; color: #1C1A16; margin: 0; }
h1 { font-size: 42px; line-height: 1.0; }
h2 { font-size: 26px; margin-bottom: 16px; }
h3 { font-size: 17px; font-weight: 300; margin-bottom: 8px; }
.eyebrow { font-size: 10px; font-weight: 500; letter-spacing: 0.18em; text-transform: uppercase; color: #1C1A16; opacity: 0.55; display: flex; align-items: center; gap: 8px; margin-bottom: 8px; }
.dot { width: 6px; height: 6px; border-radius: 50%; background: #E6B340; flex: none; }
.bar { height: 3px; width: 32px; margin-bottom: 16px; }
.gold { color: #E6B340; font-style: italic; }
.mono { font-family: 'Courier New', monospace; letter-spacing: 0.04em; }
.rule { border: none; border-top: 1px solid rgba(28,26,22,0.10); margin: 0; }
table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
th { text-align: left; font-size: 10px; font-weight: 400; letter-spacing: 0.1em; text-transform: uppercase; opacity: 0.6; padding: 8px 10px; border-bottom: 1px solid rgba(28,26,22,0.18); }
td { font-size: 13px; padding: 7px 10px; border-bottom: 1px solid rgba(28,26,22,0.10); line-height: 1.4; }
.stat-grid { display: flex; gap: 1px; background: rgba(28,26,22,0.10); margin: 24px 0; }
.stat-card { flex: 1; padding: 18px; background: #F5F0E8; }
.stat-num { font-size: 30px; font-weight: 200; letter-spacing: -0.02em; }
.stat-label { font-size: 10px; letter-spacing: 0.1em; text-transform: uppercase; opacity: 0.55; margin-top: 4px; }
.page-break { page-break-before: always; }
.cover { min-height: 9in; display: flex; flex-direction: column; justify-content: space-between; }
.toc-row { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid rgba(28,26,22,0.10); font-size: 14px; }
p { margin: 0 0 10px 0; }
.small { font-size: 11px; opacity: 0.6; }
sup.fn { font-size: 9px; color: #E6B340; font-weight: 500; vertical-align: super; }
.footnotes { margin-top: 30px; padding-top: 16px; border-top: 1px solid rgba(28,26,22,0.18); }
.fn { font-size: 11px; line-height: 1.5; margin-bottom: 4px; color: rgba(28,26,22,0.7); }
.fn-num { font-family: 'Courier New', monospace; font-weight: 500; color: #E6B340; margin-right: 4px; }
"""


def _md_to_inline(text: str) -> str:
    """Convert inline markdown to HTML (bold, italic, code, footnotes). No recursion."""
    text = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", text)
    text = re.sub(r"\*(.+?)\*", r"<em>\1</em>", text)
    text = re.sub(r"`(.+?)`", r'<span class="mono">\1</span>', text)
    text = re.sub(
        r"\[(\d+|[A-Z]+)\]",
        r'<sup class="fn">[\1]</sup>',
        text,
    )
    return text


def _md_to_html(text: str) -> str:
    """Convert markdown text to HTML (minimal, for report content)."""
    # Paragraphs
    paragraphs = []
    for para in text.split("\n\n"):
        para = para.strip()
        if para:
            if para.startswith("- "):
                items = "".join(f"<li>{_md_to_inline(l[2:])}</li>" for l in para.split("\n") if l.startswith("- "))
                paragraphs.append(f"<ul>{items}</ul>")
            else:
                paragraphs.append(f"<p>{_md_to_inline(para.replace(chr(10), ' '))}</p>")
    return "\n".join(paragraphs)


def _table_to_html(table: list[list[str]]) -> str:
    """Convert a parsed table to HTML."""
    if not table:
        return ""
    header = table[0]
    rows = table[1:] if len(table) > 1 else []
    thead = "<thead><tr>" + "".join(f"<th>{_md_to_html(c)}</th>" for c in header) + "</tr></thead>"
    tbody = "<tbody>" + "".join(
        "<tr>" + "".join(f"<td>{_md_to_html(c)}</td>" for c in row) + "</tr>"
        for row in rows
    ) + "</tbody>"
    return f"<table>{thead}{tbody}</table>"


def node_generate_html(state: PipelineState) -> PipelineState:
    """Generate HTML from parsed sections."""
    state.current_node = "generate_html"

    # Build cover page
    engagement = state.metadata.get("engagement", "Report")
    methodology = state.metadata.get("methodology", "")
    date = state.metadata.get("date", "")

    cover = f"""
<div class="cover">
  <div>
    <div class="eyebrow"><span class="dot"></span>CLIENT REPORT</div>
    <div style="height:60px"></div>
    <h1>{_md_to_html(engagement)}</h1>
    <p style="font-size:16px; max-width:500px; margin-top:18px; opacity:0.75;">{_md_to_html(methodology)}</p>
  </div>
  <div>
    <hr class="rule" style="margin-bottom:18px;">
    <div style="display:flex; justify-content:space-between; font-size:13px;">
      <div><div class="mono small">PREPARED FOR</div><div style="margin-top:3px;">[Client Organisation]</div></div>
      <div><div class="mono small">PREPARED BY</div><div style="margin-top:3px;">DarojaAI</div></div>
      <div><div class="mono small">DATE</div><div class="mono" style="margin-top:3px;">{_md_to_html(date)}</div></div>
    </div>
  </div>
</div>
"""

    # Build content sections
    content_parts = [cover]
    for section in state.sections:
        if section.level <= 1:
            continue  # Skip h1 (used for cover)

        content_parts.append('<div class="page-break"></div>')

        if section.level == 2:
            content_parts.append(f'<div class="eyebrow"><span class="dot"></span>{_md_to_html(section.title.upper())}</div>')
            content_parts.append(f'<div class="bar" style="background:#3299BB;"></div>')
            content_parts.append(f"<h2>{_md_to_html(section.title)}</h2>")
        elif section.level == 3:
            content_parts.append(f"<h3>{_md_to_html(section.title)}</h3>")

        # Add tables
        for table in section.tables:
            content_parts.append(_table_to_html(table))

        # Add remaining content (minus tables)
        content_no_tables = section.content
        for table in section.tables:
            for row in table:
                for cell in row:
                    content_no_tables = content_no_tables.replace("|".join(row), "")
        content_parts.append(_md_to_html(content_no_tables))

    # Build footnotes page
    if state.footnotes:
        content_parts.append('<div class="page-break"></div>')
        content_parts.append('<div class="eyebrow"><span class="dot"></span>REFERENCES</div>')
        content_parts.append('<div class="bar" style="background:#E6B340;"></div>')
        content_parts.append("<h2>Footnotes &amp; sources</h2>")
        content_parts.append('<div class="footnotes">')
        for fn in state.footnotes:
            content_parts.append(f'<p class="fn">{_md_to_html(fn)}</p>')
        content_parts.append("</div>")

    content_parts.append('<hr class="rule" style="margin-top:30px; margin-bottom:12px;">')
    content_parts.append(f'<p class="mono small">DarojaAI · {methodology} · {date}</p>')

    # Assemble full HTML
    state.filled_html = f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>{REPORT_CSS}</style>
</head>
<body>
{"".join(content_parts)}
</body>
</html>"""

    return state


# ---------------------------------------------------------------------------
# Node: Generate PDF
# ---------------------------------------------------------------------------

def node_generate_pdf(state: PipelineState) -> PipelineState:
    """Generate PDF from HTML using weasyprint."""
    state.current_node = "generate_pdf"

    output = Path(state.output_path)
    output.parent.mkdir(parents=True, exist_ok=True)

    if state.output_format == "html":
        output.write_text(state.filled_html, encoding="utf-8")
        state.pdf_path = str(output)
        return state

    # Write temporary HTML
    tmp_html = output.with_suffix(".tmp.html")
    tmp_html.write_text(state.filled_html, encoding="utf-8")

    try:
        # Try weasyprint first
        from weasyprint import HTML as WeasyHTML
        WeasyHTML(filename=str(tmp_html)).write_pdf(str(output))
        state.pdf_path = str(output)
    except ImportError:
        # Fall back to chromium
        try:
            subprocess.run(
                ["chromium", "--headless", "--disable-gpu", "--no-sandbox",
                 f"--print-to-pdf={output}", "--print-to-pdf-no-header",
                 str(tmp_html)],
                check=True, capture_output=True, timeout=30,
            )
            state.pdf_path = str(output)
        except (subprocess.CalledProcessError, FileNotFoundError) as e:
            state.error = f"PDF generation failed: {e}"
    finally:
        tmp_html.unlink(missing_ok=True)

    return state


# ---------------------------------------------------------------------------
# Node: Validate Document
# ---------------------------------------------------------------------------

def node_validate(state: PipelineState) -> PipelineState:
    """Validate the generated document before marking ready."""
    state.current_node = "validate"
    state.validation_errors = []
    state.validation_warnings = []

    pdf_path = Path(state.pdf_path) if state.pdf_path else None

    if state.output_format == "pdf":
        if not pdf_path or not pdf_path.exists():
            state.validation_errors.append("PDF file not generated")
            state.is_valid = False
            return state

        # Check file size (should be > 10KB for a real report)
        size_kb = pdf_path.stat().st_size / 1024
        if size_kb < 10:
            state.validation_errors.append(f"PDF too small ({size_kb:.0f}KB) — likely empty or corrupted")
        if size_kb > 10_000:
            state.validation_warnings.append(f"PDF unusually large ({size_kb/1024:.1f}MB)")

        # Check page count via pdfinfo if available
        try:
            result = subprocess.run(
                ["pdfinfo", str(pdf_path)],
                capture_output=True, text=True, timeout=5,
            )
            if result.returncode == 0:
                pages_match = re.search(r"Pages:\s+(\d+)", result.stdout)
                if pages_match:
                    pages = int(pages_match.group(1))
                    if pages < 3:
                        state.validation_errors.append(f"PDF has only {pages} pages — expected 5+")
                    elif pages > 30:
                        state.validation_warnings.append(f"PDF has {pages} pages — verify completeness")
        except FileNotFoundError:
            state.validation_warnings.append("pdfinfo not available — page count not verified")

    # Check HTML content quality
    if state.filled_html:
        # Check for placeholder text
        placeholders = re.findall(r"\[([A-Z][a-z]+\s[A-Z][a-z]+)\]", state.filled_html)
        if placeholders:
            state.validation_warnings.append(
                f"Possible unfilled placeholders: {', '.join(set(placeholders[:5]))}"
            )

        # Check for footnote references
        fn_refs = re.findall(r'sup class="fn">\[(\d+|[A-Z]+)\]', state.filled_html)
        if fn_refs:
            state.validation_warnings.append(
                f"{len(fn_refs)} footnote references in output (definitions may be inline in source)"
            )

        # Check for empty sections
        empty_sections = [s for s in state.sections if len(s.content.strip()) < 20 and s.level == 2]
        if empty_sections:
            state.validation_warnings.append(
                f"Empty sections: {', '.join(s.title for s in empty_sections)}"
            )

    # Determine validity
    state.is_valid = len(state.validation_errors) == 0
    return state


# ---------------------------------------------------------------------------
# LangGraph Pipeline (manual implementation — no langgraph dependency)
# ---------------------------------------------------------------------------

class ReportPipeline:
    """Sequential pipeline: parse → generate HTML → generate PDF → validate.

    Uses LangGraph-style node pattern without requiring the langgraph package.
    Each node is a pure function that transforms PipelineState.
    """

    def __init__(self):
        self.nodes = [
            node_parse_markdown,
            node_generate_html,
            node_generate_pdf,
            node_validate,
        ]

    def run(self, state: PipelineState) -> PipelineState:
        """Execute the pipeline end-to-end."""
        for node_fn in self.nodes:
            state = node_fn(state)
            if state.error:
                break
        return state


# ---------------------------------------------------------------------------
# Convenience function
# ---------------------------------------------------------------------------

def generate_report(
    markdown_path: str,
    template_path: str = "",
    output_path: str = "",
    output_format: Literal["pdf", "html"] = "pdf",
) -> dict[str, Any]:
    """Run the full report generation pipeline.

    Returns a dict with: success, pdf_path, errors, warnings, sections_count.
    """
    if not output_path:
        stem = Path(markdown_path).stem
        output_path = f"docs/{stem}.pdf"

    state = PipelineState(
        markdown_path=markdown_path,
        template_path=template_path,
        output_path=output_path,
        output_format=output_format,
    )

    pipeline = ReportPipeline()
    result = state = pipeline.run(state)

    return {
        "success": result.is_valid,
        "pdf_path": result.pdf_path,
        "errors": result.validation_errors,
        "warnings": result.validation_warnings,
        "sections_count": len(result.sections),
        "footnotes_count": len(result.footnotes),
        "metadata": result.metadata,
    }


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python -m pipeline.report_generator <markdown_path> [output_path]")
        sys.exit(1)

    md_path = sys.argv[1]
    out_path = sys.argv[2] if len(sys.argv) > 2 else ""

    result = generate_report(md_path, output_path=out_path)

    print(f"Success: {result['success']}")
    print(f"Output: {result['pdf_path']}")
    print(f"Sections: {result['sections_count']}")
    print(f"Footnotes: {result['footnotes_count']}")
    if result["errors"]:
        print(f"ERRORS: {result['errors']}")
    if result["warnings"]:
        print(f"Warnings: {result['warnings']}")
