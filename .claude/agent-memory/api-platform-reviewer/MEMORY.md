# api-platform-reviewer memory

## REDO trigger checks (verified)

- Direct Entity exposure (→ use an `app/src/ApiResource/` DTO), unspecified `operations:` (relying on the
  default set), read/write `#[Groups]` mismatch or sensitive-field exposure → REDO.
- State not wired (missing operation `provider:`/`processor:`) or domain logic accumulated in the
  Provider/Processor → REDO. Manual implementation without considering built-in Doctrine reuse
  (`stateOptions` + `#[Map]`) → flag.
- New use of the legacy `#[ApiFilter]`, or manual LIMIT/OFFSET inside the Provider → flag. Validation via
  manual `if` instead of `#[Assert]` → REDO. Hand-assembled custom error response (bypassing RFC
  7807/Hydra) → REDO.
- Misuse of the operation `security:` expression variables (`user`/`object`/`previous_object`),
  uncontrolled sensitive-field groups, `symfony/rate-limiter` not applied → flag.

## Judgment principles

- Classify findings as `[MUST]/[SHOULD]/[CONSIDER]` and cite `file:line`. Base reasoning only on the SoT
  and project files; no guessing.

## Team collaboration (hand-off)

- Role: Review (quality gate, read-only) · upstream: **`api-platform-author`** (the generation half, the
  usual path when `api-agent-team` spawns the pair) / main routing / the `api-platform-rest-build-skill` ·
  `api-platform-oauth2-build-skill` build skills / `api-platform-tester` (gating its TDD output)
- Downstream: `[MUST]` fixes return to whoever authored — **`api-platform-author`** when the pair was
  spawned, `api-platform-tester` for a test-first cycle, otherwise the main agent under the build
  skill. The orchestrator owns the retry budget (max 3, code domains). Regression → `api-platform-tester`;
  **security findings → `api-platform-analyzer`** (severity diagnosis); **structural debt →
  `api-platform-author`** (implement); domain logic behind a State → `app-php-symfony-reviewer`
- **`api-platform-author` exists again as of 2026-08-22** — it was dissolved on 2026-08-17 (renamed to
  `api-platform-analyzer`, which became a read-only axis) and revived to restore the author→reviewer
  pair. An earlier version of this note said it does not exist and must never be named as a fix
  target; that is obsolete. It **is** the fix target, and it does not own the authoring conventions —
  the two `*-build` commands remain SoT for those.
- Orchestrator: `api-agent-team` agent / `/api-platform-review` command (single reviews route directly from main)
- Design SoT: .claude/docs/api-agent-team-docs.md

## SoT

- .claude/rules/api-platform-rule.md
- .claude/rules/app-php-symfony-08-security-rule.md (security, CSRF, rate limiting)
