# Open Questions

Gaps in my knowledge that need operator input or further investigation. Severity-tagged.

> **Severity:**
> - **P0** — Load-bearing. Architectural contract violation, security risk, or fact I'm depending on for other answers.
> - **P1** — Structural. Wrong or missing docs, unclear ownership, drift between governance and reality.
> - **P2** — Hygiene. Naming, description, broken links. Batchable.

---

## P0 — Need to resolve

### Q1. What is `pattern-miner` and how does it relate to `dev-nexus`?
**Resolved 2026-06-14 (operator):** Both `pattern-miner` and `dependency-orchestrator` are **archived**. They were forked from an external source with the intent to propose a PR upstream; the upstream was unpinned so operator created a fork-of-fork (the `-1` suffix). The repos are kept archived. No action needed beyond leaving them as-is. See Q-arch for the archived-repo treatment.

### Q2. What is `dependency-orchestrator`?
**Resolved 2026-06-14 (operator):** Same as Q1 — archived, same fork-of-fork origin. Left as-is.

### Q3. Are the two `google-cloud-terraform-neo4j*` repos the same?
**Resolved 2026-06-14 (operator):** Fork-of-fork situation. Operator originally forked from an external source intending to propose a PR upstream. Upstream was unpinned; couldn't control for it. Created a fork-of-fork (the `-1` suffix). **The `-1` suffix repo is the one in active use** and has a version tag. The other (`google-cloud-terraform-neo4j`, no suffix) is the older fork. Both retained. **Decision:** leave as-is; the `-1` is the load-bearing one for the org. No sunset.

---

## P1 — Structural

### Q4. Add "Shared Libraries & Templates" as a fifth governance category
**Resolved 2026-06-14 (operator):** Create the new category. Repos that fit:
- `infra-actions` (CI/CD library)
- `devnexus-common` (Python utility library) — to be renamed `py-daroja-libs` per Q5
- `daroja-frontend-starter` (frontend template)
- `intelligent-feed` (cross-product activation library, see Q12)

**Action:** Open `[RFC]` in `DarojaAI/.github` proposing the new category and listing the affected repos. Same template used for the AGENTS.md RFC (`.github#1`).

### Q5. Rename `devnexus-common` → `py-daroja-libs`
**Resolved 2026-06-14 (operator):** Rename. Reasoning: name implies `dev-nexus` ownership; in fact it's a shared Python utility library for the whole org.

**Action items (queue):**
- Repo rename via GitHub Settings (operator has the buttons; I can prepare a PR with updated references in dependent repos).
- Update `devnexus-common` README to reflect the new name and broader scope.
- Update any import paths in consumer repos (`dev-nexus`, `mcp-tooling`, others — need an audit).
- Update AGENTS.md / CONTRIBUTING.md / GOVERNANCE.md references.
- Open an issue / PR per affected repo with the rename change.
- Watch for downstream breakage (CI, docs links, etc.).

**Cost:** Medium. Not a 1-line change. Worth doing in a batched PR per consumer repo.

### Q6. Does every repo have a CODEOWNERS file?
**Status:** Not yet audited. Operator: "i'm not sure if it does" → confirmed gap. **Action:** Sweep all 42 repos for `.github/CODEOWNERS`. Open an issue per repo that's missing one. Reuse the audit pattern from `skills/audit-org-readmes`.

### Q7. Which repos use `infra-actions` vs. roll their own CI?
**Resolved 2026-06-14 (operator):** Intent of `infra-actions` is org-wide (composite actions available to all repos). **Usage is uneven** — some repos import, some roll their own. **Action:** Sweep `.github/workflows/` across all repos, list actions used, compare to `infra-actions` library. Identify the high-value roll-your-own cases and propose migrations. Pattern is reusable; extract a skill.

### Q8. Does the `DAT contract` (no hardcoded env values) apply beyond `openclaw-gateway`?
**Status:** Open. Need to read `DarojaAI/.github/docs/CI-CD-STANDARDS.md` to confirm whether the DAT contract is org-wide or local to `openclaw-gateway`. **Action:** Fetch the standards doc and report.

---

## P2 — Hygiene

### Q9. Repos with empty GitHub descriptions — fix
**Resolved 2026-06-14 (operator):** Fix. **Done earlier in this session:** batched 18/20 repos via `gh repo edit`. 2 remain empty (both archived, see Q-arch). No further action unless new empty-description repos appear.

### Q10. Six repos with no description and no obvious category
**Resolved 2026-06-14 (operator):** 5/6 mapped, 1 left as-is.
- `GlobalBitings` — leave as-is (operator decision).
- `intelligent-feed` — **mapped** to Phase 4 Cognee research pipeline orchestrator. Houses per-project activators for `globalbitings`/`bond-nexus`/`rag_research_tool`/`dynamic-worlock` (last one: dangling reference, repo missing). Imported by `research-orchestrator` via `INTELLIGENT_FEED_PATH` sys.path injection. Full take at `memory/2026-06-14-intelligent-feed-take.md`.
- `pattern-miner` — **archived** per Q1.
- `dependency-orchestrator` — **archived** per Q2.
- `design-artifacts` — **mapped** to organizational design artifacts (brand guide, visual identity) per operator.
- `core-business-management` — **mapped** to AI agent designated for managing DarojaAI's core business operations per operator.

### Q11. `trip-planning` has no README
**Resolved 2026-06-14 (operator):** Add a README. **Action:** Clone `trip-planning`, read the code, propose a README structure. (Queued; not started.)

### Q12. Do all repos link back to `.github` governance?
**Resolved 2026-06-14 (operator):** Should be. **Action:** Sweep all 42 READMEs for a `.github` reference; add a "see also" footer where missing. Batch into a single housekeeping PR per repo, or a tracking issue with checklist.

### Q13. Stale branches / open PRs / unaddressed issues per repo
**Resolved 2026-06-14 (operator):** Have a look. **Action:** Sweep all repos for: (a) branches untouched for >90 days, (b) PRs open for >30 days without activity, (c) issues open for >90 days without activity. Surface a per-repo health report. Sunset candidates = 30+ open issues AND 0 commits in 6 months. Pattern is reusable; extract a skill.

---

## P1 — Structural (raised by intelligent-feed deep read 2026-06-14)

### Q14. `dynamic-worlock` is a dangling reference
`intelligent-feed/intel/activation/dynamic_worlock.py` and `factory.py` reference `DarojaAI/dynamic-worlock` (with both hyphen and underscore aliases). **The repo does not exist** (`gh repo view DarojaAI/dynamic-worlock` → 404). The activator ships in `intelligent-feed` and is registered in the factory, so `get_activator("dynamic-worlock")` will fail at runtime if anyone tries it. Three possibilities:
- (a) Repo is private, invisible to this token. **Verify.**
- (b) Repo was deleted; the activator is dead code.
- (c) Different org, or never created.

**Need:** operator to confirm the status and decide: delete the activator + factory entries, or unorphan the repo.

### Q15. `intelligent-feed` is a shared library masquerading as a product
**Resolved 2026-06-14 (operator):** Should be documented as a shared lib. **Action:** Add a standardized `AGENTS.md` to `intelligent-feed` (per the RFC template from `.github#1`) + document the cross-repo activation contract prominently in the README. Cheapest viable path.

This is the same shared-lib-with-misleading-name pattern as `devnexus-common`/`py-daroja-libs`. The activators themselves are well-structured (BaseActivator ABC, factory, dry-run mode, readiness check) — the *packaging* is the problem. `research-orchestrator` imports via `sys.path` injection, not a proper package install.

**Cost:** ~30 min. **Impact:** turns intelligent-feed from "works on the operator's machine" into a properly consumable shared lib.

### Q16. Hardcoded operator-local paths in all 4 activators
`~/GithubProjects/GlobalBitings/...`, `~/GithubProjects/bond-nexus/...`, `~/GithubProjects/rag_research_tool/...`, `~/GithubProjects/dynamic-worlock/...`. None configurable via env vars. The repo "works" only on the operator's local checkout layout.

**Fix options:** env vars per activator, or one config block at the top, or a `paths.yaml` config file.

**Cheapest:** add a single env-var-override constructor param to each activator (5 min per file). Operates only on `intelligent-feed`.

**Status:** Open. **Action:** When Q14 is resolved and we know whether `dynamic-worlock` stays or goes, apply the env-var-override fix to the 3 (or 4) activators that remain.

### Q17. `intelligent-feed` has no `.github/`, no `AGENTS.md`, no LICENSE
**Action:** Add a basic pytest workflow (uses `infra-actions` per org standard) + the standardized `AGENTS.md` template from the RFC + a LICENSE file. **Cost:** ~30 min. **Impact:** turns intelligent-feed into a properly consumable shared lib with regression detection.

---

## Resolved (archive)

### Q-arch. Archived repos with proposed descriptions
**Resolved 2026-06-14:** Operator decision: leave the 2 archived repos (`dependency-orchestrator`, `pattern-miner`) as-is. Their proposed descriptions stay in `_context/descriptions-pending-archived.csv` for re-application when unarchived.

### Q-who-using. skill-bridge "Who is using" table — operator row accuracy
**Status 2026-06-14:** The "Who is using skill-bridge" section in the README (PR #30) lists the operator workspace (`session-commands`, `maintenance` skills) as "in use" — that's an inference from the manifest, not ground-truth confirmation from the operator. **Need operator to confirm:** is that row correct, or should it say "pre-adoption, consumers TBD" until a real consumer pipeline is verified? Edit the row in PR #30 or amend it post-merge.

### Q-copyright-name. Manifest copyright holder is "Milan Patel" but operator is now "no_decaf_milan"
**Resolved 2026-06-14 (operator):** Keep "Milan Patel" as the copyright/legal name. Leave manifests as-is.
