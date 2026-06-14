# Repo Inventory

> **Status legend:**
> - `mapped` — purpose, layer, and relationships understood
> - `partial` — purpose clear, relationships inferred (need confirmation)
> - `unexplored` — purpose unclear from outside; needs clone + read
> - `flagged` — known issue (duplicate, stale, naming, etc.)
>
> **Categories** match `DarojaAI/.github/GOVERNANCE.md` where possible, with extra buckets for things the governance doc doesn't cover.

Last refresh: 2026-06-14

---

## Governance (1)

| Repo | Status | Owner | Notes |
|---|---|---|---|
| `.github` | mapped | Infrastructure team | P0. Source of `GOVERNANCE.md`, `CONTRIBUTING.md`, `pull_request_template.md`, `workflow-templates/`. Defines the four official categories. |

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
| `trip-planning` | partial | AI travel assistant | **No README.** Description: itinerary, destination research, travel logistics. Likely consumes `mcp-tooling/duffel`. |
| `research-orchestrator` | mapped | Research extraction (Firecrawl + Cognee) | FastAPI. Per-project activation. |

## Shared Infrastructure (10)

| Repo | Status | Purpose | Notes |
|---|---|---|---|
| `infra-actions` | mapped | Composite GitHub Actions | CI/CD backbone. Has `CONTRIBUTING.md` with action-authoring rules. |
| `devnexus-common` | mapped | Shared Python utils | LLM client (Anthropic + OpenRouter), tracing. **Naming concern:** name implies `dev-nexus` ownership but it's a shared lib. |
| `daroja-frontend-starter` | mapped | Vite 19 + Cloudflare template | Should be the seed for any new frontend. |
| `vpc-infra` | mapped | Shared VPC for GCP Postgres | Per its description. |
| `gcp-postgres-terraform` | mapped | Postgres on GCP | Compute Engine. |
| `gcp-dbt-terraform` | mapped | dbt on GCP | |
| `gcp-postgres-validators` | partial | Pydantic validators for GCP Postgres | Likely a Pydantic lib, not Terraform itself. |
| `google-cloud-terraform-neo4j` | flagged | Neo4j on GCP | **Duplicate?** See `google-cloud-terraform-neo4j-1` below. |
| `google-cloud-terraform-neo4j-1` | flagged | Neo4j on GCP | Likely a v2 or fork of above. Two repos with same name + `-1` suffix is a smell. |
| `terraform-gcp-cloudrun-vpc-job` | partial | Cloud Run job w/ VPC | |
| `gcp-vpc-egress-terraform` | partial | VPC egress | |

## Agentic Systems (4)

| Repo | Status | Purpose | Notes |
|---|---|---|---|
| `agentic-log-attacker` | mapped | Cloud log → to-do → PR fixer | Has description. Different concern from dev-nexus (logs vs. patterns). |
| `dependency-orchestrator` | **unexplored** | unclear | Python, no description, updated 2026-06-10. |
| `pattern-miner` | **unexplored** | unclear | Python, no description, updated 2026-06-10. **Naming overlap with `dev-nexus` ("pattern discovery").** |
| `skill-bridge` | partial | Claude Code skills → OpenClaw | TypeScript. Closes a gap: lets skills authored for Claude Code be used in OpenClaw. |

## Utilities / Misc (10)

| Repo | Status | Purpose | Notes |
|---|---|---|---|
| `machine-learning-commons` | partial | Base ML tools | Jupyter. Updated 2026-05-27. |
| `openstreetmap-location-data-cleaner` | partial | OSM data cleaner | Likely consumed by `trip-planning` or similar. |
| `GlobalBitings` | **unexplored** | unclear | Python, no description, updated 2026-05-03. |
| `intelligent-feed` | **unexplored** | unclear | Python, no description, updated 2026-05-07. |
| `design-artifacts` | **unexplored** | unclear | HTML. Probably design files, not runnable code. |
| `business-website` | partial | Public site | HTML. |
| `core-business-management` | **unexplored** | unclear | No language set, no description. Oldest in the org (created 2026-04-24). |
| `twentycrm-management` | partial | TwentyCRM management tooling | Paired with `bond-nexus`? Needs confirmation. |
| `dev-nexus-frontend` | mapped | dev-nexus React UI | Vite + TypeScript. |
| `gcp-postgres-terraform-example` | partial | Public example of Postgres+Cloud Run+Terraform | Public-facing. |

---

## Summary statistics

Snapshot 2026-06-14 (post-batch, refreshed via `skills/audit-org-readmes`):

- **Total repos:** 42
- **Empty GitHub descriptions:** 2 (5%) — was 20 (47%); 18 fixed, 2 remaining are archived repos (read-only, see `OPEN_QUESTIONS.md` Q-arch)
- **No README:** 6 — `GlobalBitings`, `core-business-management`, `design-artifacts`, `darojaai_architect` (this repo), `gcp-postgres-terraform-example`, `trip-planning`
- **Neither README nor description:** 3 — `GlobalBitings`, `core-business-management`, `design-artifacts`
- **Mapped:** 18
- **Partial:** 12
- **Unexplored:** 6
- **Flagged:** 2

The "empty description" ratio was the single biggest org-wide documentation gap. After a one-time batch on 2026-06-14, the remaining 2 are archived-repo blockers. README and description are *different* signals: README = developer-facing docs; description = discoverability on the org page.

---

## What I'd audit next

1. **README audit** — for every repo, does it have a README? Does the README say what the repo is, what it depends on, and how to run it?
2. **CODEOWNERS audit** — does each repo have a CODEOWNERS file? Maps to the per-repo owner requirement in `GOVERNANCE.md`.
3. **`infra-actions` consumer audit** — which workflows import which actions? Establishes the CI/CD dependency graph.
4. **Mystery repo clones** — clone the 6 unexplored repos and figure out what they are.
5. **Duplicate detection** — confirm or rule out the two `google-cloud-terraform-neo4j*` repos. Check for other name collisions.
