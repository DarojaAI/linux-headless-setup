# Agent Registry & Inter-Agent Coordination Plan

> **Status:** Reconstructed from 2026-06-19 channel history (chat was the source; this doc is the persisted form).
> **Author:** darojaai_architect (2026-06-21 recovery pass)
> **Goal:** Empower org agents (linux-desktop-seed, mcp-tooling, architect, ...) to coordinate with each other while keeping a single Discord bot surface ("coder").

---

## 1. Why this exists

Today, multiple agents run on the same Discord surface under the name "coder." A user can't tell whether they're talking to `linux-desktop-seed`, `mcp-tooling`, or `architect`. The agents themselves can't route to each other without knowing who the other is. The runtime has the identity; the chat surface doesn't expose it.

This plan fixes that without creating new Discord bots per channel. Routing identity moves *inside* the gateway.

## 2. The architecture (Option C, picked 2026-06-19)

**One Discord bot. Multiple agent identities. Routing by mention.**

- A user writes `@linux-desktop-seed do X` or `@mcp-tooling do Y` in chat.
- The "coder" bot parses the `@handle`, routes to the right agent runtime, replies as that agent.
- Inter-agent: `@linux-desktop-seed ask @mcp-tooling about foo` — the bot parses the double-mention, bridges as a one-shot `sessions_send` between runtimes. **One-shot, scoped, no chat loop.** No agent may re-trigger another agent on its own — that would re-introduce the loop problem the P0 contract was written to prevent.

**Three concrete components:**

1. **Per-agent `discord.yaml`** in each agent repo (linux-desktop-seed, mcp-tooling, architect, ...). Declares: handle, allowed channels, capabilities, skill/role policies, inter-agent contract version. *Source of truth lives with the agent.*

2. **Deploy action extension.** The existing per-repo deploy GitHub Action (already automates agent registration) gets a new output: validate `discord.yaml`, generate `agents.lock.toml`, open a PR against `openclaw-gateway`. *The deploy action is the natural place to validate and version it.*

3. **`openclaw-gateway` registry loader.** Reads `agents.lock.toml` at startup. No webhook, no live-update, no auth surface. Adding an agent = PR lands. Removing = delete the file + PR. *Gateway stays read-only against the registry.*

**Tradeoff vs. Option A (static toml in gateway) and Option B (runtime POST registration):**
- A: simple but agent identity lives in someone else's repo.
- B: dynamic but adds auth/webhook/live-update complexity.
- C: identity lives with the agent; deploy action is the validator; gateway is the consumer. **Audit point is still a human-reviewed PR.**

## 3. The 9 features the registry unlocks

Once `agents.lock.toml` exists, each of these becomes a one-line addition to `discord.yaml` plus a corresponding feature in the gateway's router:

1. **Per-agent capability manifests.** Agents advertise what they're *for*: `capabilities: ["terraform-plan", "vm-provision", "secret-scan"]`. Enables capability-based dispatch: `@mcp-tooling do terraform-plan`.
2. **Channel-to-agent pinning.** `allowed_channels: ["#darojaai-architect", "#ops"]` enforced by the gateway. Security boundary the P0 contract implicitly assumes and probably doesn't have today.
3. **Skill/role policies per agent.** `skills: [...], role: "executor" vs "advisor"`. The deploy action provisions the runtime accordingly.
4. **Versioned inter-agent contracts.** `contract: "v1"` field. Bump it when bridge semantics change. Old agents keep working.
5. **Health/heartbeat routing.** Deploy action posts a registration heartbeat on successful deploy. Gateway tracks last-seen. Stale agents (no deploy in 30 days, or failed health check) get auto-quarantined — `@linux-desktop-seed` returns "agent offline" instead of routing into a dead runtime.
6. **Self-documentation.** The compiled `agents.lock.toml` *is* the org map for the AI layer. `audit-org-readmes` (existing skill) extends to flag drifted `discord.yaml` vs. reality.
7. **Cross-agent `@oncall` addressing.** Combine capability + presence: `@oncall terraform question` → online agent with that capability. Replaces tribal knowledge.
8. **Audit log keyed to org structure.** Every inter-agent bridge call lands in the gateway log with `{from_agent, to_agent, contract_version, capability}`. Queryable, not greppable.
9. **Soft launch / canary routing.** `canary: true` in the manifest. Gateway routes 10% → new, 90% → previous. Observes, flips. Boring deploys instead of scary ones.

**Of these, the load-bearing ones for v1:**
- **(2) channel bindings** — security boundary, probably overdue.
- **(1) capabilities** — makes the bridge useful instead of just cute.
- **(5) health/quarantine** — prevents the "agent is 3 versions stale and no one noticed" failure mode.

## 4. The 6 rollout phases

**Phase 1 — Dark launch (zero risk, additive).** Deploy action runs the new validator and generates the lockfile *into a separate file*, not `agents.lock.toml` yet. The gateway ignores the new file. We can verify the pipeline produces correct output end-to-end without changing runtime behavior. **Start here.**

**Phase 2 — Lockfile consumption.** Gateway starts reading `agents.lock.toml` at startup. Still no behavior change — routing is hardcoded as before. The lockfile is consumed only as observability (logged at boot, exposed via a debug command). If something is wrong with the lockfile, behavior is unchanged.

**Phase 3 — `@handle` routing.** Gateway routes by `@handle` instead of hardcoded identities. Bot still single Discord surface. Existing agents get a migration path: their handle is set in their new `discord.yaml`, deploy produces a PR that adds them to the lockfile, merge, restart, done.

**Phase 4 — Bridge syntax (`@A ask @B`).** One-shot `sessions_send` between runtimes. Loop guard explicit in code: agent responses never trigger another agent. Operator-initiated only.

**Phase 5 — Capabilities + channel pinning (features 1 + 2).** Gateway dispatches by capability for unknown `@handle`. `allowed_channels` enforced. This is where the security boundary becomes real.

**Phase 6 — Health/quarantine (feature 5) + audit log (feature 8) + canary (feature 9).** The long-tail operational features. Probably 1-2 weeks after Phase 5 to make sure nothing's on fire.

Features 3 (skill/role policies), 4 (versioned contracts), 6 (self-doc), 7 (cross-agent `@oncall`) are **queue-able** post-v1. They each become trivial once the registry exists.

## 5. The 5 open questions

These are the ones I wanted operator input on before filing the RFC for `agent.schema.json`:

**Q1. Schema name + location.** Is the per-agent file `discord.yaml`, `agent.toml`, or something else? And does it live at the repo root, in `.openclaw/`, or in `infra/`? My lean: `discord.yaml` at the repo root, mirrors `CODEOWNERS` location, makes it findable. (Naming is hard; `discord.yaml` is honest about the *consumer* — the bot — rather than overpromising about the *purpose*.)

**Q2. Lockfile format.** `agents.lock.toml` (TOML, matches `CODEOWNERS`-adjacent conventions) vs. `agents.lock.json` (JSON, matches GitHub's lockfile-style patterns). My lean: TOML, easier to diff in PRs, comments are legal.

**Q3. Schema authority.** Where does the JSON Schema (or equivalent) for `discord.yaml` live? Options:
- (a) in `openclaw-gateway` (gateway is the validator).
- (b) in `DarojaAI/.github` (org-wide standards go there per GOVERNANCE.md).
- (c) in a new shared repo like `daroja-agent-schema`.

My lean: (b). Schema is a *standard*, not a runtime dependency. RFC in `.github`, schema checked in alongside `CONTRIBUTING.md`.

**Q4. First consumer.** Which agent repo gets `discord.yaml` first? Three candidates:
- `linux-desktop-seed` — most active, already has CI/deploy, exercises the deploy-action path end-to-end.
- `architect` (this repo) — meta, but a useful canary because the user reads my output here daily and notices regressions immediately.
- `mcp-tooling` — different surface (capability-based), useful for stress-testing Phase 5.

My lean: `linux-desktop-seed` for Phase 1-4 (proves the pipeline), then `architect` for Phase 5 (capabilities are mostly N/A for me but the canary is informative), then `mcp-tooling` for Phase 6+ (real capability routing).

**Q5. Backwards compatibility during Phase 1-2.** Existing deployments already have agents running. How do we roll out without forcing a re-deploy of every agent on day 1? Options:
- (a) Phase 1 lockfile is *additional* (lives at `agents.lock.next.toml`, ignored by gateway).
- (b) Phase 1 lockfile is *advisory* (gateway logs warnings if it differs from hardcoded identities, but doesn't act).
- (c) Phase 1 has no lockfile at all; just the deploy action output.

My lean: (a). Pure additive, zero risk, easy to verify in PR review.

---

## 6. Affected repos

- **`openclaw-gateway`** — registry loader (Phase 2), `@handle` routing (Phase 3), bridge (Phase 4), capabilities (Phase 5).
- **`linux-desktop-seed`** (or whatever the canonical deploy action lives in) — first consumer, deploy action extension.
- **`DarojaAI/.github`** — RFC for `discord.yaml` schema, `agents.lock.toml` format spec.
- **`mcp-tooling`** — second consumer, capability-driven dispatch stress test.
- **`darojaai_architect` (this repo)** — third consumer, canary for Phase 5.

## 7. Migration cost + rollback

- **Cost:** ~1 PR per repo per phase. Phase 1 is ~50 lines (deploy action extension). Phase 2 is ~100 lines (gateway loader + boot log). Phase 3 is ~200 lines (handle parsing + routing table). Phase 4-5 each ~150-300 lines.
- **Rollback:** Each phase is additive and gated. Phase N rollback = revert the PR for Phase N. Earlier phases keep working (lockfile is generated; gateway ignores unused fields).
- **Risk per phase:** Phase 1 = none. Phase 2 = none (observability only). Phase 3 = medium (could mis-route `@handle`; mitigation: log every routing decision, alert on unknown handles). Phase 4 = medium-high (inter-agent loops possible; mitigation: explicit loop guard in code, not config). Phase 5 = medium (channel enforcement could lock out an agent by typo; mitigation: dry-run mode for one week).

## 8. RFC: `agent.schema.json`

To file in `DarojaAI/.github`:
- **Title:** `[RFC] discord.yaml schema for org agent identity`
- **Body:** Schema spec for `discord.yaml` fields, `agents.lock.toml` format, ownership (`.github` per Q3), validation rules.
- **Status:** DRAFT, gated on Q1-Q5 above being resolved.

---

## 9. Where this plan lives now

- This file: `docs/agent-registry-plan.md` (this repo, committed).
- Cross-references: `ARCHITECTURE.md` should link here once the registry ships.
- Daily log: extend `memory/2026-06-21.md` with the recovery pass and sign-off on Phase 1.

## 10. Reflection (the lesson)

When the operator says "find the plan," the answer is not "it doesn't exist." The answer is "the plan is in the channel history, I just didn't read it before answering." Plans need to land in a file *before* they're cited — and if I cite one that isn't on disk, I owe the operator an honest recovery pass, not a confident "not found."

This is the second time in two sessions I've had a "I'm sure it's not there" claim contradict reality. AGENTS.md house rule #2 (verify writes) covers the edit-revert case; this one is a *new* failure mode: **"confident absence without verification."** Adding to AGENTS.md.