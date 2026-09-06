# OAuth2 Integration Registry (build)

The dispatch table `app-src-service-api-oauth2-build-skill` uses in step 1 to **fix the target
integration**.

**This is not judgment criteria** — only coordinates live here. Authoring conventions, the verification
checklist and known gaps belong to the `Build command`; integration-specific facts (token endpoints,
secret field names, TTL values) belong to the rule file that
`app-src-service-api-oauth2-client-skill` points at. **Never copy that content into this table.**

## Registered integrations

| Integration | Code path (glob) | Build command | Test command | Verification output (tmp) | Secrets |
| --- | --- | --- | --- | --- | --- |
| _(none registered)_ | — | — | — | — | — |

> ⚠️ **The table is deliberately empty.** `[Verified]` 2026-09-06 — this project has no third-party
> OAuth2 integration registered yet, and `app/` contains only `.gitkeep`.

## When nothing is registered

**An empty table is not a blocker.** Step 1 of the build skill falls back to
`app-src-service-api-oauth2-client-skill` for the criteria, and the target integration and code path come
from the user's instruction. In that mode:

- write the verification output to `./.claude/tmp/app/service/{integration}-api-oauth2-review.md`
  (run `mkdir -p .claude/tmp/app/service` first);
- treat **TTL values, the expiry buffer and secret field names** as unverifiable and say so — these are
  the values that cause silent damage when guessed;
- treat **every string that could be a credential** as a secret, since no `Secrets` column exists to
  enumerate them. On this transport that is the default posture, not a precaution.

## Registering an integration

This skill is fixed regardless of how many integrations exist. To add one, create **one row above** plus
the artifacts below — do not edit the skill body.

1. `.claude/rules/{integration}-api-oauth2-rule.md` — the judgment criteria (SoT). **Required.**
2. `.claude/commands/{integration}-api-oauth2-build.md` — authoring conventions and verification
   checklist. Optional; without it, leave `Build command` as `—` and the skill falls back to the client
   skill.
3. `.claude/commands/{integration}-api-oauth2-review.md` and `{integration}-api-oauth2-test.md` —
   optional.
4. `.claude/docs/{integration}-api-oauth2-docs.md` — a detailed reference (optional).
5. Add the matching row to
   `.claude/skills/app-src-service-api-oauth2-client-skill/references/provider-registry.md`, which holds
   the rule, cache pool and official-documentation coordinates.

**All `.claude/**` trees are flat** — name new artifacts `<domain>-<name>-<kind>.md` with the domain as a
hyphenated filename prefix, never as a directory tier
(`rules/utility-claude-code-rule.md` is the SoT for that).

**Fill in the `Secrets` column precisely, with names only — never values.** List every credential the
integration handles: application key, application secret, issued access token, and any separate approval
key used for a WebSocket handshake. The build skill reads this column to know what must never reach any
output.
