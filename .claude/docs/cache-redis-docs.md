# Redis / Symfony Cache — Technical Reference

This document holds the **detailed reference and configuration examples** for Redis usage in this
project (cache pools, session store, distributed locks, Messenger transport). The enforced judgment
criteria (SoT) live in the rule file — if this document conflicts with the rule, the rule wins.

@see .claude/rules/cache-redis-rule.md — Redis/Cache judgment criteria (SoT)
@see https://symfony.com/doc/current/cache.html — Symfony Cache (official)
@see https://symfony.com/doc/current/components/cache/adapters/redis_adapter.html — Redis adapter (official)

---

## 1. Basic Cache Usage

Inject a specific pool with `#[Target(...)]` and set an environment-aware TTL:

```php
use Symfony\Component\DependencyInjection\Attribute\Autowire;
use Symfony\Component\DependencyInjection\Attribute\Target;
use Symfony\Contracts\Cache\CacheInterface;
use Symfony\Contracts\Cache\ItemInterface;

public function __construct(
    #[Autowire(param: 'kernel.debug')]
    private readonly bool $isDebug,
    #[Target('cache_pool_company')]
    private readonly CacheInterface $cache,
) {}

public function getData(): array
{
    return $this->cache->get('my_key', function (ItemInterface $item): array {
        $item->expiresAfter($this->isDebug ? 10 : 3600);

        return $this->repository->findAll();
    });
}
```

---

## 2. Redis Configuration

@see https://symfony.com/doc/current/components/cache/adapters/redis_adapter.html#configuring-redis

### Environment Variables

Defined in `app/.env` and overridden in `.env.local` (never commit the override values):

```dotenv
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
LOCK_DSN="redis://${REDIS_HOST}:${REDIS_PORT}/0"
```

### Service Definitions

Two Redis services are defined in `app/config/services.yaml`:

**1. `Redis`** — the raw `\Redis` instance, used only for the session handler:

```yaml
Redis:
  class: Redis
  calls:
    - connect: ['%cache_host%', '%cache_port%']
```

**2. `app.cache_redis_provider`** — a factory-based connection for all cache pools:

```yaml
app.cache_redis_provider:
  class: Redis
  factory: ['Symfony\Component\Cache\Adapter\RedisAdapter', 'createConnection']
  arguments:
    - 'redis://%cache_host%:%cache_port%'
    - { retry_interval: 2, timeout: 10 }
```

- Use `app.cache_redis_provider` as the `provider:` of every cache pool — do not reference `Redis` directly.
- Do not change the `retry_interval` or `timeout` values without load-testing in the target environment.

### Default Provider

Declared in `app/config/packages/cache.yaml`:

```yaml
framework:
  cache:
    default_redis_provider: 'redis://%cache_host%'
```

### Non-Cache Uses of Redis

In this project, Redis serves three additional roles beyond caching:

**Session store** (`RedisSessionHandler` — example wiring in `config/services.yaml`):

```yaml
Symfony\Component\HttpFoundation\Session\Storage\Handler\RedisSessionHandler:
  arguments:
    - '@Redis'
    - { prefix: 'redis_session_', ttl: 600 }
```

- The session TTL is 600 seconds (10 minutes) — do not increase it without a security review.
- This uses the `Redis` service (raw connection), not `app.cache_redis_provider`.

**Distributed locks** (`app/config/packages/lock.yaml`):

```yaml
framework:
  lock:
    abstract:  '%env(LOCK_DSN)%'
    company:   '%env(LOCK_DSN)%'
    partners:  '%env(LOCK_DSN)%'
    projects:  '%env(LOCK_DSN)%'
    team:      '%env(LOCK_DSN)%'
    tools:     '%env(LOCK_DSN)%'
```

- Available named lock stores: `abstract`, `company`, `partners`, `projects`, `team`, `tools`.
- Inject a per-domain `LockFactory` with `#[Target('{domain}.lock')]`:

```php
use Symfony\Component\DependencyInjection\Attribute\Target;
use Symfony\Component\Lock\LockFactory;

public function __construct(
    #[Target('abstract.lock')]
    private readonly LockFactory $lockFactory,
) {}
```

- Lock key pattern for API rate limiting: `lock_{provider}_{endpoint_tr_id}` (e.g. `lock_korea_investment_FHKST01010100`).

**Messenger sync transport** (`app/config/packages/messenger.yaml`):

- `sync_providers_finance_app_digitalasset_upbit_domestic` → `MESSENGER_TRANSPORT_DSN_REDIS`
- `sync_providers_finance_app_securities_koreainvestment_domestic` → `MESSENGER_TRANSPORT_DSN_REDIS`

The Redis transport is exclusively for **synchronous, in-process** message handling. All asynchronous work uses the RabbitMQ transport — do not route asynchronous messages to the Redis transport.

---

## 3. Redis Cache Adapter

@see https://symfony.com/doc/current/components/cache/adapters/redis_adapter.html

### Pool Conventions

All 15 domain-scoped cache pools share the same configuration:

```yaml
adapter: cache.adapter.redis
provider: app.cache_redis_provider
tags: true
```

`tags: true` wraps the pool in a `TagAwareCacheAdapter`, so every pool supports both `CacheInterface` and `TagAwareCacheInterface`.

### Pool Name Reference

| Pool name | Domain |
|-----------|--------|
| `cache_pool_abstract` | Abstract |
| `cache_pool_company` | Company |
| `cache_pool_partners` | Partners |
| `cache_pool_products` | Products |
| `cache_pool_resources` | Resources |
| `cache_pool_team` | Team |
| `cache_pool_tools` | Tools |
| `cache_pool_providers_finance_app_agencies_ecos` | Finance / ECOS |
| `cache_pool_providers_finance_app_agencies_kosis` | Finance / KOSIS |
| `cache_pool_providers_finance_app_digitalasset_upbit` | Finance / UPbit |
| `cache_pool_providers_finance_app_digitalasset_upbit_domestic` | Finance / UPbit Domestic |
| `cache_pool_providers_finance_app_securities_koreainvestment` | Finance / KoreaInvestment |
| `cache_pool_providers_finance_app_securities_koreainvestment_domestic` | Finance / KoreaInvestment Domestic |
| `cache_pool_providers_property_app_agencies_kostat` | Property / KOSTAT |
| `cache_pool_providers_property_app_agencies_vworld` | Property / VWorld |

Naming pattern:
- Core domains: `cache_pool_{domain}`
- Provider integrations: `cache_pool_providers_{provider_path}`

When adding a new provider, add the same pool to both `config/packages/dev/cache.yaml` and `config/packages/prod/cache.yaml`.

### Injection Patterns

**Simple cache** — use `CacheInterface` with `#[Target]`:

```php
use Symfony\Component\DependencyInjection\Attribute\Target;
use Symfony\Contracts\Cache\CacheInterface;

#[Target('cache_pool_company')]
private readonly CacheInterface $cache,
```

**Tag-based invalidation** — use `TagAwareCacheInterface` with `#[Target]`:

```php
use Symfony\Contracts\Cache\TagAwareCacheInterface;

#[Target('cache_pool_providers_finance_app_agencies_ecos')]
private readonly TagAwareCacheInterface $cache,

// Store with tags:
$value = $this->cache->get('ecos_data_key', function (ItemInterface $item): array {
    $item->expiresAfter($this->isDebug ? 5 : 21600);
    $item->tag(['ecos', 'ecos_economic']);

    return $this->service->fetch();
});

// Invalidate by tag:
$this->cache->invalidateTags(['ecos']);
```

### TTL Reference

| Situation | Debug TTL | Production TTL |
|---------|-----------|----------------|
| Company / controller data | 10s | 3600s (1 hour) |
| Financial agency data (ECOS / KOSIS) | 5–10s | 21600–86400s (6–24 hours) |
| Real-time quote data (UPbit) | 5s | 30s |
| Candle / order-book data (UPbit) | 5s | 600s (10 minutes) |
| Twig extension runtime | 30s | 3600s (1 hour) |

### Per-Environment Adapter Matrix

The `app` adapter differs by environment, but the 15 pools always use Redis:

| Environment | `app` adapter | Pool adapter |
|-------------|--------------|-------------|
| `dev` | `cache.adapter.filesystem` | `cache.adapter.redis` |
| `prod` | `cache.adapter.array` | `cache.adapter.redis` |

The difference in the `app` adapter means Symfony's internal metadata (routes, DI container) is stored on the filesystem in `dev` and in memory in `prod` — the Redis pools are unaffected by this difference.
