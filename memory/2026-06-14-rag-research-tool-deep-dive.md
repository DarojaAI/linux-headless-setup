# Architectural Take: rag_research_tool (a.k.a. Synapse)

> **Date:** 2026-06-14, Session 14 part 6
> **Repo:** `DarojaAI/rag_research_tool` — public, v0.2.0, Python (Synapse 1.0.0 in pyproject)
> **Operator question:** "do you have a good depth of understanding of rag-research-tool ecosystem itself? That's probably going to end up being the premier product. But im having real trouble getting it ready to accept and process knowledge"
> **Status:** DRAFT v0.1 — for operator review.
> **Scope of this take:** architectural diagnosis only. No code changes. No cross-repo claims that aren't verified.

---

## What I learned by reading the code

**Renamed/renaming:** `pyproject.toml` calls this `synapse` 1.0.0. GitHub repo is still `rag_research_tool`. The README and AGENTS.md call it "RAG Research Tool" or "Synapse." This is a load-bearing confusion — see Finding F0.

**Scale:** not the small RAG repo the README implies. ~3,934 LOC in `src/rag/`, plus 855 LOC in `tools/pipeline/ingest_documents.py`, plus a 146 KB `wiki_server.py`, plus 4 routers, 4 services, 4 dependency docs. CHANGELOG shows 50+ PRs in 1.5 months (v0.1.0 → v0.2.0).

**Two parallel implementations of the pipeline:**
1. **Old CLI pipeline** (`src/rag/run_kg_pipeline.py`, `save_chunks.py`, `extract_entities.py`, `load_triplets.py`, `entity_resolution.py`) — script-style entry points. Goes PDF → chunks → triplets JSON → Neo4j. **No Postgres write at all.** This is what the docs/kg_development_plan.md describes.
2. **New FastAPI pipeline** (`api/routers/ingest.py`, `api/services/pipeline_orchestrator.py`, `tools/pipeline/rag_pipeline.py`, `tools/pipeline/ingest_documents.py`) — Cloud Run service, has `pipeline_orchestrator.run_pipeline_job()` with 6 stages: `kg_extraction`, `triplet_verification`, `neo4j_sync`, `wiki_graph`, `domain_classification`, `curation_pass`.

**Critical architectural mismatch:** `docs/ARCHITECTURE.md` describes 9 stages (1-9), including **stage 6 entity resolution → Postgres `entities`/`relationships`**. But the orchestrator's stage list has 6 stages and **does NOT include entity resolution or Postgres write**. The canonical Postgres tables (per `docs/ARCHITECTURE.md` and `atlas/schema.hcl`) are supposed to be the source of truth, but the production pipeline never writes to them. Neo4j syncs from raw triplets via `sync_postgres_to_neo4j.py` — but Postgres has nothing in it. This is the "Critical" gap in the architecture doc's "Remaining Gaps" table.

**`postgres_writer.py` exists but is orphan code.** It has working `INSERT INTO entities` and `INSERT INTO relationships` code (line 275, 291). It is **not imported or called from any orchestrator/router**. The `pipeline_orchestrator.py` does `from tools.pipeline.kg_extractor import extract_entities` and that's the only `tools.pipeline` import. The Postgres writer is a dead branch.

**Entity resolution only touches Neo4j.** `src/rag/entity_resolution.py` (475 LOC) has a sophisticated canonical-form normalizer + acronym expansion + duplicate-merge that operates entirely in Neo4j (`Neo4jManager`). It never reads from or writes to Postgres.

---

## Diagnosis of the operator's pain

The operator says: "having real trouble getting it ready to accept and process knowledge." After reading the code, I see **three distinct problems layered on top of each other**. Each is fixable, but they need to be fixed in order.

### Problem 1: The pipeline bypasses the canonical store (P0 — the central issue)

**What it looks like:** PDFs get uploaded, chunks get extracted, triplets get generated, Neo4j gets populated (via the orchestrator's `neo4j_sync` stage), wiki gets generated. But the Postgres `entities` and `relationships` tables — which `docs/ARCHITECTURE.md` says are the canonical source of truth — stay empty. So:
- Neo4j syncs from "raw triplets" (the `neo4j_sync` stage uses `kg_extractor` output directly), not from the canonical tables.
- Wiki generates from raw triplets, not from curated data.
- The "triplet_verification" stage has nothing to verify against the canonical store.
- The "curation_pass" stage is operating on data that has no canonical home.

**Evidence:**
- `api/services/pipeline_orchestrator.py` STAGES list (line 49-55): no `entity_resolution`, no `postgres_write`.
- `docs/ARCHITECTURE.md` "Remaining Gaps" row 1: "Pipeline does not write to Postgres `entities`/`relationships` — Neo4j syncs from empty tables; wiki generates from raw triplets instead of curated data — **Critical**"
- `tools/pipeline/postgres_writer.py` exists with working code but is not called by anyone (grep for `PostgresWriter` returns only the file itself).

**The fix shape (not the code):**
1. Add a `postgres_write` stage to the orchestrator's STAGES list, between `triplet_verification` and `neo4j_sync`.
2. Have it call `PostgresWriter.write_triplets()` on the verified triplets.
3. Update `neo4j_sync` and `curation_pass` to read from Postgres, not from the in-memory `kg_extractor` output.
4. Update `docs/ARCHITECTURE.md` "Remaining Gaps" to check this row off.

This is a ~1-2 day change for someone who knows the codebase. The Postgres writer is already written; it just needs to be wired in.

### Problem 2: The API has a schema/code mismatch (P1 — the visible symptom)

**What it looks like:** Issue #789 ("router queries FROM documents; no such table in migrations") is open. The API router queries a `documents` table that doesn't exist in the Postgres schema migrations. `atlas/migrations/` has 5 migrations but no `documents` table. So at least one endpoint is broken.

**Evidence:**
- `gh issue list --repo DarojaAI/rag_research_tool --state open` returns #789.
- The migrations list (`atlas/migrations/2026*.sql`) shows tables: pipeline_jobs, comments, content_hash_versioning, domains column. No `documents`.

**The fix shape:**
- Either the router is wrong (rename `documents` to the actual table — likely `source_documents` per `docs/ARCHITECTURE.md`), or the schema is missing a table.
- Likely a 1-2 hour fix once the right answer is known.

### Problem 3: Two pipelines, one old (P1 — the maintenance hazard)

**What it looks like:** The old `src/rag/run_kg_pipeline.py` family of scripts (`save_chunks.py`, `extract_entities.py`, `load_triplets.py`, `entity_resolution.py`) still exists, still works, and still ships with the repo. They are referenced from `docs/kg_development_plan.md` and `docs/next_steps.md`. The new FastAPI orchestrator doesn't use them.

**Evidence:**
- `docs/kg_development_plan.md` describes the old pipeline as the production path.
- `docs/next_steps.md` Priority 1 says "Run KG extraction pipeline on Elastica source files" — references the old scripts.
- The new orchestrator at `api/services/pipeline_orchestrator.py` calls `kg_extractor.extract_entities` directly, not via the old `run_kg_pipeline.py` script.

**The fix shape:**
- Either delete the old scripts (they're orphans), or document that the new orchestrator is the production path and the old scripts are dev-only. Currently the docs are inconsistent.
- This is housekeeping, not a blocker. But it confuses new contributors.

---

## Additional findings (not the central pain, but worth flagging)

### F0: Naming confusion — "RAG Research Tool" vs. "Synapse"

- GitHub repo: `rag_research_tool`
- `pyproject.toml`: `name = "synapse", version = "1.0.0", description = "Synapse — document coordination and knowledge graph pipeline"`
- AGENTS.md: calls it "RAG Research Tool"
- README.md: calls it "RAG Research Tool"
- Cloud Run service: `rag-research-eai`
- Module imports: `from synapse...` (in wiki_storage.py maybe?) — need to verify
- CHANGELOG v0.2.0 entries: "FortEvent document coordination platform"

**Implication:** the repo has been renamed (or is mid-rename) and the artifacts don't agree. Any cross-repo reference (skill names like `rag-research-tool` in skill-bridge, dependency docs, the SKILL.md files) will be wrong relative to current truth. This is a P2 hygiene task but it's a real issue.

### F1: Weaviate removal is documented but ghosts remain

`docs/ARCHITECTURE.md` says "Weaviate was removed" (2026-05-20). But:
- `tools/llm/query_handler.py` (WeaviateQueryHandler) still exists — flagged as dead code in the architecture doc.
- `docker-compose*.yml` still reference Weaviate — also flagged.
- The decision log row "Remove Weaviate" is in the doc.

**Implication:** the dead code is documented as dead but not deleted. This is the "use a `trash` (recoverable beats gone forever)" pattern from AGENTS.md in reverse — the code is in a Schrödinger's-removal state.

### F2: Atlas migrations are clean but coverage is unclear

`atlas/migrations/` has 5 SQL files (2026-05-06 to 2026-05-29). All well-formed, all reference the `rag_research_bronze` schema. But:
- The "documents" table referenced by the broken API router isn't there (see Problem 2).
- The architecture doc says `source_documents` and `document_chunks` are canonical; those need to be in migrations too. Let me verify with a follow-up.

### F3: The experiment framework is real and well-designed

`tools/experiments/` (referenced from ARCHITECTURE.md but I didn't read it in depth) is a MLflow-backed prompt testing framework. Looks like a real strength — extraction prompts are versioned, tested, and gated on approval before production. The "Experiment → Production Promotion Workflow" diagram in ARCHITECTURE.md is exactly the discipline you'd want. This is a load-bearing good thing the operator should know is working.

### F4: The verification layer (kg-neo4j, kg-audit, kg-extract, kg-query skills) is well-built

The 4 Claude Code-format skills in `rag_research_tool/.claude/skills/` are operator-facing tools for working with the system. kg-audit (hallucination verification) is referenced from the architecture as part of the cross-pipeline reads of pgvector. These are part of the "premier product" story — they make the system inspectable.

### F5: The skill_workshop `/` naming trap from §2.3 of skill-ecosystem.md does NOT apply here

`rag_research_tool` does not have a `skill_workshop/` folder. Its skills are at `.claude/skills/`. Different convention. Good — this is the format skill-bridge already targets.

---

## What the operator's pain most likely looks like, in concrete terms

Based on the code and the open issues:

1. **User uploads a PDF via the API.** The `kg_extraction` stage extracts chunks, embeds them, stores them in Postgres `document_chunks` with pgvector. ✅ Works.
2. **Triplets get extracted by the LLM** and stored as JSON. The `triplet_verification` stage runs. ✅ Should work.
3. **The pipeline tries to "resolve entities."** There is no such stage in the orchestrator. Triplets stay as raw JSON. ❌ Breaks here.
4. **The pipeline tries to "write to Postgres `entities`/`relationships`."** There is no such stage. Tables stay empty. ❌ Breaks here.
5. **`neo4j_sync` runs.** It reads from the in-memory triplets, not Postgres, and syncs to Neo4j. ⚠️ Works, but bypasses the canonical store.
6. **Wiki gets generated from raw triplets** (not from canonical data). ⚠️ Works, but not what the doc says.
7. **User queries via API.** Router queries a `documents` table that doesn't exist. ❌ Breaks (#789).

So the user-visible failures are:
- "I uploaded a PDF but I can't query the knowledge" (because the query router is broken on schema).
- "The knowledge graph shows entities but they're not in the canonical tables" (because the pipeline bypasses Postgres).
- "The wiki is full of raw, unverified, unresolved triplets" (because curation has nothing curated to work on).

---

## Recommended order of work

This is a sequence, not a parallel batch. Each step unblocks the next.

### Step 1: Fix the API schema mismatch (#789)

**Time:** 1-2 hours. **Risk:** Low. **Files:** `api/routers/ingest.py` (or whichever router queries `documents`).

Either:
- (a) Rename `documents` to `source_documents` in the router query (1 line, if the table is `source_documents`), or
- (b) Add a `documents` table to the Atlas schema and a migration.

Recommendation: (a). The architecture doc says `source_documents` is the canonical name.

### Step 2: Wire Postgres writer into the orchestrator

**Time:** 1-2 days. **Risk:** Medium (this is the load-bearing change). **Files:** `api/services/pipeline_orchestrator.py`, `tools/pipeline/postgres_writer.py`.

Add a `postgres_write` stage between `triplet_verification` and `neo4j_sync`. Call `PostgresWriter.write_triplets()` on the verified triplets. Update `neo4j_sync` to read from Postgres, not from the in-memory dict.

### Step 3: Add entity resolution to the pipeline

**Time:** 2-3 days. **Risk:** Medium. **Files:** new `api/services/entity_resolution_service.py`, integration with `pipeline_orchestrator.py`.

The existing `src/rag/entity_resolution.py` is good code, but it's CLI-style. Wrap it as a service that the orchestrator can call, and have it write the canonical/merged entities to Postgres (not just Neo4j). This makes the canonical store actually canonical.

### Step 4: Update the wiki stage to read from Postgres

**Time:** 1 day. **Risk:** Low. **Files:** `tools/pipeline/wiki_*.py`, the `wiki_graph` stage in the orchestrator.

Once Postgres has the canonical entities/relationships, the wiki generation should read from there, not from raw triplets. This is what `docs/ARCHITECTURE.md` already says should happen.

### Step 5: Housekeeping

**Time:** 0.5-1 day. **Risk:** Low. **Files:** many.
- Delete the orphan `tools/llm/query_handler.py` (WeaviateQueryHandler) and the Weaviate docker-compose refs.
- Decide: rename repo to `synapse` or rename pyproject to `rag_research_tool`. Pick one.
- Update the docs that reference the old `run_kg_pipeline.py` scripts as the production path.
- Move the 16 root-level files (`docs/issue-root-cleanup.md` already lists them) per the housekeeping plan.

---

## What I want from the operator before doing any of this

1. **Sign-off on the diagnosis.** Is the layered problem right? Specifically: do you experience Problem 1 (Postgres bypass), Problem 2 (schema mismatch), or Problem 3 (two pipelines) as the visible pain? Or is there a 4th problem I haven't seen?
2. **Permission to do Step 1 (the small fix) as a sandbox PR.** I can draft the schema-mismatch fix in a `fix/issue-789-documents-router` branch and submit it for your review. ~30 min of my time, no behavior change beyond making the API not 500.
3. **A second deep-dive session for research-orchestrator and intelligent-feed.** You said "do the other 2 after this." I'll do them next session — but I'd like to know the priority order (research-orchestrator first, or intelligent-feed first). research-orchestrator is the orchestrator (FastAPI + Cognee); intelligent-feed is the per-project activators. They have different shapes.
4. **What "premier product" means in 6-12 months.** Multi-tenant SaaS? Internal research tool for the org? Customer-facing? The shape changes the answer to "ready to process knowledge" — internal needs different things than customer-facing.

---

## What this take does NOT cover

- **research-orchestrator** (Firecrawl + Cognee): next session.
- **intelligent-feed** (per-project activators): next session.
- **The orbit relationship** (how rag_research_tool, research-orchestrator, and intelligent-feed relate): next session, after I've read all three.
- **Cognee strengthening work** the operator mentioned: next session, will inform §3.4 of the skill-ecosystem doc.
- **The v0.2 → v1.0 transition** (since pyproject says "synapse 1.0.0" but repo is "rag_research_tool"): flagged as F0, not addressed.
- **Code changes.** This is diagnosis only. Step 1 PR requires your sign-off.

---

## Open architectural hypotheses (verify in next session)

- The 4 Claude Code skills in `rag_research_tool/.claude/skills/` are operator-facing tools, not the user-facing product. (Partially verified — kg-audit is referenced in architecture. Need to verify others.)
- `research-orchestrator` is the "external knowledge" ingestion path (Firecrawl scraping → Cognee) and `rag_research_tool` is the "internal document" ingestion path. Together they form a complete ingestion story. (From `docs/research-pipeline-plan.md` — need to verify against current code.)
- The skill-ecosystem v0.2 doc's claim that "Cognee is in the rag_research_tool-orbit" is correct as far as `rag_research_tool` itself goes, but `research-orchestrator` is the **primary** Cognee integration. Need to revise §3.4 of the skill-ecosystem doc to reflect this.
- The `_context/rag_research_tool` and `_context/rag-research-tool-frontend` are in different repos and may have inconsistent naming. The skill names `rag_research_tool:kg-neo4j` etc. reference the Python repo.

---

**Bottom line:** the operator's pain is real and is centered on the fact that the production pipeline bypasses the canonical Postgres store. Fixing that — adding a `postgres_write` stage to the orchestrator and reading from it downstream — unblocks the visible symptoms (query router broken, wiki full of raw data, Neo4j syncing from non-canonical source). The fix is well-scoped (~3-5 days of focused work) and the code is mostly there (postgres_writer.py, entity_resolution.py). What's missing is the wiring in the orchestrator.

Ready to draft the Step 1 PR (issue #789 schema fix) on your sign-off, and to start the research-orchestrator + intelligent-feed deep dive next session.


---

## Status (2026-06-15, post-issues-filed)

Operator direction: "save this as a plan in rag-research-tool. open the issues in the correct places."

**Done:**
- **`DarojaAI/rag_research_tool` PR #813 (MERGED):** `docs/convergence-plan.md` — the org-wide roadmap. 5 phases over ~14 days. Cross-references this take and the orbit take.
- **4 new issues filed in `DarojaAI/rag_research_tool`:**
  - #814 (P0): Pipeline bypasses canonical Postgres entities/relationships tables — Phase A.3 of the plan
  - #815 (P1): Two parallel pipelines — Phase E.2 of the plan
  - #816 (meta): Convergence tracking — links to all sub-issues
  - #817: Naming decision (Synapse recommended) — Phase E.1 of the plan
- **Comment on existing #789:** Full diagnosis from the deep-dive + suggested 1-line fix.
- **Cross-repo issues filed:**
  - `DarojaAI/research-orchestrator#1` (P0): Schema mismatch breaks rag-research path + sys.path deprecation — Phase A.2 + D.2 of the plan
  - `DarojaAI/intelligent-feed#2` (P1): Make installable Python package — Phase D.1 of the plan

**Yes, prior findings & shortcomings were saved:**
- This file (`memory/2026-06-14-rag-research-tool-deep-dive.md`) — the rag_research_tool take, in the architect repo
- `memory/2026-06-14-research-orchestrator-intelligent-feed-deep-dive.md` — the orbit take, in the architect repo
- Both are in `DarojaAI/darojaai_architect#3` (PR)

These are *architect-side* memory files, not issues in the target repos. **The issues in the target repos were the gap — now closed.**

**Next step awaiting operator sign-off:** Phase A.1 (1-line fix for #789, ~1-2h) as the immediate unblock. Or any of the 6 issues can be picked up first.
