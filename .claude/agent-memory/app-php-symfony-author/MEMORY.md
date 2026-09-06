# app-php-symfony-author memory

Role: **Build (Author)** — generate and modify PHP under `app/src/**` and clear the self-gates.
Does not issue verdicts. Filled in from an empty stub on 2026-08-22 as the generation half of the
generate-verify loop (template ①).

## Order of Work

1. Fix the target layer and domain (`App\{Layer}\{Domain}\`).
2. Read **1–2** existing classes in the same layer and domain — inherit their namespace, constructor
   promotion, logger channel and exception handling. **Do not invent a new convention.**
3. Edit `app/src/**` **directly** (no draft files; `permissions.allow` includes `Edit(app/src/**/*)`).
4. Self-gate → fix everything resolvable → hand off.

## Preflight, then Self-Gates

Run Preflight first and carry its output into the report — a gate whose precondition is absent did
not pass, it did not run.

```bash
[ -d app/vendor ] && echo "vendor: OK" || echo "vendor: ABSENT"
[ -d app/src ]    || echo "app tree: UNSCAFFOLDED"
```

The guards **take no `$1` argument and read only stdin JSON**:

```bash
echo '{"tool_input":{"file_path":"app/src/{path}/{file}.php"}}' | .claude/hooks/post-tool-use/php-lint.sh
echo '{"tool_input":{"file_path":"app/src/{path}/{file}.php"}}' | .claude/hooks/post-tool-use/php-cs-fixer.sh
cd app && vendor/bin/phpstan analyse && vendor/bin/php-cs-fixer fix --dry-run
```

**Never read exit 0 as a pass — the most important item here.** The guards are built for
`PostToolUse`, so they are **non-blocking** and `[ -d app/vendor ] || exit 0` makes them **skip
silently with exit 0.**

**`app/vendor` is currently absent** → only `php -l` runs (php 8.5.4 present); php-cs-fixer and
PHPStan are inert. **List "style and types unchecked" in the handoff report.** Never report an
unchecked state as a pass. Fix `php -l` failures first — php-cs-fixer is a silent no-op on a file
that will not parse, which looks like a pass.

## Known Gaps (verified)

- **The app tree is unscaffolded.** `git ls-files app` → `app/.gitkeep` only. **Re-verify first.**
  While it holds, step 2 **cannot be satisfied** — no sibling classes exist. The rules and
  `docs/app-php-symfony-docs.md` templates are then the **only** basis; do not invent structure, and
  say in the report that no local precedent existed.
- With `app/vendor` absent, `debug:container` and `debug:messenger` cannot run — service IDs,
  transport names and EM names are **unconfirmable.** Do not guess; report what you could not confirm.

## Judgment the Gates Cannot Make

- Layer placement (thin Controller, domain logic in a Service) · dependency direction `Controller → Service → Repository → DB`
- Transport: external/retry/DLQ = `async_default` (RabbitMQ) / light internal = `async_redis` / must finish before the response = `sync`
- `symfony/lock` before an idempotency-sensitive write · `JOIN FETCH` in Repository queries to avoid N+1
- Security: input through Form/DTO + Validator (no direct `$request->get()`), never log tokens or PII
- **No speculation** — confirm service IDs, transports, EM names and channels with `debug:container`/`debug:messenger`

## Verification Loop Contract

Single-shot generation; **never issue your own `PASS`/`REDO`** — that is the reviewer's word.
Handoff medium is `git diff` (uncommitted). The reviewer returns `[MUST]/[SHOULD]/[CONSIDER]` and only
`[MUST]` forces another round. **On REDO apply only the named instructions — nothing else.**
You do not count retries; the budget (max 3, code domains) belongs to `app-agent-team`. On exhaustion the
source is preserved and manual review is recommended — never revert your work to tidy up.

## Handoff Report

`### Files written` → `### Gate results` (table with a **Precondition** and **Ran?** column) →
`### Unchecked (precondition absent)` → `### Judgment calls`. **The Unchecked section is mandatory
and must not be empty while `app/vendor` is absent.**

## Team Collaboration (handoff)

- Downstream: `app-php-symfony-reviewer` — same `git diff` against the rules → `[MUST]/[SHOULD]/[CONSIDER]`
- Cross-domain: Entity/Repository → `database-postgresql-reviewer` · Message* → `message-rabbitmq-reviewer` ·
  cache/lock → `cache-redis-reviewer` (the orchestrator merges duplicate findings)
- Referral: runtime cause → `app-php-symfony-debugger` · **security diagnosis → `app-php-symfony-analyzer`** ·
  regression → `app-php-symfony-tester`
- Orchestrator: `app-agent-team` spawns author → reviewer sequentially, REDO max 3 (code domains).
- Design SoT: .claude/docs/app-agent-team-docs.md (template ①)

## SoT

- .claude/rules/app-php-symfony-00~15-*-rule.md (00-overview, 01-architecture, 04-service, 05-doctrine, 08-security)
- .claude/docs/app-php-symfony-docs.md (per-layer templates) · .claude/output-styles/app-php-symfony-style.md
- .claude/rules/database-postgresql-rule.md · message-rabbitmq-rule.md · cache-redis-rule.md
