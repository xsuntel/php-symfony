---
name: cache-redis-skill
description: 'Use when injecting a Redis cache pool, setting a TTL, performing tag-based invalidation, configuring a distributed lock, or understanding this Symfony project''s session/messenger Redis usage. Triggered by questions about CacheInterface, TagAwareCacheInterface, cache_pool_*, #[Target], expiresAfter, invalidateTags, LOCK_DSN, RedisSessionHandler, or the caching strategy.'
---

# Redis Cache Skill

This is the entry point for implementing and reviewing this project's Redis / Symfony Cache work.

## Information Source (single source of truth: the rule file)

**All detailed criteria** — the pool list, TTL table, injection patterns, service configuration,
per-environment adapters — are in the rule file. This skill does not duplicate the rules; it only
provides the work procedure and verification methods.

@see .claude/rules/cache-redis-rule.md — full cache pool/TTL/injection/lock/session/transport standards (SoT)
@see https://symfony.com/doc/current/cache.html

Source of truth (configuration): `app/config/packages/cache.yaml`, `app/config/services.yaml`, `app/config/packages/lock.yaml`

## Work Procedure

1. **Identify the domain** → select the target `cache_pool_{domain}` from the rule's `## Redis Cache Adapter > Pool Name Reference` table. No generic `cache.app`.
2. **Select the interface** → `TagAwareCacheInterface` if tag invalidation is needed, otherwise `CacheInterface`. Inject with `#[Target('cache_pool_...')]`.
3. **TTL branching** → branch debug/prod TTL with `#[Autowire(param: 'kernel.debug')]` (the rule's `### TTL Reference` table). Do not omit `expiresAfter(...)`.
4. **Lock/session/transport** → see the rule's `## Redis Configuration > Non-Cache Uses of Redis`.

## Verification (Bash)

```bash
# Check the cache pool list
cd app && php bin/console cache:pool:list

# Check the configured pools/adapters
cd app && php bin/console debug:config framework cache

# Clear a specific pool (caution in production)
cd app && php bin/console cache:pool:clear cache_pool_company
```

## Checklist (common to implementation & review)

- [ ] Did you inject the domain pool with `#[Target('cache_pool_{domain}')]` (no `cache.app`)?
- [ ] Does every cache item have an explicit `expiresAfter(...)` TTL?
- [ ] Did you branch dev/prod TTL with `kernel.debug`?
- [ ] Did you avoid injecting `TagAwareCacheInterface` when not using tags?
- [ ] Did you avoid calling `\Redis` directly (except the session handler)?
- [ ] Did you inject the distributed lock with `#[Target('{domain}.lock')]`?
- [ ] Did you avoid routing async messages to the Redis transport (use RabbitMQ)?

When a review is requested, report severity as MUST (critical) / SHOULD (recommended) / CONSIDER (optional).
