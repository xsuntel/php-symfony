---
paths:
  - ".claude/agents/app-agent-team.md"
  - ".claude/agent-memory/app-agent-team/**"
  - ".claude/docs/app-agent-team-docs.md"
---

# app-agent-team Orchestration Rules

This rule is the judgment criteria (SoT) for the **routing, roster and handoff invariants** of the
`app-agent-team` orchestrator. It covers the command boundary for the application itself (PHP, JS,
Twig), external provider consumption, and operational assets.

@see .claude/agents/app-agent-team.md — the orchestrator this rule judges (execution directives)
@see .claude/docs/app-agent-team-docs.md — team composition · role axes · verification loop rationale (not a SoT)
@see .claude/rules/api-agent-team-rule.md — the sibling orchestrator (exposure layer) verdict SoT
@see .claude/rules/tools-agent-team-rule.md — the sibling orchestrator (infrastructure · data · deployment) verdict SoT
@see .claude/docs/abstract-orchestrator-contract-docs.md — rationale and measured values of the shared operational contract
@see .claude/rules/abstract-structure-rule.md — directory and path conventions · rule index (SoT)

## Judgment Scope (no overlap with other SoTs)

This domain's criteria are split four ways. **This rule owns only the third axis** and does not
restate the others.

| Axis | SoT | What it covers |
| --- | --- | --- |
| `.claude/**` structure and placement | `rules/utility-claude-code-rule.md` | directory tiers · flattening · frozen roots |
| Artifact spec | `commands/utility-claude-code-review.md` | frontmatter · naming · tool minimality |
| **Orchestration invariants** | **this rule** | **roster boundary · handoff direction · fan-out · verdict-suspension conditions** |
| Code verdicts | each domain rule (`app-php-symfony-*` etc.) | the code standards the subagents cross-check |

**The duplication with the agent prompt is intentional.** A subagent starts from an empty context and
cannot reach this rule through `@see`, so the directives must be physically present in
`agents/app-agent-team.md`. When the two diverge **this rule is the SoT**, and they are revised
**in the same change**.

## Shared Orchestration Contract (identical across the three teams)

The six **numbered imperatives** below are worded identically across the `app`, `api` and `tools`
rules. Never fix just one. The **indented notes are deliberately team-specific** — they record what
each roster actually declares, which differs — so they are not part of the shared wording. The
rationale and measured values live in `docs/abstract-orchestrator-contract-docs.md` and are not
restated here.

1. **The three orchestrators never spawn one another.** Out-of-scope files are handed over by naming
   the responsible team under `## Handoffs`, and are **never dropped silently**.
   > **One documented exception, in one direction only:** `api-agent-team` delegates its non-exposure
   > half to `app-agent-team` (Mode D). That arrives here as a caller, and this team must not bounce
   > the exposure-layer half back — see `## Invariant — Mode D`.
2. **All seven spawn-payload fields are mandatory** — target file list · role · governing rule (SoT)
   path · **output channel** · severity vocabulary · no secrets · marking of unrun gates. A missing
   field is a `[MUST]`.
   > **The fourth field is a channel, not always a path.** An agent declaring
   > `disallowedTools: Edit, Write` **cannot write a file**, so handing it a tmp path guarantees a
   > spawn that fails at its last step. Give a tmp path only to an agent that is both write-capable
   > and non-isolated; otherwise require the findings **in the returned report**.
3. **The orchestrator itself must never take `isolation: worktree`.** Its working material is the real
   tree — uncommitted `git diff` output and the gitignored `.claude/tmp/**` — and a worktree holds
   tracked content only, so isolating it produces an empty verdict as a silent failure.
   > **This is a constraint on the orchestrator, not a blanket ban.** `[Verified]` 2026-08-30: **all
   > 15 `app-*` specialists set `isolation: worktree`** by design. The consequence is the opposite of
   > a prohibition — see `## Invariant — verification loop` for the inline-diff requirement it forces.
4. **Keep the tmp consolidated-report path isolated per team** — never overwrite another team's report.
5. **A gate that did not run is not a pass** — tally across three values: passed / failed / **unchecked**.
6. **Re-spawn a partial failure exactly once**; if it fails again, state it as "cannot judge (not
   performed)" and **suspend go/no-go**. Exhausting your own turns is also a partial failure, so
   record into the consolidated report incrementally.

## Invariant — roster (direct spawn targets)

- **The only direct `Agent` spawn targets are the 15 `.claude/agents/app-*-*.md` agents**
  (PHP · JS · Twig × `-author`, `-analyzer`, `-debugger`, `-reviewer`, `-tester`). A name that starts
  with `app-` but does not end in a role suffix is not a spawn target.
- **Never spawn yourself** — `app-agent-team` also matches the `app-` prefix but is excluded.
- **The three groups below are never direct-spawned**, under any circumstances. Each goes through a
  command, a skill, or a sibling orchestrator.

  | Forbidden spawn target | The correct route |
  | --- | --- |
  | The 6 infrastructure and data reviewers (`cache-`, `database-`, `message-`, `server-`, `tools-aws-`, `tools-gcp-`) | the 4 `/…-review` commands, or a `tools-agent-team` handoff (which direct-spawns 5 of the 6) |
  | The 4 `utility-*` author/reviewer agents (Diagram · Commit) | `utility-drawio-diagram-skill` · `utility-git-commit-skill` |
  | The 5 `api-platform-*` agents | an `api-agent-team` handoff |

  > **Only four `/…-review` commands exist for those six reviewers** — `/cache-redis-review`,
  > `/database-postgresql-review`, `/message-rabbitmq-review` and `/server-nginx-review`. `[Verified]`
  > 2026-08-30: **GCP Cloud Run and AWS ECS have no dedicated review command.** For those two, route
  > to the deploy gate skill or hand off to `tools-agent-team`; never invent a command name.

## Invariant — scope boundary and handoffs

- **Only the three paths `ApiResource`, `State` and `api_platform.yaml` belong to `api-agent-team`.**
  Everything else under `app/src/**`, `app/assets/**`, `app/templates/**`, `scripts/**`, `diagram/**`
  and `.claude/**` is concluded by this team. When in doubt, handle it here.
- **Never hand `app/src/Service/Providers/**` to `api-agent-team`** — since the 2026-08-29 transfer,
  all provider consumption belongs to this team. Handing it over creates a **handoff loop** that comes
  straight back (observed in practice with Agencies).
  > ⚠️ **The provider domain is unimplemented, so a provider path is unroutable — not merely
  > mis-scoped.** `[Verified]` 2026-08-30: `.claude/rules/api/`, `.claude/commands/api/` and the five
  > `api-providers-*-build-skill` directories **do not exist**. An earlier revision of this rule named
  > `rules/api/providers/finance/**` as the verdict SoT; that path has never existed on disk. Report a
  > change under a provider path as **unroutable**, naming the expected artifact, and never redirect
  > it quietly to `app-php-symfony-reviewer`, which holds no criteria for it.
- **When infrastructure, data or deployment assets span several domains, hand off to
  `tools-agent-team`.** For a single domain the matching `/…-review` command is enough.
  **Only `message-rabbitmq-reviewer` sits outside that team's roster**, so it stays with this team's
  `/message-rabbitmq-review` command — do not hand it to `tools-agent-team` because the name looks
  similar.
- **Never drop a routing-unmatched file silently** — a changed file matching no row is stated verbatim
  under `## Summary` in the consolidated report. A file handed to another team is a **handoff**, not
  an unmatched file.

## Invariant — Mode D (delegation from `api-agent-team`)

- **Take the caller's file list verbatim.** Do not re-expand it with `git diff`; anything added is
  outside the delegation.
- **Suppress the exposure-layer split.** Step 2 normally routes `ApiResource`/`State`/
  `api_platform.yaml` to `api-agent-team`; under Mode D that orchestrator is the caller, so the split
  would loop and burn both budgets. Report such a path as **already owned by the caller** and judge
  the rest.
- **Return findings for the caller to merge.** Do not emit go/no-go as though you were the top-level
  orchestrator.
- **The roster stays closed under Mode D.** A delegation frequently expects a Doctrine Entity reached
  through `stateOptions` to be judged, but `database-postgresql-reviewer` still may not be spawned —
  return `/database-postgresql-review` as a referral and say plainly that the layer was not reviewed.

## Invariant — delegation mechanism

- **When deployment assets fall in scope, or an "is it safe to deploy" intent is confirmed, delegate
  to the `tools-app-deploy-skill` gate instead of spawning reviewers directly.** Direct spawning
  splits ownership of go/no-go.
- **Diagram and Commit skills own the draft guard, the retry limit and the final action**, so never
  direct-spawn their agent pairs.
- **The delegation mechanism is the `Skill` tool.** Do not substitute reading `SKILL.md` with `Read`
  and improvising the procedure — that detour skips every control the skill owns.
- **Never invent an entry point that does not exist.** GCP Cloud Run and AWS ECS have **no** dedicated
  review command: for a deployment verdict use the gate skill, and otherwise hand off to
  `tools-agent-team`.

## Invariant — verification loop and artifacts

- **Build uses template ① (the agent pair)** — a `*-author` edits `app/**` directly (it writes no
  draft file) and a `*-reviewer` issues the verdict.
- **The reviewer cannot reach the author's work through the working tree.** `[Verified]` 2026-08-30:
  all 15 `app-*` agents set `isolation: worktree`, author and reviewer are two separate `Agent` calls
  with two separate worktrees, and a worktree is branched from the default branch holding tracked
  content only. A reviewer told to run `git diff` therefore sees an **empty diff and reports a clean
  pass on work it never read**. **Paste the author's full unified diff inline into the reviewer's
  prompt.**
  > An earlier revision of this rule said the reviewer "judges by `git diff`". That is the exact
  > silent-failure this invariant exists to prevent; do not restore it.
- **The provider axis alone would use template ②** (build skill + command-based self-verification) —
  but see the unroutable warning above: none of those skills or commands exist yet.
- **Retry limits** — code domains **3**, configuration and meta domains (commit, diagram, `.claude`,
  shell) **2**. Past the limit, do not revert the source; stop as-is and present the unresolved
  instructions. **The orchestrator owns this counter**, because each author states that it does not
  count retries.
- **Never pass downstream to the tester while a `[MUST]` remains** — the resolution cycle comes first.
- **The consolidated report is returned in the response; the tmp copy is best-effort.** The path,
  when written, is `./.claude/tmp/app/app-agent-team-report.md`. A `Write` there is **denied while the
  session is in plan mode** (inherited, since the orchestrator declares no `permissionMode`), and
  nothing reads the file — a refused write is a non-event and must never be reported as persisted.
  Never overwrite `tmp/api/**` or `tmp/tools/**`.

## Invariant — safety boundary

- **The orchestrator never modifies code directly.** `disallowedTools: Edit` enforces the
  no-modification half at the harness level; writes are confined to `./.claude/tmp/**`. Note that
  `Bash` is unrestricted and can write (redirection, `tee`, `sed -i`, `git apply`) — the same boundary
  covers all of those.
- **Live order and withdrawal provider endpoints** (KoreaInvestment `order-*` / `OrderCash`, UPbit
  `orders` / `withdraws`) may have their code changes reviewed, but **never execute a real call as a
  trial** — the monetary consequence is irreversible.
- **Destructive or irreversible operations** (production deployment, `terraform apply`, drawio
  `set_page`, deletion, permission changes) require announcing the blast radius and obtaining user
  approval before execution.
- Never include a secret or credential value in plaintext in any output — record the type and
  `file:line` instead of the value, and raise it as a `[MUST]`.

## Violation Severity

- **`[MUST]`** — direct-spawning outside the roster; the three teams spawning one another (Mode D
  excepted); handing `Service/Providers/**` to `api-agent-team`; direct-spawning reviewers on a deploy
  intent; direct-spawning the Diagram or Commit agents; granting the orchestrator
  `isolation: worktree`; **routing a reviewer to a path instead of pasting the author's diff inline**;
  trespassing on another team's tmp path; a missing spawn-payload field; assigning a tmp path to an
  agent that declares `disallowedTools: Write`; tallying unchecked as passed; issuing go while an axis
  is unjudged; failing to report a routing-unmatched file; exposing a secret.
- **`[SHOULD]`** — failing to spawn independent agents in parallel (6 or fewer at a time is the
  bound); failing to merge cross-matched duplicates (doctrine↔postgresql, the broad cache paths);
  failing to name the handoff team.
- **`[CONSIDER]`** — improvements that carry a structural change, such as rearranging a role axis or
  creating a new agent. Never apply without approval.

## Companion Updates

When the roster or a boundary changes, fix all of the following **in the same change**. Leave one out
and the descriptions diverge.

- `.claude/agents/app-agent-team.md` — execution directives (roster table · routing table · checklist)
- `.claude/agent-memory/app-agent-team/MEMORY.md` — the always-loaded context summary
- `.claude/docs/app-agent-team-docs.md` — background · inventory · trade-offs
- The sibling teams' rules, agents and memory (`api-agent-team`, `tools-agent-team`) — a boundary is described from both sides
- `.claude/workflows/README.md` — per-role entry points
