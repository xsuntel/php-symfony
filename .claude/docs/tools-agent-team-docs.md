# Tools Agent Team Composition

> Status: **Design document (background and rationale)** — it defines the structure that binds this
> repository's **infrastructure, data and deployment asset** verdicts into a single orchestrator, and
> the rationale behind `tools-agent-team`'s roster, routing and fan-out.
>
> **It is not a verdict SoT.** Per `## Docs Layout` in `utility-claude-code-rule.md`, everything under
> `.claude/docs/**` is always a reference, and where it conflicts with a rule the rule wins. The
> verdict SoTs paired with this document are **`rules/tools-agent-team-rule.md`** (orchestration
> invariants) and the **five domain rules** (code and configuration verdicts).
>
> Written: 2026-08-30
>
> **Created 2026-08-30 — this document reverses an earlier decision.** When the team was created on
> 2026-08-29 the call was that "a Review-only team has no role-axis design, so it needs no paired
> document", and `abstract-orchestrator-contract-docs.md` doubled as its design SoT. The grounds for
> reversing that are in §5.3.

@see .claude/agents/tools-agent-team.md — the orchestrator this document is paired with (execution directives)
@see .claude/rules/tools-agent-team-rule.md — orchestration invariants (verdict SoT)
@see .claude/docs/app-agent-team-docs.md — application and operations axis design (SoT)
@see .claude/docs/api-agent-team-docs.md — API Platform exposure layer axis design (SoT)
@see .claude/docs/abstract-orchestrator-contract-docs.md — rationale and measured values for the contract all three teams share
@see .claude/skills/tools-app-deploy-skill/SKILL.md — the pre-deploy gate (owner of go/no-go)
@see .claude/rules/abstract-structure-rule.md — rule index (SoT)
@see .claude/output-styles/abstract-english-style.md — document style (ADR · trade-offs · citation)

---

## 1. Overview and Premises

### Purpose

This document defines the composition that binds the five reviewers responsible for **infrastructure
configuration, data mapping and deployment assets** into one orchestrator. Unlike its two sibling
documents it has **only one role axis**, so the team definition is short; the space goes instead to
**how the roster is resolved** and to **over-match suppression**, because those two are where this
team actually fails.

**Out of scope:** application code (PHP, JS, Twig), external provider consumption, shell, diagrams,
commits and `.claude` configuration belong to `app-agent-team`; the API Platform exposure layer
belongs to `api-agent-team`.

### Verified premises

`[Verified]` 2026-08-30, measured against `.claude/**`:

| Item | Value | Evidence |
| --- | --- | --- |
| Orchestrators in the repository | **3** | `agents/{app,api,tools}-agent-team.md` |
| This team's resolved roster | **5** | `ls .claude/agents/{cache,database,server,tools-aws,tools-gcp}-*.md` |
| Roster common spec | `model: sonnet` · `maxTurns: 30` · `memory: project` · `disallowedTools: Edit, Write` · **no `isolation`** · **no `color`** | each `*-reviewer.md` frontmatter |
| Roster tool lists (**not uniform**) | `cache-redis-reviewer` and `database-postgresql-reviewer`: `Read, Grep, Glob, Bash, WebFetch, WebSearch` · the other three: `Read, Grep, Glob, Bash` | same |
| Orchestrator spec | `model: opus` · `maxTurns: 40` · `tools: Agent, Bash, Read, Grep, Glob, Write, Skill` · `disallowedTools: Edit` | `agents/tools-agent-team.md` |
| Dedicated review commands | **3** (`/cache-redis-review` · `/database-postgresql-review` · `/server-nginx-review`) | `commands/` |
| Axes with **no** dedicated command | GCP Cloud Run · AWS ECS | same location |

> **Two corrections to an earlier draft of this table.** It claimed the five share `color: blue` and a
> uniform `tools: Read, Grep, Glob, Bash`. `[Verified]` 2026-08-30 — **none of the five declares
> `color` at all**, and the two data-domain reviewers additionally carry `WebFetch, WebSearch`. Do not
> restore either claim.

**`maxTurns: 40` is below the siblings' 50** — not half of 80, which an earlier draft asserted;
`app-agent-team` and `api-agent-team` both set 50. `[Verified]` 2026-08-30. One fan-out plus
consolidation, with no author→reviewer loop to fund, is why this team needs less.

### The three-layer collaboration principle

Applying the repository-wide structure to this team:

```text
orchestrator (agents/tools-agent-team.md)  = owns routing, fan-out and consolidation only. Holds no criteria
reviewers    (agents/{the 5}.md)           = cross-check their own domain rule (SoT) and issue a verdict
rules        (rules/{the 5}-rule.md)       = the single source of the criteria
```

**The orchestrator holding no criteria is the point.** Copy the criteria here and there are two
copies; fix only the rule and they diverge silently.

---

## 2. Agent Inventory

### 2.1 The roster (five prefixes)

| Domain | Reviewer | Governing rule (SoT) | Principal target paths |
| --- | --- | --- | --- |
| Redis · cache · locks · sessions | `cache-redis-reviewer` | `cache-redis-rule.md` | `app/config/packages/{cache,lock}.yaml` · PHP **actually related to** caching |
| PostgreSQL · Doctrine | `database-postgresql-reviewer` | `database-postgresql-rule.md` | `app/src/{Entity,EntityRepository,Repository}/**/*.php` · `app/migrations/**` |
| Nginx | `server-nginx-reviewer` | `server-nginx-rule.md` | `scripts/**/nginx/**` |
| GCP Cloud Run | `tools-gcp-cloudrun-reviewer` | `tools-gcp-cloudrun-rule.md` | `scripts/deploy/prod/gcp/**` · `scripts/containers/prod/**` · `**/*.tf` · `**/cloudbuild.yaml` · `**/Dockerfile` |
| AWS ECS | `tools-aws-ecs-reviewer` | `tools-aws-ecs-rule.md` | `scripts/deploy/prod/aws/**` · `**/taskdef*.json` · `**/buildspec.yml` |

**The roster is defined by the five prefixes, not by this table** — the table is the preflight
resolution as of 2026-08-30. The verdict convention is owned by
`## Invariant — the roster is fixed by preflight` in `rules/tools-agent-team-rule.md` (SoT).

> **Read the rule's `paths` rather than this column when a call is close.** The paths above are a
> working map. `tools-aws-ecs-rule.md` in particular declares a **narrower** `paths` than the shared
> container and Terraform assets suggest — those reach ECS through the deploy gate's routing table
> (`tools-app-deploy-skill/SKILL.md:42-43`), not through the rule.

### 2.2 What is not in the roster (the two easy mistakes)

- **`message-rabbitmq-reviewer`** — a real sixth infrastructure reviewer in this repository, but it
  matches none of the five prefixes. Messenger and RabbitMQ verdicts belong to `app-agent-team`'s
  `/message-rabbitmq-review` command. **Do not pull it in because the name looks similar.**
- **A shell-script reviewer** — the agent **does not exist** (merged into a command on 2026-08-16).
  `/utility-shell-script-review` holds both the existing-file review and the draft self-verification
  criteria.

### 2.3 Model and tool axes

- **All five are `sonnet` and read-only.** Infrastructure verdicts are mostly rule cross-checking, so
  no higher model is warranted; only the orchestrator runs `opus`, for routing and consolidation.
- **Read-only IS enforced by the harness here.** `memory: project` auto-grants `Read`, `Write` and
  `Edit` `[Verified]` 2026-08-30 [WebFetch: <https://code.claude.com/docs/en/subagents>], but each of
  the five declares `disallowedTools: Edit, Write`, and **`disallowedTools` reverses the auto-grant
  per tool**. They retain `Bash`, so that part of the boundary is still self-held.

  > **This corrects an earlier draft**, which said the read-only boundary was *not* harness-enforced
  > and that a review should therefore not flag a write. The opposite is true, and it has a direct
  > operational consequence — see §4.4.

---

## 3. Team Definition — Review Only

### 3.1 The Review team (the whole team)

- **Trigger:** after an infrastructure, data or deployment asset change, or an intent such as "infra
  check", "cache review", "check the Doctrine mapping", "review the nginx config", "look at the Cloud
  Run setup", "review the ECS taskdef".
- **Entry point:** the `tools-agent-team` orchestrator (multi-domain), or the matching `/…-review`
  command (single domain).
- **Procedure:** preflight → scope filtering → routing (with over-match suppression) → parallel
  fan-out → duplicate merging → consolidated report.
- **Output:** a `[MUST]`/`[SHOULD]`/`[CONSIDER]` severity report. Only `[MUST]` blocks a merge.

### 3.2 The missing axes and what follows

| Axis | Status | Alternative route |
| --- | --- | --- |
| **Build** (generation) | none | issue the verdict only; fixes go to the user or `app-agent-team` (PHP, shell) |
| **Security** (diagnosis) | none | each domain rule's security section is judged inside Review |
| **Debug** (root cause) | none | `app-php-symfony-debugger` (runtime) · the relevant deploy skill (operations) |
| **Test** (regression) | none | the infrastructure domains have no tester axis |

**So this team runs neither an author→reviewer loop nor a REDO retry cycle.** A verdict is issued
once, and re-spawning happens only in partial-failure handling.

### 3.3 Deploy — a role this team does not own

Deploy go/no-go is **owned by the `tools-app-deploy-skill` gate**. That skill runs its **own fan-out**
across three of this roster (`server-nginx-reviewer`, `tools-gcp-cloudrun-reviewer`,
`tools-aws-ecs-reviewer`) plus the `/utility-shell-script-review` command, and returns PASS/BLOCK.

```text
"is it safe to deploy"   → delegate to tools-app-deploy-skill with the Skill tool (never spawn the reviewers directly)
"just look at nginx"     → spawn server-nginx-reviewer directly
"review the Cloud Run setup" → spawn tools-gcp-cloudrun-reviewer directly (outside deployment scope)
```

**Do not conflate the two go/no-go verdicts** — this team's is **infrastructure configuration
quality**; the gate's PASS/BLOCK is **deployment approval**.

---

## 4. Orchestration Reference Patterns

### 4.1 One fan-out plus consolidation (no loop)

```text
0. Roster preflight — resolve the five prefixes → fix the permitted spawn set
1-3. Fix scope → filter (split off handoffs) → route (apply over-match suppression first)
4. Plan spawns   — the resolved reviewers have no interdependencies, so all are parallel (max 5)
5. Delegate      — the seven-field spawn payload
6. Consolidate   — collapse duplicates to one entry, sort by severity
7. Verdict       — 1+ [MUST] → no-go / 0 → go / any unjudged axis → suspended
```

Five is within the sibling teams' "6 or fewer at a time" fan-out bound, so **no batching is needed**.

### 4.2 Why preflight is step 0

This is §8 of the operational contract (a routing target is unverified until checked) applied to this
team. Fixing the roster in prose memory lets the agent file go stale ahead of the tree, and that drift
is **silent** — either a spawn fails against an agent that no longer exists, or a newly added reviewer
is never called. Resolving the prefixes surfaces both.

### 4.3 Merging duplicate findings (3 cases)

| Collision | Handling |
| --- | --- |
| `cache-redis-rule.md`'s `paths` reach service- and repository-layer PHP, overlapping `database-postgresql-rule.md` | If the change is unrelated to caching, locking, sessions or the transport, **do not spawn**. If already spawned, **remove** the unrelated findings (remove, not merge) |
| GCP and AWS share the container and Terraform assets **in the deploy gate's routing table** | **Fix the deploy target and spawn one side only.** If both had to run, collapse the same issue into one entry |
| `database-postgresql-rule.md` ↔ `app-php-symfony-05-doctrine-rule.md` on the same paths | This team judges mapping, queries and indexes only. Mark domain-logic findings as `app-agent-team`'s and merge |

> **An earlier draft asserted that `cache-redis-rule.md` declares `app/src/**/*.php`.** `[Verified]`
> 2026-08-30 — **it does not.** Its `paths` are the two cache YAML files plus `Service/**`,
> `EntityRepository/**`, `Repository/**` and `MessageQueryHandler/**`. That is still broad enough to
> over-match, so the handling is unchanged — but do not cite a glob the rule does not have, and read
> the rule rather than reciting the list from memory.

### 4.4 tmp artifact convention

| Purpose | Path |
| --- | --- |
| Consolidated report | `./.claude/tmp/tools/agent-team-report.md` |

**There is no per-domain artifact path, and this is a hard consequence of §2.3.** All five reviewers
declare `disallowedTools: Edit, Write`, so a reviewer handed `./.claude/tmp/tools/<domain>-review.md`
**fails at its final step**. Findings arrive **in the returned report**; only the orchestrator writes
to tmp.

Be precise about the reason, because two different mechanisms are easily conflated (contract §3): the
five are **not** worktree-isolated and therefore *do* share the working tree — what stops them writing
is `disallowedTools`, not isolation.

`tmp/app/**` belongs to `app-agent-team` and `tmp/api/**` to `api-agent-team`. Run `mkdir -p` on the
full parent chain first; `settings.json` denies `Bash(rm:*)`, so cleanup is left to
`cleanupPeriodDays` and `.gitignore`.

---

## 5. Trade-offs

### 5.1 Splitting off a third orchestrator (2026-08-29)

#### Context

At the 2026-08-28 split there were two orchestrators, and `app-agent-team` spawned the six
infrastructure and data reviewers directly (a roster of 21). One team was therefore directing **two
axes of different character** — the application generate-verify loop (5 roles × 3 domains) and a
loop-free, single-shot infrastructure verdict. With spawn targets split between `app-*` and the
infrastructure prefixes, routing misjudgements were frequent and the fan-out width was hard to predict.

#### Decision

**Split the infrastructure, data and deployment axis into its own orchestrator.** Define its roster by
five prefixes (`cache-`, `database-`, `server-`, `tools-aws-`, `tools-gcp-`), and narrow
`app-agent-team`'s direct spawn set to the 15 `app-*-*` agents.

#### Consequences

- **Scalability** (+) each team's spawn targets converge on one prefix family, so fan-out width is
  determined by roster size. (−) with three orchestrators, the boundary description must be
  **maintained across three files together** — each rule's `## Companion updates` section manages that
  cost explicitly.
- **Maintainability** (+) there is now a single entry point for infrastructure verdicts. (−)
  `message-rabbitmq-reviewer` sits outside the prefixes, so **only five of the six moved** — an
  asymmetry where the infrastructure reviewers straddle two teams remains (§6.2).
- **Performance** (+) `maxTurns` was set to 40, below the siblings' 50, cutting the budget of an
  infrastructure invocation. (=) the reviewer specs are unchanged, so verdict latency is unaffected.

#### Rejected alternatives

- **Leave them in `app-agent-team`** — preserves the cause of the routing misjudgements.
- **Move all six and add `message-` to the prefixes** — the roster definition reverts to an enumerated
  "all the infrastructure reviewers", losing the self-verifying property of a prefix rule (§5.2).

### 5.2 Roster definition — prefix preflight vs. a fixed list (2026-08-30)

#### Context

At creation the roster constraint was **five fixed names embedded in prose**. The execution procedure
had no target-confirmation step, so it was not connected to §8 of the operational contract
(preflight), and the document went stale silently whenever the roster changed.

#### Decision

**Define the roster by five prefixes and resolve them with Glob at step 0 of every invocation.**
Demote the five-row table from grounds for a verdict to a point-in-time snapshot; when the resolution
and the table disagree, **the resolution wins**.

#### Consequences

- (+) a reviewer added under the same prefix is **enrolled automatically**, and one that disappears
  surfaces as "cannot judge (target absent)". Neither passes silently.
- (+) excluding self and siblings **holds at the glob level** — `tools-agent-team` starts with
  `tools-` but matches neither `tools-aws-` nor `tools-gcp-`, so no separate exception clause is needed.
- (−) a newly matching agent **may have no governing rule (SoT)**. Assigning one arbitrarily would
  judge against criteria that are not its own, so spawn only once the rule is confirmed and otherwise
  report "routing unmatched".
- (−) it costs one file lookup per invocation — a single `ls`, which is negligible.

#### Relationship to harness enforcement

This constraint is **documentary; the harness does not enforce it.** A `PreToolUse` hook payload does
carry `agent_id` and `agent_type`, so identifying the caller is possible `[Verified]`
[WebFetch: <https://code.claude.com/docs/en/hooks>], but the documentation does not state whether the
spawn tool name is `Task` or `Agent`, so matcher design must be preceded by measurement
`[Uncertain]`. This is the follow-up in §6.3.

### 5.3 Creating the paired document — reversing an earlier decision (2026-08-30)

#### Context

At creation the call was that "a Review-only team has no role-axis design", so no paired document was
created and `abstract-orchestrator-contract-docs.md` doubled as the design SoT. That decision was
recorded as an explicit exception in four places: `abstract-structure-rule.md`,
`workflows/README.md`, `app-agent-team-docs.md` and the operational contract document.

#### Decision

**Create the paired document and restore symmetry across the three axes.** The operational contract
document goes back to holding **only what all three teams share**, and this team's own inventory,
trade-offs and gaps live here.

#### Consequences

- (+) the shared-slug convention (`agents/`, `rules/`, `docs/` carrying the same slug) now holds for
  all three teams, so every `@see` resolves without exception.
- (+) removing this team's specifics from the shared contract document sharpens its character as
  genuinely **common to three teams**.
- (−) one more document to maintain. The "no paired document" exception in the four files above had to
  be removed **in the same change** — leaving even one makes the descriptions diverge.

  > `[Verified]` 2026-08-30 — the `docs/` row of `CLAUDE.md` was the last holdout, still describing
  > this file as "a heading-only placeholder". It was corrected in the same change that created this
  > document. If a fifth such statement is found later, treat it as this consequence still being
  > settled, not as a new finding.

---

## 6. Current Gaps and Follow-ups

### 6.1 There are no dedicated GCP and AWS review commands

`/cache-redis-review`, `/database-postgresql-review` and `/server-nginx-review` exist; Cloud Run and
ECS do not have one. The only standalone entry points for those two axes are therefore **a direct
reviewer spawn or this orchestrator**, with the gate skill taking them when the scope is a deployment.
**Do not invent a command that does not exist.** Creating the two commands is a structural change, so
it is `[CONSIDER]` and requires approval.

### 6.2 The infrastructure reviewers straddle two teams

Only `message-rabbitmq-reviewer` falls outside the prefixes and remains `app-agent-team`'s. When a
user says "infra check", Messenger may therefore go unreviewed — so whenever that axis falls within
scope, this team must **state it as an explicit handoff** rather than dropping it silently.

### 6.3 The roster constraint is not harness-enforced

`tools: Agent` does not restrict spawn targets, so a roster violation depends on model compliance. A
`PreToolUse` hook (`.claude/hooks/pre-tool-use/` currently holds only `.gitkeep`) could block on
`agent_type`, but the spawn tool name must be settled first (§5.2). On adoption, update the
`## Currently active hooks` table in `.claude/hooks/README.md` and the `settings.json` wiring together.

### 6.4 Configuration verification skips silently when `app/vendor` is absent

The `bin/console`-based checks (`lint:yaml`, `lint:container`) depend on the vendor tree. When it is
absent or incomplete they break or are skipped, and **neither outcome means "the configuration is
fine"**. The consolidated report tallies these as **unchecked** and states the remedy
(`cd app && composer install`).

---

## Appendix: Reference Assets

| Type | Path |
| --- | --- |
| Orchestrator | `.claude/agents/tools-agent-team.md` |
| Orchestration verdict SoT | `.claude/rules/tools-agent-team-rule.md` |
| Agent memory | `.claude/agent-memory/tools-agent-team/MEMORY.md` |
| The 5 roster reviewers | `.claude/agents/{cache-redis,database-postgresql,server-nginx,tools-aws-ecs,tools-gcp-cloudrun}-reviewer.md` |
| The 5 domain verdict SoTs | `.claude/rules/{cache-redis,database-postgresql,server-nginx,tools-aws-ecs,tools-gcp-cloudrun}-rule.md` |
| Domain reference documents | `.claude/docs/{cache-redis,database-postgresql,server-nginx,tools-aws-ecs,tools-gcp-cloudrun}-docs.md` |
| The 3 standalone review commands | `.claude/commands/{cache-redis,database-postgresql,server-nginx}-review.md` |
| Deploy gate | `.claude/skills/tools-app-deploy-skill/SKILL.md` |
| Deploy execution skills | `.claude/skills/tools-{gcp-cloudrun,aws-ecs}-skill/SKILL.md` |
| Shared operational contract | `.claude/docs/abstract-orchestrator-contract-docs.md` |
| Sibling team designs | `.claude/docs/{app,api}-agent-team-docs.md` |
