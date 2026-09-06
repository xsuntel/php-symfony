---
paths:
  - "app/config/packages/messenger.yaml"
  - "app/src/Message*/**/*.php"
  - "app/src/Messenger/**/*.php"
  - "app/src/Scheduler/**/*.php"
---

# Message Rules

This rule is the judgment criteria (SoT) for RabbitMQ / Symfony Messenger usage. The detailed transport
configuration examples, routing tables, and handler snippets live in the docs.

@see .claude/docs/message-rabbitmq-docs.md — transport/DSN config, routing, retry/DLQ, worker examples
@see .claude/rules/cache-redis-rule.md — the paired transport rule (Redis = sync/in-process only)
@see https://symfony.com/doc/current/messenger.html — Symfony Messenger (official)

## General Rules

- Use `#[AsMessageHandler]` on a dedicated handler class per message — never handle a message inline in a controller or service.
- Keep messages as immutable, serializable DTOs: `final readonly class` with constructor-promoted, scalar/serializable properties only. Never put a Doctrine entity in a message payload — pass its identifier and re-fetch in the handler.
- RabbitMQ is the **primary transport for all asynchronous work**. The Redis transport is exclusively for synchronous, in-process handling — never route an asynchronous message to the Redis transport (see the paired Redis rule).
- Dispatch through `MessageBusInterface`; do not instantiate or call handlers directly.
- Every consumed message handler must be **idempotent** — a message may be redelivered after a retry or a worker crash.

## Transport & DSN

- Define the RabbitMQ (AMQP) transport DSN via the `%env(MESSENGER_TRANSPORT_DSN_AMQP)%` environment variable — mirror the Redis transport's `MESSENGER_TRANSPORT_DSN_REDIS` naming. Never hardcode an `amqp://` DSN with credentials in `messenger.yaml`; inject it from `.env.app` / `.env.local`.
- Name async transports `async_*` (parallel to the Redis `sync_*` transports); for provider integrations use `async_providers_{provider_path}`, matching the cache-pool / Redis-transport naming.
- Declare `exchange`, `queues`, and binding keys explicitly under the transport `options:` — do not rely on Messenger auto-setup in production. Run `messenger:setup-transports` at deploy time instead.
- Never bind Messenger's AMQP transport to the management port; use the AMQP protocol port only.

## Message Routing

@see https://symfony.com/doc/current/messenger.html#routing-messages-to-a-transport

- Route every message class explicitly in the `routing:` map to a named transport — do not leave a message unrouted (it would be handled synchronously and silently).
- Group routing by domain/provider so the transport name matches the message namespace (e.g. `App\MessageCommand\...` → `async_...`).
- One message class routes to exactly one transport; if multiple consumers are needed, use separate handlers on the same message, not multiple transports.

## Reliability (Retry, Failure Transport, DLQ)

@see https://symfony.com/doc/current/messenger.html#retries-failures

- Configure an explicit `retry_strategy` on every async transport: bounded `max_retries` (3), `delay`, `multiplier`, and `max_delay` — never leave retries unbounded.
- Define a dedicated `failed` failure transport (its own durable queue) and set `failure_transport: failed`. Do not discard failed messages silently.
- Treat the failure transport as a dead-letter queue (DLQ): inspect with `messenger:failed:show`, replay with `messenger:failed:retry`, and remove poison messages explicitly — never auto-retry the DLQ in a loop.
- Throw `UnrecoverableMessageHandlingException` for permanent failures (validation/business-rule rejects) so Messenger skips retries and sends the message straight to the failure transport.

## Handler Idempotency & Locks

- Guard non-idempotent side effects (external API writes, financial aggregation) with the per-domain distributed lock from the Redis rule — inject `#[Target('{domain}.lock')]` (`LockFactory`). Available stores: `abstract`, `company`, `partners`, `projects`, `team`, `tools`.
- Use a stable business key for deduplication (e.g. the message's own identifier), not a random value, so a redelivered message resolves to the same lock/dedupe key.
- Keep handler work transactional: either the whole side effect commits or the message fails and is retried — never leave partial state on an exception.

## Consumer / Worker Operation

@see https://symfony.com/doc/current/messenger.html#deploying-to-production

- Run workers with `messenger:consume <transport> --time-limit=3600 --memory-limit=128M` — always bound both limits so a leaking or long-lived worker is recycled by the process manager (supervisor/systemd), not left to grow.
- One worker command per transport (or a small explicit set); do not consume all transports with a single unbounded process.
- On deploy, stop workers gracefully with `messenger:stop-workers` **after** `cache:clear`/`cache:warmup` so restarted workers load the new code — do not kill workers mid-message.
- Never run `messenger:consume` with `APP_DEBUG=true` in production — the debug profiler collector leaks memory across consumed messages.

## Serialization & Security

- Use Symfony's default PHP serializer for internal messages; only switch to the JSON serializer for messages exchanged with an external/non-Symfony producer, and then validate the decoded payload before handling.
- Never trust a message payload as pre-validated — re-run Symfony Validator on any externally-sourced message inside the handler before acting on it.
- Do not put secrets, tokens, or full credentials in a message payload; pass a reference and resolve the secret from the environment/secret manager inside the handler.
