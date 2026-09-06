# Harness Verification Guide

Supplementary reference for `SKILL.md` Phase 6. It confirms that **what was built actually loads and is
actually invocable**.

Most harness defects in this repository **raise no error** — a skill drops out of the listing, a memory
never loads, a gate is skipped, a reviewer PASSes an empty diff. All of it is silent. So verification
has to be a matter of counting **"is what I expected actually there"**, not of asking "did it error".

**This document does not issue spec verdicts** — delegate those to `/utility-claude-code-review <path>`.

## Contents

1. [Preflight — checking that it loads](#1-preflight--checking-that-it-loads)
2. [Reference factuality — finding broken links](#2-reference-factuality--finding-broken-links)
3. [Trigger verification](#3-trigger-verification)
4. [Full-sweep scripts](#4-full-sweep-scripts)
5. [Dry-run checklist](#5-dry-run-checklist)

---

## 1. Preflight — checking that it loads

**A file existing and the harness finding it are different things.** Skip this comparison and you
accumulate artifacts that exist but cannot be invoked.

```bash
# Skills — the two values must match for everything to load
find .claude/skills -name SKILL.md | wc -l   # skills in the repository
ls -d .claude/skills/*/ | wc -l              # flat first-tier entries the harness scans
```

A difference means that many are **absent from autocomplete and uncallable by name.** Ten provider
skills were once in exactly this state (19 of 29) — every file existed; they were merely nested.
Commands of the same names registered correctly under a `:` namespace, so the listing mixed the two and
**the skills read as present**.

`[Measured]` 2026-09-06 — both values are **22**, so the tree is currently clean.

```bash
# Suffix convention — empty output is correct
ls -d .claude/skills/*/ | grep -v -- '-skill/$'

# Agent memory — find agents declaring memory: project with no flat-path memory
grep -l '^memory:' .claude/agents/*.md | while read -r f; do
  n=$(grep -m1 '^name:' "$f" | sed 's/^name: *//')
  [ -f ".claude/agent-memory/$n/MEMORY.md" ] || echo "MISSING MEMORY: $n"
done
```

The harness **computes** the memory path as `<sanitize(name)>`, where `sanitize` replaces `/` with `-`.
Nest it or let the name diverge and **the memory is simply absent, with no error.** The directory name
keys off the **frontmatter `name`**, not the filename.

---

## 2. Reference factuality — finding broken links

`@see` is a notation rather than an import, so **a wrong path raises no error.** The reference just goes
quietly dead.

```bash
# Confirm the internal SoT paths exist
grep -rhoE '\.claude/[A-Za-z0-9/._-]+\.(md|sh|json)' <target-path> | sort -u | \
  while read -r p; do [ -f "$p" ] || echo "MISSING: $p"; done

# References inside a skill bundle (references/ · examples/ · scripts/)
cd <skill-directory> && grep -rhoE '(references|examples|scripts|assets)/[A-Za-z0-9._-]+\.[a-z]+' . | \
  sort -u | while read -r p; do [ -f "$p" ] || echo "MISSING: $p"; done
```

**Check section-number citations separately** — a reference like `docs/… § 3.5` needs the section
verified to actually hold that content even when the file exists. Number drift is common, and the live
example is the `docs/app-agent-team-docs.md` "§ 2.4" that several documents cited as the routing SoT
until 2026-09-06 despite no such section existing (the real owner is
`rules/app-agent-team-rule.md`, `## Invariant — scope boundary and handoffs`).

**Verifying external URLs is not this document's job** — the full `.claude/**` sweep is owned by
`/utility-claude-code-review` (which runs in official-doc synchronization mode when invoked with no
argument). When writing a single new artifact, check **only the URLs that draft cites**.

---

## 3. Trigger verification

**Valid only after a session restart** — the skill listing is assembled at session start.

### 3-1. Confirming it appears in the listing

| Listing state | Diagnosis |
| --- | --- |
| both name and description visible | normal |
| **name only, no description** | listing budget exceeded — descriptions are dropped starting from the least-used skills |
| **absent entirely** | discovery failure (a placement problem). Raising the budget will not fix it → see §1 preflight |

### 3-2. should-trigger / near-miss

**Near-miss is the point.** An obviously unrelated query like "write a Fibonacci function" has no
verification value. **A query on an ambiguous boundary** is the good test.

This repository's actual near-miss pairs:

| Query | Should go to | Easily confused with |
| --- | --- | --- |
| "create an agent for me" | `utility-claude-code-skill` | `abstract-harness-engineering-skill` |
| "audit the harness" | `abstract-harness-engineering-skill` | `utility-claude-code-skill` |
| "check the retry budget" | `abstract-loop-engineering-skill` | `abstract-harness-engineering-skill` |
| "the routing keeps going round" | `abstract-graph-engineering-skill` | `abstract-loop-engineering-skill` ("going round" reads like a loop) |
| "is a role axis empty" | `abstract-harness-engineering-skill` | `abstract-graph-engineering-skill` |
| "review the UPbit integration" | `app-agent-team` | `api-agent-team` (the name looks like API) |
| "add an ApiResource" | `api-agent-team` | `app-agent-team` |
| "check the Messenger routing" | `app-agent-team` | `tools-agent-team` (looks like infrastructure) |
| "run gcloud run deploy ... for me" | execute directly | `tools-gcp-cloudrun-skill` |
| "do a git commit -m 'fix'" | execute directly | `utility-git-commit-skill` |

**Checking for collisions with the existing 22 skills:** confirm that the new skill's should-trigger
queries do not wrongly trigger an existing one. On a collision, state the **boundary condition** in the
description more clearly (and pull it forward).

---

## 4. Full-sweep scripts

### 4-1. Detecting truncated YAML values

Find values truncated at a `#` or `: ` in an unquoted scalar. The parser raises no error, so
**comparing the length against the raw line** is the only means of detection.

```bash
python3 - <<'EOF'
import re, glob, yaml
for f in sorted(glob.glob('.claude/**/*.md', recursive=True)):
    m = re.match(r'---\n(.*?)\n---', open(f, encoding='utf-8').read(), re.S)
    if not m: continue
    raw = m.group(1)
    for k, v in (yaml.safe_load(raw) or {}).items():
        if not isinstance(v, str): continue
        lm = re.search(rf'^{re.escape(k)}:\s*(.*)$', raw, re.M)
        if lm and lm.group(1)[:1] not in ('"', "'") and len(v) < len(lm.group(1)) - 2:
            print(f'TRUNCATED {f} :: {k} :: {len(v)} < {len(lm.group(1))}')
EOF
```

### 4-2. description length

```bash
python3 - <<'EOF'
import re, glob, yaml
for f in sorted(glob.glob('.claude/skills/*/SKILL.md')):
    m = re.match(r'---\n(.*?)\n---', open(f, encoding='utf-8').read(), re.S)
    d = (yaml.safe_load(m.group(1)) or {}).get('description', '')
    if len(d) > 1024: print(f'OVER 1024 :: {f} :: {len(d)}')
EOF
```

### 4-3. Skill `name` constraints

```bash
for f in .claude/skills/*/SKILL.md; do
  d=$(basename "$(dirname "$f")")
  n=$(grep -m1 '^name:' "$f" | sed 's/^name: *//')
  [ "$d" = "$n" ] || echo "NAME MISMATCH: dir=$d name=$n"
  [ ${#n} -le 64 ] || echo "OVER 64: $n (${#n})"
  case "$n" in *--*) echo "DOUBLE HYPHEN: $n";; esac
done
```

### 4-4. Missing rule `paths`

```bash
for f in $(find .claude/rules -name '*-rule.md'); do
  grep -q '^paths:' "$f" || echo "NO paths: $f"
done
```

Exactly two files are exempt: `rules/abstract-structure-rule.md` (an index) and
`rules/utility-git-commit-rule.md` (it applies to a commit message, which is not a file). Any third
result is a `[MUST]`.

---

## 5. Dry-run checklist

Review the design without executing it.

- [ ] **Routing dead links** — do all the rules, agents, skills and commands the orchestrator cites exist?
- [ ] **Three-way roster sync** — do the orchestrator's routing table, the team rule and
      `agent-roster-guard.sh`'s `case` table agree? Fix one alone and the new agent is blocked with
      `exit 2` the instant it is spawned.
- [ ] **Tool minimality in the opposite direction** — are the tools the body's instructions require
      actually present? Delegating to a skill or command → `Skill`; spawning a sub-agent → `Agent`.
      **An omission shows up as a silent workaround, not an error.**
- [ ] **`isolation` matches the domain-scope convention** — does an agent scoped to `app/**` sources
      carry `isolation: worktree` like its 19 peers, and do the orchestrators, `api-platform-reviewer`,
      the infrastructure reviewers and the `utility-*` agents correctly lack it? Adding it to the
      `utility-git-commit-*` pair is a `[MUST]`, since they must see the real working tree.
- [ ] **The isolated handoff channel** — where the author is isolated, does the loop pass the **full
      unified diff inline** rather than routing the reviewer to a path? Reverting to "the reviewer reads
      the same diff" is a `[MUST]`.
- [ ] **tmp path collisions** — are the new loop's draft and review different files, and separated per axis?
- [ ] **Role boundaries** — are upstream/downstream, the orchestrator and the output paths stated, and
      do they match the actual caller?
- [ ] **Severity protocol** — does the reviewer use `[MUST]`/`[SHOULD]`/`[CONSIDER]`, with only
      `[MUST]` blocking?
- [ ] **Retry limit** — does the skill state a limit, and does it withhold the final action past it?
- [ ] **No duplicated criteria** — does the new artifact point at the SoT with `@see` rather than
      restating it?

**Finally, run `/utility-claude-code-review <path>` and confirm 0 `[MUST]`.** That command also performs
the official-documentation synchronization step, so where its items overlap this document's, take its
result.
