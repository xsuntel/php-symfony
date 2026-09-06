# WebSocket Integration Registry (client)

The dispatch table `app-src-service-api-websocket-client-skill` uses to locate each integration's
**judgment criteria (SoT) and configuration coordinates**.

**This is not judgment criteria** — only coordinates live here. Hosts, channel and subscription
identifiers, the authentication handshake, concurrent-subscription limits and payload schemas all belong
in the rule file named in the `Judgment criteria (SoT)` column. **Never copy that content into this
table.**

## Registered integrations

| Integration | Code path | Judgment criteria (SoT) | Public / private hosts | Parameter YAML | Official docs |
| --- | --- | --- | --- | --- | --- |
| _(none registered)_ | — | — | — | — | — |

> ⚠️ **The table is deliberately empty.** `[Verified]` 2026-09-06 — this project has no third-party
> WebSocket integration registered yet, and `app/` contains only `.gitkeep`.

## When nothing is registered

The client skill still works with an empty table — placement, connection lifetime management and the
secret rules apply to any WebSocket integration. What you lose without a row is the
**integration-specific** half:

- **the concurrent-subscription limit.** Without it there is no way to tell a correct registration loop
  from one that will be rejected by the server — report it as unverified rather than assuming a number.
- **channel and subscription identifiers**, and the payload schema.
- **the public/private host split.** Getting this wrong either attaches credentials to a public feed or
  connects a private feed unauthenticated.
- the keep-alive message shape and the server's disconnect policy.

## Registering an integration

This skill is fixed regardless of how many integrations exist. To add one, create **one row above** plus
the artifacts below — do not edit the skill body.

1. `.claude/rules/{integration}-api-websocket-rule.md` — the judgment criteria (SoT). **Required**, and
   on this transport it must fix at minimum: the public and private hosts, the channel and subscription
   identifiers, the concurrent-subscription limit, the keep-alive shape, and the backoff schedule.
2. `app/config/parameters/.../{integration}.yaml` — hosts and channel paths, since the skill forbids
   hardcoding them.
3. A Redis pool for connection handle and subscription state — the skill forbids PHP memory and static
   properties.
4. `.claude/docs/{integration}-api-websocket-docs.md` — a detailed reference (optional).
5. Add the matching row to
   `.claude/skills/app-src-service-api-websocket-build-skill/references/provider-registry.md`.

**Where the integration needs a separate approval key rather than a REST access token**, record that in
the OAuth2 registries too — the credential is issued through the OAuth2 path, and the two transports
must not share a token.
