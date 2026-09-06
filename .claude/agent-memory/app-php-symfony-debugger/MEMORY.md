# app-php-symfony-debugger memory

## Environment constants (verified)

- **Multi-EntityManager environment** — a common cause of "not persisted" / "migration missing" is the wrong `--em=` target. Establish which EM first when diagnosing.
- Three transports: `async_default` (RabbitMQ, external integration/retry/DLQ) / `async_redis` (lightweight internal tasks) / `sync` (tests, or immediate completion required).
- Logger uses a named channel `#[Target('monolog.logger.{channel}')]`; logs go to `var/log/{channel}.log`. Using the global `logger` is an anti-pattern.

## Diagnostic principles

- Validate DB/migration problems against the **actual PostgreSQL state** — do not conclude from a mocked state (past: mocked tests passed but the real migration failed).
- Frequent root causes: MessageHandler not running (transport routing / `#[AsMessageHandler]` missing), duplicate processing (`symfony/lock` not applied at an idempotency point), N+1 (`JOIN FETCH` missing), a market-time guard living in the Scheduler (→ it should be in the Handler).

## SoT

- .claude/rules/app-php-symfony-01-architecture-rule.md, 04-service-rule.md, 05-doctrine-rule.md
- .claude/rules/cache-redis-rule.md (cache invalidation & locks)
