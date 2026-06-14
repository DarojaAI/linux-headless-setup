# Repo Inventory

> **Status legend:**
> - `mapped` — purpose, layer, and relationships understood
> - `partial` — purpose clear, relationships inferred (need confirmation)
> - `unexplored` — purpose unclear from outside; needs clone + read
> - `flagged` — known issue (duplicate, stale, naming, etc.)
>
> **Categories** match `DarojaAI/.github/GOVERNANCE.md` where possible, with extra buckets for things the governance doc doesn't cover. A 5th category ("Shared Libraries & Templates") is approved by operator 2026-06-14, pending RFC — repos that fit it are tagged below.

Last refresh: 2026-06-14

---

## Governance (1)

| Repo | Status | Owner | Notes |
|---|---|---|---|
| `.github` | mapped | Infrastructure team | P0. Source of `GOVERNANCE.md`, `CONTRIBUTING.md`, `pull_request_template.md`, `workflow-templates/`. Defines the four official categories. **5th category RFC pending (Q4).** |

## Provisioning Stack (4)

| Repo | Status | Layer | Notes |
|---|---|---|---|
| `terraform-hcloud-linux-vm` | mapped | L1 | Hetzner VM module. The "primary" L1 per cross-references. |
| `terraform-gcp-wrappers` | partial | L1 alt | GCP VM wrappers. Secondary path. Need to confirm if this wraps upstream or is a parallel module. |
| `linux-headless-setup` | mapped | L2 (headless) | Server-only OpenClaw host base. No GUI. |
| `linux-desktop-setup` | mapped | L2 (desktop) | Full GUI base. Production-ready, tested 22.04/24.04. |
| `linux-desktop-seed` | mapped | L3a | VM ops + deploy orchestration. Imports L1 + L2. |

## Intelligence Triad (3)

| Repo | Status | Role | Notes |
|---|---|---|---|
| `dev-nexus` | mapped | Knowledge | P0 boundary contract lives here. Has its own AGENTS.md, HEARTBEAT.md, IDENTITY.md. A2A + MCP server. Pattern discovery, drift detection, remediation PRs. |
| `mcp-tooling` | mapped | Capability | MCP servers wrapping external APIs (Duffel, Cal.com, payments) and host ops. Has its own architectural boundaries doc. |
| `openclaw-gateway` | mapped | Coordination (L3b) | Discord AI agent runtime. Has the strongest env/deploy hygiene in the org (DAT contract, test/head/prod topology). |

## Application Products (5)

| Repo | Status | Purpose | Notes |
|---|---|---|---|
| `rag_research_tool` | mapped | PDF → vector RAG | FastAPI + GCP + Atlas + Neo4j. Best-documented application repo. Has `INTEGRATION_GUIDE.md`. |
| `rag-research-tool-frontend` | partial | React UI for above | Public. Paired with backend. |
| `bond-nexus` | mapped | TwentyCRM sales pipeline | 10-doc setup package, 60-min quickstart. "Bond Nexus" is the customer name. |
| `trip-planning` | partial | AI travel assistant | **No README.** Description: itinerary, destination research, travel logistics. Likely consumes `mcp-tooling/duffel`. **Q11: add README.** |
| `research-orchestrator` | mapped | Research extraction (Firecrawl + Cognee) | FastAPI. Per-project activation. **Imports intelligent-feed's activators via `INTELLIGENT_FEED_PATH` sys.path injection.** |

## Shared Libraries & Templates (5) — pending RFC, Q4

| Repo | Status | Purpose | Notes |
|---|---|---|---|
| `infra-actions` | mapped | Composite GitHub Actions | CI/CD backbone. Has `CONTRIBUTING.md` with action-authoring rules. **Q7: usage is uneven; sweep planned.** |
| `devnexus-common` | mapped | Shared Python utils | LLM client (Anthropic + OpenRouter), tracing. **Q5: rename to `py-daroja-libs` is approved.** Name implies `dev-nexus` ownership but it's a shared lib. |
| `daroja-frontend-starter` | mapped | Vite 19 + Cloudflare template | Should be the seed for any new frontend. |
| `intelligent-feed` | mapped | Phase 4 Cognee research pipeline | **Houses per-project activators** for `globalbitings`, `bond-nexus`, `rag_research_tool`, and a dangling `dynamic-worlock` (repo missing). Imported by `research-orchestrator` via `INTELLIGENT_FEED_PATH` sys.path injection. **Q15: add AGENTS.md; Q16: env-var paths; Q17: .github/ + LICENSE + CI.** See `memory/2026-06-14-intelligent-feed-take.md`. |
| *(slot reserved)* | — | — | The 5th slot — likely an *additional* shared lib to be named. Currently this category has 4 members; one slot is intentionally open. |

## Other Shared Infrastructure (8) — current category: Infrastructure (IaC)

| Repo | Status | Purpose | Notes |
|---|---|---|---|
| `vpc-infra` | mapped | Shared VPC for GCP Postgres | Per its description. |
| `gcp-postgres-terraform` | mapped | Postgres on GCP | Compute Engine. |
| `gcp-dbt-terraform` | mapped | dbt on GCP | |
| `gcp-postgres-validators` | partial | Pydantic validators for GCP Postgres | Likely a Pydantic lib, not Terraform itself. |
| `google-cloud-terraform-neo4j` | mapped | Neo4j on GCP | Older fork. (Q3 resolved: kept as-is per fork-of-fork convention.) |
| `google-cloud-terraform-neo4j-1` | mapped | Neo4j on GCP | **The one in active use** with a version tag. (Q3 resolved.) |
| `terraform-gcp-cloudrun-vpc-job` | partial | Cloud Run job w/ VPC | |
| `gcp-vpc-egress-terraform` | partial | VPC egress | |

## Agentic Systems (2)

| Repo | Status | Purpose | Notes |
|---|---|---|---|
| `agentic-log-attacker` | mapped | Cloud log → to-do → PR fixer | Has description. Different concern from dev-nexus (logs vs. patterns). |
| `skill-bridge` | partial | Claude Code skills → OpenClaw | TypeScript. Closes a gap: lets skills authored for Claude Code be used in OpenClaw. |

> Note: `dependency-orchestrator` and `pattern-miner` were originally in this bucket but are **archived** (Q1, Q2, fork-of-fork convention). They've been moved out of the active inventory.

## Utilities / Misc (10)

| Repo | Status | Purpose | Notes |
|---|---|---|---|
| `machine-learning-commons` | partial | Base ML tools | Jupyter. Updated 2026-05-27. |
| `openstreetmap-location-data-cleaner` | partial | OSM data cleaner | Likely consumed by `trip-planning` or similar. |
| `GlobalBitings` | **unexplored** | unclear | Python, no description, updated 2026-05-03. **Operator decision 2026-06-14: leave as-is.** |
| `design-artifacts` | mapped | Organizational design artifacts (brand guide, visual identity) | Per operator, 2026-06-14. |
| `business-website` | partial | Public site | HTML. |
| `core-business-management` | mapped | AI agent designated for managing DarojaAI's core business operations | Per operator, 2026-06-14. |
| `twentycrm-management` | partial | TwentyCRM management tooling | Paired with `bond-nexus`? Needs confirmation. |
| `dev-nexus-frontend` | mapped | dev-nexus React UI | Vite + TypeScript. |
| `gcp-postgres-terraform-example` | partial | Public example of Postgres+Cloud Run+Terraform | Public-facing. |

---

## Summary statistics

Snapshot 2026-06-14 (post-batch, refreshed via `skills/audit-org-readmes`):

- **Total repos:** 42 (active) + 2 (archived, `dependency-orchestrator` + `pattern-miner`) = 44 total; 42 in active use
- **Empty GitHub descriptions:** 2 (5%) — was 20 (47%); 18 fixed, 2 remaining are archived repos (read-only, see `OPEN_QUESTIONS.md` Q-arch)
- **No README:** 6 — `GlobalBitings`, `core-business-management`, `design-artifacts`, `darojaai_architect` (this repo), `gcp-postgres-terraform-example`, `trip-planning`
- **Neither README nor description:** 1 — `GlobalBitings` only. (`core-business-management` and `design-artifacts` now have descriptions but still no READMEs.)
- **Mapped:** 23
- **Partial:** 11
- **Unexplored:** 1
- **Flagged:** 0 (Q3 resolved: the two Neo4j repos are intentional fork-of-fork, not duplicates)

The "empty description" ratio was the single biggest org-wide documentation gap. After a one-time batch on 2026-06-14, the remaining 2 are archived-repo blockers. README and description are *different* signals: README = developer-facing docs; description = discoverability on the org page.

> The "1 unexplored" is `GlobalBitings` (operator decision 2026-06-14: leave as-is).

---

## What I'd audit next

1. **README audit (Q11, Q12)** — for every repo, does it have a README? Does the README say what the repo is, what it depends on, and how to run it? Do all READMEs link back to `.github` governance?
2. **CODEOWNERS audit (Q6)** — does each repo have a CODEOWNERS file? Maps to the per-repo owner requirement in `GOVERNANCE.md`.
3. **`infra-actions` consumer audit (Q7)** — which workflows import which actions? Establishes the CI/CD dependency graph and identifies roll-your-own cases.
4. **Stale branches / open PRs / open issues (Q13)** — surface sunset candidates.
5. **DAT contract org-wide applicability (Q8)** — read `.github/docs/CI-CD-STANDARDS.md` to confirm whether the contract from `openclaw-gateway` is org-wide or local.
6. **Q5 rename: `devnexus-common` → `py-daroja-libs`** — queued batched PR per consumer repo.
7. **Q4 RFC: Shared Libraries & Templates category** — file in `.github`.
8. **Q15-Q17: intelligent-feed shared-lib hardening** — AGENTS.md, env-var paths, CI.
