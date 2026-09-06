---
name: api-platform-oauth2-build-skill
description: Use when building the server-side authentication for this project's API Platform endpoints. The project default is stateless JWT (LexikJWTAuthenticationBundle); triggered by questions about keypair generation, security.yaml firewalls (json_login + jwt), the login endpoint (/api/login), access control via operation security, exposing Bearer auth in Swagger UI (api_platform.swagger.api_keys), and OAuth2 server provider configuration. For the client-side OAuth2 flow (Swagger UI Authorize · token consumption) use api-platform-oauth2-client-skill.
---

# API Platform OAuth2/JWT Build Skill (authentication server configuration)

This skill is the entry point for **building the authentication for this project's API on the server
side**. The detailed access-control (authorization) rules are owned by the rule file as the SoT, and
this skill covers only the authentication wiring procedure. The flow by which a client obtains a
token and calls the API is out of scope (→ `api-platform-oauth2-client-skill`).

## Project Standard: stateless JWT

Per CLAUDE.md, this project's API authentication standard is **JWT/Bearer based on
`LexikJWTAuthenticationBundle`**, and the API is `stateless: true` (no cookie session → CSRF exempt).
Do not build a custom authenticator; extend the Symfony authenticator.

@see .claude/rules/api-platform-rule.md — `## Security` section (operation security·stateless·denial messages, SoT)
@see .claude/rules/app-php-symfony-08-security-rule.md — security & rate limiting (SoT)
@see https://api-platform.com/docs/symfony/jwt/ — JWT Authentication with Symfony (official)
@see https://api-platform.com/docs/symfony/security/ — operation access control (security/Voter)
@see .claude/skills/api-platform-oauth2-client-skill/SKILL.md — client flow that consumes the API with an issued token

## Accuracy Principles

- The keys in security.yaml/api_platform.yaml are version-sensitive — do not assert; confirm against
  the installed bundle version/official docs.
- Never commit secrets (passphrase, client secret, keys) in plaintext — inject them only via
  `.env.local`/a secrets manager/environment variables.

## Wiring Procedure (JWT)

```bash
# 1) Install the bundle
cd app && composer require lexik/jwt-authentication-bundle

# 2) Generate the public/private keypair (passphrase from the JWT_PASSPHRASE env var)
cd app && php bin/console lexik:jwt:generate-keypair
```

`config/packages/security.yaml` — wire `json_login` (login) + `jwt` (request auth) into the firewall:

```yaml
firewalls:
  login:
    pattern: ^/api/login
    stateless: true
    json_login:
      check_path: /api/login # declare a POST route in routes.yaml
      username_path: email
      password_path: password
      success_handler: lexik_jwt_authentication.handler.authentication_success
      failure_handler: lexik_jwt_authentication.handler.authentication_failure
  api:
    pattern: ^/api
    stateless: true
    jwt: ~
```

`config/packages/api_platform.yaml` — expose the Bearer input ("Authorize" button) in Swagger UI:

```yaml
api_platform:
  swagger:
    api_keys:
      JWT:
        name: Authorization
        type: header
```

Operation access control follows the rules (SoT) — `security:`/Voter, and collection row filtering in
the Provider/query extension.

## Core Checks

- [ ] Generated the keypair and inject the passphrase as an **environment variable/secret** (no plaintext commit)
- [ ] Is the firewall `stateless: true` and wired with `json_login` + `jwt`
- [ ] Is the login route (`/api/login`) declared as POST in `routes.yaml`
- [ ] In `access_control`, are the docs/login/context paths public and the rest of `/api` set to require authentication
- [ ] Is the auth input exposed in Swagger UI via `api_keys` (or OAuth2)
- [ ] Is authorization applied with operation `security:`/Voter (checked against the rule SoT)
- [ ] Is `symfony/rate-limiter` applied to public endpoints

## Verification (Bash)

```bash
# Dump the firewall/security configuration
cd app && php bin/console debug:config security

# Token issuance smoke test (credentials per your environment)
curl -fsS -X POST https://<host>/api/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"user@example.com","password":"..."}'

# Access a protected endpoint with the issued token (verify 401→200)
curl -fsS https://<host>/api/books -H "Authorization: Bearer <TOKEN>" -o /dev/null -w '%{http_code}\n'
```

## Prohibitions

- Do not implement a custom authentication mechanism yourself — extend the Symfony authenticator/Lexik JWT.
- Do not place keys/passphrase/client secret in committed files (`.env`·config·source).
- Do not force form-login CSRF onto a token-based stateless API — see the rules `## Security` for the rationale.
