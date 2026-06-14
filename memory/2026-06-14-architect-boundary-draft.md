# Draft Issue: Add `darojaai_architect` to the architectural boundary contract

> **Status:** DRAFT for operator review before posting as an issue on `DarojaAI/dev-nexus`.
> **Author:** `darojaai_architect`
> **Date:** 2026-06-14
> **Target:** New issue in `DarojaAI/dev-nexus`, label `architecture`, then a follow-up PR adding a paragraph to `docs/architecture/architectural-boundaries.md`.

---

## Title

`[RFC] Carve out the darojaai_architect role in the P0 architectural boundary contract`

## Body

The architectural boundary contract at `DarojaAI/dev-nexus/docs/architecture/architectural-boundaries.md` (P0, dated 2026-06-09) defines three cooperating systems:

- **dev-nexus** = Knowledge & Analysis
- **mcp-tooling** = Capability
- **openclaw-gateway** = Coordination

It does **not** carve out `darojaai_architect` (`DarojaAI/darojaai_architect`), the new architectural advisor role. As a result, the boundary between dev-nexus' per-repo analysis work and the architect's org-level analysis work is ambiguous.

This is a P0-adjacent issue: the boundary doc is load-bearing, and the architect role is now in production (binding to `#darojaai-architect` Discord channel id `1515423505171353661`, scheduled weekly curator pass).

## Evidence of overlap

`dev-nexus` ships 12 in-repo skills under `skill_workshop/`. Five of them overlap with work the architect does or would do:

| Skill | Per-repo vs. org-level? |
|---|---|
| `docs-audit` | Per-repo. Architect can also run org-wide versions. |
| `hardcoding-audit` | Per-repo. Architect runs org-wide. |
| `structure-diagnosis` | Per-repo. Architect runs org-wide. |
| `strategic-analysis` | Per-repo. Architect runs org-wide. |
| `cicd-audit`, `infra-repo-onboarding`, etc. | Per-repo only. No architect overlap. |

Plus two agent-level skills (`gcp-postgres-vm-state-inspector`, `atlas-silent-skip-detector`) installed at `~/.openclaw/skills/` for live prod-state inspection.

## Proposed boundary

I propose adding this paragraph to `architectural-boundaries.md`, after the table of system responsibilities and before the "Core Principle" section:

> ### darojaai_architect: Org-Level Architecture Advisor
>
> **Role:** Sits alongside the triad as a fourth horizontal concern: *architecture itself.* The architect is a code-light, advisory role that maintains the org's mental model — its architectural map, repo inventory, documentation health, and structural recommendations — and helps enforce the boundary contract.
>
> **Belongs in darojaai_architect:**
> - Org-wide documentation audits (across all 42+ repos)
> - Cross-repo consistency checks (naming, conventions, link rot)
> - Standards proposals (filed as `[RFC]` issues in `.github`)
> - Org-level structure analysis (when to split, when to merge, when to sunset)
> - Boundary contract enforcement — flagging drift in this doc and proposing updates
> - Weekly curator pass: consolidate, deprecate stale content, promote durable facts
>
> **Does NOT belong in darojaai_architect:**
> - Per-repo analysis (that's dev-nexus' skill_workshop) — the architect dispatches per-repo work to dev-nexus via A2A
> - Tool implementation (that's mcp-tooling)
> - Agent runtime / orchestration (that's openclaw-gateway)
> - Application code in any other repo (the architect is advisory, not a coding agent)
> - Standards changes without operator approval (the architect proposes; the operator decides)
>
> **Relationship to dev-nexus:** dev-nexus is the *per-repo analysis engine*; the architect is its *org-level wrapper and consumer*. When the architect needs per-repo analysis (e.g., "is `dev-nexus`'s `docs-audit` skill applied consistently across the org?"), the architect calls dev-nexus via A2A. When dev-nexus finds a pattern that crosses repos, it surfaces the finding to the architect for org-level action.

## Why this matters

Without an explicit boundary:
- The architect and dev-nexus may duplicate work
- Neither agent can confidently say "this is my job, not yours"
- The boundary contract (P0) is incomplete

## Open questions

- **Q1.** Is the proposed boundary language right? Specifically, "per-repo wrapper" might be too narrow — the architect also does ad-hoc per-repo deep dives (e.g., the 2026-06-14 audit of `dev-nexus`/`rag_research_tool`/`linux-desktop-seed`). Should the boundary say "per-repo work goes to dev-nexus when the work has a reusable skill; ad-hoc deep dives stay with the architect"?
- **Q2.** Should the architect be listed as a *system* in the boundary doc (parallel to dev-nexus/mcp-tooling/openclaw-gateway), or as a *role* (separate concept)? My read: it's a role, not a system — it doesn't run services. But the doc structure makes the role/system distinction fuzzy.
- **Q3.** Should the boundary doc be split into "System Boundaries" (current content) and "Role Boundaries" (this new content)? Cleaner separation, but two files to maintain.

## What I'm NOT asking for

- I'm not asking to *change* dev-nexus' role. The triad is fine as it is.
- I'm not asking for code changes. This is a doc-only update.
- I'm not asking for retroactive analysis of past work. Future sessions can refer to the new boundary.

## Why I'm filing this issue instead of opening a PR directly

The boundary doc is P0. Any change to it deserves review by the team that owns it (the `dev-nexus` maintainers, per the file's `Owner` header). An issue-first approach gives the maintainers a chance to push back on the boundary language before it's committed.
