# 2026-06-14 — Org Audit Report (sessions 14+)

Two sweeps performed via `gh api` against all 41 active + 3 archived repos. Raw data in `_context/audits/`:

- `codeowners-and-workflows.txt` — Q6 raw output
- `infra-actions-consumers.txt` — Q7 raw output
- `REPORT-2026-06-14.md` — formatted summary

## Q6: CODEOWNERS

**4 of 41 active repos have `.github/CODEOWNERS`:**

- `infra-actions`
- `rag_research_tool`
- `dev-nexus`
- `mcp-tooling`

**37 of 41 do not.** Notable absences: `openclaw-gateway`, `linux-desktop-seed`, all the Terraform modules except the 3 listed above.

12 repos returned "ERR" for the workflows check (likely non-`main` default branch): `linux-headless-setup`, `bond-nexus`, `linux-desktop-setup`, `machine-learning-commons`, `design-artifacts`, `GlobalBitings`, `gcp-postgres-terraform-example`, `gcp-postgres-validators`, `core-business-management`, `intelligent-feed`, `openstreetmap-location-data-cleaner`, plus the 3 archived. A second sweep with the right default branch is needed.

**Recommended action:** single tracking issue in `.github` with checklist; per-repo issues are noise. Most repos can default to `@no_decaf_milan` until a real team structure is set up.

## Q7: infra-actions consumers

**18 of 41 active repos use `DarojaAI/infra-actions` in at least one workflow (~44% adoption).**

Heaviest users:
- `rag_research_tool` — 9 workflows (full suite: GCP, terraform, docker, release, sync-env, pre-commit)
- `dev-nexus` — 7 workflows (same breadth)
- `infra-actions` — 4 (self-consuming)

Most common single use: `reusable-semantic-release.yml@v1.x.x` (8 repos).

**High-leverage gaps** (repos that should use infra-actions but don't):
- `openclaw-gateway` — 1 workflow, no infra-actions. The org's flagship L3b isn't consuming its own infra lib. **Most important gap to close.**
- `bond-nexus` — no `.github/workflows/` at all
- `research-orchestrator` — 1 workflow, no infra-actions
- `mcp-tooling` — 1 workflow, no infra-actions

## Q8: DAT contract is org-wide (RESOLVED)

While reading `DarojaAI/.github/docs/CI-CD-STANDARDS.md` (sections 1-3, "No Hardcoded Values" subsection), found:

> ### No Hardcoded Values
> - Database credentials → GitHub Secrets + GitHub Actions `environment`
> - API keys → GitHub Secrets
> - SSH keys → GitHub Secrets

This is the same principle as `openclaw-gateway`'s "DAT contract." The contract is already org-wide in the standards doc (dated 2026-04-28, before this session). The term "DAT contract" is local naming in `openclaw-gateway`; the principle is the org standard.

**Promote to MEMORY.md** as a clarified load-bearing fact: the "no hardcoded env values" principle is org-wide; `openclaw-gateway` calls it the DAT contract.

## Repo count update

**41 active + 3 archived = 44 total repos** in the org.

Two new repos I hadn't tracked before:
- `linux-desktop-seed-public` — mirrors `linux-desktop-seed`; per GOVERNANCE.md's "Public/Examples" category.
- `terraform-linux-desktop` — paired with `linux-desktop-seed` per L1b? Need to read to confirm.

## Caveats

- CODEOWNERS check used `main` branch only; repos with non-`main` default need a second pass.
- `devnexus-common/README-publish-vpc-runner-base.md` was caught as a "workflow" but it's a docs file. Edge case in the parser.
- Slow API sweep (per-repo, per-file); bulk API would be faster for re-runs.

## Action plan queued (next session or this one if time)

1. File a single tracking issue in `.github` with the Q6 + Q7 checklists.
2. Q4 RFC: Shared Libraries & Templates category (Q4 already approved by operator).
3. Q5: rename `devnexus-common` → `py-daroja-libs`.
4. Q15-Q17: intelligent-feed hardening (AGENTS.md, env-var paths, CI, LICENSE).
5. Q10: PAT redaction PRs in `rag_research_tool` + `rag-research-tool-work`.
6. Q11: trip-planning README — DONE this session (PR #1 opened).
