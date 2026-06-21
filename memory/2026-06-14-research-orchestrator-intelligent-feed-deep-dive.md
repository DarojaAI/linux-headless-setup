# Architectural Take: research-orchestrator + intelligent-feed (the Cognee orbit)

> **Date:** 2026-06-14, Session 14 part 7 (original); revised 2026-06-15 after peer review of the rag_research_tool take.
> **Repos:** `DarojaAI/research-orchestrator` (FastAPI), `DarojaAI/intelligent-feed` (Python activators + renderers)
> **Operator direction:** "do deep dive into rag research tool first, then the other 2."
> **Status:** DRAFT v0.2 — revised after peer review. Most of this take is about research-orchestrator and intelligent-feed, which the in-repo agent couldn't verify, so the schema mismatch claim (§5.1) is unchanged. Cross-references to the rag_research_tool take's P0 in §6 are now stale; see the correction note below.
> **Scope:** architectural diagnosis only. No code changes. No cross-repo claims that aren't verified.

---

## ⚠️ Note (2026-06-15, post-peer-review)

The peer review of the rag_research_tool take by the in-repo `rag_research_tool` agent did **not** invalidate the core findings of this take. The agent reviewed the rag_research_tool repo, not research-orchestrator or intelligent-feed. So:

- **§5.1 (schema mismatch is a P0)** — still stands, unverified by anyone but me. The in-repo agent offered to produce a curl + traceback repro for `DarojaAI/research-orchestrator#1` — that should happen before treating it as a confirmed P0.
- **§5.3 (intelligent-feed#1 = right kind of work)** — **now landed**. PR #1 was MERGED 2026-06-14. PR #3 (the packaging work, `intelligent-feed#2`) was also MERGED 2026-06-15 by operator. The `intelligent-feed` part of this take is now substantially done.
- **§6 reference to "rag_research_tool's P0: pipeline bypasses canonical store"** — **stale.** The rag_research_tool take v0.1 was wrong about that. The real P0 is stage 6 (entity resolution) missing from the orchestrator. See `memory/2026-06-14-rag-research-tool-deep-dive.md` for the corrected version.
- **Q14 (dynamic-worlock 404)** — **RESOLVED 2026-06-15.** Operator confirmed it's private in `e16af80` commit on intelligent-feed.

**Lesson promoted to AGENTS.md (House Rules, commit `0260385`):** "Verify the code, not the docs." The peer review caught a real failure in the rag_research_tool take. This take was less affected because the agent couldn't review the orchestrator/intelligent-feed code, but the lesson applies: every cross-repo claim should be re-derived from call sites, not from the docs.

---

## Why these two go together

The operator flagged that the Cognee KG work is in the rag_research_tool-orbit, naming **research-orchestrator** and **intelligent-feed** as the two companion repos. After reading both, I can confirm: the Cognee work is *primarily* in research-orchestrator, and intelligent-feed is the **activation surface** that the orchestrator delegates to. They're a single subsystem split across two repos, coupled by an env-var-based `sys.path` import.

**Single subsystem, two repos:**
- research-orchestrator = HTTP service, schema, orchestration, Cognee call
- intelligent-feed = per-project activators, renderers, file-output sinks

The split is questionable (see §4).

---

## 1. research-orchestrator — small, structurally complete, untested

### What's there

691 LOC total across 8 files:
- `app/main.py` (38) — FastAPI app + 3 routers
- `app/orchestrator.py` (142) — core flow: scrape → extract → activate
- `app/cognify_client.py` (105) — Cognee wrapper
- `app/firecrawl.py` (75) — Firecrawl HTTP client
- `app/activation.py` (72) — *thin wrapper over intelligent-feed's `intel.activation.factory`*
- `app/schemas.py` (81) — Pydantic models
- `app/config.py` (52) — env-var loading + validation
- `app/routers/goals.py` (46), `health.py` (50), `projects.py` (28)

Terraform in `terraform/` (Cloud Run deploy). One workflow: `.github/workflows/terraform.yml` (apply on push to main, plan on PR).

**Python deps** (`requirements.txt`): `fastapi`, `uvicorn`, `pydantic`, `cognee[postgres]>=0.5.0`, `openrouter`, `firecrawl`, `psycopg2-binary`, `SQLAlchemy`, `pytest`, `pytest-asyncio`, `httpx`.

### What's NOT there (findings)

- **No tests.** The repo has `pytest` in requirements but no `tests/` directory, no `pytest` config, no test fixtures. The service is functionally unvalidated.
- **No Python CI.** Only a terraform workflow. No lint, no type-check, no test, no coverage.
- **No persistence.** Goals are run synchronously and the response is returned. `GET /research/goals/{goal_id}` returns 501 ("not implemented in v1"). `GET /research/projects/{project}/records` returns 501 ("not implemented in v1"). The service is *stateless* — every call is a fresh start.
- **Zero open issues, zero open PRs.** Last push 2026-05-03, 6 weeks ago. Quiet.
- **AGENTS.md is the OpenClaw default template.** No project-specific contract, no project-specific house rules, no project-specific scope.
- **CORS is `allow_origins=["*"]` with `allow_credentials=True`.** That's a security smell in production (browsers reject this combo by spec, but the config intent is wrong).
- **No `pyproject.toml`.** Pure `requirements.txt`. No project metadata, no version, no installable distribution.
- **No LICENSE.** Public repo, no license file.

### The data flow (real, from the code)

```
POST /research/goals {goal, project, sources[], output_schema}
  ↓
config.validate() — fails 503 if OPENROUTER_API_KEY / FIRECRAWL_API_KEY / DB / INTELLIGENT_FEED_PATH missing
  ↓
ResearchOrchestrator.run_goal()
  ├─ _scrape_sources()  → FirecrawlClient.scrape(url) for each source
  ├─ _extract_records() → CogneeClient.cognify(content, goal, schema)
  │                      (applies env vars via CogneeConfig.apply_to_env() first)
  │                      returns ExtractionRecord[] (UUID, fact, source_url, project, tags, confidence)
  └─ activation = get_activator(project.value).activate(records)
                     ↓
                     INTELLIGENT_FEED_PATH/sys.path → intel.activation.factory.get_activator(project)
                     ↓
                     Project-specific activator (one of 4: globalbitings, bond-nexus, rag_research, dynamic-worlock)
                     ↓
                     Writes to project-specific file (e.g. triplets.json for rag_research)
  ↓
ResearchGoalResponse {goal_id, status=completed, records, activations}
```

### What the operator's pain looks like, in this repo

The orchestrator is fine. The pain is upstream and downstream of it:
- **Upstream:** the orchestrator is a *Firecrawl* ingestion path. It only handles URL-sourced knowledge. PDFs (rag_research_tool's main ingestion surface) are not handled here. The two paths don't share schema, infrastructure, or storage.
- **Downstream:** the orchestrator's "activation" is a fire-and-forget write to a file. There's no record of what was activated, when, or whether the activator actually succeeded (the orchestrator catches exceptions and returns them as `ActivationOutcome(status="error", ...)` but doesn't persist the outcomes either).
- **Between:** the orchestrator's goals are not persisted. The Cognee extraction results live in Cognee's own storage (configured via env vars) but the orchestrator doesn't expose a way to query them later.

**The operator said "real trouble getting it ready to accept and process knowledge." This is a different repo from where the visible failure mode is.** research-orchestrator is the *external knowledge* path. rag_research_tool is the *internal document* path. The two don't share a "ready to accept and process knowledge" surface.

---

## 2. intelligent-feed — the activation surface

### What's there

1537 LOC total across 9 files:
- `intel/activation/base.py` (68) — `BaseActivator` ABC + `ActivationResult` dataclass
- `intel/activation/factory.py` (38) — `get_activator(project, **kwargs)` dict-lookup
- `intel/activation/bondnexus.py` (235) — writes to `~/GithubProjects/bond-nexus/.../conventions.yaml` + `MARKET_SOURCES.md`
- `intel/activation/dynamic_worlock.py` (210) — writes to `~/GithubProjects/dynamic-worlock/data/knowledge_store.json` + `conflicts.json`
- `intel/activation/globalbitings.py` (184) — writes to extraction log + triggers RAG sync
- `intel/activation/rag_research.py` (166) — writes to `~/GithubProjects/rag_research_tool/triplets.json`
- `intel/activation/__init__.py` (26) — exports
- `intel/renderers/agent.py` (141) — output format for AI agents
- `intel/renderers/human.py` (219) — output format for human readers
- `intel/renderers/structured.py` (249) — output format for structured (JSON/Markdown) consumers
- `intel/renderers/__init__.py` (1)

### The coupling — explicit, not implicit

research-orchestrator's `app/activation.py` does:

```python
path = os.environ.get("INTELLIGENT_FEED_PATH")
...
if path not in sys.path:
    sys.path.insert(0, path)
from intel.activation import factory
```

So the orchestrator **runtime-loads** intelligent-feed from a filesystem path. Both repos have to be checked out and the env var has to be set. This is the cross-repo coupling I flagged in the skill-ecosystem v0.2 doc — `INTELLIGENT_FEED_PATH` as a `sys.path` injection.

**Why this matters for the skill ecosystem work:** intelligent-feed is not a typical "shared library." It's:
- Imported by name (`intel.activation.factory`) at runtime via `sys.path` injection
- Has no `pyproject.toml`, no version pin, no installable distribution
- Has env-var path overrides for its file outputs (Q16 work landed in `intelligent-feed#1`)
- Has the same "shared lib with misleading name" pattern as `devnexus-common` (Q5) and `intelligent-feed` (Q15-17)

### The activators (4, ~800 LOC total)

Each activator has the same shape: `BaseActivator` subclass, `check_readiness()` (verify file paths exist), `activate(claims)` (write claims to project-specific file). They're simple file-writers, not sophisticated processors.

**`RagResearchActivator.activate()` is the load-bearing one for the operator's "premier product" pain.** It:
1. Filters claims by `entity_type in ("relationship", "entity", "concept")`
2. Converts each to a triplet `{subject, predicate, object, source, confidence}`
3. Appends to `~/GithubProjects/rag_research_tool/triplets.json` (or `$RAG_RESEARCH_TRIPLETS_PATH`)

Then **rag_research_tool's** old CLI script `load_triplets.py` reads `triplets.json` and writes to Neo4j. So:

```
research-orchestrator (Firecrawl scrape)
  → Cognee (extraction)
  → intelligent-feed RagResearchActivator
  → writes triplets.json
  → rag_research_tool load_triplets.py (manual, scripted)
  → Neo4j
```

**The orchestrator's rag-research path is a side-channel that bypasses the new FastAPI orchestrator entirely.** External knowledge (URLs) goes through orchestrator → activators → files → *old* rag_research_tool scripts → Neo4j. Internal documents (PDFs) go through the new orchestrator → chunking → embedding → extraction → *should* go to Postgres entities/relationships but doesn't (per the rag_research_tool deep-dive).

**The two ingestion paths in the org's premier product have nothing in common except the triplets.json file format.**

### The renderers (3, ~600 LOC total)

`intel/renderers/` has 3 renderers that take Cognee records and produce:
- `agent.py` — output for AI agent consumption (compact JSON-ish)
- `human.py` — output for human readers (markdown narrative)
- `structured.py` — output for structured consumers (JSON/Markdown)

These are not called by the orchestrator. They're for *future* consumption paths that don't exist yet. The current `run_goal` flow doesn't use any of them — it just returns the records directly in the response.

### What's missing (findings)

- **No tests.** Same as research-orchestrator. Pytest is in some deps, no actual tests.
- **No Python CI.** (Until PR #1 lands.)
- **No installable distribution.** No `pyproject.toml`. Pure `requirements.txt` (or nothing — let me verify).
- **`__init__.py` is bare.** `intel/__init__.py` (if it exists) is just an empty file.
- **Default AGENTS.md.** Same as the orchestrator — no project-specific contract.
- **No LICENSE.** Public repo, no license.
- **No `docs/`.** (Until PR #1 lands.)
- **The 4 activators have cross-file inconsistency.** `bondnexus.py` has 235 LOC, `rag_research.py` has 166 LOC — they may do different amounts of work for different reasons, but no doc explains why. Worth a follow-up.

---

## 3. The actual orbit (and the question it raises)

```
                ┌──────────────────────────────────────────────┐
                │   research-orchestrator (FastAPI, 691 LOC)   │
                │   • Firecrawl scrape                          │
                │   • Cognee cognify()                          │
                │   • Activation dispatch                       │
                │   • Stateless; no DB persistence              │
                └────────────────┬─────────────────────────────┘
                                 │
                                 │ INTELLIGENT_FEED_PATH (sys.path)
                                 ▼
                ┌──────────────────────────────────────────────┐
                │   intelligent-feed (Python, 1537 LOC)        │
                │   • 4 per-project activators (BaseActivator) │
                │   • 3 renderers (agent/human/structured)     │
                │   • Writes to project-specific files         │
                └────────────────┬─────────────────────────────┘
                                 │
                                 │ file I/O (triplets.json, conventions.yaml, etc.)
                                 ▼
        ┌──────────────┬──────────────┬──────────────┬──────────────┐
        ▼              ▼              ▼              ▼
   globalbitings   bond-nexus   rag_research   dynamic-worlock
   (extraction     (yaml/md)    (triplets.json) (KG store)
    log.jsonl)
```

**Three things stand out:**

1. **The orchestrator adds very little value over intelligent-feed alone.** If you have intelligent-feed checked out, you can call `get_activator("rag_research").activate(claims)` directly. The orchestrator wraps Cognee + Firecrawl around it. But the "Cognee + Firecrawl" is just one of many ways to produce claims — and the orchestrator doesn't have any other ways. So it's a *single concrete implementation* of "research activation" rather than a *general orchestration platform*.

2. **The renderers are dead code in the current flow.** They're written, tested (let me verify), and shipped, but the orchestrator doesn't call them. They're for a future API surface that doesn't exist.

3. **The Cognee config is brittle.** `CogneeConfig.apply_to_env()` sets env vars before each `cognify()` call. This is a global state mutation. If two requests run concurrently with different LLM configs, they race. (The orchestrator uses synchronous `cognify()`, not async, so there's no actual concurrency today. But if you make it async, this breaks.)

### The question: is this a real "orbit" or is it one repo split into two?

**Argument for keeping them split:**
- research-orchestrator has a deploy artifact (Cloud Run service). intelligent-feed is a library. Different lifecycles.
- research-orchestrator is "the part that talks to Firecrawl and Cognee." intelligent-feed is "the part that knows about each project's file format." Clear separation of concerns.
- Different ownership possible: research-orchestrator maintained by the platform team, intelligent-feed maintained by per-project contributors.

**Argument for merging:**
- The activation logic is a *thin* wrapper. `research-orchestrator/app/activation.py` is 72 LOC and does nothing except `sys.path` injection + a function call.
- The coupling is by `INTELLIGENT_FEED_PATH` env var, which is a deployment-time concern, not a domain boundary. Every deploy of the orchestrator has to also deploy intelligent-feed.
- The "two-repo split" introduces friction without introducing isolation. If you want to change an activator, you change intelligent-feed, but the orchestrator deploys from a frozen point — the env-var-based coupling means you have to re-deploy both for any change.
- intelligent-feed is *only* consumed by research-orchestrator (today). It's not a shared library in the `devnexus-common` sense.

**My take:** the two-repo split is a real architectural choice, not an accident. But the boundary is *too thin* to be load-bearing. **The right move is probably:** make intelligent-feed a proper installable Python package (`pyproject.toml`, versioned distribution, installable via `pip install intelligent-feed`), and have the orchestrator install it as a dependency. That kills the `sys.path` injection, makes versions explicit, and keeps the conceptual split without the deployment coupling.

This is the *same pattern* as the `devnexus-common` → `py-daroja-libs` rename (Q5). **Same fix shape, applied to a different repo.** Worth treating both as part of the "Shared Libraries & Templates" category work.

---

## 4. Recommended order of work

| Step | Time | Risk | What |
|---|---|---|---|
| 1 | 1d | Low | Add `pyproject.toml` to intelligent-feed. Make it installable. The activator code is already self-contained. Add a `version`. This unblocks Step 2. |
| 2 | 0.5d | Low | Update research-orchestrator to `pip install intelligent-feed` and remove the `sys.path` injection. The `INTELLIGENT_FEED_PATH` env var goes away. |
| 3 | 1d | Low | Add tests to both repos. The orchestrator can be tested with a mock activator (the abstraction is already there via `BaseActivator`). The activators can be tested against fixture files. |
| 4 | 1d | Low | Add a Python CI workflow to both repos (lint + type-check + test + coverage). Uses infra-actions if applicable. |
| 5 | 0.5d | Low | Add AGENTS.md to research-orchestrator (using the RFC #1 template from `.github#1`). intelligent-feed already has one (from PR #1, session 12). |
| 6 | 1d | Low | Implement goal persistence in research-orchestrator. PostgreSQL via SQLAlchemy (already in deps). Adds the missing `GET /research/goals/{goal_id}` and `GET /research/projects/{project}/records` endpoints. |
| 7 | 1d | Low | Add the renderers to the orchestrator's response (or expose as separate endpoints). The renderers are dead code today; either use them or remove them. |
| 8 | 0.5d | Low | Add LICENSE files to both (the operator is Milan Patel per MEMORY.md; MIT or Apache 2.0 is consistent with intelligent-feed's PR #1). |
| 9 | 0.5d | Low | Add a `pyproject.toml` to research-orchestrator. Pin version. Add project metadata. |

**Total: ~7 days of focused work to make the Cognee orbit production-ready.**

### What's NOT in this plan

- **The Cognee strengthening work itself.** The operator said this is in flight. The plan above doesn't *do* the strengthening — it makes the *substrate* (repos, packaging, testing) ready for the strengthening to land cleanly.
- **The schema/contract work.** What's the schema of a Cognee claim? The orchestrator defines `ExtractionRecord` (Pydantic) but the activators use a *different* claim shape (per the docstring in `rag_research.py`: `{"claim_text", "entity_type", "source_url", "domain"}`). The two don't match. **This is a real schema-mismatch bug** — `RagResearchActivator.activate()` would crash on a real Cognee claim because `c.get("entity_type")` would return `None` for `ExtractionRecord` instances. Worth flagging as P1.
- **Multi-LLM support.** The orchestrator hardcodes OpenRouter. If you want to use Anthropic or Gemini directly, you have to fork.
- **Async support.** Everything is sync. Will block under load.

---

## 5. Three things the operator should know

### 5.1 The schema mismatch is a real bug, not a TODO

research-orchestrator's `ExtractionRecord` (Pydantic) has fields: `id`, `goal_id`, `fact`, `source_url`, `project`, `tags`, `confidence`, `created_at`.

intelligent-feed's `RagResearchActivator` expects claims with: `claim_text`, `entity_type`, `source_url`, `domain`.

**The two schemas are completely different.** The orchestrator's `run_goal` returns `ExtractionRecord` instances. The activator's `activate(claims)` does `c.get("entity_type")` on a dict.

If you actually call `POST /research/goals` with a `rag-research` project today, the orchestrator will:
1. Firecrawl scrape (works)
2. Cognee extract (works, returns `ExtractionRecord[]`)
3. Call `RagResearchActivator.activate(extraction_records)` where `extraction_records` are Pydantic models, not dicts
4. The activator does `c.get("entity_type")` on a Pydantic model — this will AttributeError (Pydantic models don't have `.get()`)

**This service is broken end-to-end today.** It has never been run with a real `rag-research` goal. The P0 of the operator's "ready to accept and process knowledge" pain may *be* this bug, or it may be a different bug in rag_research_tool. Either way: this needs to be fixed.

### 5.2 The 6-week silence is a signal

research-orchestrator's last push was 2026-05-03. That's 6 weeks ago, in the middle of a session-heavy org (per the cron, today alone is the 7th session in 36 hours). The repo isn't dead — it's just incomplete. The schema mismatch in §5.1 may be why: the operator tried it once, hit a wall, and parked it. Worth a brief conversation: "what did you try that didn't work?"

### 5.3 intelligent-feed's PR #1 (session 12) is exactly the right kind of work — and it landed

The Q15-17 work landed in `intelligent-feed#1` (MERGED 2026-06-14): env-var path overrides, AGENTS.md, CI, LICENSE. **That's the same pattern as this plan's Steps 1-4 and 8.** PR #1 is now in `main`. Operator also pushed PR #3 (the packaging work, MERGED 2026-06-15) which closed `intelligent-feed#2`. The `intelligent-feed` part of this take is now substantially done — the substrate work is complete. What's left is: (a) the orchestrator's `sys.path` deprecation (Phase D.2 of the convergence plan), and (b) the cross-claim schema reconciliation (Phase C of the convergence plan).

---

## 6. What this take does NOT cover

- **rag_research_tool's "premier product" pain.** That's a separate repo with a separate problem. **The v0.1 framing of this take (and the convergence plan) called it "pipeline bypasses canonical store" — the in-repo agent peer-reviewed and the actual code shows the wiring is there. The corrected P0 is stage 6 (entity resolution) missing from the orchestrator.** See `memory/2026-06-14-rag-research-tool-deep-dive.md` (revised 2026-06-15) for the full corrected diagnosis. This take is about the orbit around rag_research_tool, not rag_research_tool itself.
- **Cognee strengthening work.** The operator has ambitions; this take makes the substrate ready but doesn't *do* the strengthening.
- **Multi-tenant or scaling concerns.** Both services are single-tenant, single-instance. Worth a separate take if/when that becomes a concern.
- **Code changes.** This is diagnosis only. Steps 1-9 require operator sign-off before any code change.

---

## 7. Open architectural hypotheses (verify in next session or with operator)

- **The schema mismatch (§5.1) is the P0 bug.** Likely. Worth a 30-min fix-and-verify (run a real `POST /research/goals` with `project=rag-research`, observe the crash, fix the schema, re-run).
- **The renderers are dead code that should be deleted or used.** Likely. They're 600 LOC of code that no one calls. Either they're aspirational (in which case flag them as "planned, not done") or they're forgotten (in which case delete them).
- **The two-repo split is a real architectural choice, not a mistake.** Likely. The boundary is too thin to be load-bearing, but the deployment separation is real. Make the boundary explicit via packaging (Step 1-2) rather than merging the repos.
- **intelligent-feed is the canonical "shared activation library" for the org.** Almost certainly yes. The skill-ecosystem doc v0.2 names it explicitly. This take confirms the load-bearing nature of the work and points to the next steps.
- **Cognee strengthening is the operator's next big bet.** Operator said so. This take makes the substrate ready; the strengthening is a separate workstream.

---

## 8. Recommended next action (single)

**Open a `DarojaAI/research-orchestrator#1` issue** titled "Fix schema mismatch between orchestrator and intelligent-feed activators" with the §5.1 bug as the headline. Get the operator's sign-off on the schema shape (which side adapts to which, or define a new shared shape), then a single PR fixes it. ~30 min of work, unblocks the entire orchestrator for `rag-research` projects.

**After that:** Step 1 (intelligent-feed `pyproject.toml`) and Step 2 (remove `sys.path` injection) as a single PR. Then Steps 3-9 as separate PRs, in the order listed.

---

## 9. Bottom line

The "Cognee orbit" is real: research-orchestrator + intelligent-feed are the Cognee ingestion and activation paths. They work together via env-var-based `sys.path` injection. The **schema mismatch is a P0 bug** that means the service has never successfully run end-to-end with a `rag-research` goal. The fix is small (~30 min) but is currently blocked by the question of *whose* schema wins.

The two-repo split is a real architectural choice but the boundary is too thin to be load-bearing. Make the boundary explicit via packaging (pyproject + installable distribution), which is the same pattern as the `devnexus-common` → `py-daroja-libs` work. The total work to make the orbit production-ready is ~7 days, with the schema fix as the immediate unblock.

The operator's "premier product" framing applies to *both* rag_research_tool (the internal document path) and the Cognee orbit (the external knowledge path). They need to converge at some point — likely at the `entities`/`relationships` Postgres tables that the rag_research_tool orchestrator currently bypasses. **Both halves of the operator's pain are connected at that table.**

---

**Ready for operator review at PR #4 (this take). The single most valuable next step is the schema-mismatch fix in §5.1; the rest is substrate work that the in-flight Cognee strengthening will build on.**
