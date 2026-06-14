# DarojaAI Org Architecture

> **Status:** DRAFT v0.1 — first cut after initial recon 2026-06-14.
> **Source of truth:** This is a *model* built from `gh repo list`, `GOVERNANCE.md`, and READMEs of key repos. It will be wrong in places. Flag corrections to `OPEN_QUESTIONS.md`.

---

## The Org in One Picture

```
DarojaAI/
├── .github/                    # Org governance, standards, templates  (P0)
│
├── PROVISIONING (L1 → L2 → L3a → L3b)
│   ├── terraform-hcloud-linux-vm      # L1: VM (Hetzner)
│   ├── terraform-gcp-wrappers         # L1 alt: VM (GCP)
│   ├── linux-headless-setup           # L2: no-GUI base
│   ├── linux-desktop-setup            # L2: GUI base
│   └── linux-desktop-seed             # L3a: VM ops + deploy
│
├── INTELLIGENCE TRIAD (Knowledge / Capability / Coordination)
│   ├── dev-nexus                      # Knowledge: patterns, lessons, drift
│   ├── mcp-tooling                    # Capability: external APIs, host ops
│   └── openclaw-gateway               # Coordination: agent runtime (L3b)
│
├── APPLICATION PRODUCTS
│   ├── rag_research_tool              # PDF → vector RAG (GCP, Atlas)
│   ├── rag-research-tool-frontend     # its React UI
│   ├── bond-nexus                     # TwentyCRM sales pipeline
│   ├── trip-planning                  # AI travel (uses mcp-tooling/duffel)
│   └── research-orchestrator          # Firecrawl + Cognee extraction
│
├── SHARED INFRASTRUCTURE
│   ├── infra-actions                  # composite GitHub Actions
│   ├── devnexus-common                # shared Python (LLM client, etc.)
│   ├── daroja-frontend-starter        # Vite 19 + Cloudflare template
│   ├── vpc-infra                      # GCP VPC modules
│   ├── gcp-postgres-terraform         # Postgres on GCP
│   ├── gcp-dbt-terraform              # dbt on GCP
│   ├── gcp-postgres-validators        # Pydantic validators
│   ├── google-cloud-terraform-neo4j   # Neo4j modules
│   ├── terraform-gcp-cloudrun-vpc-job # Cloud Run job
│   └── gcp-vpc-egress-terraform       # VPC egress
│
├── AGENTIC SYSTEMS
│   ├── agentic-log-attacker           # log → to-do → PR fixer
│   ├── dependency-orchestrator        # (purpose unclear — see OQ)
│   ├── pattern-miner                  # (purpose unclear)
│   └── skill-bridge                   # Claude Code skills → OpenClaw
│
├── UTILITIES / MISC
│   ├── machine-learning-commons       # base ML tools
│   ├── openstreetmap-location-data-cleaner
│   ├── GlobalBitings                  # (purpose unclear)
│   ├── intelligent-feed               # (purpose unclear)
│   ├── design-artifacts               # HTML design files
│   ├── business-website               # public site
│   ├── core-business-management       # (purpose unclear)
│   ├── twentycrm-management           # TwentyCRM management tooling
│   ├── dev-nexus-frontend             # dev-nexus UI
│   └── gcp-postgres-terraform-example # public example repo
│
└── darojaai_architect                 # ← THIS REPO (me)
```

---

## The Four Stacks

### 1. Provisioning Stack (L1 → L2 → L3a → L3b)

The org's flagship pipeline: bare VM → Discord AI agent. Three README sources confirm the layering, though wording varies.

| Layer | Repos | Purpose | Notes |
|---|---|---|---|
| **L1** (VM) | `terraform-hcloud-linux-vm`, `terraform-gcp-wrappers` | Provision bare Linux VM | Hetzner is the documented primary; GCP wrapper exists for secondary use. |
| **L2** (OS) | `linux-headless-setup`, `linux-desktop-setup` | Configure OS, install dev tools | Two flavors: headless (server) and desktop (with GUI/RDP). `linux-headless-setup` is explicitly for OpenClaw gateway hosts. |
| **L3a** (Ops) | `linux-desktop-seed` | VM ops, deploy orchestration, CI/CD | Imports L1 + L2, adds maintenance and version API. |
| **L3b** (Agent) | `openclaw-gateway` | Discord AI agent runtime | Built on OpenClaw. Sits on top of L3a. |

**Key contracts:**
- Each layer can be used independently (per `linux-desktop-seed` README).
- `openclaw-gateway` requires L2 (uses `desktopuser` conventions).
- `linux-desktop-seed` is described as "Validated for personal/developer use" — production-readiness of the full stack is a separate question.

### 2. Intelligence Triad

Three systems with an explicit, load-bearing boundary contract at `dev-nexus/docs/architecture/architectural-boundaries.md` (P0, dated 2026-06-09).

```
       ┌──────────────────┐
       │ openclaw-gateway │  Coordination: routes, sessions, policy
       │      (L3b)       │
       └────────┬─────────┘
                │ calls
       ┌────────┴─────────┐
       │   mcp-tooling    │  Capability: Duffel, Cal.com, vm-ops, payments
       │  (Capability)    │
       └──────────────────┘
                ▲
                │ query/verify
       ┌────────┴─────────┐
       │    dev-nexus     │  Knowledge: patterns, drift, lessons, RAG
       │   (Knowledge)    │
       └──────────────────┘
```

**The forcing function:** "If a PR adds code to system X that could be answered by system Y, it belongs in Y." This is the spec. Any drift here is P0.

**OpenClaw repo naming confusion to be aware of:**
- `openclaw-gateway` = L3b Discord agent platform (DarojaAI's product, built on OpenClaw).
- OpenClaw (upstream, https://openclaw.ai) = the underlying runtime/framework.
- Don't conflate them in docs.

### 3. Application Products

| Repo | Purpose | Stack | Status from recon |
|---|---|---|---|
| `rag_research_tool` | PDF → vector RAG with FastAPI | Python, FastAPI, GCP, Atlas, Neo4j | Active, has `INTEGRATION_GUIDE.md`, well-documented |
| `rag-research-tool-frontend` | React UI for above | TypeScript | Public, paired with backend |
| `bond-nexus` | TwentyCRM sales-pipeline setup | Docs + scripts | Private; described as "60-min setup package" |
| `trip-planning` | AI travel assistant | Unknown (no README) | Private; desc says uses itinerary/destinations/logistics |
| `research-orchestrator` | Research extraction (Firecrawl + Cognee) | FastAPI | Private; standalone service, per-project activation |

`trip-planning` and `research-orchestrator` are the two application repos most likely to consume `mcp-tooling` services. Worth confirming dependencies.

### 4. Shared Infrastructure

These repos serve multiple consumers:

- **`infra-actions`** — composite GitHub Actions library. Used by GCP, Docker, Terraform, and other CI/CD. Has a `CONTRIBUTING.md` with composite-action rules. Strategic: any new CI need should check here first.
- **`devnexus-common`** — shared Python utilities. Has `common.llm` (unified LLM client for Anthropic + OpenRouter). Despite the name, it's not just for `dev-nexus` — it's a shared library. **Naming risk:** name implies `dev-nexus` ownership. See `OPEN_QUESTIONS.md`.
- **GCP Terraform modules** (`vpc-infra`, `gcp-postgres-terraform`, `gcp-dbt-terraform`, `terraform-gcp-cloudrun-vpc-job`, `google-cloud-terraform-neo4j`, `gcp-vpc-egress-terraform`) — each scoped to one resource type. The two Neo4j repos (`google-cloud-terraform-neo4j` and `google-cloud-terraform-neo4j-1`) are likely the same thing at different versions — see `OPEN_QUESTIONS.md`.
- **`daroja-frontend-starter`** — template for new frontends. Should be the starting point for any new TS/React product.

---

## Cross-Cutting Concerns

### Standards and governance
`DarojaAI/.github` is the source of truth. Categories per `GOVERNANCE.md`:
1. Infrastructure (IaC) — owned by infra team
2. Core Services — owned by product teams
3. Frontend Applications — owned by frontend team
4. Public/Examples — owned by docs/advocacy

**Note:** The `GOVERNANCE.md` doesn't explicitly call out "agentic systems" or "shared infrastructure libraries" as categories. The four-way split doesn't fit `infra-actions`, `devnexus-common`, `agentic-log-attacker`, etc. — see `OPEN_QUESTIONS.md`.

### Observability
- `dev-nexus` has LangSmith integration per its docs. Likely the org's tracing standard.
- `devnexus-common` has a `[tracing]` extra in `pyproject.toml`. Confirms trace is a first-class concern.
- `infra-actions` has a `resilience/` directory (chaos/recovery actions). Worth investigating.

### Environments
`openclaw-gateway` is the only repo I've seen with explicit multi-environment topology (test/head/prod, one bot per env, env-specific values injected at deploy). This is a strong pattern — the `DAT Contract` (no hardcoded env values) is a model other repos should follow. **Check:** do other repos (especially `dev-nexus`, `mcp-tooling`, `rag_research_tool`) have equivalent hygiene? Hypothesis: probably not, based on description field gaps.

---

## What This Map Doesn't Show Yet

- **Ownership.** `GOVERNANCE.md` mentions "owner/team" per repo but I don't have a per-repo owner map. Need to scrape GitHub for CODEOWNERS or the repo's "People" tab.
- **Runtime dependencies.** Which services actually call which at runtime? `trip-planning` → `mcp-tooling/duffel` is inferred from `mcp-tooling`'s README. Need to verify with imports/config.
- **Data flow.** Where does data live? Postgres + Neo4j + pgvector are referenced in `rag_research_tool`. Cross-product data sharing? Probably none, but worth checking.
- **CI/CD matrix.** Which repos use `infra-actions` vs roll their own? Need a sweep.
- **The 6 mystery repos** with empty descriptions: `GlobalBitings`, `intelligent-feed`, `pattern-miner`, `dependency-orchestrator`, `design-artifacts`, `core-business-management`. See `OPEN_QUESTIONS.md`.

---

## How to keep this file honest

When I learn something new about a repo, I update the relevant section + bump the version comment at the top. When the operator confirms a structural change (rename, merge, sunset), I update here and propagate to `REPOS.md`.

If a section in this doc contradicts `dev-nexus/docs/architecture/architectural-boundaries.md`, **the boundary doc wins** — it's the explicit P0 contract.
