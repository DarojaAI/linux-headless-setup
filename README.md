# darojaai_architect

Architectural advisor for the `DarojaAI` GitHub organization. This repo is the architect's home — it contains the architect's mental model of the org, not application code.

## What this repo is

`darojaai_architect` is an agent role, not a service. It lives in `#darojaai-architect` on Discord and advises the operator (`no_decaf_milan`) on:

- **Structural problems** — architecture drift, missing boundaries, undocumented cross-repo dependencies.
- **Documentation problems** — missing READMEs, stale docs, contradictory guidance, broken links.
- **Cross-repo opportunities** — code, docs, CI, governance, or tooling that should be shared and isn't.
- **Standards changes** — proposed via `[RFC]` issues in `DarojaAI/.github` (not pushed unilaterally).

The full role contract is in [`AGENTS.md`](./AGENTS.md). Read that first.

## Repo contents

| File | Purpose |
|---|---|
| `AGENTS.md` | The architect's contract. Role, responsibilities, severity tiers, daily reflection rules. |
| `MEMORY.md` | Long-term org knowledge (main session only). |
| `ARCHITECTURE.md` | Org structure: provisioning stack, intelligence triad, application products, shared infra. |
| `REPOS.md` | Per-repo inventory with status (`mapped` / `partial` / `unexplored` / `flagged`). |
| `OPEN_QUESTIONS.md` | Gaps in the architect's knowledge, severity-tagged, awaiting operator input. |
| `docs/org-overview.md` | CTO-facing one-page summary of the org with a Mermaid diagram. |
| `diagrams/` | Raw Mermaid source for the org overview diagram. |
| `memory/YYYY-MM-DD.md` | Daily session notes. |
| `skills/<name>/SKILL.md` | Procedures the architect follows. See `skills/authoring-skill/SKILL.md` for how to author one. |
| `USER.md`, `SOUL.md`, `IDENTITY.md`, `TOOLS.md` | OpenClaw runtime identity and persona files (inherited from seed). |
| `_context/` | Gitignored scratch space for clones of repos being analyzed. |

## Skills

Skills are the architect's procedural memory. They follow the convention in `skills/authoring-skill/`.

- [`skills/authoring-skill/`](./skills/authoring-skill/SKILL.md) — how to write a skill in this repo.
- [`skills/audit-org-readmes/`](./skills/audit-org-readmes/SKILL.md) — sweep the org for empty descriptions and missing READMEs.

## Quick start (for the architect at session startup)

1. Read `AGENTS.md` (in startup context).
2. Read `MEMORY.md` (in startup context, main session only).
3. Check `OPEN_QUESTIONS.md` — anything you can resolve today?
4. Cross-check `REPOS.md` against `gh repo list DarojaAI` — new/removed repos?
5. If you did real work: write `memory/YYYY-MM-DD.md` with a `## Reflection` section.

## Related org repos

- `DarojaAI/.github` — org governance, standards, RFCs. The architect proposes changes there.
- `DarojaAI/dev-nexus/docs/architecture/architectural-boundaries.md` — P0 boundary contract the architect helps enforce.
- `DarojaAI/openclaw-gateway/docs/architecture.md` — DAT contract, the model of env hygiene other repos should follow.
