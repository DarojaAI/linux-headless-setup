# RFC: Standardized AGENTS.md Template for DarojaAI

> **Status:** DRAFT for operator review before posting as an `[RFC]` issue in `DarojaAI/.github`.
> **Author:** `darojaai_architect`
> **Date:** 2026-06-14
> **Target issue:** `DarojaAI/.github` issues, `[RFC] AGENTS.md template`

---

## Summary

DarojaAI repos currently ship `AGENTS.md` files of wildly varying scope, size, and structure. Sizes range from ~3k (`dev-nexus`) to ~29k (`linux-desktop-seed`). Content focuses on different things per repo. There is no org-level standard.

This RFC proposes a *minimum* required template that all repos must satisfy, with a clear "repo-specific extension" section so repos can grow the file without bloating it with boilerplate.

## Motivation

1. **Operator + agent onboarding is repo-specific.** Every new agent session reads the target repo's `AGENTS.md`. Inconsistent structure means the agent has to re-learn the format each time.
2. **Cross-repo standards are harder to enforce** when each repo describes them differently. The same "don't hardcode IPs" rule should be a one-paragraph checkable item, not a 200-line essay.
3. **The org has 4 categories of repos** (per `GOVERNANCE.md`): Infrastructure, Core Services, Frontend, Public/Examples. Each category legitimately needs different guidance. A one-size-fits-all template is wrong; a *minimum required* template is right.

## Proposal

### A. Minimum required sections (every repo)

Every `AGENTS.md` MUST include these top-level sections, in this order:

1. **Role** (1 paragraph) — what this repo is and what an agent's job is when working in it. Cite the relevant `GOVERNANCE.md` category.
2. **First Run** — if `BOOTSTRAP.md` exists, follow it, then delete it.
3. **Session Startup** — what to read first. Reference the runtime startup context; don't duplicate it.
4. **Project Quick Context** — a 5-10 line bullet list pointing to key docs:
   - Architecture: `docs/ARCHITECTURE.md` (or equivalent)
   - Components: `docs/COMPONENTS.md` (or equivalent)
   - Dev setup: `docs/SETUP.md` or `README.md`
   - Env vars: link, don't enumerate
   - Decisions / lessons: `docs/decisions/`
5. **House Rules** — 5-10 bullets of repo-specific rules that an agent MUST follow. Examples:
   - "Don't bypass Terraform CI for state mutations."
   - "Don't commit secrets; pre-commit includes Gitleaks."
   - "Don't push directly to main; PR required."
6. **Related** — 5-10 links to the upstream/downstream repos and the P0 boundary contract (if applicable).

### B. Optional extension sections (per category)

| Category | Recommended additions |
|---|---|
| Infrastructure (Terraform) | "**Work Completion Gate**" — pre-commit, fmt, init, validate, checkov; PR via `.github` not direct apply. |
| Core Services (Python) | "**Behavioral Anchors**" — "what high agency means" in this repo; tests/coverage gate. |
| Frontend (TypeScript) | "**Build & Deploy**" — Vite/CRA/Next build, lint, type-check, deploy target. |
| Public/Examples | "**Audience**" — who the example is for; "if you copy this repo, also read X." |

### C. Prohibited content

These belong in `README.md` (humans), not `AGENTS.md` (agents):

- Marketing copy / "Why this project is great"
- Long changelogs (use a `CHANGELOG.md`)
- Setup tutorials for non-agents
- Sponsor / contributing pitches

### D. Size budget

- **Minimum viable `AGENTS.md`:** 50 lines, ~3-4k chars. Anything shorter is a stub.
- **Soft cap:** 300 lines, ~20k chars. Above this, content should move to `docs/` and be linked.
- **Hard cap:** none enforced, but anything >500 lines almost certainly has content that belongs elsewhere.

## Why this is the right shape

- **Minimum required is a forcing function** for hygiene. Every repo can be evaluated against the same 6 sections. Missing one = a checkable issue.
- **Optional extensions are category-aware** so a Terraform repo's "Work Completion Gate" doesn't pollute a frontend's `AGENTS.md`.
- **Prohibited content** keeps `AGENTS.md` focused on agent behavior, not human marketing.
- **Size budget** prevents the `linux-desktop-seed` 29k-file pattern (which I haven't audited in detail, but 29k is a smell for a contract file).

## Migration plan

1. **Phase 1 (this RFC, if accepted):** add the template to `DarojaAI/.github/docs/AGENTS-TEMPLATE.md`.
2. **Phase 2:** file per-repo issues for any repo whose `AGENTS.md` doesn't meet the minimum. Estimated work: 5-10 minutes per repo, batchable.
3. **Phase 3 (optional):** add a CI check in `infra-actions` that fails the PR if `AGENTS.md` is missing a required section header.

## Open questions for the operator

- **Q1.** Should this be a *required* standard (enforced via CI) or *recommended* (advisory)? My recommendation: required for new repos, recommended for existing. Existing repos get an issue and 30 days.
- **Q2.** Is the 6-section minimum too prescriptive? Some repos have legitimate reasons to diverge. The minimum should be *minimum*, not *maximum*.
- **Q3.** Do we want a `CLAUDE.md` equivalent? Some repos have both (`linux-desktop-seed` does). The current `AGENTS.md` standard should make clear that `AGENTS.md` is the canonical name; `CLAUDE.md` is a legacy alias that gets the same content.

## What this is NOT

- Not a content rewrite of any repo's `AGENTS.md`. The template is a *shape*; the content is the repo owner's responsibility.
- Not a replacement for repo-specific docs. `AGENTS.md` is a contract; `docs/` is the source of truth on architecture and code.
- Not a one-time standardization. Repos grow and change; the template is a recurring check.
