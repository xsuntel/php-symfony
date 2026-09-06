# REST Integration Registry (client)

The dispatch table `app-src-service-api-rest-client-skill` uses to locate each integration's
**judgment criteria (SoT) and configuration coordinates**.

**This is not judgment criteria** — only coordinates live here. Endpoint paths, the auth scheme, request
identifiers, hosts, rate-limit numbers and response schemas all belong in the rule file named in the
`Judgment criteria (SoT)` column. **Never copy that content into this table.**

## Registered integrations

| Integration | Code path | Judgment criteria (SoT) | Parameter YAML | Service wiring YAML | Official docs |
| --- | --- | --- | --- | --- | --- |
| _(none registered)_ | — | — | — | — | — |

> ⚠️ **The table is deliberately empty.** `[Verified]` 2026-09-06 — this project has no third-party REST
> integration registered yet, and `app/` contains only `.gitkeep`. An empty registry is a valid state,
> not a gap to be filled with placeholder rows.

## When nothing is registered

The client skill still works with an empty table — its transport-layer conventions and checklist apply
to any REST integration. What you lose without a row is only the **integration-specific** half:

- endpoint paths, hosts and environment variants;
- the authentication scheme and header or field names;
- rate-limit numbers and request identifiers;
- response schemas.

**Report those as unverifiable rather than guessing them.** Confirm them against the vendor's official
documentation and, if the integration is going to persist, register it below.

## Registering an integration

This skill is fixed regardless of how many integrations exist. To add one, create **one row above** plus
the artifacts below — do not edit the skill body.

1. `.claude/rules/{integration}-api-rest-rule.md` — the judgment criteria (SoT). **Required**: without
   it the integration has no criteria of its own and reviews fall back to transport-layer checks only.
   Follow the flat naming convention in `rules/utility-claude-code-rule.md`.
2. `app/config/parameters/.../{integration}.yaml` — the endpoint parameter tree. **Required**, because
   the client skill forbids hardcoded URLs.
3. `app/config/services/.../{integration}.yaml` — decorator and scoped-client wiring.
4. `.claude/docs/{integration}-api-rest-docs.md` — a detailed reference (optional; the rule↔docs pairing
   convention applies if you create it).
5. Add the matching row to
   `.claude/skills/app-src-service-api-rest-build-skill/references/provider-registry.md`, which holds
   the build and test coordinates.

**Record the secret shape in the build registry, not here** — in particular, note whether the apiKey
travels in the URL, because that makes the entire request URL a secret.
