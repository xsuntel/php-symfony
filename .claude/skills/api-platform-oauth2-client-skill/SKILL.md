---
name: api-platform-oauth2-client-skill
description: Use when dealing with this project's API OAuth2/Bearer authentication from the client (consumer) perspective. Triggered by questions about the api_platform.oauth config for the Swagger UI "Authorize" button (enabled/clientId/clientSecret/type/flow/tokenUrl/authorizationUrl/scopes), OAuth2 grant flow selection (authorizationCode/implicit/password/clientCredentials), calling the API with the issued token as a Bearer header, authentication testing with ApiTestCase's auth_bearer, the single-flow limitation, and CORS caveats. For building authentication on the server side use api-platform-oauth2-build-skill.
---

# API Platform OAuth2 Client Skill (authentication consumption)

This skill is the entry point for dealing with this project's API authentication from the
**client/consumer perspective**: configuring Swagger UI to demonstrate the OAuth2 flow, and calling
protected endpoints with the issued token. **Server-side building** — authenticators, firewalls, keys,
etc. — is out of scope (→ `api-platform-oauth2-build-skill`).

@see https://api-platform.com/docs/core/openapi/ — Swagger UI OAuth2/security schemes (official)
@see https://api-platform.com/docs/core/configuration/ — api_platform config reference (oauth keys)
@see .claude/rules/api-platform-rule.md — operation security criteria for the consumed API (SoT)
@see .claude/skills/api-platform-oauth2-build-skill/SKILL.md — use this instead when building authentication (JWT/OAuth2) on the server side
@see .claude/skills/api-platform-rest-client-skill/SKILL.md — also reference this when wiring authentication into a generated frontend client

## Accuracy Principles

- The `api_platform.oauth` keys **may be renamed across versions** — do not assert; confirm against
  the config reference for the installed version.
- Inject `clientId`/`clientSecret` only via environment variables — no plaintext commit.

## Swagger UI OAuth2 Configuration

Configure the Swagger UI "Authorize" flow in `config/packages/api_platform.yaml`. `clientId`/
`clientSecret` are used by Swagger UI:

```yaml
api_platform:
  oauth:
    enabled: true
    clientId: "%env(OAUTH_CLIENT_ID)%"
    clientSecret: "%env(OAUTH_CLIENT_SECRET)%"
    type: "oauth2"
    flow: "authorizationCode" # grant type (see table below)
    authorizationUrl: "https://accounts.example.com/o/oauth2/v2/auth"
    tokenUrl: "https://oauth2.example.com/token"
    scopes:
      email: "Allow to retrieve user email" # scopes is a name:description map
```

Required URLs per grant type:

| `flow`              | Purpose                                     | Required URL                       |
| ------------------- | ------------------------------------------- | ---------------------------------- |
| `authorizationCode` | server/mobile web apps (most common)        | `authorizationUrl` + `tokenUrl`    |
| `implicit`          | clients with no server component            | `authorizationUrl`                 |
| `password`          | trusted clients (send credentials directly) | `tokenUrl` (+ optional refreshUrl) |
| `clientCredentials` | server-to-server (no user)                  | `tokenUrl` (+ optional refreshUrl) |

- **[MUST] Swagger UI activates only one OAuth2 flow at a time** (multiple flows unsupported — a known limitation).
- **CORS caveat:** with some providers the token URL does not support CORS, which can cause a
  "Failed to fetch" in Swagger UI — in that case a controller that proxies the token exchange may be needed.
- To expose plain Bearer/JWT only, use `swagger.api_keys` instead of OAuth2 (→ `api-platform-oauth2-build-skill`).

## Consume the API with a Token

```bash
# After obtaining a token, call with the Bearer header
curl -fsS https://<host>/api/books -H "Authorization: Bearer <TOKEN>"
```

`ApiTestCase` authentication tests pass the token via the `auth_bearer` option:

```php
static::createClient()->request('GET', '/api/books', ['auth_bearer' => $token]);
// or as a header: ['headers' => ['Authorization' => 'Bearer ' . $token]]
```

## Core Checks

- [ ] Inject `clientId`/`clientSecret` as environment variables (no plaintext commit)
- [ ] Set only the URLs matching the `flow` (`authorizationUrl`/`tokenUrl`)
- [ ] Declare `scopes` as a `name: description` map
- [ ] Aware of the single-flow limitation and activated only one
- [ ] Consumption calls use the `Authorization: Bearer` header (or test `auth_bearer`)
- [ ] Considered the CORS failure possibility (a token-exchange proxy controller if needed)

## Verification (Bash)

```bash
# Confirm the securityScheme (oauth2/apiKey) is reflected in the generated OpenAPI
cd app && php bin/console api:openapi:export --yaml | grep -A8 -i 'securitySchemes'

# Swagger UI: verify the "Authorize" button exposure and flow behavior at /api/docs
```

## Prohibitions

- Do not leave `clientId`/`clientSecret`/tokens in plaintext in committed files or logs.
- Do not assume multiple OAuth2 flows can be active simultaneously (unsupported).
- Do not reconfigure the server-side authenticator/firewall in this skill — delegate to `api-platform-oauth2-build-skill`.
