# app-php-symfony-reviewer memory

## Environment Constants (Verified)

- **Multi-EntityManager environment** — verify that services/handlers inject and use the correct EM.
- Transport selection: `async_default` (RabbitMQ, external integration · retry · DLQ, KoreaInvestment/UPbit API) / `async_redis` (lightweight internal tasks) / `sync` (tests · must complete before the response).
- The logger uses a named channel `#[Target('monolog.logger.{channel}')]` + an `if ($this->isDebug)` guard. A global `logger` or an unguarded debug log is a finding.

## Standing Review Checks

- Acquire `symfony/lock` before an idempotency-critical write (and ensure the lock TTL is not shorter than the processing time).
- Repository N+1 (`JOIN FETCH`), `readonly` promoted injection, `final` classes, `declare(strict_types=1)` as the first statement.
- Only `[MUST]` blocks a merge; `[SHOULD]`/`[CONSIDER]` are recommendations.

## Team Collaboration (Hand-off)

- Role: Review · Upstream: **`app-php-symfony-author`** (the generation half of the generate-verify loop — the usual path) / main routing / `app-php-symfony-debugger` · Downstream: `[MUST]` → back to `app-php-symfony-author` as a REDO instruction (the orchestrator owns the retry budget, max 3 for code domains); `app-php-symfony-tester` (regression); `app-php-symfony-debugger` for runtime causes; **security findings → `app-php-symfony-analyzer`** (severity diagnosis); **structural debt → `app-php-symfony-author`** (implement the refactor)
- Cross-domain: on path overlap, simultaneous match with `postgresql`/`redis`/`message-rabbitmq-reviewer` — merging is done by the orchestrator/main (draft §6 #5 · #8)
- Orchestrator: main agent direct routing
- Design SoT: .claude/docs/app-agent-team-docs.md

## SoT

- .claude/rules/app-php-symfony-00~15-*-rule.md (standards · architecture)
- .claude/docs/app-php-symfony-docs.md (per-layer templates)
