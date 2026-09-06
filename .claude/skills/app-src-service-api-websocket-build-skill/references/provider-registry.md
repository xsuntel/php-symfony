# WebSocket Integration Registry (build)

The dispatch table `app-src-service-api-websocket-build-skill` uses in step 1 to **fix the target
integration**.

**This is not judgment criteria** — only coordinates live here. Authoring conventions, the verification
checklist and known gaps belong to the `Build command`; integration-specific facts (hosts, channel
identifiers, subscription limits) belong to the rule file that
`app-src-service-api-websocket-client-skill` points at. **Never copy that content into this table.**

## Registered integrations

| Integration | Code path (glob) | Build command | Test command | Verification output (tmp) | Secrets |
| --- | --- | --- | --- | --- | --- |
| _(none registered)_ | — | — | — | — | — |

> ⚠️ **The table is deliberately empty.** `[Verified]` 2026-09-06 — this project has no third-party
> WebSocket integration registered yet, and `app/` contains only `.gitkeep`.

## When nothing is registered

**An empty table is not a blocker.** Step 1 of the build skill falls back to
`app-src-service-api-websocket-client-skill` for the criteria, and the target integration and code path
come from the user's instruction. In that mode:

- write the verification output to `./.claude/tmp/app/service/{integration}-api-websocket-review.md`
  (run `mkdir -p .claude/tmp/app/service` first);
- treat **channel identifiers, the concurrent-subscription limit and the keep-alive shape** as
  unverifiable and say so;
- treat **every string that could be a credential** as a secret, since no `Secrets` column exists to
  enumerate them — and never log a handshake URL verbatim.

**Be especially careful reporting a PASS here.** Reconnection, subscription restore and keep-alive are
only observable at runtime, so a static gate passing says nothing about them. Report them as unverified
unless a worker was actually run.

## Registering an integration

This skill is fixed regardless of how many integrations exist. To add one, create **one row above** plus
the artifacts below — do not edit the skill body.

1. `.claude/rules/{integration}-api-websocket-rule.md` — the judgment criteria (SoT). **Required.**
2. `.claude/commands/{integration}-api-websocket-build.md` — authoring conventions and verification
   checklist. Optional; without it, leave `Build command` as `—` and the skill falls back to the client
   skill.
3. `.claude/commands/{integration}-api-websocket-review.md` and `{integration}-api-websocket-test.md` —
   optional.
4. `.claude/docs/{integration}-api-websocket-docs.md` — a detailed reference (optional).
5. Add the matching row to
   `.claude/skills/app-src-service-api-websocket-client-skill/references/provider-registry.md`, which
   holds the rule, host and official-documentation coordinates.

**All `.claude/**` trees are flat** — name new artifacts `<domain>-<name>-<kind>.md` with the domain as a
hyphenated filename prefix, never as a directory tier
(`rules/utility-claude-code-rule.md` is the SoT for that).

**Fill in the `Secrets` column with names only — never values.** On this transport that includes any
approval key used in the handshake, which is issued through the OAuth2 path and must not be a reused
REST access token.
