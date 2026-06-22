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

1. **Per-agent `.openclaw/agent-config.yaml`** in each agent repo (linux-desktop-seed, mcp-tooling, architect, ...). Declares: handle, allowed channels, capabilities, skill/role policies, inter-agent contract version. *Source of truth lives with the agent.*

2. **Deploy action extension.** The existing per-repo deploy GitHub Action (already automates agent registration) gets a new output: validate `agent-config.yaml`, generate `agents.lock.toml`, open a PR against `openclaw-gateway`. *The deploy action is the natural place to validate and version it.*

3. **`openclaw-gateway` registry loader.** Reads `agents.lock.toml` at startup. No webhook, no live-update, no auth surface. Adding an agent = PR lands. Removing = delete the file + PR. *Gateway stays read-only against the registry.*

**Tradeoff vs. Option A (static toml in gateway) and Option B (runtime POST registration):**
- A: simple but agent identity lives in someone else's repo.
- B: dynamic but adds auth/webhook/live-update complexity.
- C: identity lives with the agent; deploy action is the validator; gateway is the consumer. **Audit point is still a human-reviewed PR.**

## 3. The 9 features the registry unlocks

Once `agents.lock.toml` exists, each of these becomes a one-line addition to `agent-config.yaml` plus a corresponding feature in the gateway's router:

1. **Per-agent capability manifests.** Agents advertise what they're *for*: `capabilities: ["terraform-plan", "vm-provision", "secret-scan"]`. Enables capability-based dispatch: `@mcp-tooling do terraform-plan`.
2. **Channel-to-agent pinning.** `allowed_channels: ["#darojaai-architect", "#ops"]` enforced by the gateway. Security boundary the P0 contract implicitly assumes and probably doesn't have today.
3. **Skill/role policies per agent.** `skills: [...], role: "executor" vs "advisor"`. The deploy action provisions the runtime accordingly.
4. **Versioned inter-agent contracts.** `contract: "v1"` field. Bump it when bridge semantics change. Old agents keep working.
5. **Health/heartbeat routing.** Deploy action posts a registration heartbeat on successful deploy. Gateway tracks last-seen. Stale agents (no deploy in 30 days, or failed health check) get auto-quarantined — `@linux-desktop-seed` returns "agent offline" instead of routing into a dead runtime.
6. **Self-documentation.** The compiled `agents.lock.toml` *is* the org map for the AI layer. `audit-org-readmes` (existing skill) extends to flag drifted `agent-config.yaml` vs. reality.
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

**Phase 3 — `@handle` routing.** Gateway routes by `@handle` instead of hardcoded identities. Bot still single Discord surface. Existing agents get a migration path: their handle is set in their new `agent-config.yaml`, deploy produces a PR that adds them to the lockfile, merge, restart, done.

**Phase 4 — Bridge syntax (`@A ask @B`).** One-shot `sessions_send` between runtimes. Loop guard explicit in code: agent responses never trigger another agent. Operator-initiated only.

**Phase 5 — Capabilities + channel pinning (features 1 + 2).** Gateway dispatches by capability for unknown `@handle`. `allowed_channels` enforced. This is where the security boundary becomes real.

**Phase 6 — Health/quarantine (feature 5) + audit log (feature 8) + canary (feature 9).** The long-tail operational features. Probably 1-2 weeks after Phase 5 to make sure nothing's on fire.

Features 3 (skill/role policies), 4 (versioned contracts), 6 (self-doc), 7 (cross-agent `@oncall`) are **queue-able** post-v1. They each become trivial once the registry exists.

## 5. The 5 open questions

These are the ones I wanted operator input on before filing the RFC for `agent.schema.json`:

**Q1. Schema name + location — RESOLVED (operator 2026-06-22).**
- **File name:** `agent-config.yaml` (operator's suggestion; "specific"). Dropped `discord.yaml` — operator wants the file to describe what it *is* (this agent's config), not what *consumes* it.
- **Location:** `.openclaw/agent-config.yaml` (my proposal, mirrors `.github/` convention; OpenClaw is the consumer; keeps repo root clean).
- **Rationale for `.openclaw/`:** OpenClaw is the runtime that reads this file, so the folder names the consumer (consistent with `.github/` being GitHub's config folder). Hidden = no root pollution. Single file in a dedicated folder = trivial to find via `git ls-files .openclaw/`. The runtime's generated `.openclaw/` state (e.g., `workspace-state.json`) is separate concern; source-controlled config can coexist there.
- **Backup option if `.openclaw/` collides with runtime state:** `agent/agent-config.yaml` (visible folder, also clean). Pick during Phase 1 PR review.

**Q2. Lockfile format — RESOLVED (operator 2026-06-22).**
- **Format:** TOML. Operator confirmed. `agents.lock.toml`.
- Rationale (unchanged from my lean): easier to diff in PRs, comments are legal, matches `CODEOWNERS`-adjacent conventions.

**Q3. Schema authority — RESOLVED (operator 2026-06-22, picked (a)).**
- **Authority:** `openclaw-gateway`. Schema lives next to the validator.
- Operator overrode my lean for (b) `.github`. Their reasoning (implicit): the schema is *implementation-coupled* to the gateway's loader, so colocating it with the consumer makes the upgrade story tighter. RFC for the schema lives in `openclaw-gateway` (not `.github`).
- **Note:** This is a deviation from the typical "standards in `.github`" pattern. If we ever want to make the schema consumable by tools outside the gateway (e.g., a CLI that validates configs without running the gateway), we'd want a second copy in `.github`. Not blocking; flagged for Phase 5+.

**Q4. First consumer — RESOLVED (operator 2026-06-22, picked all three).**
- **All three agents ship `agent-config.yaml` in Phase 1.** `linux-desktop-seed`, `architect` (this repo), `mcp-tooling`.
- Operator overrode my lean (sequential). Their reasoning (implicit): rolling out three configs at once proves the deploy-action path handles *diversity* (different repo shapes, different deploy-action invocations), not just one shape repeated.
- **Phase 1 expands** to: add `.openclaw/agent-config.yaml` to all three repos, deploy action generates the lockfile in all three, one aggregated PR lands in `openclaw-gateway`. Phase 2-6 proceed as originally planned.

**Q5. Backwards compatibility — RESOLVED (operator 2026-06-22, picked (a)).**
- **Phase 1 lockfile is additive.** Lives at `agents.lock.next.toml`, gateway ignores it.
- Confirms my lean. Pure additive, zero risk, easy to verify in PR review.

---

## 6. Affected repos

- **`openclaw-gateway`** — schema authority (per Q3), registry loader (Phase 2), `@handle` routing (Phase 3), bridge (Phase 4), capabilities (Phase 5).
- **`linux-desktop-seed`** (or whatever the canonical deploy action lives in) — Phase 1 consumer, deploy action extension.
- **`darojaai_architect` (this repo)** — Phase 1 consumer, canary for Phase 5.
- **`mcp-tooling`** — Phase 1 consumer, capability-driven dispatch stress test for Phase 5+.

## 7. Migration cost + rollback

- **Cost:** ~1 PR per repo per phase. Phase 1 is ~50 lines (deploy action extension). Phase 2 is ~100 lines (gateway loader + boot log). Phase 3 is ~200 lines (handle parsing + routing table). Phase 4-5 each ~150-300 lines.
- **Rollback:** Each phase is additive and gated. Phase N rollback = revert the PR for Phase N. Earlier phases keep working (lockfile is generated; gateway ignores unused fields).
- **Risk per phase:** Phase 1 = none. Phase 2 = none (observability only). Phase 3 = medium (could mis-route `@handle`; mitigation: log every routing decision, alert on unknown handles). Phase 4 = medium-high (inter-agent loops possible; mitigation: explicit loop guard in code, not config). Phase 5 = medium (channel enforcement could lock out an agent by typo; mitigation: dry-run mode for one week).

## 8. RFC: `agent-config.schema.json`

To file in **`openclaw-gateway`** (per Q3):
- **Title:** `[RFC] agent-config.yaml schema for org agent identity`
- **Body:** Schema spec for `agent-config.yaml` fields, `agents.lock.toml` format, ownership (`openclaw-gateway`), validation rules.
- **Status:** READY to file. All 5 open questions resolved (2026-06-22).

---

## 9. Where this plan lives now

- This file: `docs/agent-registry-plan.md` (this repo, committed).
- Cross-references: `ARCHITECTURE.md` should link here once the registry ships.
- Daily log: extend `memory/2026-06-21.md` with the recovery pass and sign-off on Phase 1.

## 10. Reflection (the lesson)

When the operator says "find the plan," the answer is not "it doesn't exist." The answer is "the plan is in the channel history, I just didn't read it before answering." Plans need to land in a file *before* they're cited — and if I cite one that isn't on disk, I owe the operator an honest recovery pass, not a confident "not found."

This is the second time in two sessions I've had a "I'm sure it's not there" claim contradict reality. AGENTS.md house rule #2 (verify writes) covers the edit-revert case; this one is a *new* failure mode: **"confident absence without verification."** Adding to AGENTS.md.