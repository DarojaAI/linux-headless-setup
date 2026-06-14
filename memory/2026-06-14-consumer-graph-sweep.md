# Consumer Graph Sweep: `infra-actions` and `devnexus-common`

> **Date:** 2026-06-14, Session 10
> **Method:** `grep -r` across the 14 repos I have cloned in `_context/`. For each shared lib, looked for both direct references (in workflows, requirements files, source imports) and indirect ones (in docs, plans, READMEs).
> **Scope:** the 14 repos I cloned in session 1, plus `skill-bridge` (cloned in session 7). Does NOT cover the other 28 repos in the org — those are still unexplored.

---

## `infra-actions` — consumer graph

Repos that reference `DarojaAI/infra-actions` (or its actions) in workflows, docs, or READMEs:

| Consumer | Where | What they use it for |
|---|---|---|
| `daroja-frontend-starter` | `.github/workflows/deploy.yml`, `README.md` | Deploy workflow |
| `dev-nexus` | `.github/workflows/release.yml`, `ci.yml`, `terraform-apply-v2.yml` | Release, CI, Terraform apply |
| `devnexus-common` | `.github/workflows/release.yml`, `ci.yml` | Release, CI |
| `dev-nexus-frontend` | `.github/workflows/release.yml`, `deploy.yml`, `docs/guides/CLOUDFLARE_PAGES_MULTI_ENV.md` | Release, deploy, Cloudflare Pages setup |
| `linux-desktop-seed` | `.github/workflows/release.yml`, `docs/plans/linux-desktop-infra-actions-alignment.md` | Release; has a planning doc titled "linux-desktop-infra-actions-alignment" — meaning this repo has a dedicated plan to align with infra-actions |
| `rag_research_tool` | `AGENTS.md`, `.github/workflows/release.yml`, `terraform-apply-v2.yml` | Release, Terraform apply. **The `AGENTS.md` references it, so it's a recognized dependency at the project-contract level.** |
| `infra-actions` (itself) | `platform/gcp/deploy-neo4j/action.yml`, `atlas-migrate-via-job/action.yml` | Self-reference (composite actions call other composite actions) |

**Count:** 6 consumer repos (excluding self-reference), spanning 3 categories (Core Services, Frontend, Infrastructure). All 6 have at least release/CI workflows; 3 have deploy workflows.

**Pattern:** infra-actions is the *CI/CD backbone*, used by every multi-deploy repo in the org. New CI work should check here first. The `linux-desktop-seed` alignment plan suggests there was a deliberate standardization effort.

**Gap:** I haven't confirmed that `mcp-tooling`, `openclaw-gateway`, `trip-planning`, `research-orchestrator`, or `bond-nexus` use infra-actions. The first 4 are unexplored; bond-nexus probably doesn't (it's docs + scripts, not a deploy target).

---

## `devnexus-common` — consumer graph

Repos that reference `devnexus-common` (in requirements, imports, or docs):

| Consumer | Where | What they use it for |
|---|---|---|
| `dev-nexus` | `requirements.txt` (pinned `v1.7.0`), `src/a2a/llm_client.py` (shim), `tests/test_database_resilience.py`, `tests/integration/test_complexity_workflow.py`, `.github/workflows/terraform-apply-v2.yml` | LLM client (`common.llm`), database (`common.db`), config, in tests and CI |
| `rag_research_tool` | `requirements.scripts.txt` (comment about production usage), `api/services/pipeline_orchestrator.py`, `api/dependencies.py`, `.github/workflows/check-psycopg2-imports.yml`, `AGENTS.md` | LLM client, database, lazy-imported with fallback |
| `infra-actions` | `.github/workflows/reusable-deploy-atlas.yml` (defensive comment about dev-nexus PR #1047 and devnexus-common PR #47), `platform/gcp/ensure-artifact-registry/action.yml` (example uses `devnexus-common` as the artifact name) | Cross-reference in workflow; example name only |
| `linux-desktop-seed` | `docs/plans/workspace-cleanup-and-token-rotation.md` | Plan references it; not a runtime consumer |

**Count:** 2 confirmed runtime consumers (`dev-nexus`, `rag_research_tool`); 1 documentation reference (`linux-desktop-seed` plan); 1 incidental cross-reference (`infra-actions`).

**Critical observation: `rag_research_tool` is the OTHER key consumer, exactly as the operator indicated.** This confirms the shared-lib pattern: the *Knowledge* agent (dev-nexus) and the flagship application (rag_research_tool) both depend on `devnexus-common` for the same primitives (LLM, DB, config).

**Pattern:** devnexus-common is a *Python shared library* with at least 2 production consumers. Despite its name, it is NOT a dev-nexus-private repo. This validates the OPEN_QUESTIONS.md finding (Q-naming-devnexus-common, P1): the name is misleading.

---

## Cross-edge: `infra-actions` → `devnexus-common`

A surprising find. `infra-actions/.github/workflows/reusable-deploy-atlas.yml` has a defensive comment:

> See DarojaAI/dev-nexus PR #1047 and DarojaAI/devnexus-common PR #47 for the upstream fix. This step is defensive in case the ENTRYPOINT bug ever returns or a sibling repo's image regresses.

This means `infra-actions` *knows about* a `devnexus-common` PR (#47) and a `dev-nexus` PR (#1047) related to an entrypoint bug. The CI step is defensive against a regression. The image being deployed is presumably the dev-nexus image, which depends on devnexus-common. So:

```
infra-actions (CI) → dev-nexus (image) → devnexus-common (Python lib)
```

**This is a load-bearing 3-hop dependency in the deploy pipeline.** Worth documenting.

---

## CRITICAL FINDING (P0): Embedded GitHub PAT in two repos

**Source:** `linux-desktop-seed/docs/plans/workspace-cleanup-and-token-rotation.md` (line ~15-20)

> a GitHub personal access token (`ghp_Nh…PiSs`) is embedded in cleartext in `.git/config` of two repos (`gcp-postgres-terraform`, `terraform-linux-desktop`). The token is also documented in `rag_research_tool/memory/2026-05-09.md` and `rag-research-tool-work/memory/2026-05-09.md`, so it has been in cleartext for at least 5 weeks. This is the higher-priority item.

**Severity:** P0. A PAT committed to a repo's `.git/config` is a credential leak. Even if the repo is private:
- Anyone with read access to the repo (collaborators, org members, future hires) can extract the token.
- If the token has `repo` scope, it can be used to clone and modify ANY repo the owner has access to — potentially the entire DarojaAI org.
- 5 weeks of exposure is a long time. The token may have been used in ways that aren't in the git log.

**Action required (P0):**
1. **Revoke the token NOW** (in GitHub Settings → Developer settings → Personal access tokens). This is a one-click action that the operator must do; I cannot do it from here.
2. **Audit the token's use** (GitHub Settings → Security log, or the token's own audit log if available) to see what the token has accessed in the last 5 weeks.
3. **Generate a replacement** if needed, store it as a GitHub Actions secret or a personal access credential, never commit it.
4. **Clean the git history** of the two affected repos (`gcp-postgres-terraform`, `terraform-linux-desktop`) using `git filter-repo` or BFG Repo-Cleaner. This is a P1 follow-up after the immediate revocation.
5. **Rotate the token references in `rag_research_tool/memory/2026-05-09.md` and `rag-research-tool-work/memory/2026-05-09.md`** — those are also cleartext. Note: `rag-research-tool-work` is mentioned as a separate local clone in the plan doc; I don't have it in my clones.
6. **Add `ghp_*` and other high-entropy patterns to the Gitleaks pre-commit hook** if not already covered. The org's `.github` standards require Gitleaks; verify it's enforced in all 3 affected repos.

**Recommended communication:** I should flag this in the channel immediately, not wait for the next session. The operator needs to act TODAY.

---

## Other findings from the sweep

### F-architect: `linux-desktop-seed/docs/plans/` is a first-class planning directory

The plan doc I read is structured (Categories A-E, separate workstreams, explicit "out of scope" calls). It also has 25 issue worktrees mentioned (`-NNNN` suffixed dirs), meaning linux-desktop-seed is actively used as an *agent's home* in addition to being a code repo. The architect's role (mine) is well-suited to maintain docs/plans/ directories like this; the operator may want to standardize on this pattern across the org.

### F-ElasticaApp: not a GitHub repo, local-only dir

The plan doc references `ElasticaApp` (capital — real org name) vs `elasticaapp` (lowercase — agent home). Neither is a `DarojaAI` repo per `gh repo list`. Either this is a separate org the operator works with, or it's a stale local dir. Not in scope for the DarojaAI inventory, but worth confirming.

### F-token-in-memories: `rag_research_tool/memory/` and `rag-research-tool-work/memory/` have daily notes that contain the token

This is consistent with the org's "memory is durable" practice — the daily notes record what happened. But it means the token is now in git history *and* in memory files. Rotating the token references in those memory files is part of the cleanup.

---

## What I'd do next (operator decision)

1. **P0 IMMEDIATE:** flag the embedded PAT in the channel. Don't wait for review.
2. **P1 follow-up:** PR in `gcp-postgres-terraform` and `terraform-linux-desktop` to remove the PAT from `.git/config` (after the operator has revoked the token; the local files will still have the old string until cleaned).
3. **P1 follow-up:** PR to redact the token from the memory files. Or: a sweep script that finds and redacts all `ghp_*` patterns in memory/ and .git/config.
4. **P1 follow-up:** verify Gitleaks pre-commit is wired in all 3 affected repos. Add it if missing.
5. **P2 doc work:** include the consumer graph (this report) in `ARCHITECTURE.md` so the relationship is documented. Currently it's only in my own memory.
6. **P2 doc work:** consider standardizing on `docs/plans/` directories across repos (per the linux-desktop-seed pattern).
