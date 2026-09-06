---
description: "Creates/modifies the authentication and authorization code for the API exposed via API Platform (Symfony), then self-verifies it against the SoT rules."
argument-hint: "[implementation target (firewall · authenticator · operation access control · Voter scope)]"
---

Handle the following API Platform authentication/authorization implementation target:

**`$ARGUMENTS`**

If no argument is given, **ask once for the implementation target** (firewall · authenticator ·
operation access control · Voter scope) **and stop** — do not widen the scope on your own. Edit the real
sources per `## Authoring Conventions` below, then cross-check the change (`git diff`) via
`## Self-Verification` and issue a PASS/REDO verdict.

This command is **inbound only** — it protects the API we expose. Outbound OAuth2/JWT for consuming
external provider APIs is out of scope; no provider build command exists yet (see `TODO.md`).

Default target paths:

- `app/src/ApiResource/` — operation `security:` / `securityPostDenormalize:` / `securityMessage:`
- `app/src/Security/` — Voters
- `app/config/packages/security.yaml` — firewalls and authenticators
- `app/config/packages/rate_limiter.yaml` — rate-limiter wiring for public endpoints

The single source of truth (SoT) for the criteria is the rule files. Read the following and cross-check
each clause — this command does not restate the criteria.

@see .claude/rules/api-platform-rule.md — judgment criteria (SoT, `## Security` section)
@see .claude/rules/app-php-symfony-08-security-rule.md — authentication · authorization · CSRF · rate limiter (SoT)
@see .claude/commands/api-platform-review.md — codebase-specific checkpoints (verification procedure)
@see .claude/skills/api-platform-oauth2-client-skill/SKILL.md — when only an implementation guide is needed
@see <https://api-platform.com/docs/symfony/security/> — official docs

## Authoring Conventions (essentials — details live in the rules)

- Distinguish the two access-control hooks by meaning and use each accordingly: the operation's
  `security:` runs **before** denormalization (for decisions that do not depend on input values), while
  `securityPostDenormalize:` runs **after** it (for decisions that need an `object` /
  `previous_object` comparison). Do not swap them out of habit.
- Use only the `user` · `object` · `previous_object` · `request` expression variables, and do not invent
  an unconfirmed one. State the denial reason explicitly via `securityMessage:`.
- **When the same authorization rule is repeated as a string across several operations, extract it into a
  Voter** and call it as `is_granted('ATTRIBUTE', object)`. Place Voters in `app/src/Security/` and extend
  `Symfony\Component\Security\Core\Authorization\Voter\Voter`.
- Keep `stateless: true` on the `^/api` firewall — that is precisely the grounds for not requiring a CSRF
  token, since the firewall is not session-based. Any change that turns statelessness off must weigh the
  CSRF impact at the same time.
- Wire `symfony/rate-limiter` onto public (unauthenticated) endpoints.
- Reference secrets (JWT signing keys · passphrases · tokens) **only through environment variables or a
  secrets manager** — never leave them as literals in config files, code, logs, or exception messages.
- Let API Platform serialize authorization failures as RFC 7807/Hydra — no custom error response
  assembly.
- Write every PHP file assuming `declare(strict_types=1)`, `final`/`readonly`, constructor promotion
  injection, and PHPStan level 8.
- Write only complete, runnable code — no unrequested `// TODO` or placeholders, and include the `use`
  statements at the top.
- **On a REDO pass, do not change anything the correction instruction did not ask for.**

## Preflight Checks

The Symfony app is not scaffolded yet — `app/` currently holds only `.gitkeep`. Verify each item below
against the real tree before writing code, and **never assert which authentication method is active**.

- Does `app/config/packages/security.yaml` exist and define an `^/api` firewall with `stateless: true`?
  If it is absent, say so before wiring an authenticator.
- Is `lexik/jwt-authentication-bundle` installed, and is the firewall actually enabled? Confirm both
  before implementing a token issuance/verification mechanism, and tell the user first if installation or
  activation is needed. Do not repurpose `firebase/php-jwt` as an inbound authenticator — it is for
  outbound providers only.
- Do `app/src/ApiResource/` and `app/src/Security/` exist? With no operations to protect yet, create the
  resource first via `/api-platform-rest-build`. When adding the first Voter, also confirm the
  `App\Security\` namespace is autoconfigured in `config/services.yaml`.

## Self-Verification

Cross-check the change (`git diff`) in the order below and issue a PASS/REDO verdict. **When the verdict
is uncertain, choose REDO over PASS.**

1. Cross-check each clause of `.claude/rules/api-platform-rule.md` (`## Security`) and
   `.claude/rules/app-php-symfony-08-security-rule.md` against the changed files.
2. Sweep the security items in `## Review Procedure` of `.claude/commands/api-platform-review.md`
   (operation security · securityPostDenormalize · securityMessage · Voter · stateless · rate limiter).
3. Confirm that each item of `## Authoring Conventions` above and `## Preflight Checks` was applied — in
   particular, **any code that presumes an uninstalled bundle is a REDO**.
4. Classify findings as `[MUST]` / `[SHOULD]` / `[CONSIDER]` and cite **file:line**. A single `[MUST]`
   means REDO.

The static gates (`vendor/bin/phpstan analyse` · `vendor/bin/php-cs-fixer fix`) are recommended after a
PASS verdict; this command neither runs them automatically nor commits.

## Working Principles

- Do not touch files outside the target scope.
- **Never include secret values (JWT signing keys · tokens · passphrases) in any output.**
- Once access control is complete, hand off to the `api-platform-tester` agent when authorization-denial
  (401/403) regression tests are needed.

## Output Format

Present the list of changed files → the self-verification verdict (PASS/REDO + findings) → a summary of
the change under the **How it works / Why this way / Next steps** headings. For a multi-file response,
state the file path in a comment before each code block.
