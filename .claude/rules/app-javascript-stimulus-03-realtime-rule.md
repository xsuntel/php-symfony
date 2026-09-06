---
paths:
  - "app/config/packages/mercure.yaml"
  - "app/templates/turbo/streams/**/*.twig"
  - "app/src/EventListener/**/*StreamListener.php"
---

# JavaScript / Stimulus Rules — Realtime (Mercure/SSE)

This rule is the judgment criteria (SoT) for Mercure (Server-Sent Events) based realtime server → browser
push. It mandates the configuration, publish, subscribe, authorization, and test skeletons. Syntax and
detailed API examples are supplemented by the docs.

@see .claude/docs/app-php-symfony-docs.md — §13 Mercure / Server-Sent Events (SSE) details
@see .claude/rules/app-javascript-stimulus-00-overview-rule.md ~ app-javascript-stimulus-02-quality-rule.md — module · controller · quality criteria
@see .claude/rules/app-php-symfony-10-frontend-rule.md — frontend · UX Turbo integration
@see https://symfony.com/doc/current/mercure.html

## Transport (non-negotiable)

- Server → browser realtime state push uses **Mercure (SSE) + Turbo Streams**.
- Do not introduce a new **raw WebSocket server** or **polling loop** for browser state updates — the provider outbound WebSocket (ratchet/pawl) is only for the server consuming external market data, never for browser inbound.

## Installation & Configuration

- Packages: `symfony/mercure-bundle` (+ `symfony/mercure`). Configuration lives in `config/packages/mercure.yaml`.
- Do not hardcode the three environment variables:
  - `MERCURE_URL` — the internal Hub URL the app (server) **publishes** to.
  - `MERCURE_PUBLIC_URL` — the public Hub URL the browser **subscribes** to.
  - `MERCURE_JWT_SECRET` — the JWT signing secret (must match the Hub's key). **Never commit a secret** — inject it via `.env.local` or Symfony Secrets (per `app-php-symfony-02-configuration-rule.md`).

## Publishing (server)

- Publish only through `Symfony\Component\Mercure\HubInterface::publish(new Update($topics, $data))` — do not call the Hub directly via `\Redis` or raw HTTP.
- Put publishes that react to a domain state transition in an `#[AsEventListener]` listener (filename `*StreamListener.php`) — do not publish inline from a Service or Controller body. For a Workflow transition, hook the `workflow.{name}.entered` event.
- **A Hub failure must not break domain logic** — wrap the publish in `try/catch (\Throwable)`, log, and fail gracefully (graceful degradation in production, docs §10); never abort the state transition or the response.
- Published data must be either a server-rendered, trusted `<turbo-stream>` fragment (HTML string) or a serialized string.

## Topic Conventions

- Use a stable topic string that reflects the resource hierarchy — e.g. `trading/orders/{provider}/{id}`.
- **Do not expose sensitive information (user identifiers, secrets, PII) in a topic string** — handle the scoping you need with a private update plus a subscribe JWT.
- Encapsulate an entity's own topic behind an interface method (e.g. `getStreamTopic()`) — listeners and templates must not each hardcode the topic string.

## Subscribing (browser)

- Subscribe by rendering `<turbo-stream-source>` from Twig with `{{ turbo_stream_listen(topic) }}` — do not hand-write `data-*` strings or `new EventSource(...)`.
- When subscribing to several resources in a list, **do not create a per-row subscription** — subscribe once with a **single** URI-template topic (`.../{id}`), and give each row only the DOM id it replaces (e.g. `order-status-{id}`).
- Keep the replacement stream template a pure `<turbo-stream action="...">` fragment, and have the initial render and the stream replacement share the **same partial template** (badges and the like) so the markup matches after an update.

## public vs private Authorization

- Carry **non-sensitive data only** on a default public topic.
- Publish per-user or sensitive data with `new Update($topic, $data, true)` (private), and isolate it with the subscriber JWT's `mercure.subscribe` claim (cookie-based `Authorization::setCookie()`).
- Restrict topic access with the `mercure.publish` claim on the publisher JWT and the `mercure.subscribe` claim on the subscriber JWT — in production, do not mistake `publish: ['*']` for a subscribe permission.

## Testing

- Unit: verify the publish call with `Symfony\Component\Mercure\MockHub` (+ `StaticTokenProvider`) — do not make a network request to a real Hub.
- Functional: substitute a `HubInterface` implementation `HubStub` for `mercure.hub.default` in `config/services_test.yaml`.
- Verify rendering with a Functional test (WebTestCase), asserting the presence of `<turbo-stream-source>` and the replacement target DOM id.

## Quality Gates (mandatory before merge)

```bash
# Turbo Stream / subscription template syntax
cd app && php bin/console lint:twig templates/turbo/streams

# static analysis of listener and publish code
cd app && vendor/bin/phpstan analyse
```

- `lint:twig` passes; the publish `try/catch` guard is present; no sensitive information is exposed in a topic; no secret is committed.
- Classify review findings by severity `[MUST]` / `[SHOULD]` / `[CONSIDER]`, and only `[MUST]` blocks a merge.
