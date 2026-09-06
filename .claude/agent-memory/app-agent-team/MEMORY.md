# app-agent-team memory

> Re-split on 2026-08-28 from the single `agent-team` orchestrator back into `app-agent-team` and
> `api-agent-team`, restoring the pairing that existed before the 2026-08-16 merge. This file covers
> the **app domains plus the repository-wide domains**; the API Platform exposure layer moved to
> `agent-memory/api-agent-team/MEMORY.md`. The stale four-role quartet and the claim that no author
> agent exists were corrected in the same pass.

## Role (verified)

- Coordinator/dispatcher — routes, fans out, drives the Build loop, and consolidates; does **not**
  perform domain judgment itself (that belongs to the sub-agents).
- **App family — 15 agents:** `app-{php-symfony,javascript-stimulus,twig-symfony}-{author,analyzer,debugger,reviewer,tester}`
  — 3 domains × 5 workflow roles.
- **The roster is closed (2026-08-29).** Those 15 are the **only** permitted `Agent` targets. Spawning
  an infrastructure reviewer (`database-postgresql`, `cache-redis`, `message-rabbitmq`, `server-nginx`,
  `tools-gcp-cloudrun`, `tools-aws-ecs`) or any `api-platform-*` agent is a role violation.
- **Also directs, via skills and commands only:** the `tools-app-deploy-skill` pre-deploy gate (which
  spawns the nginx/GCP/ECS reviewers itself — calling a skill is always permitted), the
  `utility-git-commit-skill` commit workflow, and the (unimplemented) provider routes.
- **Infrastructure and data → refer, do not judge.** Name `/database-postgresql-review`,
  `/cache-redis-review` or `/message-rabbitmq-review` in `## Handoffs` and state the layer was **not
  reviewed**. There is no `/tools-gcp-cloudrun-review` or `/tools-aws-ecs-review` — those two reach
  only through the deploy gate. `[Verified]` 2026-08-29
- Agents resolve by frontmatter `name`, not filename.

## Corrections carried forward (do not regress)

- **The `*-analyzer` agents are the Security axis, not Analyze.** Repurposed 2026-08-22 — they diagnose
  vulnerabilities (missing authorization, injection, sensitive data exposure, DOM XSS, `|raw`, missing
  CSRF), not structural health. Structural design and refactoring go to `*-author`; rule-compliance
  verdicts to `*-reviewer`.
- **The 3 app-domain `*-author` agents exist** (filled in 2026-08-22). The earlier note that "no author
  agent exists in any code domain" is false and has been removed.
- **The infrastructure domains have only a Review axis.** There is no `cache-redis-analyzer`,
  `server-nginx-debugger`, etc. — preflight will fail. Their security verdicts come from the domain
  reviewer covering the `## Security` section of its own rule.
- **Retry limit is 3** for the code domains (2 for config/meta domains such as commit and diagram).

## Routing constants

- **Exposure layer → `api-agent-team`.** `app/src/ApiResource/**`, `app/src/State/**`,
  `config/{packages,routes}/api_platform.yaml`, and any "add a resource / expose an operation /
  endpoint returns 404" intent. **Do not route these to `app-php-symfony-*` because the file is `.php`.**
  On a mixed diff, split it and say so in `## Handoffs`.
- **Domain axis (by path):** `app/src/**/*.php` (outside the two exposure namespaces) →
  `app-php-symfony-*`; `app/assets/**/*.js` → `app-javascript-stimulus-*`; `app/templates/**/*.twig` →
  `app-twig-symfony-*`.
- **Role axis (by intent):** generate/modify/refactor → `-author`; security or vulnerability diagnosis
  → `-analyzer`; bug/root cause → `-debugger`; quality gate → `-reviewer`; regression tests or TDD →
  `-tester`. Resolved cell = domain family + role suffix.
- **Fan out** on a multi-domain change (a page touching `.php` + `.twig` + `.js` → three agents of the
  same role, invoked in parallel in one turn). Cap at 6 spawns per batch.
- **Deploy assets** (`scripts/**/nginx/**`, `scripts/containers/prod/**`, `*.tf`, `Dockerfile`,
  `taskdef*.json`, `scripts/**/*.sh`) → delegate to `tools-app-deploy-skill`, never spawn the
  infrastructure reviewers directly. The gate returns go/no-go; the actual rollout belongs to
  `tools-gcp-cloudrun-skill` / `tools-aws-ecs-skill` and needs user approval.
- **Provider paths** (`app/src/**/Providers/Finance/**`) → report as **unroutable**, naming the expected
  `*-build-skill`. `[Verified]` 2026-08-24: `.claude/rules/api/`, `.claude/commands/api/providers/` and
  the five `api-providers-*-build-skill` directories do **not** exist. Never silently redirect to
  `app-php-symfony-reviewer`. Despite their `api` prefix these are **outbound** clients and are **not**
  `api-agent-team`'s — that orchestrator covers only our own exposed API.

## Build verification loop (app domains)

- `author → reviewer → PASS/REDO`, spawned **sequentially**. **Paste the author's full unified diff
  inline** into the reviewer prompt: all 15 app agents are `isolation: worktree`, so a reviewer told to
  run `git diff` sees an empty diff and returns a false clean pass.
- On REDO re-invoke the author with **only the `[MUST]` items**; retry limit 3, then stop **without
  reverting the source** and recommend manual review.
- **`exit 0` from a `PostToolUse` hook does not mean "passed".** All four (`php-lint.sh`,
  `php-cs-fixer.sh`, `twig-lint.sh`, `js-guard.sh`) are non-blocking and skip silently via
  `[ -d app/vendor ] || exit 0`. `app/vendor` is currently absent, so only `php -l` and `js-guard.sh`
  really run — relay any skipped gate as **"unchecked"**, never as a pass.

## Isolation constraint (the failure mode that bites)

`[Verified]` 2026-08-30 — of 33 agents, 19 set `isolation: worktree` and 14 do not. **All 15 app-domain
agents are isolated.** The 14 non-isolated are the 3 orchestrators + 4 `utility-*` (tmp-writers) and
`api-platform-reviewer` + the 6 infrastructure reviewers (read-only, `disallowedTools: Edit, Write`).

- Never assign a tmp output path to an isolated agent — `.claude/tmp/` is gitignored and therefore
  absent from every worktree.
- Never assign a tmp path to an analyzer or reviewer at all. Ask for findings **in the returned report**.

## Hand-off flows

- `author/debugger → reviewer (quality gate) → tester (regression)`.
- `analyzer (security) → author (fix) → reviewer → tester`.
- `debugger → author` when structural debt is the cause; `analyzer → debugger` when a runtime failure
  surfaces; `reviewer/debugger → analyzer` when a security vulnerability surfaces.
- Do not chain past the user's intent — chain only when the sub-agent's result calls for it.

## Consolidation & dedupe

- Merge findings grouped by domain then severity; keep `[MUST]/[SHOULD]/[CONSIDER]`; **only `[MUST]`
  blocks the merge**.
- `app-php-symfony-05-doctrine-rule.md` ↔ `database-postgresql-rule.md` cover the same paths
  (`Entity`, `Repository`) → collapse identical findings into one.
- **The Redis rule's `paths` are `cache.yaml`, `lock.yaml`, `app/src/Service/**`,
  `app/src/EntityRepository/**`, `app/src/Repository/**`, `app/src/MessageQueryHandler/**` — *not*
  `app/src/**/*.php`** (a long-standing error in this file, corrected against the real rule). They are
  still broad enough that many PHP changes match; when a change is unrelated to caching, locking,
  sessions or the Messenger transport, either skip the Redis reviewer or filter its findings out.
- Deploy assets are already de-duplicated inside the gate (a `Dockerfile` matches both GCP and AWS) —
  do not split the gate report apart and re-merge it.
- Report which agents ran and how many loop iterations occurred, so routing is auditable.
- **Never report an unrun branch as clean** — "did not run" and "no findings" are different verdicts.

## Team collaboration (hand-off)

- Role: repository-wide orchestrator · downstream: the 15 `app-*` sub-agents (the **only** spawn
  targets) plus the deploy/commit/diagram skills. The 6 infrastructure reviewers are **referred or
  gated, never spawned**.
- Sibling: `api-agent-team` owns the 5 `api-platform-*` agents and the exposure layer.
- **Two concerns stay shared and this agent keeps its half:** the domain logic a State delegates to
  (`app/src/Service/**`, `app/src/Repository/**`), and the Symfony security configuration behind an API
  resource (`app-php-symfony-08-security-rule.md` is SoT for firewalls, Voters, `stateless` tokens and
  the rate limiter).

## SoT

- `.claude/docs/app-agent-team-docs.md` (repository-wide team composition & workflow-role axis)
- `.claude/rules/abstract-structure-rule.md` (rule index & path context)
- `.claude/skills/tools-app-deploy-skill/SKILL.md` (pre-deploy gate fan-out)
- `.claude/skills/utility-git-commit-skill/SKILL.md` (author→reviewer loop reference standard)
