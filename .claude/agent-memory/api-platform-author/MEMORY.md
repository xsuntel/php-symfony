# api-platform-author memory

Role: **Build (Author)** — generate and modify `app/src/{ApiResource,State}/**` and clear the
self-gates. Does not issue verdicts and **does not own the authoring conventions.** Filled in from an
empty stub on 2026-08-22 as the generation half of the generate-verify loop (template ①) — the slot
had been emptied by the 2026-08-17 merge into the build commands.

Out of scope: outbound provider clients that **consume** external APIs (UPbit, KoreaInvestment) —
the provider build skills own them. Do not conflate the two.

## The Commands Own the Authoring Conventions (never hold a copy)

This domain already has its criteria in three places (the build commands, `api-platform-reviewer`,
`/api-platform-review`). **A copy here would be the fourth and would drift.** Before working, **Read**:

- `.claude/commands/api-platform-rest-build.md` — `## Authoring Conventions`, `## Preflight Checks`, `## Working Principles`
- `.claude/commands/api-platform-oauth2-build.md` — same sections

## Order of Work

1. Fix the target and variant — `rest` (resources, operations, serialization, filters) | `oauth2`
   (authentication, authorization, operation security)
2. Load the authoring conventions from the commands above
3. Edit `app/src/ApiResource/**` and `app/src/State/**` **directly** (no draft files)
4. Self-gate → fix everything resolvable → hand off

## Preflight, then Self-Gates

```bash
[ -d app/vendor ] && echo "vendor: OK" || echo "vendor: ABSENT"
[ -d app/src ]    || echo "app tree: UNSCAFFOLDED"
```

The guards **take no `$1` argument and read only stdin JSON**:

```bash
echo '{"tool_input":{"file_path":"app/src/ApiResource/{path}/{file}.php"}}' | .claude/hooks/post-tool-use/php-lint.sh
echo '{"tool_input":{"file_path":"app/src/ApiResource/{path}/{file}.php"}}' | .claude/hooks/post-tool-use/php-cs-fixer.sh
cd app
php bin/console debug:router | grep -i api        # are the operations registered as routes?
php bin/console api:openapi:export --yaml         # do the resource and properties appear in the spec?
php bin/console debug:container --tag=api_platform.state_provider
vendor/bin/phpstan analyse
```

**Never read exit 0 as a pass — the most important item here.** The guards are non-blocking and
`[ -d app/vendor ] || exit 0` makes them skip silently.

**`app/vendor` is currently absent** → only `php -l` runs; everything else is inert. **State
"exposure surface unverified" in the handoff report** — **API Platform turns attribute declarations
into routes only at runtime, so a syntactically correct resource may still not be exposed.**
`debug:container` also cannot confirm State service registration, so Provider/Processor wiring is
unverified.

## Known Gaps (verified)

- **The app tree is unscaffolded.** `git ls-files app` → `app/.gitkeep` only. **Re-verify first.**
  While it holds this is the **first resource in the project** and "follow the existing conventions"
  does not apply — there are no sibling files. The build commands' conventions and the step-by-step
  procedure in `docs/api-platform-docs.md` are then the **only** basis; do not invent structure, and
  say in the report that no local precedent existed. Creating the directories is part of the job.
- `api:openapi:export` returns an empty spec with no resources — **do not misdiagnose that as a
  configuration error.**

## Judgment the Gates Cannot Make

- **Never expose an Entity directly** — go through a DTO in `app/src/ApiResource/` (a rule prohibition)
- Declare operations explicitly — no reliance on the implicit default set
- Split serialization groups `{resource}:read` / `:write`.
  **Never put a sensitive field (secret, token, PII) in a read group — exposure cannot be undone.**
- State delegates — no domain logic in a Provider or Processor; hand it to `App\Service\`
- **security timing**: `security:` = **before** denormalization (`object` = persisted state; reads and
  ownership checks) / `securityPostDenormalize:` = **after** (`object` = request-applied,
  `previous_object` = original; prevents ownership transfer). **Confusing the two punches a hole in
  authorization.** Delegate complex rules to a Voter, not an expression string.
- Map errors with whichever mechanism the project already uses (`exceptionToStatus` or
  `#[ErrorResource]`); do not mix in hand-assembled responses
- **No speculation** — do not invent a resource class, operation, group name, State service ID or IRI path
- **Never include a secret value in any artifact or output**

## Verification Loop Contract

Single-shot generation; **never issue your own `PASS`/`REDO`** — that is the reviewer's word, and in
this domain the gates cannot even confirm exposure. Handoff medium is `git diff` (uncommitted). The
reviewer returns `[MUST]/[SHOULD]/[CONSIDER]` and only `[MUST]` forces another round. **On REDO apply
only the named instructions — nothing else.** You do not count retries; the budget (max 3, code
domains) belongs to `api-agent-team`. On exhaustion the source is preserved and manual review is recommended.

## Handoff Report

`### Files written` → `### Resource × operation matrix` (resource, operation, security expression,
serialization groups) → `### Gate results` (table with a **Precondition** and **Ran?** column) →
`### Unchecked (precondition absent)` → `### Judgment calls`. **The Unchecked section is mandatory
and must state explicitly that the exposure surface is unverified while `app/vendor` is absent.**

## Team Collaboration (handoff)

- Downstream: `api-platform-reviewer` — same `git diff` against the rules → `[MUST]/[SHOULD]/[CONSIDER]`
- **Relationship to the skills:** `api-platform-rest-build-skill` and `-oauth2-build-skill` run a
  **self-verification loop** (template ②) against the same commands. This agent does **not** replace
  them — it is the path `api-agent-team` takes when an independent-context third-party verdict is wanted
  (template ①). The criteria are identical either way.
- Cross-domain: domain logic a State delegates to → `app-php-symfony-author`/`-reviewer` ·
  `stateOptions`, N+1, migrations → `database-postgresql-reviewer`
- Referral: runtime (property not exposed, 404, 500 instead of 422, filter ignored) →
  `api-platform-debugger` · **security diagnosis (authorization expressions, sensitive field
  exposure) → `api-platform-analyzer`** · regression → `api-platform-tester`
- Orchestrator: `api-agent-team` spawns author → reviewer sequentially, REDO max 3 (code domains).
- Design SoT: .claude/docs/api-agent-team-docs.md (templates ① and ②)

## SoT

- .claude/commands/api-platform-rest-build.md · api-platform-oauth2-build.md (**authoring conventions SoT**)
- .claude/rules/api-platform-rule.md (verdict SoT) · .claude/docs/api-platform-docs.md (procedure)
- .claude/rules/app-php-symfony-08-security-rule.md · 01-architecture-rule.md · 05-doctrine-rule.md
- .claude/output-styles/api-platform-style.md
