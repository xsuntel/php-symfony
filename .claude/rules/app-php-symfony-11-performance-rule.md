---
paths:
  - "app/src/**/*.php"
---

# Performance & Deployment Rule

@see https://symfony.com/doc/current/performance.html

## PHP OPcache

- OPcache must be enabled and tuned in production — without it, Symfony is roughly 5× slower.
- After warmup, set `opcache.preload` to `var/cache/prod/App_KernelProdContainer.preload.php`.

## Doctrine Caching

Enable the Metadata, Query, and Result caches in production:

```yaml
# config/packages/doctrine.yaml
doctrine:
    orm:
        metadata_cache_driver:
            type: pool
            pool: doctrine.system_cache_pool
        query_cache_driver:
            type: pool
            pool: doctrine.system_cache_pool
        result_cache_driver:
            type: pool
            pool: doctrine.result_cache_pool
```

Map the cache pools to Redis in `config/packages/cache.yaml`:

```yaml
framework:
    cache:
        pools:
            doctrine.result_cache_pool:
                adapter: cache.adapter.redis
                provider: 'redis://localhost'
```

## HTTP Cache

Use the `#[Cache]` attribute for controller-level HTTP caching:

```php
#[Cache(smaxage: 3600, mustRevalidate: true)]
#[Route('/post/{id}', name: 'post_show', methods: ['GET'])]
public function show(Post $post): Response { ... }
```

Use ESI to cache page fragments with different TTLs — configure it in `config/packages/framework.yaml`:

```yaml
framework:
    esi: true
    fragments: true
```

@see https://symfony.com/doc/current/http_cache.html

## Redis Caching Strategy

- Use Redis as the **primary cache adapter** for all application caching.
- Use a tag-aware cache pool (`cache.adapter.redis_tag_aware`) when tag-based cache invalidation is needed.
- Set an explicit TTL — do not cache without expiration.
- Use a dedicated Redis database index per cache pool to simplify flushing.

```php
$item = $this->cache->get('post_'.$id, function (ItemInterface $item) use ($id): Post {
    $item->expiresAfter(3600);
    $item->tag(['posts', 'post_'.$id]);
    return $this->postRepository->find($id);
});
```
