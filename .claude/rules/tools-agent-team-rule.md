---
paths:
  - ".claude/agents/tools-agent-team.md"
  - ".claude/agent-memory/tools-agent-team/**"
  - ".claude/docs/tools-agent-team-docs.md"
---

# tools-agent-team Orchestration Rules

This rule is the judgment criteria (SoT) for the **roster, routing and handoff invariants** of the
`tools-agent-team` orchestrator. It covers the command boundary for infrastructure configuration, data
mapping and deployment assets.

@see .claude/agents/tools-agent-team.md — the orchestrator this rule judges (execution directives)
@see .claude/docs/tools-agent-team-docs.md — team composition · single-role rationale · trade-offs (not a SoT)
@see .claude/rules/app-agent-team-rule.md — the sibling orchestrator (application · provider · operations) verdict SoT
@see .claude/rules/api-agent-team-rule.md — the sibling orchestrator (exposure layer) verdict SoT
@see .claude/skills/tools-app-deploy-skill/SKILL.md — deploy go/no-go gate (not owned by this team)
@see .claude/docs/abstract-orchestrator-contract-docs.md — rationale and measured values of the shared operational contract
@see .claude/rules/abstract-structure-rule.md — directory and path conventions · rule index (SoT)

## Judgment Scope (no overlap with other SoTs)

**This rule owns the orchestration invariants only** and does not restate the rest.

| Axis | SoT | What it covers |
| --- | --- | --- |
| `.claude/**` structure and placement | `rules/utility-claude-code-rule.md` | directory tiers · flattening · frozen roots |
| Artifact spec | `commands/utility-claude-code-review.md` | frontmatter · naming · tool minimality |
| **Orchestration invariants** | **this rule** | **roster boundary · preflight · handoffs · verdict-suspension conditions** |
| Code and configuration verdicts | the 5 domain rules (see the roster table) | the infrastructure standards each reviewer cross-checks |
| Deployment approval | `skills/tools-app-deploy-skill/SKILL.md` | PASS/BLOCK go/no-go |

**The duplication with the agent prompt is intentional.** A subagent starts from an empty context and
cannot reach this rule through `@see`, so the directives must be physically present in
`agents/tools-agent-team.md`. When the two diverge **this rule is the SoT**, and they are revised
**in the same change**.

## Shared Orchestration Contract (identical across the three teams)

The six **numbered imperatives** below are worded identically across the `app`, `api` and `tools`
rules. Never fix just one. The **indented notes are deliberately team-specific** — they record what
each roster actually declares, which differs — so they are not part of the shared wording. The
rationale and measured values live in `docs/abstract-orchestrator-contract-docs.md` and are not
restated here.

1. **The three orchestrators never spawn one another.** Out-of-scope files are handed over by naming
   the responsible team under `## Handoffs`, and are **never dropped silently**.
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
   > **This is a constraint on the orchestrator, not a blanket ban.** `[Verified]` 2026-08-30: the 15
   > `app-*` specialists and 4 of the 5 `api-platform-*` agents **do** set `isolation: worktree` by
   > design. The consequence for whoever spawns them is the opposite of a prohibition — because an
   > isolated agent cannot see a sibling's uncommitted work, the author's **full unified diff must be
   > pasted inline** into the reviewer's prompt. This team's own five reviewers are not isolated.
4. **Keep the tmp consolidated-report path isolated per team** — never overwrite another team's report.
5. **A gate that did not run is not a pass** — tally across three values: passed / failed / **unchecked**.
6. **Re-spawn a partial failure exactly once**; if it fails again, state it as "cannot judge (not
   performed)" and **suspend go/no-go**. Exhausting your own turns is also a partial failure, so
   record into the consolidated report incrementally.

## Invariant — the roster is fixed by preflight

- **The roster is defined by five prefixes, not a fixed list of names** —
  `cache-` · `database-` · `server-` · `tools-aws-` · `tools-gcp-`.
- **At step 0 of every invocation, resolve `.claude/agents/` to fix the permitted spawn set.**
  Substituting memory lets this rule and the agent file go stale ahead of the tree.

  ```bash
  ls -1 .claude/agents/{cache,database,server,tools-aws,tools-gcp}-*.md
  ```

- **The direct-spawn condition is a conjunction** — (1) the name begins with one of the five prefixes,
  **and** (2) it actually resolves in preflight. If either fails, do not spawn.
- **When the resolution differs from the snapshot below, the resolution wins.**

  | Domain | Reviewer (2026-08-30 resolution) | Governing rule (SoT) |
  | --- | --- | --- |
  | Redis · cache · locks · sessions | `cache-redis-reviewer` | `cache-redis-rule.md` |
  | PostgreSQL · Doctrine | `database-postgresql-reviewer` | `database-postgresql-rule.md` |
  | Nginx | `server-nginx-reviewer` | `server-nginx-rule.md` |
  | GCP Cloud Run | `tools-gcp-cloudrun-reviewer` | `tools-gcp-cloudrun-rule.md` |
  | AWS ECS | `tools-aws-ecs-reviewer` | `tools-aws-ecs-rule.md` |

- **A new agent matching a prefix but absent from the table** — spawn it only once its governing rule
  (SoT) is confirmed. If it cannot be confirmed, **do not assign a SoT arbitrarily**; report it as
  "routing unmatched".
- **An agent in the table that does not resolve** — not a re-spawn candidate. State it as
  **"cannot judge (target absent)"**, name the path you expected, and suspend go/no-go.
- **Self and sibling orchestrators fall out at the glob level** — `tools-agent-team` begins with
  `tools-` but matches neither `tools-aws-` nor `tools-gcp-`. Never widen the prefix to a bare `tools-`.
- **Never direct-spawn `app-*`, `api-platform-*`, `message-*` or `utility-*`.** In particular,
  **`message-rabbitmq-reviewer` is not in this roster** — it matches none of the five prefixes, so
  Messenger and RabbitMQ verdicts are pointed at `app-agent-team`'s `/message-rabbitmq-review` command.

## Invariant — this is a single-role (Review) team

Every roster member is a **reviewer**: `model: sonnet`, `maxTurns: 30`, `memory: project`,
`disallowedTools: Edit, Write`, and **no `isolation` key**. There is no author, debugger or tester
axis. This team therefore does **not**:

- **Run an author→reviewer verification loop** — there is no generation axis. When a configuration
  needs fixing, issue the verdict only and hand the fix to the user or `app-agent-team`.
- **Run a REDO retry cycle** — a verdict is issued once; re-spawning happens only in partial-failure
  handling.
- **Write tests.**
- This is the basis for `maxTurns: 40`, below the siblings' **50** `[Verified]` 2026-08-30 — one
  fan-out plus consolidation is the whole budget.

> **Two frontmatter facts a review must not get backwards.** `[Verified]` 2026-08-30
> [Read: .claude/agents/*-reviewer.md]:
>
> - **Read-only is harness-enforced.** `memory: project` auto-grants `Write` and `Edit`, but each of
>   the five declares `disallowedTools: Edit, Write`, which reverses the grant per tool. Do not
>   instruct one to edit a configuration, and do not describe the boundary as prose-only. They retain
>   `Bash`, so that portion is still self-held.
> - **The tool lists are not uniform.** `cache-redis-reviewer` and `database-postgresql-reviewer`
>   carry `Read, Grep, Glob, Bash, WebFetch, WebSearch`; the other three carry
>   `Read, Grep, Glob, Bash`. Do not assert a single shared list.

## Invariant — over-match suppression (this team's most common misjudgement)

**The authoritative globs belong to the rule files.** This rule states the shape of each collision and
the decision it forces; when a call is close, `Read` the rule's `paths` and decide against the
resolved list rather than against any list recited from memory.

1. **cache ↔ database, at the repository layer.** `cache-redis-rule.md` reaches past the two cache
   YAML files into service- and repository-layer PHP, overlapping `database-postgresql-rule.md`, so a
   single Repository change can select both reviewers. **When a PHP change is unrelated to caching,
   locking, sessions or the Messenger transport, do not spawn** the cache reviewer. If already
   spawned, **remove** the unrelated findings during consolidation (remove, not merge).
   > Do not widen this into a blanket `app/src/**/*.php` — `[Verified]` 2026-08-30,
   > `cache-redis-rule.md` does **not** declare that glob, and an earlier revision of this rule
   > wrongly asserted it did.
2. **GCP ↔ AWS, on the shared container and Terraform assets.** The collision lives in the deploy
   gate's routing table (`tools-app-deploy-skill/SKILL.md:42-43`), **not** in `tools-aws-ecs-rule.md`,
   whose own `paths` are narrower. Either way, **fix the deploy target first and spawn one side only**.
   Ask once when unclear — spawning both is the last resort, and then duplicate merging is mandatory.
3. **database ↔ `app-php-symfony-05-doctrine-rule.md` on the same paths.** This team judges **mapping,
   queries, indexes and migrations only** — when a domain-logic or service-wiring finding comes back,
   mark it as `app-agent-team`'s and merge.

## Invariant — scope boundary and handoffs

- **Application PHP, JS, Twig · `Service/Providers/**` · shell · diagrams · commits · `.claude`
  configuration** are not handled here → `app-agent-team`.
- **`ApiResource` · `State` · `api_platform.yaml`** are not handled here → `api-agent-team`.
- **Even when reading `Entity` and `Repository`, the verdict scope is mapping, queries, indexes and
  migrations**; that class's domain logic belongs to `app-agent-team`.
- **Never drop a routing-unmatched file silently** — state its path verbatim under `## Summary` in the
  consolidated report. A file handed to another team is a **handoff**, not an unmatched file.

## Invariant — this team does not own deploy go/no-go

- **Once an intent along the lines of "is it safe to deploy" is confirmed, do not spawn the reviewers
  directly — delegate to the `tools-app-deploy-skill` gate with the `Skill` tool.** Spawning the three
  here splits the verdict and makes go/no-go ownership ambiguous.
- **A single-domain review request** ("just look at the nginx config") skips the gate and spawns that
  reviewer directly.
- **The roster constraint applies only to direct `Agent` calls.** The fan-out the gate skill runs
  internally is owned by that skill and is not a leak in the roster. Do not take the gate's report
  apart and re-merge it.
- **This team's go/no-go is an infrastructure configuration quality verdict, not deployment approval.**
  Do not conflate them.
- **Never execute a deployment, traffic shift or rollback** — those belong to
  `tools-gcp-cloudrun-skill` and `tools-aws-ecs-skill`, and being destructive they require user
  approval first.

## Invariant — safety boundary and artifacts

- **The orchestrator never modifies configuration or code directly.** `disallowedTools: Edit` enforces
  the no-modification half at the harness level; writes are confined to `./.claude/tmp/**`. Note that
  `Bash` is unrestricted and can write (redirection, `tee`, `sed -i`, `git apply`) — the same boundary
  covers all of those.
- **Migrations are read and judged only** — never run `doctrine:migrations:migrate`. It is a schema
  change that is hard to reverse.
- **Never run `terraform apply` or a production deployment.**
- Never include a secret, credential or connection-string value in plaintext in any output —
  infrastructure configuration is the layer most likely to carry one. Record the type and `file:line`
  instead of the value, and raise it as a `[MUST]`.
- **Pass the governing rules per domain, never mixed** — handing the cache reviewer the ECS rule makes
  it judge against criteria that are not its own.
- **The consolidated report is returned in the response; the tmp copy is best-effort.** The path,
  when it is written at all, is fixed at `./.claude/tmp/tools/agent-team-report.md`. A `Write` there is
  **denied while the session is in plan mode** (`permissions.defaultMode: "plan"`, inherited because the
  orchestrator declares no `permissionMode`), and nothing in this repository reads the file — so a
  refused write is a non-event, must not be retried or worked around with `Bash`, and must never be
  reported as persisted. There is
  **no per-domain artifact path**: the five reviewers cannot write, so their findings arrive in the
  returned report. Never overwrite `tmp/app/**` or `tmp/api/**`.

## Violation Severity

- **`[MUST]`** — skipping preflight; direct-spawning outside the resolved set (especially
  `message-rabbitmq-reviewer`); the three teams spawning one another; direct-spawning reviewers on a
  deploy intent; spawning both GCP and AWS without fixing the target and then failing to merge;
  granting the orchestrator `isolation: worktree`; trespassing on another team's tmp path; a missing
  spawn-payload field; **assigning a tmp path to a reviewer that declares `disallowedTools: Write`**;
  mixing domain rules in one payload; tallying unchecked as passed; issuing go while an axis is
  unjudged; failing to report a routing-unmatched file; running a migration or `terraform apply`;
  exposing a secret.
- **`[SHOULD]`** — failing to remove cache over-match findings; failing to merge doctrine↔postgresql
  duplicates; serialising reviewers that could run in parallel; failing to name the handoff team.
- **`[CONSIDER]`** — improvements that carry a structural change, such as widening the role axis
  (adding an author or tester) or creating dedicated review commands. Never apply without approval.

## Companion Updates

- `.claude/agents/tools-agent-team.md` — execution directives (preflight procedure · roster table · checklist)
- `.claude/agent-memory/tools-agent-team/MEMORY.md` — the always-loaded context summary
- `.claude/docs/tools-agent-team-docs.md` — background · inventory · trade-offs
- The sibling teams' rules, agents and memory (`app-agent-team`, `api-agent-team`) — a boundary is described from both sides
- `.claude/skills/tools-app-deploy-skill/SKILL.md` — whenever the reviewers the gate calls change
- `.claude/workflows/README.md` — per-role entry points
