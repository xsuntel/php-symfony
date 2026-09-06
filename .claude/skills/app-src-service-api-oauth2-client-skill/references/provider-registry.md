# OAuth2 Integration Registry (client)

The dispatch table `app-src-service-api-oauth2-client-skill` uses to locate each integration's
**judgment criteria (SoT) and configuration coordinates**.

**This is not judgment criteria** — only coordinates live here. Token endpoints, secret field names, TTL
values, expiry buffers and response schemas all belong in the rule file named in the
`Judgment criteria (SoT)` column. **Never copy that content into this table.**

## Registered integrations

| Integration | Code path | Judgment criteria (SoT) | Redis cache pool | Parameter YAML | Official docs |
| --- | --- | --- | --- | --- | --- |
| _(none registered)_ | — | — | — | — | — |

> ⚠️ **The table is deliberately empty.** `[Verified]` 2026-09-06 — this project has no third-party
> OAuth2 integration registered yet, and `app/` contains only `.gitkeep`.

## When nothing is registered

The client skill still works with an empty table — the token lifecycle, error branching and secret rules
apply to any OAuth2 integration. What you lose without a row is the **integration-specific** half, and
on this transport two of those are especially dangerous to guess:

- **secret field names** (`appsecret` vs `secretkey` and similar). The skill forbids inferring a field
  name from the fact that the value is the same — with no rule file, confirm it against the vendor's
  documentation and report it as unverified.
- **TTL values and the expiry buffer.** Guessing these produces either constant re-issuing (tripping the
  rate limit) or the use of expired tokens.
- the token endpoint path, the issue-rate limit, and the response schema.

## Registering an integration

This skill is fixed regardless of how many integrations exist. To add one, create **one row above** plus
the artifacts below — do not edit the skill body.

1. `.claude/rules/{integration}-api-oauth2-rule.md` — the judgment criteria (SoT). **Required**, and on
   this transport it must fix at minimum: the token endpoint, the secret field name per endpoint, the
   `expires_in` fallback default, the expiry buffer, and the cache pool name.
2. A dedicated Redis cache pool in `app/config/packages/cache.yaml` — the skill forbids storing tokens in
   a PHP session, in memory or in a static property, so a shared pool is not acceptable.
3. `app/config/parameters/.../{integration}.yaml` — the token endpoint tree plus `%env(...)%` secret
   injection.
4. `.claude/docs/{integration}-api-oauth2-docs.md` — a detailed reference (optional).
5. Add the matching row to
   `.claude/skills/app-src-service-api-oauth2-build-skill/references/provider-registry.md`.

**Never write a secret value into this table** — record the field *names* and the env var *names* only.
