# Operations

This repo (`linux-desktop-seed` depends on this one as L2 — the install orchestrator)
ships a brief operations runbook for security-sensitive admin / governance
operations that are not code-PR-mergeable. Hand-listed here because they
require `repo:admin` scope plus a privileged remote client.

## `HEAD` symref re-attach (deploy-cascade `#34981557152`)

Last seen in the deploy chain: 2026-09-15.

**Symptom**

`git ls-remote https://github.com/DarojaAI/linux-headless-setup.git HEAD`
returns a commit older than `git ls-remote … refs/heads/main` by a wide
margin. Demonstrate:

```
$ git ls-remote https://github.com/DarojaAI/linux-headless-setup.git HEAD
0b78df920d83fd8dd8c8676428dfb8e9dae23a15	HEAD

$ git ls-remote https://github.com/DarojaAI/linux-headless-setup.git refs/heads/main
5cacad77671edbb5968aad3bab453d127eebdd4f	refs/heads/main
```

`HEAD` resolves to commit `0b78df9` dated 2026-07-15; `main` resolves to
`5cacad7` (merge of PR #66, 2026-09-15). Detached by ≈ 2 months.

**Why this matters**

`git clone <url>` (without `--branch`) follows the upstream `HEAD` symref.
`DarojaAI/linux-desktop-seed`'s `scripts/ci/clone-l2-step.sh` ran that
flavour of `git clone` until Sept 2026 — and consumed a 2-months-old clone
into its in-band tarball stream, defeating every downstream gate that
assumed "the runner's clone is current main". Mitigation was shipped
upstream — `linux-desktop-seed` PR #1688 now passes `--branch main` and
echoes `L2_HEAD_REMOTE_MAIN` so any future divergence is observable in
the deploy log.

**One-liner refresh (admin op)**

Re-attach `HEAD` to `refs/heads/main` via any of:

- GitHub web UI: Settings → Default branch → choose `main`. (Implicitly
  re-publishes the HEAD symref.)
- GitHub CLI: `gh repo edit DarojaAI/linux-headless-setup --default-branch main`
- Push-based: `git push origin HEAD:main` from a clone owned by someone
  with the `repo` admin scope on this repo. Requires force-push-style
  semantics — GitHub rejects unless the local HEAD is `main` and the
  default branch is not protected.

The first option is the cleanest.

**When to run**

Re-run this op whenever the deploy log emits any of:

```
WARN: L2 HEAD symref is detached from refs/heads/main
      clone HEAD: <abbrev_sha>
      main HEAD:  <abbrev_sha>
```

That message is emitted by `linux-desktop-seed`'s `clone-l2-step.sh` after
PR #1688 lands. Today, before #1688 lands, the divergence is silent, so
a manual `git ls-remote` check is part of the deploy-cascade close-out.

**Re-attach verification**

```bash
# Both lines should show the same short SHA.
git ls-remote https://github.com/DarojaAI/linux-headless-setup.git HEAD | awk '{print substr($1,1,7)}'
git ls-remote https://github.com/DarojaAI/linux-headless-setup.git refs/heads/main | awk '{print substr($1,1,7)}'
```

If they agree, `HEAD` is re-attached. If not, repeat or escalate.

---

## L2 hardening baseline — closure index (2026-10-02)

Epic [#48](https://github.com/DarojaAI/linux-headless-setup/issues/48)
shipped across PRs #55–#60 on 2026-09-01, plus the SSH follow-on (PR #72,
2026-10-02). All open children are closed in
[#1848](https://github.com/DarojaAI/linux-headless-setup/pull/1848) — this
section exists so future readers can trace each hardening change back to
its shipping PR without grepping git log.

| Issue | Title | Shipped in | Notes |
| --- | --- | --- | --- |
| #49 | chrony + NTPSynchronized gate | [PR #55](https://github.com/DarojaAI/linux-headless-setup/pull/55) | `scripts/system.sh` |
| #50 | journald size/rate caps | [PR #56](https://github.com/DarojaAI/linux-headless-setup/pull/56) | `/etc/systemd/journald.conf.d/99-l2-caps.conf` |
| #51 | net.ipv4 sysctl drop-in | [PR #57](https://github.com/DarojaAI/linux-headless-setup/pull/57) | `/etc/sysctl.d/99-l2-hardening.conf` |
| #52 | SSH MaxAuthTries / MaxStartups / ClientAlive drop-in | [PR #58](https://github.com/DarojaAI/linux-headless-setup/pull/58) + [PR #72](https://github.com/DarojaAI/linux-headless-setup/pull/72) | PR #72 reversed MaxAuthTries=3 so CI runners with multiple keys reach the right key |
| #53 | openclaw-healthwatch.{service,timer} | [PR #59](https://github.com/DarojaAI/linux-headless-setup/pull/59) | Auto-restart gateway on `/healthz` failure |
| #54 | vim-tiny + bash-completion + man-db + less | [PR #60](https://github.com/DarojaAI/linux-headless-setup/pull/60) | `scripts/system.sh` |

If you need to audit any of these, the L2 epic and its children are
still searchable in the issue tracker; the working tree has not changed
between this index and the shipping PRs.

End runbook. Operate sparingly — every repo-admin op should land in a
ticket or issue before being performed.
