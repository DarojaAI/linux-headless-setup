# MEMORY.md — Long-term Org Knowledge

> **Main session only.** Do not load in shared/group contexts.
> **Distilled from:** session work, `ARCHITECTURE.md`, `REPOS.md`, `OPEN_QUESTIONS.md`. Last curated 2026-06-14.

---

## What DarojaAI is (one paragraph)

A small GitHub org (~42 repos) building a stack that goes from bare cloud VM to Discord AI agent, with three layered concerns: provisioning, intelligence (knowledge / capability / coordination), and user-facing products. Heavily GCP-flavored. Governed by a P0 contract in `DarojaAI/.github` that defines (currently) four repo categories; a fifth ("Shared Libraries & Templates") is approved but pending RFC.

## Operator

- **Handle:** `no_decaf_milan` (Discord), GitHub `patelmm79` (saw their name in `research-orchestrator` README, suggests they authored it).
- **Legal name (copyright holder):** **Milan Patel.** Confirmed 2026-06-14; keep in manifests/license declarations.
- **Authorized sender ID:** `1162240440322502656`.
- **Channel:** `#darojaai-architect` (Discord id `1515423505171353661`).
- **Working style (observed):** Direct. Hires me for advisory, expects me to ask questions and identify gaps before changing things. Flagged upfront that docs are "messy and inconsistent" — that's a deliberate invitation, not a complaint. Prefers "do it all" over per-item confirmation gates. Pasting "Conversation info" blocks with full metadata is normal.

## Load-bearing facts (don't forget)

1. **L1→L2→L3a→L3b provisioning stack.** `terraform-hcloud-linux-vm` → `linux-{headless,desktop}-setup` → `linux-desktop-seed` → `openclaw-gateway`. Each layer can be used independently.
2. **Intelligence triad boundary contract is P0.** `dev-nexus/docs/architecture/architectural-boundaries.md` (dated 2026-06-09). Forcing function: "If a PR adds code to X that could be answered by Y, it belongs in Y." Treat this as the spec for the whole triad.
3. **`openclaw-gateway` has the strongest env hygiene in the org** — DAT contract (no hardcoded env values), explicit test/head/prod topology, one bot per env. Model other repos should follow. **Org-wide applicability pending verification (Q8).**
4. **`infra-actions` is the CI/CD backbone** for the org. Composite actions, parameterized by design. **Intent is org-wide; usage is uneven** (per operator 2026-06-14). New CI work should check here first; Q7 sweeps for the gaps.
5. **`devnexus-common` is a shared lib, not a `dev-nexus` private one** — naming is misleading. **Rename to `py-daroja-libs` is approved (operator 2026-06-14, Q5).** Rename + downstream import-path updates is a queued batched PR per consumer repo.
5a. **`intelligent-feed` is a shared activation library** (not a "mystery" utility repo). Houses per-project activators for `globalbitings`/`bond-nexus`/`rag_research_tool`/`dynamic-worlock`. Imported by `research-orchestrator` via `INTELLIGENT_FEED_PATH` env-var-based `sys.path` injection. Operates as a Phase 4 Cognee pipeline orchestrator (RSS/PyPI fetch → Claude enrich → route → render to human/agent/structured subscribers). **Same shared-lib-with-misleading-name pattern as `devnexus-common`, with worse packaging** (no semver, no version pin, no CI). The org has at least 2 such shared-libs-to-be; a third category may be needed.
5b. **`dynamic-worlock` is a dangling reference.** Referenced in `intelligent-feed/intel/activation/dynamic_worlock.py` and `factory.py` as a project activator target, but `DarojaAI/dynamic-worlock` does not exist (404 on `gh repo view`). Either private (invisible to this token), deleted, or never created. Status pending operator confirmation (Q14).
6. **OpenClaw the framework ≠ `openclaw-gateway` the repo.** Don't conflate in docs.
7. **Skills ≠ memory.** Memory (`MEMORY.md`) is broad and declarative. Skills (`skills/<name>/SKILL.md`) are narrow and actionable — procedures I follow. The forcing function: "if I'd do this same procedure again, it's a skill." Full rules in `AGENTS.md` and `skills/authoring-skill/SKILL.md`.
8. **Shared libraries category is coming (Q4).** Approved by operator 2026-06-14. The "Shared Libraries & Templates" category is the proposed name. Repos that fit: `infra-actions`, `devnexus-common` (→ `py-daroja-libs`), `daroja-frontend-starter`, `intelligent-feed`. Action: file `[RFC]` in `.github` with the proposal. Same template used for the AGENTS.md RFC (`.github#1`).
9. **The `-1` suffix convention means "fork-of-fork, the one we use" (Q3).** Both `google-cloud-terraform-neo4j*` repos are fork-of-fork: operator originally forked from external source intending to propose a PR upstream; upstream was unpinned so they created a fork-of-fork (the `-1` suffix), which has a version tag and is the active one. **The same explanation likely covers `pattern-miner` and `dependency-orchestrator`** (both archived per Q1/Q2). Pattern to remember: `-1` is *not* a duplication smell; it's a "this is the load-bearing fork" marker.

## Open architectural hypotheses (not yet confirmed)

- `trip-planning` consumes `mcp-tooling/duffel` for flights (inferred from `mcp-tooling` README; not confirmed in `trip-planning` source).
- `agentic-log-attacker` and `skill-bridge` are the two non-archived "agentic systems" repos. May overlap with `dev-nexus`/`mcp-tooling`/`openclaw-gateway` — needs audit. (**Update 2026-06-14:** `agentic-log-attacker` is also archived. Only `skill-bridge` remains active in this bucket. Consider folding it into "Shared Libraries & Templates" once that category RFC lands.)
- The 4 GCP Terraform modules in `vpc-infra`/`gcp-postgres-terraform`/`gcp-dbt-terraform`/`gcp-vpc-egress-terraform` form a layered stack (network → db → dbt → egress) — need to confirm.

## Documentation health (snapshot 2026-06-14)

- **5% of repos have an empty GitHub description.** Down from 47% after the batched `gh repo edit` pass. The 2 remaining empties are archived repos (read-only via `gh repo edit`).
- **6 repos have no README** (`GlobalBitings`, `core-business-management`, `design-artifacts`, `darojaai_architect` (this repo), `gcp-postgres-terraform-example`, `trip-planning`).
- **5/6 mystery repos now mapped** (Q10). Only `GlobalBitings` left as-is per operator decision.
- **Best-documented:** `openclaw-gateway`, `rag_research_tool`, `dev-nexus`, `infra-actions`, `linux-desktop-seed`.
- **Worst-documented:** `trip-planning` (no README; Q11 will add one), the 6 README-less repos.

## Governance quirks

- `GOVERNANCE.md` currently defines 4 categories. **5th category ("Shared Libraries & Templates") is approved by operator 2026-06-14, pending RFC.**
- Standards changes go through `[RFC]` issues in `.github`. **Don't write standards changes unilaterally — file an RFC.**
- Per-repo owner is required. **CODEOWNERS audit is open (Q6) — not all repos have one.** Sweep planned.

## Recurring traps to avoid

- **Don't confuse `openclaw-gateway` with OpenClaw upstream.** The repo is built on OpenClaw; they're not the same thing.
- **Don't push changes to other repos without operator approval.** I'm advisory; operators and repo owners are the decision-makers.
- **Don't propose standards changes via my own docs.** They go in `.github` as RFCs.
- **Don't conflate "agentic systems" with the intelligence triad.** The triad (`dev-nexus`/`mcp-tooling`/`openclaw-gateway`) is the production platform. `agentic-log-attacker` and `skill-bridge` are separate tools.
- **"No nudges" = no scheduled/clock-driven user-visible interruption.** It does NOT mean "no reflection." End-of-session reflection (when the operator signals end of session) is part of the work, not a nudge. The weekly cron is a curator pass, not a chat ping.
- **"All logged" requires verification, not a tool success message.** After any batch of writes/edits, do a `git status` + targeted `read` to confirm. Tool success messages are not a verification. (Added 2026-06-14 after a workspace reset silently reverted several `edit` calls during a single session.)
- **The `-1` suffix is intentional, not a smell.** See fact #9 above.

## Standards cheat sheet (from `.github`)

- **Python:** Ruff (lint+format), MyPy strict, pytest ≥80% coverage.
- **TS/JS:** ESLint, Prettier, Vitest/Jest.
- **Terraform:** `terraform fmt`, Checkov, `terraform validate`, terratest where applicable.
- **Pre-commit:** Gitleaks, shared hook versions in `.github`.
- **PR requirements:** 1 approval, all CI pass, changelog/version bump if applicable.
- **Commit prefixes:** `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`.

## How to extend this file

When the operator makes a structural decision (rename, sunset, merge, new category), update both this file and `ARCHITECTURE.md`. When I learn a new load-bearing fact, put it here. When something gets old or wrong, delete it.

A fact in this file should still be true a month from now. If it won't be, it belongs in daily memory instead.

## Snapshot 2026-06-14 — org doc health (from `skills/audit-org-readmes`)

- 42 repos total.
- Started session: 20 with empty GitHub descriptions (47%), 6 with no README.
- After batch (operator-approved, no preview): 18/20 descriptions applied. Remaining 2 are archived repos (read-only via `gh repo edit`).
- 6 repos still have no README. Of those, 3 also have no description (`GlobalBitings`, `core-business-management`, `design-artifacts`) — `core-business-management` and `design-artifacts` descriptions applied 2026-06-14 per operator clarification. `GlobalBitings` left as-is per operator.
- Proposed descriptions for the 2 archived repos saved to `_context/descriptions-pending-archived.csv` for re-application when unarchived.
- All numbers re-derivable by re-running the skill; don't update this section by hand.
