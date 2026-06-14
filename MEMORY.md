# MEMORY.md — Long-term Org Knowledge

> **Main session only.** Do not load in shared/group contexts.
> **Distilled from:** session work, `ARCHITECTURE.md`, `REPOS.md`, `OPEN_QUESTIONS.md`. Last curated 2026-06-14.

---

## What DarojaAI is (one paragraph)

A small GitHub org (~42 repos) building a stack that goes from bare cloud VM to Discord AI agent, with three layered concerns: provisioning, intelligence (knowledge / capability / coordination), and user-facing products. Heavily GCP-flavored. Governed by a P0 contract in `DarojaAI/.github` that defines four repo categories and standards for contribution, security, release.

## Operator

- **Handle:** `no_decaf_milan` (Discord), GitHub `patelmm79` (saw their name in `research-orchestrator` README, suggests they authored it).
- **Authorized sender ID:** `1162240440322502656`.
- **Channel:** `#darojaai-architect` (Discord id `1515423505171353661`).
- **Working style (observed):** Direct. Hires me for advisory, expects me to ask questions and identify gaps before changing things. Flagged upfront that docs are "messy and inconsistent" — that's a deliberate invitation, not a complaint.

## Load-bearing facts (don't forget)

1. **L1→L2→L3a→L3b provisioning stack.** `terraform-hcloud-linux-vm` → `linux-{headless,desktop}-setup` → `linux-desktop-seed` → `openclaw-gateway`. Each layer can be used independently.
2. **Intelligence triad boundary contract is P0.** `dev-nexus/docs/architecture/architectural-boundaries.md` (dated 2026-06-09). Forcing function: "If a PR adds code to X that could be answered by Y, it belongs in Y." Treat this as the spec for the whole triad.
3. **`openclaw-gateway` has the strongest env hygiene in the org** — DAT contract (no hardcoded env values), explicit test/head/prod topology, one bot per env. Model other repos should follow.
4. **`infra-actions` is the CI/CD backbone** for the org. Composite actions, parameterized by design. New CI work should check here first.
5. **`devnexus-common` is a shared lib, not a `dev-nexus` private one** — naming is misleading.
6. **OpenClaw the framework ≠ `openclaw-gateway` the repo.** Don't conflate in docs.
7. **Skills ≠ memory.** Memory (`MEMORY.md`) is broad and declarative. Skills (`skills/<name>/SKILL.md`) are narrow and actionable — procedures I follow. The forcing function: "if I'd do this same procedure again, it's a skill." Full rules in `AGENTS.md` and `skills/authoring-skill/SKILL.md`.

## Open architectural hypotheses (not yet confirmed)

- `pattern-miner` and `dev-nexus` may overlap. Need to read both.
- The two `google-cloud-terraform-neo4j*` repos are likely the same thing at different versions.
- `trip-planning` consumes `mcp-tooling/duffel` for flights (inferred from `mcp-tooling` README; not confirmed in `trip-planning` source).
- Several "agentic" repos (`agentic-log-attacker`, `dependency-orchestrator`, `pattern-miner`, `skill-bridge`) may overlap with `dev-nexus`/`mcp-tooling`/`openclaw-gateway` — needs audit.

## Documentation health (snapshot 2026-06-14)

- **~52% of repos have an empty GitHub description.** Single biggest org-wide gap.
- **6 repos are "unexplored" from outside** — no description, no obvious category.
- **2 repos flagged for duplicate suspicion** (the two Neo4j modules).
- **Best-documented:** `openclaw-gateway`, `rag_research_tool`, `dev-nexus`, `infra-actions`, `linux-desktop-seed`. Each has clear READMEs and architecture docs.
- **Worst-documented:** `trip-planning` (no README), the 6 unexplored repos.

## Governance quirks

- `GOVERNANCE.md` defines 4 categories. The actual org has at least 6 (it misses "shared libraries" and "agentic systems" as categories).
- Standards changes go through `[RFC]` issues in `.github`. **Don't write standards changes unilaterally — file an RFC.**
- Per-repo owner is required. Not all repos have CODEOWNERS (unconfirmed; pending audit).

## Recurring traps to avoid

- **Don't confuse `openclaw-gateway` with OpenClaw upstream.** The repo is built on OpenClaw; they're not the same thing.
- **Don't push changes to other repos without operator approval.** I'm advisory; operators and repo owners are the decision-makers.
- **Don't propose standards changes via my own docs.** They go in `.github` as RFCs.
- **Don't conflate "agentic systems" with the intelligence triad.** The triad (`dev-nexus`/`mcp-tooling`/`openclaw-gateway`) is the production platform. `agentic-log-attacker` et al. are separate tools.
- **"No nudges" = no scheduled/clock-driven user-visible interruption.** It does NOT mean "no reflection." End-of-session reflection (when the operator signals end of session) is part of the work, not a nudge. The weekly cron is a curator pass, not a chat ping.

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
- 6 repos still have no README. Of those, 3 also have no description (`GlobalBitings`, `core-business-management`, `design-artifacts`) — these are sunset-candidate pending read.
- Proposed descriptions for the 2 archived repos saved to `_context/descriptions-pending-archived.csv` for re-application when unarchived.
- All numbers re-derivable by re-running the skill; don't update this section by hand.
