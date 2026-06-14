---
name: authoring-skill
description: Use when creating, editing, or sunsetting a skill in this repo. Defines the frontmatter, structure, and decision rules for skills/ in darojaai_architect.
version: 1.0.0
author: darojaai_architect
license: MIT
metadata:
  hermes:
    tags: [meta, skills, authoring, conventions, architect]
    related_skills: [audit-org-readmes]
---

# Authoring a Skill (in `darojaai_architect`)

## Overview

This skill describes how to create, edit, and retire skills in `darojaai_architect/skills/`. It is the procedure I (the architect agent) follow when I author procedural memory for myself.

The shape is borrowed from Hermes Agent's in-repo skill conventions (`hermes-agent/skills/software-development/hermes-agent-skill-authoring/SKILL.md`), adapted to the smaller scope of this repo.

## When to Use

- You just did a task for the first time and are tempted to write "next time, remember to do X" → create a skill.
- The operator asks you to formalize a procedure you already follow informally.
- An existing skill needs to be split, merged, or retired.

### Don't use this skill for:

- Facts about the org → those go in `MEMORY.md`, not a skill.
- Decisions the operator has made → those go in `MEMORY.md` (load-bearing) or daily memory (ephemeral).
- One-off fixes → no skill needed; daily memory is enough.

## Required Frontmatter

Every `SKILL.md` MUST start with this exact shape (YAML frontmatter delimited by `---`):

```yaml
---
name: my-skill-name               # lowercase, hyphens, ≤64 chars
description: Use when <trigger>. <one-line behavior>. ≤1024 chars.
version: 1.0.0                    # bump on meaningful edits
author: darojaai_architect
license: MIT
metadata:
  hermes:
    tags: [short, descriptive, tags]
    related_skills: [other-skill]
---
```

**Hard rules** (validator-style, mirror Hermes' `_validate_frontmatter`):

- File must start with `---` on line 1 (no leading blank line).
- Frontmatter closes with `\n---\n` before the body.
- `name` and `description` are required; description ≤1024 chars.
- Non-empty body after the closing `---`.
- `name` must match `[a-z0-9][a-z0-9._-]*` and be ≤64 chars.

**Soft conventions** (peer-matched, not enforced):

- Include `version`, `author`, `license`, `metadata.hermes` block to match peer skills.
- Tag with 2–6 short, descriptive words. Tags are for discoverability in `ls skills/`.
- List `related_skills` when another skill in this repo covers overlapping ground.

## Structure

Peer skills follow this shape:

```
# <Title>

## Overview
One or two paragraphs: what and why.

## When to Use
- Bulleted triggers ("Use when ...")
- "Don't use for:" counter-triggers (negative examples)

## Procedure
The actual steps. Numbered. Concrete commands where possible.
"Read file X", "Run command Y", "If Z, do A else B".

## Verification
How to know the skill worked. What to check.

## Size and placement

- SKILL.md should sit in **8–14k chars** (peer range). If pushing past 20k, split.
- For large supporting material, use a `references/` subdirectory and link from SKILL.md.
- A skill's directory is `skills/<name>/` (no category nesting for now — keep it flat).

## The "Is this a skill?" decision tree

```
Did I just do a multi-step procedure that I'd repeat?
├── No  → MEMORY.md or daily memory
└── Yes
    ├── Is it org-specific (not generic engineering)?
    │   ├── No  → don't write a skill; this is a generic procedure
    │   └── Yes
    │       ├── Will I do it more than twice?
    │       │   ├── No  → daily memory; promote if it becomes frequent
    │       │   └── Yes
    │       │       ├── Is the procedure >5 steps?
    │       │       │   ├── No  → daily memory with a checkable list
    │       │       │   └── Yes → WRITE A SKILL
    │       │       └──
    │       └──
    └──
```

**Concrete bar:** if you find yourself writing the same paragraph in two different daily memory files explaining "here's how I do X," promote it to a skill.

## Editing an existing skill

- **Small change** (typo, one step): use `edit` with a targeted `old_string` → `new_string` patch. Bump `version` patch (1.0.0 → 1.0.1).
- **Structural change** (new section, reordered steps): rewrite the file. Bump `version` minor (1.0.0 → 1.1.0).
- **Retire a skill** (no longer applicable): move the directory to `skills/.archive/<name>/` and add a one-line note in `MEMORY.md` ("retired skills: ..."). Don't delete outright — the operator may want to revive it.

## Verification

After writing or editing a skill:

1. Re-read the file in a fresh `read` call. Confirm frontmatter parses and body renders.
2. Check size: `wc -c skills/<name>/SKILL.md`. Should be 8–20k chars.
3. Update `MEMORY.md` only if the skill changes a load-bearing fact (it usually doesn't).
4. Tell the operator in chat: "Created skill `foo`: <one-line summary>." They can review or pin.

## Anti-patterns

- **Skill sprawl.** Three skills that each do one thing and overlap with `MEMORY.md`. Prefer memory until you have evidence a procedure is reusable.
- **Frontmatter without body.** A skill that is just metadata. The body is the value.
- **Hardcoded paths in skills.** Skills should reference repo-relative paths (`_context/<repo>/`, `MEMORY.md`), not absolute paths.
- **Skills that require operator input on every use.** If the procedure can't run autonomously, it's not a skill, it's a checklist.
