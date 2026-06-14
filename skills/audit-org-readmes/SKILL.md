---
name: audit-org-readmes
description: Use when you want a snapshot of org-wide documentation health: empty GitHub descriptions, missing READMEs, README presence, and last-updated staleness. Produces a report and an updated REPOS.md.
version: 1.0.0
author: darojaai_architect
license: MIT
metadata:
  hermes:
    tags: [audit, documentation, github, org-health, readme]
    related_skills: [authoring-skill]
---

# Audit Org-Wide README and Description Health

## Overview

Sweep the `DarojaAI` org for documentation health signals. Produces a structured report that informs what to batch into a hygiene PR (P2 in `AGENTS.md` severity tiers) and what to escalate to the operator.

This is a procedure, not a one-off. The same audit can be re-run after PR batches to measure progress.

## When to Use

- Onboarding: you just took over the architect role and want a baseline.
- Quarterly: time to check whether description/README gaps have grown.
- Pre-RFC: about to propose a documentation standard; you need current data.
- After a batch PR: confirm what changed.

### Don't use for:

- Auditing a *single* repo in depth — just clone it and read.
- Code-level audits (coverage, lint, type errors) — that's `infra-actions` territory.

## Prerequisites

- `gh` CLI authenticated against `DarojaAI` (default in this environment).
- `_context/repos.txt` already exists (refreshed in step 1).
- Write access to `REPOS.md` in this repo (for the update step).

## Procedure

### Step 1. Refresh the repo list

```bash
cd /home/desktopuser/GithubProjects/darojaai_architect
gh repo list DarojaAI --limit 100 \
  --json name,description,isPrivate,updatedAt,primaryLanguage,visibility \
  > _context/repos.json
gh repo list DarojaAI --limit 100 --json name \
  | python3 -c "import json,sys; [print(r['name']) for r in json.load(sys.stdin)]" \
  > _context/repos.txt
```

If `_context/repos.json` exists from a prior run, save a dated copy first:
```bash
cp _context/repos.json "_context/repos.$(date -u +%Y%m%d).json"
```

### Step 2. Triage descriptions (no clone needed)

```bash
python3 <<'PY' > _context/audit-descriptions.txt
import json
data = json.load(open("_context/repos.json"))
empty, present, by_status = [], [], {}
for r in data:
    name = r["name"]
    desc = (r.get("description") or "").strip()
    status = "empty" if not desc else "present"
    by_status.setdefault(status, []).append(name)
    (empty if status == "empty" else present).append((name, desc))
print(f"# Description audit — {len(data)} repos")
print(f"# Empty: {len(empty)}  Present: {len(present)}  Empty%: {len(empty)*100//len(data)}%")
print()
print("## EMPTY (top candidates for batch PR)")
for n, _ in sorted(empty):
    print(f"- {n}")
print()
print("## PRESENT")
for n, d in sorted(present):
    print(f"- {n}: {d[:80]}")
PY
```

Read `_context/audit-descriptions.txt`. Count empties. This is the headline number.

### Step 3. README presence audit (per repo, requires API call)

```bash
python3 <<'PY' > _context/audit-readmes.txt
import json, subprocess, time
data = json.load(open("_context/repos.json"))
results = []
for r in data:
    name = r["name"]
    # gh api returns 200 if README exists, 404 if not.
    out = subprocess.run(
        ["gh", "api", f"repos/DarojaAI/{name}/readme", "--silent"],
        capture_output=True, text=True
    )
    has_readme = (out.returncode == 0)
    has_desc = bool((r.get("description") or "").strip())
    results.append((name, has_readme, has_desc, r.get("isPrivate")))
    time.sleep(0.05)  # respect rate limits; gh handles auth-bound throttling too

results.sort()
print("# README audit")
print(f"{'repo':<40} {'readme':<7} {'desc':<7} {'private':<8}")
for n, r, d, p in results:
    print(f"{n:<40} {'YES' if r else 'NO':<7} {'YES' if d else 'NO':<7} {'Y' if p else 'N':<8}")
PY
```

(Note: this issues N API calls. With 42 repos at ~50ms each it's ~2 seconds. If you scale org to 200+ repos, add a token-bucket or run via `gh api --paginate` with cached ETag headers.)

### Step 4. Classify and update REPOS.md

Use the audit results to:

- Add any new repos to `REPOS.md` that weren't there.
- Bump the "Summary statistics" section with new counts.
- For each new repo, set initial status to `unexplored` (no clone yet).
- For repos that gained a README or description, update their `Status` column.

### Step 5. Report to operator

Post a concise summary in chat (Discord format, one screen):

```
Org doc audit (YYYY-MM-DD):
- 42 repos total
- 22 (52%) have empty GitHub descriptions   ← P2 batch candidate
- 7 have no README                          ← P2 batch candidate
- 3 new repos since last audit: <names>
- 2 repos archived/deprecated: <names>
```

The 22-with-empty-descriptions and 7-no-readme numbers are the batch-candidate set. Ask the operator for approval before applying any `gh repo edit` calls.

### Step 6. (Optional) Apply a description batch

**Only with explicit operator approval.** Per `AGENTS.md` house rules, I don't push changes to other repos without confirmation.

```bash
# Draft descriptions first, in a CSV:
# name,description
# foo,Does X using Y for Z consumers.
# ...

while IFS=, read -r name desc; do
  [[ "$name" == "name" ]] && continue
  gh repo edit "DarojaAI/$name" --description "$desc"
done < descriptions-batch.csv
```

Always preview the CSV in chat first.

## Verification

After running:

- `_context/repos.json` is non-empty and parseable.
- `_context/audit-descriptions.txt` and `_context/audit-readmes.txt` both exist and have content.
- `REPOS.md` "Summary statistics" reflects the new numbers.
- Chat summary is posted.
- If a batch PR was applied, re-run this skill after merge to confirm the % dropped.

## Time cost

- Steps 1–3: ~30 seconds for 42 repos.
- Step 4: ~5 minutes to update `REPOS.md` by hand.
- Step 5: 1 message in chat.
- Step 6: variable, depends on batch size.

## Anti-patterns

- **Running the audit but not acting on it.** An audit without a follow-up plan is just noise.
- **Editing descriptions without operator sign-off.** House rule: never push to other repos.
- **Treating empty descriptions as "fine, they have a README."** They're different signals. README = developer-facing docs. Description = discoverability on the org page. Both matter.
- **Hardcoding "42" or the date.** Always read from `_context/repos.json`; numbers change.
- **Hand-edited CSV with embedded commas.** Always use a proper CSV writer (`csv.writer` with `quoting=csv.QUOTE_ALL`) or quote every field. Otherwise `csv.reader` will miscount fields and your batch will silently drop rows.
- **Applying to archived repos.** `gh repo edit` returns HTTP 403 for archived repos. Filter the batch: `skip = [n for n in batch if is_archived(n)]`. Save skipped entries to a "pending" file for re-application if the repo is unarchived later.
