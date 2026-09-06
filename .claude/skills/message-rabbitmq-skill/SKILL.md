---
name: message-rabbitmq-skill
description: 'Use when creating a Symfony Messenger message/handler, configuring an async RabbitMQ (AMQP) transport, routing messages, setting a retry strategy or failure transport (DLQ), making a handler idempotent, or operating messenger workers. Triggered by questions about MessageBusInterface, #[AsMessageHandler], messenger.yaml, MESSENGER_TRANSPORT_DSN_AMQP, retry_strategy, failure_transport, messenger:consume, messenger:failed, or the async transport strategy.'
---

# RabbitMQ / Messenger Skill

This is the entry point for implementing and reviewing this project's RabbitMQ / Symfony Messenger work.

## Information Source (single source of truth: the rule file)

**All detailed criteria** — transport naming, routing patterns, retry/DLQ strategy, idempotency and
lock usage, worker operation — are in the rule file. This skill does not duplicate the rules; it only
provides the work procedure and verification methods.

@see .claude/rules/message-rabbitmq-rule.md — full transport/routing/retry/idempotency/worker standards (SoT)
@see .claude/rules/cache-redis-rule.md — paired transport rule (Redis = sync only) & lock stores
@see https://symfony.com/doc/current/messenger.html

Source of truth (configuration): `app/config/packages/messenger.yaml`, `app/config/services.yaml`,
and the message/handler classes under `app/src/`.

## Work Procedure

1. **Define the message** → `final readonly` DTO with scalar/serializable properties only. No Doctrine entity in the payload — carry an id.
2. **Write the handler** → one dedicated `#[AsMessageHandler]` class; make `__invoke()` idempotent and re-entrant.
3. **Select/declare the transport** → async work → `async` or `async_providers_{provider_path}` (AMQP DSN `%env(MESSENGER_TRANSPORT_DSN_AMQP)%`). Never route async to the Redis transport.
4. **Route explicitly** → add the message class to the `routing:` map (exactly one transport). Configure a bounded `retry_strategy` and the shared `failed` failure transport.
5. **Guard side effects** → wrap non-idempotent work in `#[Target('{domain}.lock')]` keyed on a stable business identifier; throw `UnrecoverableMessageHandlingException` for permanent failures.

## Verification (Bash)

```bash
# Message → handler mappings across buses
cd app && php bin/console debug:messenger

# Queued message count per transport
cd app && php bin/console messenger:stats

# Declare exchanges/queues (deploy-time; do not rely on auto-setup)
cd app && php bin/console messenger:setup-transports

# Process one message with a full trace (safe to test a single delivery)
cd app && php bin/console messenger:consume async -vv --limit=1

# Inspect the dead-letter queue
cd app && php bin/console messenger:failed:show
```

## Checklist (common to implementation & review)

- [ ] Is the message a `final readonly` serializable DTO with no Doctrine entity in the payload?
- [ ] Is there exactly one dedicated `#[AsMessageHandler]` and is the handler idempotent?
- [ ] Is the AMQP DSN injected via `%env(MESSENGER_TRANSPORT_DSN_AMQP)%` (never hardcoded)?
- [ ] Is every message routed explicitly to exactly one transport (no unrouted messages)?
- [ ] Does the async transport have a bounded `retry_strategy` and a `failed` failure transport?
- [ ] Are non-idempotent side effects guarded by `#[Target('{domain}.lock')]` on a stable key?
- [ ] Did you avoid routing async work to the Redis (`sync_*`) transport?
- [ ] Are workers bounded (`--time-limit` / `--memory-limit`) and stopped gracefully on deploy?

When a review is requested, report severity as MUST (critical) / SHOULD (recommended) / CONSIDER (optional).
