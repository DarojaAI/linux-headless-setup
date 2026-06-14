# Architectural Take: `skill-bridge`

> **Date:** 2026-06-14, Session 7
> **Repo:** `DarojaAI/skill-bridge` — private, v0.3.0, TypeScript, ~840 LOC
> **Status:** DRAFT for operator review.
> **Read:** README, AGENTS.md, FEATURE.md, PLAN.md, src/*.ts, manifest, toolmap, release list. Not all of PLAN.md (~250 lines) — first 50 lines + section headers.

---

## What it is

A TypeScript CLI that translates skills between agent ecosystems. Sources: Claude Code (CC), dev-nexus. Target: OpenClaw. Architecture: plugin-based with an intermediate representation (IR); adding a new source or target = a new plugin, no core changes.

**Workflow** (per README):

```bash
skill-bridge init --target openclaw
skill-bridge add dev-nexus:data-contract-assessment \
  --source dev-nexus \
  --path /path/to/dev-nexus/skills/data-contract-assessment
skill-bridge build
# outputs OpenClaw-compatible SKILL.md to out/
```

**Key files:**

- `src/build.ts` — orchestrator (loads manifest, expands sources, writes bundles, lockfile, license summary)
- `src/manifest/schema.ts` (87 lines) — typed schema for the manifest
- `src/plugins/interfaces.ts` (77 lines) — `SkillIR`, `ParseContext`, `RenderContext`, plugin contracts
- `src/translate/frontmatter.ts` + `body.ts` — the actual translator
- `src/targets/openclaw.ts` (13 lines) — only one target today
- `src/output/lockfile.ts` — content-hash lockfile, compare-on-rebuild

**State:** v0.3.0, last release 2026-05-15. Three releases total in ~2 weeks. Manifest currently has 2 skills (`session-commands`, `maintenance`).

---

## The verdict in one paragraph

skill-bridge solves a real, strategically important problem for the org (skills are the new "shared library" layer in agent orgs, and the org has 3+ ecosystems to bridge), and the architectural choices — one-way directionality, plugin IR, lockfile, per-skill license tracking — are correct and disciplined. But the repo is **severely under-documented for adoption**: README has no "who is using this" section, no examples of pipelines in production, no link to a downstream repo that's actually consuming the output. The org's flagship skill producers (dev-nexus with 12 skills) and skill consumers (openclaw-gateway) don't mention skill-bridge in their READMEs. There's a real risk this becomes a CLI without proof of life.

---

## What it does well

### 1. Plugin IR is the right abstraction

The intermediate representation (`SkillIR` in `src/plugins/interfaces.ts:7-17`) is the linchpin. It captures the *minimum* a skill needs (name, description, instructions, optional arguments, allowed-tools, model hint) plus two extension buckets:

- `metadata`: target-specific rendering hints (output by source, consumed by target)
- `extensions`: source-specific data preserved during translation

Adding a new source = write a parser to `SkillIR`. Adding a new target = write a renderer from `SkillIR`. The core never changes. This is the right shape for an extensible skill ecosystem.

### 2. Directionality discipline

`PLAN.md:14-17` is explicit:

> **Directionality:** Priority is one-way (source → target), not bidirectional translation.
> - CC → OpenClaw (highest priority)
> - dev-nexus → OpenClaw (high priority)
> - OpenClaw → CC (don't need)
> - OpenClaw → dev-nexus (don't need)

This avoids the combinatorial mess of bidirectional translation. The skill ecosystem will be much more useful if every skill is "consumable by every agent" via a one-way pipeline than if every bridge has to maintain N² mappings. Good architectural call.

### 3. Per-skill license tracking

`manifest/schema.ts` + `output/licenses.ts` track each skill's license (`SPDX` + copyright holder). The manifest can mix MIT skills (e.g., from open source) with `PROPRIETARY` skills (e.g., operator-authored). Good — many "skill bridge" projects get this wrong (assume MIT, leak proprietary code into public outputs).

### 4. Lockfile for reproducibility

`src/output/lockfile.ts` (47 lines) computes content hashes and compares on rebuild. Means a manifest change doesn't silently re-render skills that haven't actually changed. This is a real production concern; it's good that it's there.

---

## What's wrong or missing

### Finding 1. No proof of adoption

**Evidence:**

- The org's other key repos don't mention skill-bridge:
  - `dev-nexus/README.md` (29.8k) — no mention
  - `dev-nexus/SKILLS_CATALOG.md` — no mention
  - `openclaw-gateway/README.md` — no mention
  - `mcp-tooling/README.md` — no mention
  - `daroja-frontend-starter/README.md` — no mention
  - `infra-actions/README.md` — no mention
  - `devnexus-common/README.md` — no mention
- Manifest has 2 skills, both operator-owned (`PROPRIETARY`).
- 3 releases in 2 weeks (v0.1.0, v0.2.0, v0.3.0) and then silence since 2026-05-15.

**Implication:** Either skill-bridge is in production but nobody links to it (organizational gap), or it's pre-production and aspirational (product gap). Both need attention — and a "Who is using this?" section in the README would clarify.

**Severity:** P1. A skill-bridge with no consumers is a beautiful abstraction with no value.

**Recommendation:** Add a "Who is using skill-bridge" section to `README.md` listing concrete downstream pipelines (e.g., "openclaw-gateway's `~/.openclaw/skills/refresh` runs `skill-bridge build` nightly, sourcing from dev-nexus' `skill_workshop/`"). If there are no such pipelines, say so — "this repo is pre-adoption, consumers TBD" — and surface it as an organizational gap to fill.

### Finding 2. Toolmap will go stale silently

**Evidence:** `src/targets/openclaw.ts` and the `skill-bridge.toolmap.json` are the source of truth for "this CC tool name maps to this OpenClaw tool name." Nothing in the repo validates that the target ecosystem still has those tool names. If OpenClaw renames `read` to `file_read` next month, the toolmap keeps the old name, and bridged skills silently call a non-existent tool at runtime.

**Severity:** P2. Latent failure mode; not visible until a skill breaks in production.

**Recommendation:** Add a CI check in `.github/workflows/` (and use `infra-actions` since it has the GCP/Hetzner patterns) that:
1. Loads the toolmap.
2. For each target tool name, verifies it exists in the target's tool registry (or at minimum, in a static allowed-list).
3. Fails the PR if a mapping points to a tool that's been removed.

This is a one-day task that prevents a category of silent breakage.

### Finding 3. Repo has a non-customized OpenClaw default `AGENTS.md`

**Evidence:** `skill-bridge/AGENTS.md` (first 50 lines) is the generic OpenClaw workspace template:

> # AGENTS.md - Your Workspace
> This folder is home. Treat it that way.
> ## First Run
> If `BOOTSTRAP.md` exists, that's your birth certificate...

There's no project-specific role, no quick context, no house rules. Per the RFC I just shipped (<https://github.com/DarojaAI/.github/issues/1>), this would fail the proposed minimum-sections check.

**Implication:** A repo whose entire purpose is "make skills work in our ecosystem" doesn't have a contract for agents working *in* it. The irony writes itself.

**Severity:** P2. Quality issue, not a blocker. Becomes a P1 if skill-bridge gets adopted widely and an agent that doesn't know the project opens it for the first time.

**Recommendation:** Adopt the AGENTS.md template from the RFC. Specifically:
- **Role:** "skill-bridge is a TypeScript CLI that translates skills between agent ecosystems..."
- **Project Quick Context:** link to README, PLAN.md, src/plugins/interfaces.ts (the IR), src/manifest/schema.ts (the schema)
- **House Rules:** "Don't add a target without a manifest entry first"; "All source/target plugins implement the IR interface"; "Lockfile must be updated on every build"

### Finding 4. PLAN.md is large and not a plan

**Evidence:** `PLAN.md` is 254 lines and reads more like a design document / RFC than an actionable plan. It describes the architecture in detail, but there are no task lists, no "done" markers, no phase deliverables. The repo is at v0.3.0 with the plugin IR shipped, so the plan is *partially* executed — but PLAN.md doesn't reflect that.

**Severity:** P2. Documentation rot.

**Recommendation:** Either (a) trim PLAN.md to "this is what we built; the IR spec is in `src/plugins/interfaces.ts`"; or (b) keep PLAN.md as the design rationale and add a `STATUS.md` or section that says "shipped: plugin IR, manifest schema, OpenClaw target, license tracking, lockfile. In progress: dev-nexus source plugin. Future: cursor / codex targets." Right now a new contributor has to compare PLAN.md to src/ to know what's done.

### Finding 5. Naming is bland (low priority)

**Evidence:** "skill-bridge" is descriptive but generic. Compare to:
- `agentskills.io` (the open standard referenced in Hermes' README)
- `skillx`, `skillflow`, `skillport`
- Names that signal "we're the standard" (e.g., `skill_standard`, `openskills`)

**Severity:** P3 (cosmetic). The name is fine; it's just not memorable.

**Recommendation:** Don't rename unless a rename comes with a rebrand push. If the operator wants to invest in skill-bridge as an *external* project (not just internal tooling), then renaming makes sense. If it stays internal, the current name is fine.

### Finding 6. FEATURE.md is 1 line

**Evidence:** `cat _context/skill-bridge/FEATURE.md` returned literally `feat: trigger new release`. The whole file is a release-please commit message.

**Severity:** P2 (or just delete it).

**Recommendation:** Delete `FEATURE.md` — it has no content. Or replace it with a `CHANGELOG.md` that links to GitHub releases. The repo's release notes live on the GitHub release page; FEATURE.md adds no value.

---

## Architectural questions for the operator

### Q1. Should this be a separate repo?

**My answer: yes, keep separate.**

Reasons:
- It's TypeScript, while the org's Python ecosystem is large (dev-nexus, devnexus-common, rag_research_tool, mcp-tooling).
- It has a versioned CLI surface (`skill-bridge init`, `add`, `build`).
- It's not infra-actions-shaped (composite GitHub Actions, not a CLI).
- It's not devnexus-common-shaped (Python lib, not a CLI tool).

Counter-argument: putting it in `devnexus-common` would be discoverable to Python devs. But: (a) it's the wrong language; (b) consumers are TS-based OpenClaw projects, not Python ones. The right consumers are openclaw-gateway and any new TS-based agent. **Separate repo is right.**

### Q2. Should it be a public open-source project?

**My answer: depends on operator intent.**

- If it's just an internal tool: keep it private. Maintain it. Document it. Adopt it org-wide.
- If it's intended to be the **standard** skill-translation layer across the agent ecosystem: open-source it. Standardize on the IR format. Publish to npm. The "agentskills.io" hint in Hermes' README suggests this is where the industry is going.

I don't have a strong recommendation without operator input. But: if it's private and aspirational, that's a smell. Pick one.

### Q3. Does the operator actually use it?

I asked this in Finding 1. The answer determines everything else. If the answer is "I built it, I haven't used it in production" — that's fine, but the README should say so. If the answer is "I use it daily" — the README should say *that* and link to the consumers.

---

## Summary recommendations (ordered by value × cost)

1. **Adopt the AGENTS.md template from the RFC** in this repo. P2 hygiene, ~30 minutes of work. Set the example for the org.
2. **Add a "Who is using skill-bridge" section to README.md.** P1, low-cost. Either links to real consumers or admits "pre-adoption, consumers TBD."
3. **Add a CI check that validates the toolmap.** P2, ~1 day. Prevents silent breakage.
4. **Trim or status-mark PLAN.md.** P2, low-cost. Update it to reflect what's shipped.
5. **Delete `FEATURE.md`** (1-line file) or replace with a `CHANGELOG.md`. P2, 5 minutes.
6. **Decide on adoption vs. aspirational.** P0 question for the operator. Drives the next 6 months of work.

---

## What I would NOT change

- The plugin IR design. It's right.
- The one-way directionality. It's right.
- The license tracking. It's right.
- The lockfile. It's right.

The architectural core is sound. The issues are documentation, adoption, and operational hygiene — not design.
