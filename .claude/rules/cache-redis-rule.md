---
paths:
  - "app/config/packages/cache.yaml"
  - "app/config/packages/lock.yaml"
  - "app/src/Service/**/*.php"
  - "app/src/EntityRepository/**/*.php"
  - "app/src/Repository/**/*.php"
  - "app/src/MessageQueryHandler/**/*.php"
---

# Cache Rules

This rule is the judgment criteria (SoT) for Redis/Cache usage. The detailed configuration examples,
pool/TTL tables, and injection snippets live in the docs.

@see .claude/docs/cache-redis-docs.md — configuration, pool/TTL reference, injection examples
@see https://symfony.com/doc/current/cache.html — Symfony Cache (official)

## General Rules

- Use `CacheInterface` for simple get/set operations, and `TagAwareCacheInterface` when tag-based targeted invalidation is needed.
- Always inject a specific pool with `#[Target('cache_pool_{domain}')]` — never inject the generic `cache.app` pool in a domain service.
- Set an explicit TTL on every cache item with `$item->expiresAfter(...)` — do not cache indefinitely in any environment.
- Use `kernel.debug` for environment-aware TTLs: short values in dev, production values in prod (see the TTL reference in the docs).
- Never call the `\Redis` class directly — all cache reads/writes must go through the Symfony Cache component.

## Cache Pools

- Use `app.cache_redis_provider` as the `provider:` of every cache pool — do not reference the raw `Redis` service directly.
- Every pool sets `tags: true` (wrapping it in a `TagAwareCacheAdapter`), so both `CacheInterface` and `TagAwareCacheInterface` are available.
- Pool naming: core domains use `cache_pool_{domain}`, provider integrations use `cache_pool_providers_{provider_path}` (see the pool name reference in the docs).
- When adding a new provider pool, add the identical pool to **both** `config/packages/dev/cache.yaml` and `config/packages/prod/cache.yaml`.
- Do not change the connection `retry_interval`/`timeout` without load-testing in the target environment.

## Non-Cache Uses of Redis

- **Session store**: the session TTL is 600s (10 minutes) — do not increase it without a security review. It uses the raw `Redis` service, not `app.cache_redis_provider`.
- **Distributed locks**: always inject the named lock store that matches the current domain via `#[Target('{domain}.lock')]` — do not use the default lock store. Available stores: `abstract`, `company`, `partners`, `projects`, `team`, `tools`.
- **Messenger transport**: the Redis transport is exclusively for **synchronous, in-process** handling — route all asynchronous work to the RabbitMQ transport, never to Redis.
