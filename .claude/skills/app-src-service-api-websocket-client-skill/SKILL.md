---
name: app-src-service-api-websocket-client-skill
description: 'Provides the shared transport-layer criteria for implementing, modifying or reviewing a WebSocket client for any third-party API under app/src/Service/**. Covers ratchet/pawl outbound connections, async worker placement, subscription management, Redis state storage, keep-alive, and exponential-backoff reconnection with subscription restore. Per-integration hosts, channels and subscription identifiers are SoT in the rule file the references/provider-registry.md dispatch table points to. Use it for requests like ''how should this realtime stream work'', ''review this WebSocket client'' (in any language). For REST calls use app-src-service-api-rest-client-skill; for authentication use app-src-service-api-oauth2-client-skill; to actually generate or edit code use app-src-service-api-websocket-build-skill.'
---

# WebSocket Client Skill (third-party API integration)

Provides the **shared transport-layer criteria** for implementing, modifying or reviewing WebSocket
integration code under `app/src/Service/**`.

**This skill is integration-agnostic.** **Integration-specific facts are not here** — hosts, channel and
subscription identifiers, the authentication handshake, concurrent-subscription limits and payload
schemas belong in the **rule file (SoT)** that `references/provider-registry.md` dispatches to. This
document does not restate them.

@see .claude/skills/app-src-service-api-websocket-client-skill/references/provider-registry.md — integration → rule · reference doc · parameter YAML
@see .claude/skills/app-src-service-api-websocket-build-skill/SKILL.md — when actually generating or editing code
@see .claude/rules/message-rabbitmq-rule.md — Messenger transport · worker operation (SoT)

## Sources of information

Use only sources inside the project — code, configuration and rule files. Do not guess a class name or
configuration value that is not confirmed; when the information is missing, say **"this information was
not confirmed in the project files."** For channel and subscription identifier specifications and
subscription limits, the vendor's official documentation is the authority — record its URL in that
integration's registry row.

> ⚠️ `[Verified]` 2026-09-06 — **`app/` currently contains only `.gitkeep`.** The Symfony application is
> not scaffolded yet, so every `app/**` path below is a target shape rather than an existing tree.

## Placement (mandatory rules)

- Use **`ratchet/pawl`** for the WebSocket connection — it is an outbound connection made from a worker
  process. Place the client code under `app/src/Service/**` alongside that integration's other
  transport classes.
- **Never open a connection inside a synchronous HTTP request cycle** — a console command or scheduler
  dispatches a `MessageCommand`, and an async worker manages the connection.
- Store connection handles and the subscription list **in Redis** — no PHP memory, no static property.
- Persisting a received payload and dispatching what follows belong to a **`MessageCommandHandler`** —
  do not transform or aggregate inside the receive callback. Keep one handler per channel or identifier
  (single responsibility).

## Authentication

- Obtain the required credential before connecting. **Do not reuse a REST access token for WebSocket
  authentication** — when the integration requires a separate approval key, issue it through that path
  (details in `app-src-service-api-oauth2-client-skill`).
- Where an integration splits public (market data) and private (account, order) endpoints, **the hosts
  differ** — read both from parameters, and do not attach unnecessary authentication to the public one.
- Keep keys, tokens and approval keys out of connection logs, including handshake URLs and header dumps.

## Connection lifetime management

- Respond to server keep-alive messages (PING/PONG and similar) — without a response the server drops
  the connection.
- On disconnect, implement **exponential-backoff reconnection plus restoration of existing
  subscriptions** — never an immediate infinite reconnect loop.
- There is a **limit on concurrent subscriptions per session** (the number is in the rule file and the
  official documentation) — no unbounded registration loop.
- Worker shutdown must **guarantee unsubscribe and connection close**.
- A high-frequency stream must be structured so processing lag does not accumulate — keep the receive
  callback light and push heavy work to the handler.
- A subscription that depends on a service window or business calendar starts only after checking that
  window, and **the guard belongs inside the handler**, not in the Scheduler.

## Checklist (shared by implementation and review)

- [ ] The client code sits under `app/src/Service/**` with that integration's other transport classes
- [ ] The order credential issue → connect → subscribe is respected (not a reused REST token)
- [ ] Hosts and channel paths are read from parameters (no hardcoding)
- [ ] Connection handles and the subscription list are stored in Redis (no memory, no static)
- [ ] Keep-alive responses and exponential-backoff reconnection with subscription restore are implemented
- [ ] There is no registration loop exceeding the concurrent-subscription limit
- [ ] Worker shutdown guarantees unsubscribe and connection close
- [ ] A high-frequency stream cannot accumulate processing lag
- [ ] A handler still in stub form (logging only) has been reported as a gap
- [ ] No key, token or approval key is exposed in a connection log
- [ ] Passes PHPStan level 8

When asked for a review, report findings at MUST (critical) / SHOULD (recommended) / CONSIDER (optional)
severity.
