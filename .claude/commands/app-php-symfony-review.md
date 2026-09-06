---
description: "Assesses the quality of a PHP file and provides structured improvement recommendations."
argument-hint: "[path to the PHP file to analyze]"
---

Analyze the following PHP file:

**`$ARGUMENTS`**

> **When the argument is empty**, review the app's wiring entry points as one set (the SoT for
> bootstrap · bundle registration · service wiring · scheduling):
>
> - `app/src/Kernel.php`
> - `app/src/Schedule.php`
> - `app/config/services.yaml`
> - `app/config/routes.yaml`
>
> To judge an individual class (Entity · Repository · Service · Handler), pass the target file as an
> argument instead (e.g. `app/src/Service/**`, `app/src/Entity/**`, `app/src/MessageCommandHandler/**`).
> `app/src/**` is expected to grow large, so do not blindly scan files outside the list above or the
> argument you were given, and do not guess a target.
>
> **Verify before reading:** the Symfony app is not scaffolded yet (`app/` holds only `.gitkeep`), so
> treat the paths above as the target layout and report which are missing rather than assuming they exist.

The single source of truth (SoT) for the judgment criteria is the rule files. At the start, read the
rules below, cross-check each clause against the target code, flag violations with the **exact line
number**, and provide concrete fixes (improved code snippets). Do not restate the criteria in this
command — when the rules are updated, this review automatically follows.

@see .claude/rules/app-php-symfony-00-overview-rule.md ~ app-php-symfony-15-scheduler-rule.md — judgment criteria (SoT)
@see .claude/output-styles/app-php-symfony-style.md — code style (PSR-12 · header · formatting)
@see .claude/rules/database-postgresql-rule.md — Doctrine-related
@see .claude/rules/api-platform-rule.md — API-related

## Review Procedure

Identify the layer of the target file and cross-check the corresponding rules: file header · standards
(00 · 02) · PHP 8.4 features · type safety / PHPStan level 8 · class design (01) · DI / Symfony
conventions (04) · Doctrine (05 · postgresql-rule) · Messenger / CQRS (01) · security (08) · error
handling / logging · domain structure (01 · abstract-structure-rule) · performance (11).

## Output Format

### Summary

| Category | Status (OK / WARN / FAIL) | Issue count |
| --- | --- | --- |
| File header and standards | | |
| PHP 8.4 modern features | | |
| Type safety and static analysis | | |
| Class design and architecture | | |
| Dependency injection | | |
| Doctrine ORM | | |
| Messenger / CQRS | | |
| Security | | |
| Error handling and logging | | |
| Domain structure | | |

### Critical Issues (must fix)

For each issue: **[Line N]** description → recommended fix including a code snippet.

### Improvement Suggestions (recommended)

For each suggestion: **[Line N]** description → recommended approach.

### Refactoring Suggestions

Describe structural changes (class extraction, layer relocation, CQRS separation, etc.) with before/after code examples.
