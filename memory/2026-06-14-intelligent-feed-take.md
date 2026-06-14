# 2026-06-14 — intelligent-feed deep read

Operator: "look at files for intelligent-feed" (in response to Q10 cleanup of 6 mystery repos).

## What it is

**Phase 4 Cognee research pipeline orchestrator.** Scheduled pipeline that:

1. Fetches content from RSS / PyPI (configurable sources).
2. Enriches via Claude API (summary, tags, relevance, urgency).
3. Routes to subscriptions by topic filter + threshold.
4. Renders to human (Markdown) / agent (JSON) / **structured (Cognee cognify + project activators)** subscribers.

**It's not just a content monitor — it's a shared activation library.** This was the load-bearing finding.

## Cross-repo coupling (the architecture signal)

`intel/activation/` ships **per-project activators** that write into 4 other org repos' data files, using **operator-local hardcoded paths**:

| Activator | Target repo | Hardcoded path | File written |
|---|---|---|---|
| `GlobalBitingsActivator` | `GlobalBitings` | `~/GithubProjects/GlobalBitings/...` | `data/extraction_log.jsonl` + triggers `RAGResearchTool.py --sync` |
| `BondNexusActivator` | `bond-nexus` | `~/GithubProjects/bond-nexus/...` | `conventions.yaml` + regenerates `MARKET_SOURCES.md` |
| `RagResearchActivator` | `rag_research_tool` | `~/GithubProjects/rag_research_tool/...` | `triplets.json` |
| `DynamicWorlockActivator` | **`DarojaAI/dynamic-worlock` does not exist** | `~/GithubProjects/dynamic-worlock/...` | `data/knowledge_store.json` + `data/conflicts.json` |

`get_activator(project)` factory in `intel/activation/factory.py` exposes all four. Adding a new project = adding a new activator + registering it in the factory.

## `research-orchestrator` consumes `intelligent-feed`

`_context/research-orchestrator/app/activation.py` **imports** intelligent-feed's activators (does NOT copy them):

- Reads `INTELLIGENT_FEED_PATH` env var
- Adds that path to `sys.path`
- Imports `intel.activation.factory.get_activator`
- Wraps it

Implication: **intelligent-feed is a shared library, even though it's not in the "Shared Infrastructure" bucket.** research-orchestrator depends on it at runtime. This is the same architectural pattern as `devnexus-common` being a shared lib with a misleading name — but here the import boundary is via `sys.path` injection, which is more fragile (no pip install, no version pinning, no CI to catch breakage).

## Dangling reference: `dynamic-worlock`

`intel/activation/dynamic_worlock.py` and `intel/activation/factory.py` reference `DarojaAI/dynamic-worlock` (multiple aliases: `dynamic-worlock`, `dynamic_worlock`). **The repo does not exist in the org** (`gh repo view DarojaAI/dynamic-worlock` → 404). Two interpretations:
- (a) Repo is private, not visible to this token. **Need to verify.**
- (b) Repo was deleted; activator is dead code.
- (c) Repo is on a different org or was never created.

This blocks the `get_activator("dynamic-worlock")` call at runtime. Either delete the activator + factory entries, or unorphan it.

## Documentation gaps

- **No `.github/` directory** (no workflows, no CODEOWNERS, no issue templates, no PR template).
- **No LICENSE file.**
- **No `AGENTS.md`** — and `intelligent-feed` is a shared library, so a standardized AGENTS.md is *especially* important (consumers need to know what semver means here, what the activation contract is, how to add a new activator).
- **No dependency declaration** in `research-orchestrator` (it's an env-var-based sys.path injection, not a Python package).

## The big picture — what was missing from the org map

`ARCHITECTURE.md` v0.1 listed `intelligent-feed` as `(purpose unclear)`. The actual coupling graph:

```
research-orchestrator  ───imports──▶  intelligent-feed (activators)
                                            │
                                            ▼ activates
                              ┌─────────────┼─────────────┐
                              ▼             ▼             ▼
                       globalbitings  bond-nexus   rag_research_tool
                              │
                              ▼
                       dynamic-worlock (DOES NOT EXIST)
```

`intelligent-feed` belongs in a new category: **"Cross-Product Coordination Library"** or simply tagged as a shared library alongside `devnexus-common`. It's *not* "agentic" in the `agentic-log-attacker` sense (no LLM-decided autonomy), and it's *not* a product (consumed by other services, not end-user facing).

The `rag_research_tool/docs/research-pipeline-plan.md` doc has a 4-phase plan that *re-uses* intelligent-feed's fetcher/enricher/router/renderers and adds a `StructuredRenderer`. Phase 4 of intelligent-feed (`StructuredRenderer`) is essentially that plan, but built into intelligent-feed itself rather than rag_research_tool.

## Operator decisions logged in this session (2026-06-14)

- Copyright holder in manifests = "Milan Patel" (keep as-is).
- `GlobalBitings` = leave as-is (operator decision).
- `intelligent-feed` = read the files (this session).
- `pattern-miner` and `dependency-orchestrator` = confirmed archived (already known, but reaffirmed via Q1/Q2).
- `design-artifacts` = organizational design artifacts (brand guide etc.).
- `core-business-management` = AI agent designated for managing DarojaAI's core business operations.

## Related open questions (now in OPEN_QUESTIONS.md)

- Q14 (P1): `dynamic-worlock` status — verify existence, then decide activator stay/go.
- Q15 (P1): intelligent-feed shared-lib documentation (AGENTS.md, README "Consumers" section). Approved by operator 2026-06-14.
- Q16 (P1): hardcoded paths → env-var overrides. Operator: "have a look" — keep open for now, queued behind Q14.
- Q17 (P1): no `.github/`, no AGENTS.md, no LICENSE, no CI. Add basic pytest workflow + AGENTS.md + LICENSE.

## Recommended follow-ups (queued, not done)

1. **Confirm `dynamic-worlock` status** — is it private? Different org? Should the activator be deleted? Operator decision.
2. **Hardcoded paths** in all 4 activators are operator-local. They should be:
   - Configurable via env vars (like `INTELLIGENT_FEED_PATH` in research-orchestrator), OR
   - Set from a single config block, OR
   - Documented as "operator's local checkout — change to your path."
   None of the above is done. **Fragile coupling.**
3. **`intelligent-feed` is a shared lib masquerading as a product.** Per operator 2026-06-14, document it as a shared lib (cheapest path: AGENTS.md + README "Consumers" section). Move-to-shared-lib-package and rename are higher-cost options.
4. **`research-orchestrator` activation path is fragile.** `sys.path` injection of a sibling repo is a code smell. Worth proposing a proper package install (`pip install -e ./intelligent-feed` or move activators to a shared lib) — but this is a refactor, not a quick fix.
5. **No GitHub workflows in `intelligent-feed`.** No CI = no signal on breakage. Adding a basic pytest workflow (uses `infra-actions` per org standard) would catch regressions.

## Files I read in this session

- `_context/intelligent-feed/README.md` (entire)
- `_context/intelligent-feed/CLAUDE.md` (entire)
- `_context/intelligent-feed/config.yaml` (entire)
- `_context/intelligent-feed/intel/activation/base.py` (entire)
- `_context/intelligent-feed/intel/activation/factory.py` (entire)
- `_context/intelligent-feed/intel/activation/globalbitings.py` (entire)
- `_context/intelligent-feed/intel/activation/bondnexus.py` (entire)
- `_context/intelligent-feed/intel/activation/rag_research.py` (entire)
- `_context/intelligent-feed/intel/activation/dynamic_worlock.py` (entire)
- `_context/intelligent-feed/intel/activation/__init__.py` (entire)
- `_context/intelligent-feed/intel/renderers/structured.py` (head 80 lines)
- `_context/research-orchestrator/app/activation.py` (head 50 lines)
- `_context/research-orchestrator/CLAUDE.md` (via grep)
- `_context/rag_research_tool/docs/research-pipeline-plan.md` (via grep, 14 hits)
