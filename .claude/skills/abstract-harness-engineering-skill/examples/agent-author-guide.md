# The author axis — generation agent definition guide

> This document is **a template, not judgment criteria.** Frontmatter, naming and tool-minimality
> verdicts are SoT in `commands/utility-claude-code-review.md`; structure and placement in
> `rules/utility-claude-code-rule.md`. The values below are **measured 2026-09-06**, and when writing a
> new agent you should **read one or two existing files of the same kind first** — those files, not this
> one, are the authority on convention.

Supplementary reference for `SKILL.md` Phase 3. The author axis is **the generation half of the
generate-verify loop**: it clears its own output through the gates, then receives a PASS/REDO verdict
from the reviewer.

**Existing instances:** `app-php-symfony-author` · `app-twig-symfony-author` ·
`app-javascript-stimulus-author` · `api-platform-author` · `utility-git-commit-author` ·
`utility-drawio-diagram-author`.

---

## 1. Frontmatter

```yaml
---
name: {domain}-author
description: '{what it generates}. Writes code that conforms to the rules (SoT), clears its own gates ({gate names}), and then submits to {domain}-reviewer for a PASS/REDO verdict — the generation half of the generate-verify loop. Activate on requests like ''{trigger1}'', ''{trigger2}''. On a REDO instruction it applies that instruction and nothing else.'
model: opus
memory: project
isolation: worktree
permissionMode: acceptEdits
maxTurns: 30
tools: Read, Grep, Glob, Bash, Write, Edit
---
```

| Key | Value | Rationale |
| --- | --- | --- |
| `maxTurns` | **30** | identical across all 6 authors. Do not raise it on the theory that generation is heavy — the testers' 45 is the only elevated value on any axis |
| `model` | `opus` (`utility-git-commit-author` is `sonnet`) | generation and reasoning warrant opus; drafting a commit message is a bounded comparison against explicit criteria |
| `tools` | `Read, Grep, Glob, Bash, Write, Edit` | it edits target files directly, so it needs write access |
| `permissionMode` | `acceptEdits` | **load-bearing.** A sub-agent inherits the session's mode and `permissions.defaultMode` is `plan`, which is read-only — without this line an author's edits are refused and the role is unexecutable |
| `isolation` | `worktree` for the 4 code-domain authors; **omitted** for the 2 utility authors | the convention follows domain scope. `utility-git-commit-author` **must** see the real working tree (`git diff --cached`), so adding it there is a `[MUST]` finding; `utility-drawio-diagram-author` reads real `diagram/**` files to learn existing conventions |
| `color` | **omit it** | only `tools-agent-team` sets a colour. There is no per-axis palette |
| `skills:` | **omit it** | no agent in this repository uses the key. If a skill must be *invoked*, put `Skill` in `tools` — `skills:` is a preload axis and does not substitute for it |

**Do not drop the REDO sentence at the end of `description`** — the orchestrator re-invokes the same
entry point on a REDO, and without that sentence the author accepts the full review and edits outside
the requested scope.

---

## 2. Canonical skeleton (identical across all 4 code domains)

```markdown
## Role
## Authoring Conventions (SoT reference)
## Self-gates (mandatory before handoff)
## Working Principles — what to leave to the gates and what to judge
## I/O Protocol
## Turn Budget (against maxTurns exhaustion)
## Role Boundaries (handoff)
## Rule Files and Helper Skill References
```

`api-platform-author` alone adds **`## Known Gaps (check before writing)`** after
`## Authoring Conventions` — in that domain the SoT for the generation conventions is the two build
commands, so the agent has to re-state the gap information those commands own.

### The four steps `## Role` fixes

`app-php-symfony-author`'s shape is canonical:

1. **Fix the target** — decide the layer and domain to write in first.
2. **Learn the existing conventions** — `Read` **one or two** existing classes in the same layer and
   domain and follow their namespace, constructor-promotion form, logger channel and exception handling
   exactly. **Do not invent a new convention.**
3. **Create or modify** — **edit the target file directly.** Do not write a draft file.
4. **Self-gate** — fix your own output until resolvable defects reach zero, then hand off.

> **Step 3 is the fork in this axis.** `utility-git-commit-author` and `utility-drawio-diagram-author`
> do the opposite and **write a draft under `.claude/tmp/**`**, because the skill owns the final action
> (the commit, applying the XML). In a code domain the target file *is* the deliverable, so there is no
> draft stage. When designing a new author, split these two cases by **who owns the final action**.

---

## 3. Self-gates — the core of this axis

**Run the gates through the same scripts as the hooks.** That is what makes it impossible for the hook
and the verdict to diverge. Call them directly rather than relying on the hook having fired:

```bash
# the guards take no $1 argument — they read only stdin JSON
echo '{"tool_input":{"file_path":"app/src/{path}/{file}.php"}}' \
  | .claude/hooks/post-tool-use/app-php-lint.sh
echo '{"tool_input":{"file_path":"app/src/{path}/{file}.php"}}' \
  | .claude/hooks/post-tool-use/app-php-cs-fixer.sh
```

Then run the project-wide gates (the commands `CLAUDE.md` documents as merge conditions):

```bash
cd app
vendor/bin/phpstan analyse            # level 8 — a merge condition
vendor/bin/php-cs-fixer fix --dry-run # the Symfony ruleset
```

Gate coverage per domain:

| Domain | Hook guard | Project-wide gate |
| --- | --- | --- |
| PHP | `app-php-lint.sh` · `app-php-cs-fixer.sh` | `phpstan analyse` · `php-cs-fixer fix --dry-run` |
| Twig | `app-twig-lint.sh` | `bin/console lint:twig` |
| JS/Stimulus | `app-javascript-stimulus-guard.sh` | — |
| API Platform | same as PHP | same as PHP + `debug:api-resource` |

### `exit 0` does not mean pass

The four hooks are **non-blocking by design**, so when their prerequisites (`app/vendor` and the like)
are absent they skip silently and return `exit 0`. Worse, the guards check **existence, not
installation** — `app-twig-lint.sh` tests `[ -d app/vendor ]` while `app-php-cs-fixer.sh` tests
`[ -x app/vendor/bin/php-cs-fixer ]`. On an incomplete vendor tree the two diverge (the former passes
the guard and then breaks loudly on kernel boot failure; the latter skips silently).

**So report gate results as three values: pass / fail / not run.** Counting a gate that never ran as a
pass makes the reviewer judge unverified code.

> **Under `isolation: worktree` this is not a hypothetical.** A worktree holds tracked content only, so
> **vendor-dependent gates cannot run there at all** unless the agent installs dependencies in the
> worktree. `php-cs-fixer`, `phpstan`, `phpunit` and `bin/console` are all in this category — expect
> "not run" and report it as such rather than as a pass.

**Do not read a static gate passing as evidence of behaviour** — a provider stub types `$parameter` as
`array<string, mixed>`, so PHPStan level 8 cannot catch access to a key that does not exist.

---

## 4. Working principles — what to leave to the gates and what to judge

| Leave to the gates | Judge yourself |
| --- | --- |
| formatting, import ordering, whitespace (`php-cs-fixer`) | layer placement and namespace |
| type errors, null safety (`phpstan`) | dependency direction (`Controller → Service → Repository`) |
| Twig syntax (`lint:twig`) | where locking and idempotency are required |
| forbidden API usage (`js-guard`) | transport selection (`async_default` vs `async_redis` vs `sync`) |

**Do not spend turns hand-fixing what a gate catches.** Conversely, do not wave through a design
decision the gates cannot see on the strength of the gates passing.

---

## 5. I/O protocol

- **Input** — the orchestrator's 7-field spawn payload (target file list · role · governing rule path ·
  output path · severity convention · no secrets · how to report an unrun gate).
- **Output** — a code domain returns the edited target files plus a change summary. A utility author
  writes `.claude/tmp/{axis}/{domain}/{artifact}-draft.md`.
- **REDO input** — `[MUST]` items only. It does not receive the full review, and **never changes
  anything the instruction did not name.**

**Under worktree isolation, the returned report is the handoff channel.** The worktree holds tracked
content only and branches from the default branch rather than the parent session's `HEAD`, so the
reviewer can reach neither your uncommitted edits nor `.claude/tmp/`. **Inline your full unified diff as
text in the returned report.** If you leave it in the working tree and the reviewer is told to run
`git diff`, it sees an empty diff and **returns PASS on work it never read** — with no error anywhere.
Reverting to that arrangement is a `[MUST]` regression.

---

## 6. Turn budget

When `maxTurns` is exhausted the harness **stops without a marker** (below CLI 2.1.246; this repository
runs 2.1.236). So the author has to detect it itself.

- If gate retries start repeating, **narrow the scope and report** — do not keep looping automatically.
- Leave the partial output and **state that it is incomplete**. Do not report it as done.
- **The retry budget belongs to the orchestrator** — an author does not count its own REDOs. The limits
  are 3 for code domains and 2 for configuration and meta domains, counted as entry-point invocations
  (not as `[MUST]` findings).

---

## 7. Role boundaries (handoff)

```text
upstream: main routing · orchestrator · {domain}-reviewer (REDO instruction)
  ↓
{domain}-author  ← generates only. It does not judge its own work
  ↓
downstream: {domain}-reviewer (PASS/REDO verdict) → {domain}-tester (regression prevention)
            {domain}-debugger when a runtime cause must be established
            {domain}-analyzer when it is a security vulnerability
```

**If the author judges its own output, the generate-verify loop loses its independence.** A self-gate is
only the objective result a tool produced; the `[MUST]`/`[SHOULD]` verdict belongs to the reviewer.

---

## 8. Checklist for creating a new author

- [ ] Do the gates exist — are the hook script paths and project-wide commands actually runnable?
- [ ] If there is no gate, is an author axis warranted at all? A generation axis with no verification
      means pushing everything onto the reviewer
- [ ] Does the `description` carry the REDO sentence?
- [ ] Are `Write` and `Edit` in `tools`? (`memory:` auto-grants them, but stating them is the convention)
- [ ] Is `permissionMode: acceptEdits` present? Without it the edits are refused under the session's
      `plan` mode
- [ ] Does `isolation` match the **domain scope** — `worktree` for an `app/**`-scoped author, omitted
      for a utility author that must see the real working tree?
- [ ] If it is isolated, does the body instruct it to **inline the full unified diff** in the returned
      report?
- [ ] Are `color` and `skills:` **absent**? Neither is a convention in this repository
- [ ] If it **invokes** a skill, is `Skill` in `tools`? (`skills:` is only a preload)
- [ ] Does the paired `{domain}-reviewer` exist — without it there is no loop?
- [ ] Was `maxTurns` taken from **an existing author of similar workload** (30) rather than from the axis?
