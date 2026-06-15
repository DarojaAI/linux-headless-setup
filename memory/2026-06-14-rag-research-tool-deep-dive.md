# Architectural Take: rag_research_tool (a.k.a. Synapse)

> **Date:** 2026-06-14, Session 14 part 6 (original); revised 2026-06-15 after peer review.
> **Repo:** `DarojaAI/rag_research_tool` — public, v0.2.0, Python (Synapse 1.0.0 in pyproject)
> **Operator question:** "do you have a good depth of understanding of rag-research-tool ecosystem itself? That's probably going to end up being the premier product. But im having real trouble getting it ready to accept and process knowledge"
> **Status:** DRAFT v0.2 — revised after peer review by the in-repo `rag_research_tool` agent. Original v0.1 had stale premises; see "Correction" section below.
> **Scope of this take:** architectural diagnosis only. No code changes. No cross-repo claims that aren't verified.

---

## ⚠️ Correction (2026-06-15, post-peer-review)

The in-repo agent peer-reviewed this take and the convergence plan it informed (PR #813, MERGED). **The agent was right on most points.** I had read `docs/ARCHITECTURE.md` "Remaining Gaps" table at face value and didn't verify against the actual call sites. Three of the four central claims in the original take were wrong. The architectural bet (converge at Postgres) is still right, but the deltas are smaller than I claimed.

### What was wrong (and the evidence)

| Claim in v0.1 | Reality | Evidence |
|---|---|---|
| "Pipeline bypasses the canonical store. Postgres `entities`/`relationships` stay empty." | Pipeline **does** write to Postgres. `TripletVerifier` (stage 2) calls `PostgresWriter.write_triplets()`. | `tools/pipeline/triplet_verifier.py:23, 95` |
| "Neo4j syncs from raw triplets via `sync_postgres_to_neo4j.py` — but Postgres has nothing in it." | Neo4j sync reads from `rag_research_bronze.entities` / `.relationships` per the sync module's own docstring. | `api/services/pipeline_orchestrator.py:729-731` + `src/rag/sync_postgres_to_neo4j.py` module docstring |
| "`postgres_writer.py` exists but is orphan code. Not imported or called from any orchestrator/router." | `TripletVerifier` imports and calls `PostgresWriter.write_triplets()`. Not orphan. | `tools/pipeline/triplet_verifier.py:23, 95` |
| "Stage 2.5 calls `sync_postgres_to_neo4j` to read from in-memory triplets." | Stage 2.5 calls `sync_postgres_to_neo4j` which reads from Postgres. Not in-memory. | `api/services/pipeline_orchestrator.py:729-731` |
| "Wiki generates from raw triplets, not from curated data." | Unverified. The wiki stage reads from `wiki/taxonomy` per the orchestrator; the source of `wiki/taxonomy` itself wasn't fully traced. | Open. |
| "Entity resolution only touches Neo4j. Never reads from or writes to Postgres." | Partially right — `entity_resolution.py` is not currently called by the orchestrator. But it's not the central pain. | `src/rag/entity_resolution.py` is currently orphaned (not wired in). |
| "Fix #789: 1-line rename to `source_documents`" | Wrong. Router was always correct (queries `documents`). Schema was missing. Operator added `documents` and `claim_versions` tables. | `atlas/migrations/20260614000000_create_documents.sql` + `20260614000001_create_claim_versions.sql` |

### What is still right

- **Convergence at Postgres** is the right architectural bet. Both `intelligent-feed` activators and `rag_research_tool` should write to the same canonical store.
- **The 5-phase convergence plan** is the right shape (verify → observability → align claim schemas → package substrate → naming). Phase boundaries don't move; individual deltas shrink.
- **The naming issue (3 names in flight)** is real and the Synapse recommendation stands.
- **The `research-orchestrator#1` silent P0** is real — the agent can't verify it from this repo, but the schema mismatch is unambiguous in the orchestrator code.
- **The shared-lib-with-sys.path-injection pattern** is real and the `intelligent-feed` packaging work (now done) was the right fix.

### What's still unverified

- **Old CLI pipeline as parallel vs orphaned.** Need a grep against routers + CI to confirm. The agent says orphaned; the agent is probably right. Unverified from my side.
- **Wiki source.** Need to trace `wiki/taxonomy` generation to confirm it reads from Postgres, not raw triplets.
- **The actual real-time behavior of the orchestrator.** The plan calls for a 30-second `pytest tests/db/test_neo4j_sync_local.py` to get ground truth. Should run before any other code change.

### Lesson promoted to AGENTS.md (House Rules)

**"Verify the code, not the docs."** The `docs/ARCHITECTURE.md` "Remaining Gaps" table is a flag, not a fact. The code is the truth. If they conflict, the code wins; update the doc as part of the fix. Promoted in commit `0260385` on `docs/rag-research-tool-take`.

---

## What I learned by reading the code

**Renamed/renaming:** `pyproject.toml` calls this `synapse` 1.0.0. GitHub repo is still `rag_research_tool`. The README and AGENTS.md call it "RAG Research Tool" or "Synapse." This is a load-bearing confusion — see Finding F0.

**Scale:** not the small RAG repo the README implies. ~3,934 LOC in `src/rag/`, plus 855 LOC in `tools/pipeline/ingest_documents.py`, plus a 146 KB `wiki_server.py`, plus 4 routers, 4 services, 4 dependency docs. CHANGELOG shows 50+ PRs in 1.5 months (v0.1.0 → v0.2.0).

**Two parallel implementations of the pipeline:**
1. **Old CLI pipeline** (`src/rag/run_kg_pipeline.py`, `save_chunks.py`, `extract_entities.py`, `load_triplets.py`, `entity_resolution.py`) — script-style entry points. Goes PDF → chunks → triplets JSON → Neo4j. **No Postgres write at all.** This is what the docs/kg_development_plan.md describes.
2. **New FastAPI pipeline** (`api/routers/ingest.py`, `api/services/pipeline_orchestrator.py`, `tools/pipeline/rag_pipeline.py`, `tools/pipeline/ingest_documents.py`) — Cloud Run service, has `pipeline_orchestrator.run_pipeline_job()` with 6 stages: `kg_extraction`, `triplet_verification`, `neo4j_sync`, `wiki_graph`, `domain_classification`, `curation_pass`.

**Critical architectural mismatch (REVISED 2026-06-15):** `docs/ARCHITECTURE.md` describes 9 stages (1-9), including **stage 6 entity resolution → Postgres `entities`/`relationships`**. The orchestrator's stage list has 6 stages. **The orchestrator is missing stage 6 (entity resolution)** — that's a real gap. But the Postgres write **does happen** in stage 2 (Triplet Verification), and the Neo4j sync **reads from Postgres** in stage 2.5, not from raw triplets. The architecture doc's "Remaining Gaps" table row 1 ("Pipeline does not write to Postgres `entities`/`relationships`") is **stale relative to the code** — the pipeline does write. Row 2 ("Neo4j sync reads from wiki markdown") is also stale — it reads from Postgres via `sync_postgres_to_neo4j.py`. Real remaining gap: **observability** (do the rows actually land? is the stage 2 Postgres write producing the data we expect?). The fix is 0.5d, not 1-2d.

**`postgres_writer.py` is NOT orphan code.** It has working `INSERT INTO entities` and `INSERT INTO relationships` code (line 275, 291). It IS imported and called by `TripletVerifier` in the orchestrator's stage 2. The `pipeline_orchestrator.py` does `from tools.pipeline.triplet_verifier import TripletVerifier` (line 680) and `TripletVerifier` does `from tools.pipeline.postgres_writer import PostgresWriter` (line 23) and calls `self.postgres_writer.write_triplets(...)` (line 95). The wiring is there. Original v0.1 of this take called it orphan — that was wrong.

**Entity resolution is currently orphaned.** `src/rag/entity_resolution.py` (475 LOC) has a sophisticated canonical-form normalizer + acronym expansion + duplicate-merge that operates in Neo4j. It is **not called by the orchestrator** — the orchestrator's stage list doesn't include a stage for it. The real delta here is wrapping it as a service that the orchestrator can call, not writing it. Stage 6 of the architecture doc is the missing stage. This is a real gap, smaller than the "bypass canonical store" framing of v0.1.

---

## Diagnosis of the operator's pain

The operator says: "having real trouble getting it ready to accept and process knowledge." After reading the code, I see **three distinct problems layered on top of each other**. Each is fixable, but they need to be fixed in order.

### Problem 1 (REVISED 2026-06-15): The pipeline is missing stage 6 (entity resolution) and stage observability is weak

**Original framing (v0.1, wrong):** "The pipeline bypasses the canonical store. Postgres `entities`/`relationships` stay empty." The in-repo agent peer-reviewed this and the actual code shows the wiring is there. **The framing was wrong; the problem is smaller than I claimed.**

**What it actually looks like (revised):** PDFs get uploaded, chunks get extracted, triplets get generated, **verified triplets are written to Postgres `entities` and `relationships` via `TripletVerifier` → `PostgresWriter.write_triplets()`** (stage 2). Neo4j sync reads from Postgres (`sync_postgres_to_neo4j` in stage 2.5), not from raw triplets. So the data flow is: extract → verify (with Postgres write) → Neo4j sync (from Postgres) → wiki → domain → curation. **The canonical store is being written to.** 

What's still wrong:
- **Stage 6 (entity resolution) is missing.** The orchestrator's 6-stage list is missing the entity resolution step described in `docs/ARCHITECTURE.md`. `src/rag/entity_resolution.py` has the code (canonical-form normalization + acronym expansion + duplicate-merge) but is not called by the orchestrator. Triplets get written to Postgres as raw extractions without resolution.
- **Stage observability is weak.** There is no stage-level "did the Postgres write actually happen?" signal. Stage 2 transitions to stage 2.5, but the orchestrator doesn't surface `entity_count` / `relationship_count` written to Postgres as part of the job state. Operators can't tell from the API response whether the Postgres write succeeded.
- **The "Remaining Gaps" table in `docs/ARCHITECTURE.md` is stale.** Rows 1 and 2 say the pipeline doesn't write to Postgres and that Neo4j syncs from wiki markdown. Both are wrong relative to the current code. **The doc needs to be updated as part of the fix.**

**Evidence:**
- `api/services/pipeline_orchestrator.py:680` `from tools.pipeline.triplet_verifier import TripletVerifier`
- `tools/pipeline/triplet_verifier.py:23` `from tools.pipeline.postgres_writer import PostgresWriter`
- `tools/pipeline/triplet_verifier.py:95` `self.postgres_writer.write_triplets(...)`
- `api/services/pipeline_orchestrator.py:729-731` `from rag.sync_postgres_to_neo4j import sync_postgres_to_neo4j; result = sync_postgres_to_neo4j(clear=False, dry_run=False)`
- `src/rag/sync_postgres_to_neo4j.py` module docstring: "Reads the canonical entities and relationships from PostgreSQL (rag_research_bronze schema) and materializes them into Neo4j as graph topology. Replaces sync_wiki_to_neo4j.py — reads from canonical relational store instead of wiki markdown artifacts."
- `tools/pipeline/postgres_writer.py:275, 291` (the `INSERT INTO entities` and `INSERT INTO relationships` code that is now actually being called)
- `docs/ARCHITECTURE.md` "Remaining Gaps" rows 1 and 2 (stale relative to the code)

**The fix shape (revised):**
1. **Add stage 6 (entity resolution) to the orchestrator.** Wrap `src/rag/entity_resolution.py` as a service (`api/services/entity_resolution_service.py`) and call it after `triplet_verification` but before `neo4j_sync`. The resolved entities replace the raw triplets in Postgres (UPSERT by canonical form).
2. **Add observability to stage 2.** Surface `entities_written` and `relationships_written` counts in the stage output JSON. Operators can see from the API whether the Postgres write happened.
3. **Update `docs/ARCHITECTURE.md` "Remaining Gaps"** to mark rows 1 and 2 as resolved (the code now does what the doc said it should). Add a new row 1: "Stage 6 (entity resolution) is not wired into the orchestrator." Add a new row 2: "Stage 2 observability doesn't surface Postgres write counts."
4. **Run the e2e test first** (`pytest tests/db/test_neo4j_sync_local.py`) to confirm the wiring actually works end-to-end. This is the verification gate before any code change.

This is a **~0.5-1 day change** for stage observability + doc update, plus **~2-3 days** for stage 6 wiring (entity resolution is non-trivial code). Much smaller than the v0.1 "1-2 day" estimate — but with new work (the doc update) that I didn't anticipate.

### Problem 2 (REVISED 2026-06-15): #789 was real, but the fix was different from what I suggested

**What it actually was:** Issue #789 ("router queries FROM documents; no such table in migrations") is real. The API router (`api/routers/documents.py:39, 44`) queries `FROM documents`. The `documents` table didn't exist in the original migration list. So the endpoint was broken at the FastAPI dependency layer.

**What I suggested (wrong):** "1-line rename to `source_documents`." I assumed the table should be `source_documents` (the canonical name per `docs/ARCHITECTURE.md`). But that was wrong — the FastAPI `documents` table is a **separate concept** from the canonical `source_documents` table. The router is a documents-API table (uploads, status, event_id); `source_documents` is the canonical RAG table (per `docs/ARCHITECTURE.md`).

**What the operator did (right):** Closed #789 by adding `20260614000000_create_documents.sql` (created the `documents` table) and `20260614000001_create_claim_versions.sql` (created the related claim_versions table). Both migrations have detailed "WHY THIS EXISTS" comments pointing back to this take's diagnosis. The router code was always correct; the schema was missing.

**The remaining gap:** the router query is un-schema-qualified (`FROM documents` not `FROM rag_research_bronze.documents`). This is a latent bug that depends on `search_path` being correctly set. Should be fixed in a follow-up, but not load-bearing for the operator's pain.

**Status:** CLOSED on 2026-06-15. Lesson for next time: read the call sites before suggesting renames. The "what table should it be" question is a domain question, not a code question — and I was wrong about which domain.

### Problem 3 (REVISED 2026-06-15): Two pipelines, one old — but probably orphaned, not parallel

**Original framing (v0.1, overstated):** "Old CLI pipeline still exists, still works, and still ships with the repo. ... The new FastAPI orchestrator doesn't use them."

**Revised framing:** The old `src/rag/run_kg_pipeline.py` family of scripts (`save_chunks.py`, `extract_entities.py`, `load_triplets.py`, `entity_resolution.py`) exists but is probably **orphaned** (not imported, not called) — per the in-repo agent's review. I claimed they were "parallel" without grepping for callers. The agent is probably right that they're orphaned. **Need a grep against routers + CI to confirm before treating this as a real issue.** If orphaned, the action is "delete + delete test refs," not "archive + docs refresh." Different scope.

**Evidence still valid:**
- `docs/kg_development_plan.md` describes the old pipeline as the production path. (Stale doc.)
- `docs/next_steps.md` Priority 1 says "Run KG extraction pipeline on Elastica source files" — references the old scripts. (Stale doc.)
- The new orchestrator at `api/services/pipeline_orchestrator.py` calls `kg_extractor.extract_entities` directly, not via the old `run_kg_pipeline.py` script. (Confirms the new orchestrator doesn't use the old scripts.)

**Revised fix shape:**
- **Verify orphan status** with one `grep -rn "from src.rag.run_kg_pipeline\|import run_kg_pipeline" .` against the repo. If zero hits outside `src/rag/` and `tests/`, the scripts are orphaned.
- If orphaned, retitle #815 from "[P1] Two parallel pipelines" to "[P1] Orphaned old CLI scripts in src/rag/".
- Delete the scripts and their test refs.
- Update `docs/kg_development_plan.md` and `docs/next_steps.md` to reference the new orchestrator.

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

### F2 (REVISED 2026-06-15): Atlas migrations are clean and growing

`atlas/migrations/` has grown from 5 to 14 SQL files (2026-05-06 to 2026-06-14). All well-formed, all reference the `rag_research_bronze` schema. The 2026-06-14 batch (`create_documents.sql`, `create_claim_versions.sql`, `reconcile_broken_migration_hashes.sql`) closed #789 and the v2 recovery migrations for `pipeline_jobs` and `contradictions` (PR #783).

**Scar tissue:** `20260603000000_add_relationship_source_document.sql` + `20260604000000_add_relationship_source_document_v2.sql` is two migrations to add the same thing. Indicates the relationship between source_documents and the rest of the schema was designed in two passes. **"Additive, forward-only" is more delicate than the convergence plan acknowledged.** Any future migration that touches this relationship needs to be aware of both.

**`source_documents` and `document_chunks`:** these are the canonical RAG tables per `docs/ARCHITECTURE.md`. They are created in `20260506000000_initial.sql` (and `document_chunks` may be in the same initial migration). Confirmed by reading the schema. **The "documents" table (added 2026-06-14) is a separate, FastAPI-side table for document upload tracking — not the same as `source_documents`.** Don't conflate them.

### F3: The experiment framework is real and well-designed

`tools/experiments/` (referenced from ARCHITECTURE.md but I didn't read it in depth) is a MLflow-backed prompt testing framework. Looks like a real strength — extraction prompts are versioned, tested, and gated on approval before production. The "Experiment → Production Promotion Workflow" diagram in ARCHITECTURE.md is exactly the discipline you'd want. This is a load-bearing good thing the operator should know is working.

### F4: The verification layer (kg-neo4j, kg-audit, kg-extract, kg-query skills) is well-built

The 4 Claude Code-format skills in `rag_research_tool/.claude/skills/` are operator-facing tools for working with the system. kg-audit (hallucination verification) is referenced from the architecture as part of the cross-pipeline reads of pgvector. These are part of the "premier product" story — they make the system inspectable.

### F5: The skill_workshop `/` naming trap from §2.3 of skill-ecosystem.md does NOT apply here

`rag_research_tool` does not have a `skill_workshop/` folder. Its skills are at `.claude/skills/`. Different convention. Good — this is the format skill-bridge already targets.

---

## What the operator's pain most likely looks like, in concrete terms (REVISED 2026-06-15)

Based on the corrected code reading and the operator's actual fixes:

1. **User uploads a PDF via the API.** The `kg_extraction` stage extracts chunks, embeds them, stores them in Postgres `document_chunks` with pgvector. ✅ Works.
2. **Triplets get extracted by the LLM** and stored as JSON. The `triplet_verification` stage runs. The `TripletVerifier` calls `PostgresWriter.write_triplets()` which INSERTs into `entities` and `relationships` in the `rag_research_bronze` schema. ✅ Works (writes to canonical store).
3. **The pipeline tries to "resolve entities."** There is no such stage in the orchestrator. Triplets stay as raw extractions — no canonical-form normalization, no duplicate-merge. ⚠️ Works, but the canonical store has raw LLM output, not curated data.
4. **Neo4j sync runs.** It calls `sync_postgres_to_neo4j(clear=False, dry_run=False)` which reads from `rag_research_bronze.entities` / `.relationships` and materializes them into Neo4j. ✅ Works (sync is from Postgres, not raw triplets).
5. **Wiki gets generated.** The `wiki_graph` stage runs `classify_main(["--wiki-root", "wiki/taxonomy"])`. ⚠️ Source of `wiki/taxonomy` is unverified — it may be generated from `wiki/concepts/{domain}/...` markdown rather than from the Postgres canonical store.
6. **Domain classification runs.** Stage runs `classify_main(...)` with the wiki root. ✅ Should work.
7. **Curation pass runs.** Stage runs `rag.run_curation_pass.main()`. ⚠️ Operates on data in Postgres; results not verified.
8. **User queries via API.** The `/documents` endpoint queries the `documents` table (now exists per the 2026-06-14 migrations). ✅ Should work (post-fix).
9. **The `documents` table is un-schema-qualified in the router query** (`FROM documents` not `FROM rag_research_bronze.documents`). Latent bug; depends on `search_path`. ⚠️ Should be fixed.

**Status: #789 closed by operator (2026-06-15) via new migrations.**

So the user-visible failures (revised):
- "The knowledge graph shows raw LLM extractions, not resolved canonical entities" (because stage 6 entity resolution is missing from the orchestrator).
- "I can't tell whether the Postgres write actually happened" (because stage 2 doesn't surface the row counts).
- "The wiki is full of raw, unverified, unresolved triplets" (because curation has nothing resolved to work on).
- "The doc says the pipeline doesn't write to Postgres, but the code says it does" (because the doc is stale).

The previously-stated failures are no longer the central pain:
- ~~"I uploaded a PDF but I can't query the knowledge"~~ — the documents table now exists, the router is unblocked.
- ~~"The pipeline bypasses Postgres"~~ — it doesn't, per the TripletVerifier wiring.

---

## Recommended order of work (REVISED 2026-06-15)

This is a sequence, not a parallel batch. Each step unblocks the next. **Step 0 is the verification gate** that was missing from v0.1 — don't skip it.

### Step 0: Run the e2e test (verification gate)

**Time:** 30 seconds. **Risk:** None. **Files:** none changed.

```bash
docker compose -f config/docker-compose.yml up -d
atlas migrate apply --env local
POSTGRES_HOST=localhost POSTGRES_USER=postgres POSTGRES_DB=rag_taxonomy \
NEO4J_URI=bolt://localhost:7687 NEO4J_USERNAME=neo4j NEO4J_PASSWORD=*** \
pytest tests/db/test_neo4j_sync_local.py -v
```

This test (described in its own docstring) seeds a known fixture into `rag_research_bronze` and validates `sync_postgres_to_neo4j` produces the expected Neo4j graph. **If it passes, the data flow from Postgres → Neo4j is verified.** If it fails, we have ground truth on what's actually broken.

**Also do:** `grep -rn "from src.rag.run_kg_pipeline\|import run_kg_pipeline" .` to confirm Problem 3 is orphaned vs parallel.

### Step 1: Update `docs/ARCHITECTURE.md` "Remaining Gaps" table

**Time:** 0.5 day. **Risk:** None (docs). **Files:** `docs/ARCHITECTURE.md`.

Mark rows 1 and 2 as resolved (the code now does what the doc said it should). Add new row 1: "Stage 6 (entity resolution) is not wired into the orchestrator." Add new row 2: "Stage 2 observability doesn't surface Postgres write counts." This is the doc/code reconciliation step that the v0.1 plan missed.

### Step 2: Add stage observability to TripletVerifier

**Time:** 0.5-1 day. **Risk:** Low. **Files:** `tools/pipeline/triplet_verifier.py`, `api/services/pipeline_orchestrator.py`.

Surface `entities_written`, `relationships_written`, and `entities_skipped` counts in the stage output JSON. Operators can see from the API response whether the Postgres write happened and how many rows landed.

### Step 3: Wire entity resolution into the orchestrator (stage 6)

**Time:** 2-3 days. **Risk:** Medium. **Files:** new `api/services/entity_resolution_service.py`, `api/services/pipeline_orchestrator.py`, `src/rag/entity_resolution.py`.

Wrap `src/rag/entity_resolution.py` as a service that the orchestrator can call. Add a stage 6 between `triplet_verification` (which writes raw extractions to Postgres) and `neo4j_sync` (which reads from Postgres). The resolved entities UPSERT the raw extractions in Postgres. The canonical store becomes actually canonical (no raw LLM output).

### Step 4: Trace and align the wiki stage with Postgres

**Time:** 1 day. **Risk:** Low. **Files:** `tools/pipeline/wiki_*.py`, the `wiki_graph` stage in the orchestrator.

Trace where `wiki/taxonomy` comes from. If it's generated from raw triplets or wiki markdown, align it to read from Postgres (now containing resolved entities). This is what `docs/ARCHITECTURE.md` already says should happen.

### Step 5: Housekeeping

**Time:** 0.5-1 day. **Risk:** Low. **Files:** many.
- Delete the orphan `tools/llm/query_handler.py` (WeaviateQueryHandler) and the Weaviate docker-compose refs.
- Decide: rename repo to `synapse` or rename pyproject to `rag_research_tool`. Pick one. (See F0 / #817.)
- Schema-qualify the `documents` table reference in `api/routers/documents.py` (`FROM rag_research_bronze.documents`).
- If grep confirms Problem 3 scripts are orphaned, delete them and update the stale `docs/kg_development_plan.md` and `docs/next_steps.md` to reference the new orchestrator.
- Move the 16 root-level files (`docs/issue-root-cleanup.md` already lists them) per the housekeeping plan.

---

## What I want from the operator before doing any of this (REVISED 2026-06-15)

1. **Sign-off on the corrected diagnosis.** The v0.1 framing was wrong on Problem 1 (Postgres bypass) and overstated on Problem 3 (parallel pipelines). The corrected framing is: **stage 6 entity resolution is missing from the orchestrator; stage 2 observability is weak; the doc is stale relative to the code.** Do these match the visible pain? Or is there a 4th problem I haven't seen?
2. **Permission to run the e2e test (Step 0).** `pytest tests/db/test_neo4j_sync_local.py` against docker-compose. ~30 seconds, no behavior change, gives ground truth.
3. **Permission to grep for old CLI pipeline callers.** One `grep -rn "from src.rag.run_kg_pipeline\|import run_kg_pipeline" .` to confirm Problem 3 is orphaned vs parallel.
4. **Permission to do Step 1 (the doc update) as a sandbox PR.** Update `docs/ARCHITECTURE.md` "Remaining Gaps" table to reflect the current code. ~30 min of my time, no behavior change. Sets the doc/code baseline before any code work.
5. **Decision on the orchestrator repro.** Do we want the in-repo `rag_research_tool` agent to produce a curl + traceback repro for `DarojaAI/research-orchestrator#1`? That repo is silent for 6 weeks; the repro would tell us if the silent P0 is real.
6. **Decision on #817 (naming).** Synapse vs rag_research_tool vs FortEvent. My recommendation is Synapse (already in `pyproject.toml` + CHANGELOG v0.2.0 framing).
7. **What "premier product" means in 6-12 months.** Multi-tenant SaaS? Internal research tool for the org? Customer-facing? The shape changes the answer to "ready to process knowledge" — internal needs different things than customer-facing.

---

## What this take does NOT cover

- **research-orchestrator** (Firecrawl + Cognee): covered in `memory/2026-06-14-research-orchestrator-intelligent-feed-deep-dive.md` (orbit take, also revised 2026-06-15).
- **intelligent-feed** (per-project activators): same orbit take. Note: intelligent-feed's PR #1 (Q15-17 work) and PR #3 (packaging) are now MERGED. The substrate work is done; remaining items are the orchestrator's `sys.path` deprecation (Phase D.2) and the cross-claim schema reconciliation (Phase C).
- **Cognee strengthening work** the operator mentioned: not in this take; see the skill-ecosystem doc §3.4.
- **The v0.2 → v1.0 transition** (since pyproject says "synapse 1.0.0" but repo is "rag_research_tool"): flagged as F0 / #817 — not addressed, awaiting operator decision.
- **Code changes.** This is diagnosis only. Step 0 (e2e test) and Step 1 (doc update) are awaiting operator sign-off.

---

## Open architectural hypotheses (verify in next session)

- The 4 Claude Code skills in `rag_research_tool/.claude/skills/` are operator-facing tools, not the user-facing product. (Partially verified — kg-audit is referenced in architecture. Need to verify others.)
- `research-orchestrator` is the "external knowledge" ingestion path (Firecrawl scraping → Cognee) and `rag_research_tool` is the "internal document" ingestion path. Together they form a complete ingestion story. (From `docs/research-pipeline-plan.md` — need to verify against current code.)
- The skill-ecosystem v0.2 doc's claim that "Cognee is in the rag_research_tool-orbit" is correct as far as `rag_research_tool` itself goes, but `research-orchestrator` is the **primary** Cognee integration. Need to revise §3.4 of the skill-ecosystem doc to reflect this.
- The `_context/rag_research_tool` and `_context/rag-research-tool-frontend` are in different repos and may have inconsistent naming. The skill names `rag_research_tool:kg-neo4j` etc. reference the Python repo.

---

**Bottom line (REVISED 2026-06-15):** the operator's pain is real, but its center is **not** "the pipeline bypasses the canonical store." The pipeline **does** write to Postgres (via `TripletVerifier` → `PostgresWriter`) and Neo4j sync **does** read from Postgres (via `sync_postgres_to_neo4j`). The original v0.1 framing of "add a `postgres_write` stage" was wrong — the stage is already there.

**The real pain, as best as I can tell from the code, is:**
1. **Stage 6 (entity resolution) is missing from the orchestrator.** The pipeline writes raw LLM extractions to Postgres; resolved canonical entities never land. This makes the canonical store less canonical than the doc says it is.
2. **Stage observability is weak.** Operators can't tell from the API whether the Postgres write succeeded.
3. **`docs/ARCHITECTURE.md` "Remaining Gaps" table is stale** relative to the code (rows 1 and 2). Doc/code reconciliation needed.
4. **`api/routers/documents.py` is un-schema-qualified** in its table references — latent bug.
5. **Naming confusion (3 names in flight)** is real and a follow-up sweep is needed (see #817).
6. **The `research-orchestrator` silent P0** is real but in a separate repo; needs the agent's repro to confirm.

The fix is well-scoped. The code is mostly there. What's missing is the **stage 6 wiring** and the **doc/code reconciliation**. Total time estimate: ~3-4 days of focused work (down from the v0.1 ~3-5 days, but the shape of the work is different).

**Lesson: read the call sites before writing the plan.** Promoted to AGENTS.md House Rules at `0260385`.

Not ready to write a Step 1 PR until the e2e test (Step 0) confirms the data flow and the grep confirms old CLI scripts are orphaned.


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

---

## Status (2026-06-15, post-peer-review) — REVISED

The in-repo `rag_research_tool` agent peer-reviewed this take and the convergence plan it informed (PR #813, MERGED). **The agent was right on most points.** Three of the four central claims in v0.1 were wrong. See "⚠️ Correction" section at the top of this file for the full evidence. Architectural bet is still right; deltas are smaller than I claimed.

**Issues status (revised):**
- **#814 (P0):** Wrong framing. Should be rewritten as "Add stage 6 (entity resolution) + stage observability." **REWRITE NEEDED.**
- **#815 (P1):** Overstated. Should be retitled "Orphaned old CLI scripts" pending grep verification. **RETITLE NEEDED.**
- **#816 (meta):** Stays as-is.
- **#817 (naming):** Stays as-is.
- **#789:** My suggested 1-line rename was **wrong** (suggested renaming to `source_documents`, but they're separate tables). Operator closed #789 by adding `documents` + `claim_versions` migrations. **The right fix.**
- **`research-orchestrator#1`:** Stays as-is. Agent can't verify from this repo; offered to produce curl + traceback repro.
- **`intelligent-feed#2`:** CLOSED 2026-06-15T02:31:34Z by operator via PR #3 (packaging with pyproject.toml + setuptools_scm + Apache-2.0 + PyPI publish). **Q14 (dynamic-worlock) also RESOLVED 2026-06-15** — operator confirmed it's private in `e16af80` commit.

**Architect repo state:** `0260385` on `docs/rag-research-tool-take`. AGENTS.md has the "Verify the code, not the docs" house rule.

**Next step (revised) awaiting operator sign-off:**

1. **Run the e2e test** (`pytest tests/db/test_neo4j_sync_local.py`) for ground truth on the data flow. **30 seconds. Do this first, no plan, no more issues.**
2. **Grep for old CLI pipeline callers** to confirm Problem 3 is orphaned vs parallel.
3. **Rewrite #814** to match the actual code (stage 6 + observability, not "wire the missing stage").
4. **Open a corrective PR** against `docs/convergence-plan.md` in `DarojaAI/rag_research_tool` with the revised deltas.
5. **Decide on #817** (Synapse vs rag_research_tool vs FortEvent).
6. **Decide on the orchestrator repro** (do we want the in-repo agent to produce the curl + traceback for `research-orchestrator#1`?).
