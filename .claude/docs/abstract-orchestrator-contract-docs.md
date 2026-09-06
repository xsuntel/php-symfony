# Orchestrator Operational Contract

> Status: **Reference document** — the detailed edition of the operational contract that
> `app-agent-team`, `api-agent-team` and `tools-agent-team` all execute. It is **not a SoT for
> verdicts**; per
> `## Docs Layout` in `utility-claude-code-rule.md` a docs file is always a reference, and when it
> disagrees with a rule the rule wins.
> Written: 2026-08-28
>
> **Why this file exists.** The three orchestrators carry near-identical operational sections by design —
> each runs standalone in a fresh context and cannot `@see` its way to a shared file *at spawn time*, so
> the imperatives have to be physically present in every prompt. What does **not** need to be duplicated
> is the **rationale and the measured numbers** behind those imperatives. Several copies of a census that
> changes whenever an agent is added is a drift generator; this file is the one place the reasoning
> lives, and all three orchestrators point here for it.
>
> **The division of labour, stated plainly:**
>
> - **In each agent prompt:** the imperative — what to do, every invocation, without reading anything.
> - **Here:** why it is the rule, what breaks when it is violated, and the evidence.
> - **In `commands/utility-claude-code-review.md`:** the authoritative agent census and frontmatter
>   conventions (that command is the verdict SoT; this file cites it and never restates the numbers).

> **A fourth class of reader was added on 2026-09-06.** The three `abstract-*-engineering-skill`
> design skills cite this file as their rationale source — `loop` for the retry budget, partial-failure
> semantics and three-valued gates (§4–§5), `graph` for the spawn payload, worktree isolation and
> preflight (§1–§2, §8), `harness` for the contract as a whole. They hold no criteria of their own, so
> this file's status is unchanged: still a reference, still subordinate to the rules. **Do not move a
> verdict here to serve them** — if one of those skills needs a criterion, its owner is a rule or
> `commands/utility-claude-code-review.md`.

@see .claude/agents/app-agent-team.md — repository-wide orchestrator (executes this contract)
@see .claude/agents/api-agent-team.md — API Platform orchestrator (executes this contract)
@see .claude/agents/tools-agent-team.md — infrastructure orchestrator (executes this contract; Review axis only)
@see .claude/skills/abstract-graph-engineering-skill/SKILL.md — consumes §1 · §2 · §8 (edges · isolation · preflight)
@see .claude/skills/abstract-loop-engineering-skill/SKILL.md — consumes §4 · §5 (partial failure · retry ownership)
@see .claude/commands/utility-claude-code-review.md — agent census · frontmatter conventions (verdict SoT)
@see .claude/docs/app-agent-team-docs.md — team composition · role axes · loop templates
@see .claude/rules/abstract-structure-rule.md — rule index (SoT)
@see .claude/output-styles/abstract-english-style.md — document style

---

## 1. Why a cold subagent needs everything spelled out

**Every subagent starts cold.** It inherits none of the orchestrator's context — not the changed-file
list, not the intent, not the rule it should read. Re-deriving that scope is the single largest way a
spawn wastes its budget, and a subagent that guesses wrong produces a confident, wrong report.

This is why the **Spawn Prompt Contract** has six mandatory items rather than "describe the task". The
items are not stylistic; each closes a specific observed failure:

| Item | Failure it prevents |
| --- | --- |
| 1. Target files, enumerated | "the changed files" → the agent runs `git diff` itself and picks a different set |
| 2. Exactly one role | a reviewer that starts fixing, or an author that starts judging its own work |
| 3. SoT rule paths, preflighted | an agent told to read a missing rule has **no criteria at all** and improvises |
| 4. Output destination | a write-blocked agent assigned a tmp path fails at its final step (§3) |
| 5. Scope limits | recursive spawning, and edits outside the intended blast radius |
| 6. Prior artifact inline | a worktree-isolated reviewer reporting a clean pass on work it never read (§2) |

---

## 2. Worktree isolation — the highest-consequence constraint

`[Verified]` 2026-08-29 [WebFetch: <https://code.claude.com/docs/en/subagents>]. A `git worktree`
checkout contains **tracked content only**, and `isolation: worktree` branches it **by default from the
repository's default branch rather than the parent session's `HEAD`**. A fresh worktree therefore has:

- **none of the author's uncommitted edits** — they live in the parent working tree;
- **no `.claude/tmp/` at all** — it is gitignored, so it is absent from every worktree.

Author and reviewer are two separate `Agent` calls, so each gets its own worktree checked out from the
default branch.

> This paragraph read "checked out from HEAD" until 2026-08-29. The corrected base makes the isolation
> **stronger**, not weaker — a worktree branched from the default branch can be further behind the
> parent session than one branched from `HEAD` — so every consequence below stands unchanged.

> **Added 2026-08-30 — isolation can be imposed from above.** `[Verified]`
> [WebFetch: <https://code.claude.com/docs/en/subagents>]: "When the main conversation runs isolated in
> a worktree, the same checks apply to every subagent, **including those without
> `isolation: worktree`**." So the "not isolated" list in §2 below describes the **normal case**, not a
> guarantee: when the main session is itself worktree-isolated, even a reviewer with no `isolation` key
> is subject to the same working-directory checks. Practical consequence for an orchestrator: the
> **returned report is the channel that always works**, and a `.claude/tmp/` handoff is an optimisation
> that holds only while the session is not isolated. Never make a tmp path the sole channel.

> **The failure mode:** a reviewer told to "run `git diff` and review the result" sees an **empty diff**,
> finds nothing wrong with nothing, and returns **PASS on work it never read**. Nothing errors. The
> orchestrator relays a clean verdict, and the `[MUST]` that was actually there reaches the user as a
> merge-ready change. This is the most damaging silent failure available in this repository.

**The imperative both orchestrators carry:** paste the author's **full unified diff text inline** into
the reviewer's prompt. Never route a reviewer to a path and assume it can reach the bytes.

Two corollaries worth stating, because both have been "fixed" in the wrong direction before:

- **Do not revert an author to "the reviewer reads the same diff."** `utility-claude-code-review.md`
  marks that regression as a `[MUST]`.
- **Vendor-dependent gates cannot run in a worktree** unless the agent installs dependencies there.
  `php-cs-fixer`, `phpstan`, `phpunit` and `bin/console` are all in this category.

### Which agents are isolated

The authoritative count lives in `commands/utility-claude-code-review.md` (`Agent isolation / maxTurns`)
and is deliberately **not restated here** — that command is the verdict SoT, and a second copy is
exactly the drift this file exists to prevent. The shape of the split, which is stable:

- **Isolated (`isolation: worktree`)** — the domain agents scoped to `app/**` sources: the `app-*`
  roster, plus `api-platform-author`, `-analyzer`, `-debugger`, `-tester`.
- **Not isolated** — the three orchestrators, the four `utility-*` agents, `api-platform-reviewer`, and
  the six infrastructure reviewers.

The convention follows the **agent's domain scope, not whether it writes** — a read-only analyzer
scoped to `app/**` is still isolated. Do not flag that as inconsistent.

---

## 3. Who may write where

**Three** independent restrictions stack, and confusing them produces spawns that fail at their last
step:

| Restriction | Mechanism | Consequence for the orchestrator |
| --- | --- | --- |
| **Cannot write any file** | `disallowedTools: Edit, Write` on the analyzers and reviewers | Ask for findings **in the returned report**. Assigning a tmp path guarantees failure |
| **Can write, but nobody can read it** | `isolation: worktree` + `.claude/tmp/` gitignored | The returned report is the only channel. A tmp path writes into a private directory |
| **Allowed to write, but refused at call time** | inherited `permissionMode` — `settings.json` sets `permissions.defaultMode: "plan"`, which is read-only | Applies to **the orchestrators themselves**: they hold `Write` but declare no `permissionMode`, so their own tmp report is denied while the session is in plan mode |

> **The third row was added on 2026-08-30 and is the one that bites the orchestrators.** `[Verified]`
> [Read: .claude/settings.json] + [WebFetch: <https://code.claude.com/docs/en/subagents>]: "If you
> leave it unset, the subagent inherits the main conversation's mode." The 14 write-path agents
> (`*-author`, `*-tester`, `*-debugger`) declare `permissionMode: acceptEdits` precisely to escape
> this; the three orchestrators deliberately do not, because they orchestrate rather than edit. The
> consequence is that **an orchestrator's consolidated tmp report is best-effort, not guaranteed** —
> the returned report is the required channel. Nothing in this repository reads those tmp reports, so
> nothing breaks when the write is refused; what would break is an orchestrator that reports a path it
> never managed to write, or that burns turns retrying, or that reaches for `Bash` redirection to
> defeat the permission mode.
>
> **Granting the orchestrators `permissionMode: acceptEdits` is the alternative, and it is a
> deliberate escalation** — they also hold unrestricted `Bash`, and their `Write` path scoping is
> prose-only, so auto-accepting their writes widens real blast radius. It needs an explicit decision,
> not a silent fix.

`memory: project` auto-grants `Write` and `Edit`, but **`disallowedTools` reverses that per tool** — so
the read-only agents' discipline is enforced by the harness, not by prose. They retain `Bash`, so the
read-only boundary is still partly self-held.

**Only give a tmp path to an agent that is both write-capable and non-isolated.** In practice that is a
short list, and `api-platform-reviewer` is the notable case of an agent that can *read* a tmp artifact
while being unable to write one.

### tmp mechanics

- **`mkdir -p` the full parent chain**, not just `.claude/tmp`. A nested path such as
  `.claude/tmp/api/providers/finance/` fails to write if only the first tier exists.
- **Cleanup is not available.** `settings.json` denies `Bash(rm:*)` outright and a deny rule outranks
  any allow; retention is handled by `cleanupPeriodDays` and `.gitignore`.
- `.claude/tmp` is gitignored at `.gitignore:4`. `[Verified]`

---

## 4. Partial results are still results

A spawned agent can fail outright, return nothing usable, or exhaust its own `maxTurns`. **Never discard
a whole orchestration because one branch failed** — but never paper over the gap either.

The distinction that matters most:

> **"Clean" and "did not run" are different verdicts.** An analyzer that never executed is not a clean
> security result. Reporting it as one is the second-most damaging failure mode here, after §2.

Consequences the orchestrators encode:

- A failed branch **does not block** the other branches' findings from being reported.
- But go/no-go **must state that coverage was incomplete**, because a `[MUST]` may be hiding in the
  branch that did not run.
- **Never fabricate or pre-empt the result of a spawn that has not returned.**
- On `maxTurns` exhaustion, take the partial output, mark the branch **incomplete**, and recommend a
  narrower re-run — do not auto-retry.

### Gates that pass by not running

The four `PostToolUse` hooks (`php-lint.sh`, `php-cs-fixer.sh`, `twig-lint.sh`, `js-guard.sh`) are
non-blocking by design and **skip silently** when their precondition is missing, via
`[ -d app/vendor ] || exit 0`. `[Verified]` [Read: .claude/hooks/post-tool-use/twig-lint.sh:39]

**`exit 0` therefore does not mean "passed".** With `app/vendor` currently absent, the PHP and Twig
gates are largely inert and only `php -l` and `js-guard.sh` genuinely run. Any gate that did not run
must be relayed as **"unchecked"** — never as a pass.

---

## 5. The retry budget belongs to the orchestrator

Every `*-author` agent states in its own body that it **does not count retries**
(`app-php-symfony-author.md:136`, `api-platform-author.md:153`). If the orchestrator does not track them
either, a REDO cycle runs unbounded.

- **Count invocations of the entry point**, not `[MUST]` findings.
- **Limit 3 for code domains**, 2 for config and meta domains (commit, diagram, Claude Code config).
- **Past the limit, do not revert the source.** Stop as-is, list the unresolved instructions, and
  recommend manual review. Reverting discards work the user may want to finish by hand.
- On REDO, re-invoke the **same entry point** with **only the `[MUST]` items** — not the full review.

---

## 6. Relaying

**A subagent's final report is not shown to the user.** Only the orchestrator sees it.

- Anything the user needs must be **restated** in the consolidated report.
- Never write "see the reviewer's output" — there is no output for the user to see.
- Merge duplicates on the same file and line into one entry at the **strictest** severity.
- Sort by `[MUST]` > `[SHOULD]` > `[CONSIDER]`; **only `[MUST]` blocks a merge**.

---

## 7. Bounding the fan-out

`maxTurns: 50` is the whole budget for one orchestration, and each spawn plus each returned result
consumes turns.

- Cap parallel spawns at **6 per batch**.
- With more targets, batch by priority (code domains before infrastructure) and report the remainder as
  **deferred** — never drop them silently.
- Never spawn the same agent twice for the same file in one invocation.
- Spawn independent branches **in parallel**; only ordered loops (author→reviewer) run sequentially.
- As the budget nears exhaustion, stop spawning, consolidate what returned, and report the untouched
  targets explicitly.

---

## 8. Preflight

Routing tables drift ahead of the tree, so **treat every routing target as unverified until checked** —
agent file, skill `SKILL.md`, command file, and any rule cited as SoT in a spawn prompt.

**When a target is missing, do not substitute a near-match and do not silently skip it.** Report it as
an unroutable target, naming the path that was expected, and continue with the targets that resolved.
A missing artifact is a repository defect worth surfacing, not an obstacle to route around.

The live example is the **provider domain**: `[Verified]` 2026-08-24, none of `.claude/rules/api/`,
`.claude/commands/api/providers/`, or the five `api-providers-*-build-skill` directories exist. A change
under a provider path is **unroutable** and must be reported as such — never quietly redirected to
`app-php-symfony-reviewer`, which holds no criteria for it.

---

## 9. Why each roster is self-held

Every orchestrator states that it may spawn only its own prefix family. **Nothing in the harness
enforces that**, and knowing why is what keeps the constraint from being quietly rationalised away the
first time a cross-roster spawn looks cheaper than a referral.

`[Verified]` 2026-08-30 [WebFetch: <https://code.claude.com/docs/en/subagents>]:

> "The `Agent(agent_type)` allowlist syntax applies only to an agent running as the main thread with
> `claude --agent`. In a subagent definition, listing `Agent` in `tools` lets that subagent spawn
> subagents of its own while the depth limit allows it, but **any type list inside the parentheses is
> ignored**."

So `tools: Agent(app-php-symfony-reviewer, …)` in an orchestrator definition buys nothing. Only two
harness-level alternatives exist, and both are worse than model compliance:

| Alternative | Why it is rejected |
| --- | --- |
| Omit `Agent` from `tools` entirely | The documented way to stop an agent nesting at all — which removes the orchestrator's entire reason to exist |
| A `disallowedTools` denylist of every non-roster agent | Wrong shape: it must enumerate the **complement** of the roster, so it grows and goes stale every time any agent is added anywhere in the tree |

The denylist's defect is the decisive one. A roster is an **allowlist by nature**, and expressing it as
a denylist inverts the maintenance burden onto the part of the tree the orchestrator does not own. The
authoritative agent census lives in `commands/utility-claude-code-review.md`; **the counts are
deliberately not restated here or in the agent prompts**, because a complement count is exactly the
kind of measured number that drifts silently.

**The consequence each agent prompt carries as an imperative:** roster discipline is self-held, and the
per-invocation checklist is its only backstop. That is why every orchestrator's checklist ends with an
explicit "was every spawn inside the permitted set?" line — it is not ceremony, it is the enforcement.
