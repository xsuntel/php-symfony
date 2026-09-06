---
name: app-src-service-api-rest-client-skill
description: 'Provides the shared transport-layer criteria for implementing, modifying or reviewing a REST client for any third-party API under app/src/Service/**. Covers HttpClient decorator and scoped-client wiring, reading endpoints from the parameter tree, the MessageCommandHandler persistence flow, rate-limit locking and error retry policy. Per-integration facts (endpoints, auth scheme, headers, rate limits) are SoT in the rule file the references/provider-registry.md dispatch table points to. Use it for requests like ''how should I write this REST client'', ''review this API integration'' (in any language). For authentication itself use app-src-service-api-oauth2-client-skill; for realtime subscriptions use app-src-service-api-websocket-client-skill; to actually generate or edit code use app-src-service-api-rest-build-skill.'
---

# REST Client Skill (third-party API integration)

Provides the **shared transport-layer criteria** for implementing, modifying or reviewing REST
integration code under `app/src/Service/**`.

**This skill is integration-agnostic.** It holds the conventions that are identical for every
third-party API. **Integration-specific facts are not here** — endpoint paths, the auth scheme (JWT,
app-key header, apiKey in the URL), request identifiers, rate-limit numbers and response schemas belong
in the **rule file (SoT)** that `references/provider-registry.md` dispatches to. This document does not
restate them.

@see .claude/skills/app-src-service-api-rest-client-skill/references/provider-registry.md — integration → rule · reference doc · parameter YAML
@see .claude/skills/app-src-service-api-rest-build-skill/SKILL.md — when actually generating or editing code
@see .claude/rules/app-php-symfony-04-service-rule.md — Service layer conventions (SoT)

## Sources of information

Use only sources inside the project — code, configuration and rule files. Do not guess a class name or
configuration value that is not confirmed; when the information is missing, say **"this information was
not confirmed in the project files."** For the API's own specification (rate-limit numbers, response
fields, request identifier values), the vendor's official documentation is the authority — record its
URL in that integration's registry row.

> ⚠️ `[Verified]` 2026-09-06 — **`app/` currently contains only `.gitkeep`.** The Symfony application is
> not scaffolded yet, so every `app/**` path below is a target shape rather than an existing tree. Do
> not report an integration as reviewed against code that does not exist.

## Client wiring

- Implement the HTTP client as an **`HttpClientInterface` decorator wrapping a named scoped client via
  `decorates:`**. Inject the inner client with `#[AutowireDecorated]`, add the auth header in
  `request()`, then delegate.
- **`stream()` and `withOptions()` must also delegate to the inner client** — omitting them lets the
  streaming and option-changing paths bypass the decorator entirely.
- Inject auth headers **inside the decorator**, not at the call site. If each endpoint service assembles
  authentication for itself, the implementations drift and some omit it.
- **Do not attach authentication to public endpoints** that do not require it.

## Implementation pattern

1. Always read the endpoint path from the **parameter tree** (`..._api_rest_parameters.path...`) —
   **no hardcoded URLs**. Build the request URL from `host` + `path`. The tree's shape is defined by
   that integration's parameter YAML, and array key access must match the real YAML structure exactly.
2. Perform the call in a `MessageCommandHandler`: **fetch → deserialize to a DTO with the Serializer →
   persist the raw payload to an Entity (JSONB) → dispatch a `MessageEvent`.** Keep fetch and transform
   separate.
3. Error handling: catch `TransportExceptionInterface` and `HttpExceptionInterface`, then branch —
   **503 and timeouts rethrow as `\RuntimeException`** so RabbitMQ retries, while **401/403 are
   non-retryable and raise a notification event.** Never swallow an exception.
4. Rate limiting: before a burst of requests, honour the limit with a `symfony/lock` sliding window.
   Scope the lock key per integration and endpoint identifier.
5. Where an integration has environment variants (sandbox vs production, dev vs prod hosts), split them
   on an **explicit environment flag** — tying it to `kernel.debug` sends a production debug build to
   the wrong host.

## Secret handling

- Never let a key, secret or token value reach a log, an exception message or test output — only a
  masked prefix (first 4 characters + `****`) is acceptable.
- **When an integration carries its apiKey in the URL path or query, the whole URL is a secret** — do
  not log the request URL verbatim.
- Inject secrets only through `%env(...)%` in the parameter YAML — never hardcode them in plaintext.

## Checklist (shared by implementation and review)

- [ ] `declare(strict_types=1)` + `final` class + constructor promotion / `readonly`
- [ ] Decorator wiring (`decorates:` + `#[AutowireDecorated]`) is intact
- [ ] `stream()` / `withOptions()` delegate to the inner client
- [ ] The endpoint path is read from the parameter tree, and the assembled URL (`host` + `path`) is what
      the request actually uses
- [ ] Parameter array key access matches the real YAML structure (watch for typos like `['$appsecret']`)
- [ ] No unnecessary authentication on public endpoints
- [ ] An endpoint is not called in an environment that does not support it
- [ ] A rate-limit lock guards the burst-request path
- [ ] The injected monolog logger uses this integration's own channel (watch for a channel copied from a
      neighbouring integration)
- [ ] No key or token value is exposed in a log, an exception message or a logged request URL
- [ ] Passes PHPStan level 8

When asked for a review, report findings at MUST (critical) / SHOULD (recommended) / CONSIDER (optional)
severity.
