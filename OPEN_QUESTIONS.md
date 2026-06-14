# Open Questions

Gaps in my knowledge that need operator input or further investigation. Severity-tagged.

> **Severity:**
> - **P0** — Load-bearing. Architectural contract issue, security risk, or fact I'm depending on for other answers.
> - **P1** — Structural. Wrong or missing docs, unclear ownership, drift between governance and reality.
> - **P2** — Hygiene. Naming, description, broken links. Batchable.

---

## P0 — Need to resolve

### Q1. What is `pattern-miner` and how does it relate to `dev-nexus`?
**Status:** Unexplored. Same primary language (Python), similar "pattern" theme. Could be:
- An early/prototype version of `dev-nexus` that should be retired or merged.
- A complementary tool (e.g., per-repo miner vs. dev-nexus' cross-repo).
- Unrelated and just sharing a word in the name.

**Need:** Clone + read; check git history for relationship to `dev-nexus`. If duplicate → sunset proposal.

### Q2. What is `dependency-orchestrator`?
**Status:** Unexplored. Python, recently updated (2026-06-10).
**Hypothesis:** Could be a cross-repo dependency tracker (consuming `dev-nexus` or `agentic-log-attacker` outputs), or could be unrelated.
**Need:** Clone + read.

### Q3. Are the two Neo4j repos the same?
- `google-cloud-terraform-neo4j`
- `google-cloud-terraform-neo4j-1`

The `-1` suffix is a strong smell. Could be (a) v1 vs. v2 split, (b) a copy-paste mistake, (c) an active fork. Last updated: 2026-06-08 (same day).
**Need:** Clone both, diff. If one is stale → sunset.

---

## P1 — Structural

### Q4. What's the org's category for shared infrastructure libs?
`GOVERNANCE.md` lists four categories: Infrastructure (IaC), Core Services, Frontend, Public/Examples. None fit:
- `infra-actions` (CI/CD library)
- `devnexus-common` (Python utility library)
- `daroja-frontend-starter` (frontend template)

These are "shared libraries / templates" — a fifth category.
**Need:** Propose adding a "Shared Libraries & Templates" category to `GOVERNANCE.md` via `[RFC]`.

### Q5. `devnexus-common` is misnamed (or its purpose isn't communicated)
The name implies it's owned by / for `dev-nexus`. Its description says "Shared Python utilities for DarojaAI projects" — broader.
**Risk:** Other repos don't know they can/should depend on it. Adoption is invisible.
**Options:** Rename to something like `daroja-common` or `py-daroja-libs`, OR keep name and improve description + add a `USING-THIS-LIB.md`. The latter is cheaper.

### Q6. Does every repo have a CODEOWNERS file?
`GOVERNANCE.md` requires per-repo owners. I haven't audited this.
**Need:** Sweep. Open an issue per repo that's missing one.

### Q7. Which repos use `infra-actions` vs. roll their own CI?
If a repo has bespoke CI that overlaps with `infra-actions`, that's a consolidation opportunity (and a risk if `infra-actions` evolves).
**Need:** Sweep `.github/workflows/` across repos, list actions used, compare to `infra-actions` library.

### Q8. Does the `DAT contract` (no hardcoded env values) apply beyond `openclaw-gateway`?
The contract is documented in `openclaw-gateway/docs/architecture.md` and is a P0-grade spec for that repo.
**Question:** Is it an org-wide standard, or local to that repo?
**Need:** Read `DarojaAI/.github/docs/CI-CD-STANDARDS.md` (haven't fetched yet) and confirm.

---

## P2 — Hygiene

### Q9. ~22 repos have empty GitHub descriptions
Description is what shows in `gh repo list` and on the org's GitHub page. Empty descriptions hurt discoverability and signal "we don't know what this is."
**Plan:** Batch fix. Use `gh repo edit --description "..."` for each. I'll draft descriptions and run them by the operator before applying.

### Q10. Six repos with no description and no obvious category
- `GlobalBitings`
- `intelligent-feed`
- `pattern-miner`
- `dependency-orchestrator`
- `design-artifacts`
- `core-business-management`

Some of these may be candidates for sunset (especially `GlobalBitings`, which is from 2026-05-03 and Python with no signal). Need to read each before proposing.

### Q11. `trip-planning` has no README
Only the GitHub description. As a user-facing product (per its description), this is a documentation gap.
**Plan:** Clone, assess, propose README.

### Q12. Do all repos link back to `.github` governance?
Not all READMEs reference the org-level governance. Worth checking and adding a "see also" footer where missing.

### Q13. Are there stale branches / open PRs / unaddressed issues per repo?
Not investigated. A repo with 30 open issues and 0 commits in 6 months is a sunset candidate.

---

## Resolved (archive)

### Q-arch. Archived repos with proposed descriptions
**Resolved 2026-06-14:** Operator decision: leave the 2 archived repos (`dependency-orchestrator`, `pattern-miner`) as-is. Their proposed descriptions stay in `_context/descriptions-pending-archived.csv` for re-application when unarchived.

### Q-who-using. skill-bridge "Who is using" table — operator row accuracy
**Status:** 2026-06-14. The "Who is using skill-bridge" section in the README (PR #30) lists the operator workspace (`session-commands`, `maintenance` skills) as "in use" — that's an inference from the manifest, not ground-truth confirmation from the operator. **Need operator to confirm:** is that row correct, or should it say "pre-adoption, consumers TBD" until a real consumer pipeline is verified? Edit the row in PR #30 or amend it post-merge.

### Q-copyright-name. Manifest copyright holder is "Milan Patel" but operator is now "no_decaf_milan"
**Status:** 2026-06-14. `skill-bridge.manifest.json` declares copyright holder as "Milan Patel" for the 2 PROPRIETARY skills (`session-commands`, `maintenance`). Operator is now `no_decaf_milan` on Discord. **Need operator to confirm:** is "Milan Patel" the legal name they want retained in the manifest, or should it be updated? If updated, also check other repos' manifests/license declarations for the same name. May be a broader name-consolidation finding.
