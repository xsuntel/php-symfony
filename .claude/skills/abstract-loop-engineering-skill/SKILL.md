---
name: abstract-loop-engineering-skill
description: 'Designs and audits this repository''s verification loops (generate → gate → verdict → retry). Judges how author→reviewer pairs, command self-verification and hook gates converge, and whether stopping conditions, retry budgets and three-valued gate aggregation (pass / fail / not run) are actually in place. Use it for requests like ''design a loop'', ''check the verification loop'', ''retry budget'', ''endless REDO'', ''stopping condition'', ''the gate is not running'', ''add a self-gate'' (in any language). What artifacts to create belongs to abstract-harness-engineering-skill, and how loops connect and route belongs to abstract-graph-engineering-skill — hand those over.'
---

# Loop Engineering Skill

Designs and audits **how a single loop converges**. The topology that **connects** loops is out of
scope.

- This skill **holds no judgment criteria.** It points at the SoTs below with `@see` and does not
  restate them.

@see .claude/docs/abstract-orchestrator-contract-docs.md — retry budget · partial failure · three-valued gates (rationale)
@see .claude/rules/utility-claude-code-rule.md — `.claude/**` structure and placement verdicts (SoT)
@see .claude/commands/utility-claude-code-review.md — artifact spec verdicts (SoT)
@see .claude/hooks/README.md — hook wiring conventions · event mapping · execution contract
@see .claude/skills/utility-git-commit-skill/SKILL.md — the reference loop (the first instance)
@see <https://code.claude.com/docs/en/skills> — skill spec
@see <https://code.claude.com/docs/en/hooks> — hook events · execution contract

---

## The three axes (read this first)

This maps the three layers of the public discourse onto this repository's artifacts. Cross the boundary
and judgment criteria get duplicated.

```text
abstract-harness-engineering-skill  = what to build   (artifact kinds · counts · role axes)
abstract-loop-engineering-skill     = how it converges (this skill — gates · verdicts · retries · stopping)
abstract-graph-engineering-skill    = how it connects  (nodes · edges · fan-out · routing)
```

**Loops create cycles, and cycles are what make the graph hard.** The moment a REDO exists the workflow
stops being a DAG, and cost, state and termination problems begin. This skill owns termination; the
graph skill owns cost and routing.

---

## 1. The canonical shape of a loop

The feedback loop the official documentation describes for Claude Code is **gather context → act →
verify → repeat**. This repository implements that shape three ways.

| Kind | Who verifies | Adopted by | Stops on |
| --- | --- | --- | --- |
| **① agent pair** | a reviewer in an independent context | git-commit · drawio · the code-domain author↔reviewer pairs | PASS, or the retry limit |
| **② command self-verification** | the skill checks itself against the command's criteria | shell script · Claude Code config | PASS, or the retry limit |
| **③ hook gate** | a `PostToolUse` hook script | php-lint · php-cs-fixer · twig-lint · js-guard | non-blocking — it has no notion of stopping |

**③ runs inside ① and ②.** The self-gate an author runs *is* ③'s script, invoked **directly** rather
than relying on the hook having fired. That is what makes it impossible for the hook and the verdict to
diverge.

> The five provider `*-build-skill` entries that once illustrated ② **do not exist on disk**
> (`[Verified]` 2026-09-06). The provider domain is designed but unimplemented, so do not cite it as a
> live instance of the pattern.

---

## 2. The five things a loop must decide

When building a new loop or auditing an existing one, check that all five are settled. **If even one is
missing, the loop either fails to converge or silently produces a wrong result.**

### 2-1. Precondition — stop a spinning loop before it starts

Check this **before** spawning an agent. `utility-git-commit-skill` is the reference:

```bash
git diff --cached --quiet   # exit 1 → there are staged changes → proceed
                            # exit 0 → report and stop (do not call an agent)
```

Without a precondition the loop runs on empty input and produces **a PASS about nothing**.

### 2-2. Gates — `exit 0` is not a pass

**This is the most expensive misreading available in this repository.** The four `PostToolUse` hooks are
non-blocking by design, so when their prerequisites are absent they skip silently and return `exit 0`.
Worse, the guards check **existence, not installation**:

| Guard | Prerequisite check | When the prerequisite is incomplete |
| --- | --- | --- |
| `app-twig-lint.sh` | `[ -d app/vendor ]` | passes the guard, then **breaks loudly** on kernel boot failure |
| `app-php-cs-fixer.sh` | `[ -x app/vendor/bin/php-cs-fixer ]` | **skips silently** |

**So aggregate gate results as three values: pass / fail / not run.** Counting a gate that never ran as
a pass ships unverified output as a PASS.

**Do not trust the session-start vendor warning at face value** — the `session-start` hook's output is a
snapshot from that moment and goes stale as soon as `composer install` runs. Judge availability by
**actual file existence**.

**Do not read a static gate passing as evidence of behaviour** — a provider stub types `$parameter` as
`array<string, mixed>`, so PHPStan level 8 cannot catch access to a key that does not exist.

### 2-3. Verdicts — separate maker from checker

**An instance grading its own homework develops confirmation bias.** That is why ① exists.

- A reviewer **does not edit the source directly.** `memory: project` makes the harness grant `Write`
  and `Edit` automatically, but the output is findings and fix fragments only.
- **If the reviewer fixes it, the loop's independent verdict collapses** — the person who fixed it
  becomes the person who judged it.
- The verdict is **PASS / REDO** (two values); finding severity is **`[MUST]` / `[SHOULD]` /
  `[CONSIDER]`**, and **only `[MUST]` blocks a merge**.
- **When the verdict is uncertain, choose REDO over PASS.**

### 2-4. Retry budget — the loop's owner does the counting

**The retry budget belongs to the orchestrator or skill.** An author does not count its own REDOs.

| Domain | Limit |
| --- | --- |
| code domains | **3** |
| configuration and meta (commit · diagram · Claude Code config · shell) | **2** |

- **Count entry-point invocations** — not the number of `[MUST]` findings.
- On a REDO, re-invoke **the same entry point** carrying **only the `[MUST]` items**. Passing the full
  review back makes the author act on `[SHOULD]` and `[CONSIDER]` too and drift out of scope.
- **Never change anything the instruction did not name.**

### 2-5. Stopping condition — what happens past the limit

**This is the design hole most often left open.** Setting a limit without deciding what follows it ends
the loop ambiguously.

- **Do not revert the source.** Stop where it is, list the unresolved instructions, and recommend a
  manual review — reverting throws away work the user may want to finish by hand.
- **Do not perform the final action.** Committing, recording and applying happen only on PASS.
- Present the last draft and end with **"automatic-approval limit reached — manual review
  recommended"**.

The official workflow examples recommend the same shape — *"stop after two rounds with no progress"*,
*"stop when a new round finds nothing"*. **Lack of progress is also a stopping condition**, not just the
limit.

---

## 3. Partial failure — a failed branch does not discard the whole

One branch failing does not throw away the orchestration. **Nor does it paper over the gap.**

> **"Clean" and "did not run" are different verdicts.** An analyzer that never executed is not a clean
> security result.

- Re-spawn a failed axis **once**; if it fails again, mark it **"cannot judge (not performed)"** and
  withhold the verdict.
- On `maxTurns` exhaustion, take the partial output, mark that branch **incomplete**, and recommend a
  **narrowed re-run** — do not retry automatically.
- **Your own turn exhaustion is a partial failure too.** If the orchestrator's own `maxTurns` runs out
  mid-consolidation, the harness **stops without an error** and the incomplete report ships as-is. That
  is why the consolidated report is written **incrementally**.
- **Never invent or pre-empt the result of a spawn that has not returned.**

The **"partial" marker for `maxTurns` exhaustion arrives in CLI v2.1.246**. This repository runs
**2.1.236** (`[Verified]` 2026-09-06), so the harness will not tell you — **detect incompleteness
yourself**.

---

## 4. Loop audit procedure

To assess an existing loop's health, check the following in order.

```bash
# 1. Which skills own a loop — do they state a retry limit?
grep -l 'retry\|REDO' .claude/skills/*/SKILL.md

# 2. Loops with a limit but no stopping condition (any output is a review target)
for f in .claude/skills/*/SKILL.md; do
  grep -qi 'retry\|REDO' "$f" && ! grep -qi 'limit reached\|do not commit\|do not record\|manual review' "$f" \
    && echo "  stopping condition unclear: $f"
done

# 3. Do authors run their self-gate through the same script as the hook?
grep -l 'post-tool-use' .claude/agents/*-author.md

# 4. Do the registered hook scripts exist and are they executable?
python3 -c "
import json, re, os
d = json.load(open('.claude/settings.json'))
for ev, ms in (d.get('hooks') or {}).items():
    for m in ms:
        for h in m.get('hooks', []):
            p = re.search(r'\.claude/hooks/[A-Za-z0-9/_.-]+\.sh', h.get('command', ''))
            if p and not os.access(p.group(0), os.X_OK): print('  not executable:', ev, p.group(0))
"
```

**Audit checklist:**

- [ ] Is there a precondition — can the loop run on empty input?
- [ ] Are gate results aggregated as **three values** — is `exit 0` being read as a pass?
- [ ] Are maker and checker separated — does the body state that the reviewer does not fix?
- [ ] Is the retry limit **stated**, and is the skill or orchestrator the one counting?
- [ ] Is the **behaviour past the limit** decided — final action not performed, source not reverted?
- [ ] Is the REDO input **`[MUST]` only** — is the full review being passed back?
- [ ] Are partial failures distinguished as "cannot judge (not performed)"?
- [ ] Are the draft and the review **different tmp files** — otherwise the reviewer overwrites the source?
- [ ] Where the agents are worktree-isolated, does the reviewer receive the **full unified diff inline**?

---

## 5. Three things that break a loop

### 5-1. Worktree isolation — used deliberately, so the loop must be built around it

`[Verified]` 2026-09-06 — **19 agents declare `isolation: worktree`**: the 15 `app-*` agents plus
`api-platform-author`, `-analyzer`, `-debugger` and `-tester`. **This is a deliberate convention, not an
oversight**, and the authoritative census lives in `commands/utility-claude-code-review.md`
(`Agent isolation / maxTurns`).

**The convention follows the agent's domain scope, not whether it writes** — a read-only analyzer scoped
to `app/**` is isolated too. Do not flag that as inconsistent. The deliberate omissions: the three
orchestrators, `api-platform-reviewer`, the six infrastructure reviewers, and the four `utility-*`
agents — the `utility-git-commit-*` pair **must** see the real working tree (`git diff --cached`), so
adding `isolation: worktree` there is a `[MUST]` finding.

**What isolation costs the loop.** A `git worktree` holds **tracked content only**, and it branches
**from the default branch rather than the parent session's `HEAD`**. So an isolated reviewer sees
neither the author's uncommitted edits nor the gitignored `.claude/tmp/`.

> The failure mode: a reviewer told to "run `git diff` and review the result" sees an **empty diff**,
> finds nothing wrong with nothing, and returns **PASS on work it never read**. Nothing errors.

**The mitigation is the handoff channel, not removing isolation.** The author inlines its **full unified
diff as text** in the returned report, and the orchestrator pastes that into the reviewer's prompt.
Reverting an author to "the reviewer reads the same diff" is a **`[MUST]`** regression — see
`utility-claude-code-review.md` and `docs/abstract-orchestrator-contract-docs.md` §2.

Two more consequences to design around:

- **Isolation can be imposed from above.** When the main conversation itself runs isolated, the same
  checks apply to **every** sub-agent, including ones with no `isolation` key. So a missing key is not a
  guarantee of a shared tree — **never make a tmp path the only channel**.
- **Vendor-dependent gates cannot run in a worktree** unless the agent installs dependencies there.
  `php-cs-fixer`, `phpstan`, `phpunit` and `bin/console` are all in this category, which is a second
  reason gate results must be aggregated as three values (§2-2).

### 5-2. A missing `Skill` tool

An agent that specifies `tools` must list **`Skill` explicitly** to delegate to a skill or command.
`memory:` auto-grants only `Read`, `Write` and `Edit`.

Omit it and the call **does not fail** — it degrades into reading `SKILL.md` with `Read` and improvising,
which **skips the draft guard, the retry limit and the final-action control the skill owns**. The
`skills:` frontmatter key is a preload axis and does not substitute for it.

### 5-3. tmp path collisions

- Writing the draft and the review to the **same file** lets the reviewer overwrite the source, so the
  REDO input disappears.
- A nested path needs **`mkdir -p` on the whole parent chain** — creating only the first segment makes
  the write fail.
- **Cleanup is impossible** — `Bash(rm:*)` is denied and deny beats allow. Retention is handled by
  `cleanupPeriodDays` and `.gitignore`.

---

## 6. Building a new loop

1. **Is a ③ hook gate enough?** For an automatic, non-blocking check one hook is cheapest. No verdict
   needed.
2. **Is ② self-verification enough?** When the conventions are long and domain-specific, gathering them
   in one command is better.
3. **Is an ① agent pair required?** Only when the output is large, **structural integrity** matters (id
   uniqueness, referential consistency), and an independent context uncontaminated by the generation
   step is an advantage.

**Once you decide to build a loop, settle all five items in §2 before** writing files. Delegate the
artifact writing itself to `utility-claude-code-skill`; which artifacts and how many is judged by
`abstract-harness-engineering-skill`.
