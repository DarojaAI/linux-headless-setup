---
name: issue-via-subagent
description: Use when the operator wants a GitHub issue implemented end-to-end (code change → PR → CI green) without keeping the main session in the loop. Validated 2026-07-30 on DarojaAI/rag_research_tool issues #1210, #1266.
version: 1.0.0
author: darojaai_architect
license: MIT
metadata:
  hermes:
    tags: [subagent, workflow, github, pr, ci, rag-research-tool]
    related_skills: [authoring-skill]
---

# Implement an Issue via Subagent (worktree + isolated session)

## Overview

This is the validated workflow for handing a single GitHub issue to a subagent and getting back a green PR. Proven on `DarojaAI/rag_research_tool` issues #1210 (pipeline_orchestrator LLM migration) and #1266 (SKILL.md) on 2026-07-30. Both PRs landed green on first push.

The main session stays clean: it composes the brief, spawns the subagent, and reports results. The subagent owns the worktree, the commits, the pre-commit hooks, and the CI verification loop.

## When to Use

- The operator wants a specific issue implemented and PR opened.
- The issue scope is contained (≤3 files touched, ≤2 commits).
- A clear reference pattern already exists for the migration.
- The operator is willing to merge the PR after CI passes.

### Don't use this skill for:

- Investigation/exploration tasks with no code change → just read in the main session.
- Multi-repo changes or architectural RFCs → keep in main session for org context.
- Work that needs operator decisions mid-flight → use a checkpoint or stay in main.
- Tasks that depend on earlier subagent output → chain them or do sequentially in main.

## Procedure

### 1. Pre-flight: verify the issue and reference

Before spawning anything, confirm:

```
gh issue view <num> --repo <org>/<repo>            # title, body, acceptance criteria
gh pr list --repo <org>/<repo> --state open        # no duplicate PR already exists
gh repo view <org>/<repo> --json defaultBranchRef  # know the base branch
```

If the work needs an upstream library change (e.g., new method in `devnexus-common`), plan the dependency PR first. **Do not** block the subagent on it — either land the upstream PR yourself or instruct the subagent to pin to a SHA.

### 2. Create a worktree branch

Each subagent gets its own worktree off the latest `origin/main`. Naming convention: `fix/<issue>-<short>` or `feat/<issue>-<short>`.

```
git fetch origin
git worktree add ../<repo>-<branch-suffix> -b <branch-name> origin/main
cd ../<repo>-<branch-suffix>
```

Worktree lives outside the main checkout, so the main session keeps its working tree clean and the subagent gets full git autonomy.

### 3. Spawn the subagent with a tight brief

Use `sessions_spawn` (isolated, not fork — fork would inherit the main session's bloated context). Include ALL of:

1. **Repo + worktree path** (absolute)
2. **Issue number + link** (the source of truth for scope)
3. **Reference pattern** (concrete code excerpt — not "see PR #1273", but actual function calls)
4. **Files to modify** with line numbers if known
5. **Hard constraints** (see below)
6. **Output format** (PR number, CI status, commits pushed)

#### Hard constraints — always include

- "Do NOT commit `_context/` or `logs/` files — they break pre-commit's dirty-tree check."
- "Verify ALL CI checks pass before reporting back (`gh pr checks <num> --repo <org>/<repo>`)."
- "If a check fails, read the actual log with `gh run view --log-failed` — don't guess at the cause."
- "Run `ruff format` and `ruff check` locally before pushing; pre-commit will run them too."
- "Commit message must follow conventional commits (`feat:`, `fix:`, `refactor:`, `docs:`, `test:`)."

#### Output format

Subagent must report back: PR number, branch name, list of files changed, CI status (pass/fail/pending with counts), and any deviations from the brief.

### 4. Let the subagent work

Spawn and yield. Do not poll. The subagent should:

- Make the code changes
- Run pre-commit / ruff locally
- Commit + push
- Open the PR (`gh pr create`)
- Watch CI until all required checks pass
- Report back

### 5. Verify in main session

When the subagent reports done, **verify in the main session**:

```
gh pr view <num> --repo <org>/<repo> --json files,commits,title
gh pr checks <num> --repo <org>/<repo>
```

Do not trust the subagent's success message — read the CI status yourself. This caught the v1.13.1 tag bug (stale tag pointed at a commit without the new method).

### 6. Report back to operator

Concise chat message: "PR #N: <title>. All M checks pass. Ready to merge." Include the issue close-out if the PR body uses `Closes #N`.

## Verification

How to know the skill worked:

1. Subagent returns a PR number and CI status.
2. `gh pr checks` in main session confirms the same status.
3. No `_context/` files in the PR's file list (`gh pr view --json files`).
4. Issue can be closed with `Closes #N` in the PR body or manually after merge.

## Anti-patterns

- **Fork context.** Spawning the subagent with `context="fork"` dumps the main session's bloated context into the child. Use `isolated` (default) with an explicit brief.
- **Vague brief.** "Implement issue #1210" gives the subagent nothing to anchor against. Always include the reference pattern.
- **Trust without verification.** The subagent will say "all checks pass" — verify in the main session before reporting to the operator.
- **Forgetting scratch paths.** A subagent that finds `_context/` notes tempting and commits them will fail pre-commit's dirty-tree check. The constraint must be in the brief.
- **Polling.** Don't `sessions_yield` then poll `subagents list` in a loop. Yield once, wait for the completion event.

## Provenance

- 2026-07-30: validated on `DarojaAI/rag_research_tool` issues #1210 and #1266 in one parallel spawn.
  - #1210 → PR #1275 (19 checks pass, merged same day)
  - #1266 → PR #1274 (15 checks pass, ready)
- Subagent task template was reverse-engineered from the issues themselves after the fact, not designed up-front. Consider whether to design the template *before* the next batch.