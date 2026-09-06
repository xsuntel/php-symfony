---
name: app-src-service-api-oauth2-build-skill
description: 'Implements or modifies OAuth2 authentication code for a third-party API under app/src/Service/** through a generate → self-verify loop. Covers access-token issue and revoke, approval keys and the Redis token lifecycle. Use it for requests like ''write the OAuth2 client'', ''implement token issuing'', ''fix authentication'' (in any language). The target integration is fixed in step 1 from references/provider-registry.md or from the user''s instruction; the criteria come from that integration''s rule file when registered, and otherwise from app-src-service-api-oauth2-client-skill. For guidance without generating code use app-src-service-api-oauth2-client-skill.'
---

# OAuth2 Build Skill (third-party API integration)

Implements OAuth2 authentication code under `app/src/Service/**` through a **generate → self-verify**
loop, then points at the static analysis gates on a PASS.

**This skill is integration-agnostic.** It fixes the target integration in step 1, loads that
integration's criteria, and owns **only the orchestration** — target selection, the loop, retries and
the gate. It restates neither the authoring conventions nor the judgment criteria.

- Generated output: **real source** (plus wiring YAML and EventSubscribers). The code path comes from
  `references/provider-registry.md` when the integration is registered, and otherwise from the user.
- Verification output: `./.claude/tmp/app/service/{integration}-api-oauth2-review.md` (gitignored)

@see .claude/skills/app-src-service-api-oauth2-build-skill/references/provider-registry.md — integration → code path · criteria · commands · tmp path · secrets
@see .claude/skills/app-src-service-api-oauth2-client-skill/SKILL.md — the transport-layer criteria and checklist (the fallback criteria)
@see .claude/rules/cache-redis-rule.md — cache pool · TTL · lock conventions (SoT)

---

## Workflow

1. **Precondition — fix the target integration and its criteria**
   - Read `references/provider-registry.md`.
   - Identify the target integration: from the user's instruction, or by matching the path being edited
     against the registry's `Code path` column.
   - If it cannot be determined, list the registered integrations, **ask once**, and stop.
   - **Resolve the criteria in this order, and state which one you landed on:**
     1. the integration's **rule file (SoT)** and **build command**, if the registry names them;
     2. otherwise **`app-src-service-api-oauth2-client-skill`**, whose token-lifecycle conventions and
        checklist serve as the criteria, together with `cache-redis-rule.md` and the
        `app-php-symfony-*` rules.
   - Falling back is the normal path for an unregistered integration — **it is not a blocker.** Report
     that no integration-specific SoT exists yet, and that TTL values and secret field names therefore
     **cannot be verified** and must be confirmed against the vendor's official documentation.
   - Confirm the implementation target (token issue/revoke, approval key, Redis storage, refresh) is
     specified. If it is unclear, ask once and stop — **never widen the scope on your own.**

2. **Generate**
   - Edit the target source according to the criteria resolved in step 1.
   - Keep the list of files you changed.

3. **Self-verify**
   - Check the diff (`git diff`) against the criteria's checklist and known gaps, and record a PASS/REDO
     verdict at the verification output path (run `mkdir -p .claude/tmp/app/service` first).
   - **When the verdict is uncertain, choose REDO over PASS.**

4. **Branch on the verdict**
   - **PASS:** report the change summary, point at the quality gates below, and stop (never commit
     automatically).

     ```bash
     cd app && vendor/bin/phpstan analyse
     cd app && vendor/bin/php-cs-fixer fix
     ```

     Then recommend an integration procedure test — via the registry's `Test command` if one is
     registered, otherwise a Functional test per `app-php-symfony-09-testing-rule.md`.
     > **These gates cannot run today.** `[Verified]` 2026-09-06 — `app/` contains only `.gitkeep`, so
     > there is no `vendor/`. Report the gates as **not run**, never as passed.
   - **REDO:** apply **only** the instructions in the verification output and repeat from step 2 (change
     nothing the instructions did not name). **Maximum 3 retries.**

5. **Retry limit**
   - Still REDO after 3 retries: **stop where you are** without reverting the source.
   - Present the last review's unresolved instructions and end with the warning "automatic verification
     limit reached — manual review recommended".

- Never include a secret value (the keys, tokens and approval keys named in the registry's `Secrets`
  column) in any output — this applies with particular force here, since credentials are this skill's
  whole subject.
