---
name: app-src-service-api-oauth2-client-skill
description: 'Provides the shared transport-layer criteria for implementing, modifying or reviewing OAuth2 authentication against any third-party API under app/src/Service/**. Covers access-token issue and revoke, WebSocket approval keys, Redis cache-pool TTL reuse and fallback tokens, issue-rate limiting, secret-exposure prevention and auth-failure event branching. Per-integration endpoints, field names and TTL values are SoT in the rule file the references/provider-registry.md dispatch table points to. Use it for requests like ''how should token caching work'', ''review this auth client'' (in any language). For endpoint calls use app-src-service-api-rest-client-skill; for realtime subscriptions use app-src-service-api-websocket-client-skill; to actually generate or edit code use app-src-service-api-oauth2-build-skill.'
---

# OAuth2 Client Skill (third-party API integration)

Provides the **shared transport-layer criteria** for implementing, modifying or reviewing authentication
code under `app/src/Service/**`. The auth client is **the single point of authentication** that both the
REST and WebSocket layers share.

**This skill is integration-agnostic.** **Integration-specific facts are not here** — endpoint paths,
secret field names, TTL values and response schemas belong in the **rule file (SoT)** that
`references/provider-registry.md` dispatches to. This document does not restate them.

@see .claude/skills/app-src-service-api-oauth2-client-skill/references/provider-registry.md — integration → rule · reference doc · parameter YAML
@see .claude/skills/app-src-service-api-oauth2-build-skill/SKILL.md — when actually generating or editing code
@see .claude/rules/cache-redis-rule.md — cache pool · TTL · lock conventions (SoT)

## Sources of information

Use only sources inside the project — code, configuration and rule files. Do not guess a class name or
configuration value that is not confirmed; when the information is missing, say **"this information was
not confirmed in the project files."** For issue-rate limits and response fields, the vendor's official
documentation is the authority — record its URL in that integration's registry row.

> ⚠️ `[Verified]` 2026-09-06 — **`app/` currently contains only `.gitkeep`.** The Symfony application is
> not scaffolded yet, so every `app/**` path below is a target shape rather than an existing tree.

## Token lifecycle (mandatory rules)

- **Separate the low-level issue method from the cache-backed method.** The method that performs a real
  HTTP issue on every call is never cached, and ordinary call sites must use the **cache-backed**
  method. A call site reaching the low-level method directly re-issues on every request and trips the
  rate limit.
- The token store must be **a Redis cache pool dedicated to that integration** — no PHP session, no
  in-memory store, no static property. The pool name is fixed by that integration's rule file.
- Set the active entry's TTL to `expires_in` **minus an expiry buffer**, so a near-expired token is
  refreshed pre-emptively on the next call. When the response carries no `expires_in`, use a defensive
  default (the value comes from the rule file).
- Keep a **fallback token** under a `_fallback` suffixed key with the real expiry TTL, and use it only
  when a re-issue fails. Read and write the fallback directly through PSR-6
  (`CacheItemPoolInterface::getItem()` / `isHit()`).
- **Do not build a retry loop around a failed issue** — return the fallback token and keep the cache
  entry short (around 5 seconds) so the next call retries.
- On revoke, **invalidate the fallback as well** — otherwise an already-revoked token comes back to life
  through the fallback path.
- Issuing is itself rate-limited: reusing a stored valid token is the default, and repeated issuing in a
  short window is forbidden.

## Separating authentication mechanisms

- A REST access token and a WebSocket approval key are **distinct credentials** — neither substitutes
  for the other.
- Even for the same application secret, **different endpoints may require different field names** (for
  example `appsecret` vs `secretkey`). Always confirm the field name in the rule file — never infer it
  because the value is the same.
- Read endpoint paths from the parameter tree — **no hardcoded URLs**.

## Error handling

**Branch in one place** — do not reimplement this per calling method.

- **401/403 (permanent failure)** — do not retry. Log it, dispatch an authentication-failure
  `MessageEvent`, then return normally (the call site recognises the failure from a `null` response).
- **Other 4xx/5xx, timeouts and decoding failures (transient)** — rethrow as `\RuntimeException` so the
  layer above (Messenger/RabbitMQ) retries.
- Catch exactly three: `HttpExceptionInterface`, `TransportExceptionInterface` and
  `DecodingExceptionInterface`. Never swallow an exception silently.

## Secret handling

- Application keys, secrets, issued tokens and approval keys must never appear in **any log, exception
  message, event payload or test output.** An authentication-failure event carries only identifying
  context such as `source`, `environment`, `status_code` and `occurred_at`.
- Inject secrets only through `%env(...)%` in the parameter YAML — never hardcode them in plaintext.

## Checklist (shared by implementation and review)

- [ ] `declare(strict_types=1)` + `final readonly` class + constructor promotion
- [ ] Call sites use the **cache-backed** method rather than the low-level issue (prevents re-issuing per
      request)
- [ ] The active TTL applies an expiry buffer, and the fallback entry is stored under its own key
- [ ] Revoke invalidates the fallback too
- [ ] The secret **field name** per endpoint matches the rule file (no inference)
- [ ] 401/403 branch to an auth-failure event without retrying, and only transient failures are rethrown
- [ ] Endpoint paths are read from the parameter tree (no hardcoding)
- [ ] The injected monolog logger uses this integration's own channel (watch for a channel copied from a
      neighbouring integration)
- [ ] No key, secret, token or approval key is exposed in a log or event payload
- [ ] Passes PHPStan level 8

When asked for a review, report findings at MUST (critical) / SHOULD (recommended) / CONSIDER (optional)
severity.
