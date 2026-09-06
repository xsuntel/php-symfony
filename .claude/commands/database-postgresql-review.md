---
description: "Assesses the quality of Doctrine Entity / Repository / Migration code and provides structured improvement recommendations."
argument-hint: "[path to the file to analyze (an Entity, Repository, or Migration)]"
---

Analyze the following database-related file:

**`$ARGUMENTS`**

> **When the argument is empty**, review the Doctrine config files as a single set (the SoT for the
> multi-EntityManager connections and the migration settings):
>
> - `app/config/packages/doctrine.yaml`
> - `app/config/packages/doctrine_migrations.yaml`
> - `app/config/packages/dev/doctrine.yaml`
> - `app/config/packages/prod/doctrine.yaml`
>
> When code-level judgment is needed (entity design, repositories, N+1, migrations, etc.), pass the
> target file as the argument — e.g. `app/src/Entity/**`, `app/src/Repository/**`,
> `app/src/EntityRepository/**`, `app/migrations/**`. Do not blindly scan files outside the list above or
> the argument you were given, and do not guess a target.

The single source of truth (SoT) for the judgment criteria is the rule file. At the start, read the rule
below, cross-check each provision against the target code, flag violations with the **exact line number**,
and provide concrete fixes (improved code snippets). Do not restate the criteria in this command — when
the rule is updated, this review follows automatically.

Before flagging, determine which EntityManager / connection the target file belongs to (from its
namespace directory) so the multi-EntityManager criteria can be judged correctly and generic-Doctrine
false positives avoided.

@see .claude/rules/database-postgresql-rule.md — judgment criteria (SoT)
@see <https://symfony.com/doc/current/doctrine.html> — Doctrine with Symfony (official)

> **Note:** this project intentionally differs from some Doctrine defaults — repositories extend
> `Doctrine\ORM\EntityRepository` (not `ServiceEntityRepository`) because `ManagerRegistry` cannot
> reliably resolve the correct EntityManager in this **multi-database / multi-EntityManager** setup, and
> cross-EntityManager associations are deliberately absent (pass an identifier and re-fetch instead). Do
> not flag these against general single-database advice — judge only against the SoT rule.

## Review Procedure

Cross-check each section of the rule in order: multiple EntityManagers · table naming · entity class
design · timezone · column mapping · index strategy · lifecycle callbacks · repository rules · migration
workflow · PostgreSQL-specific features. Focus by target type: for a Migration file, the migration-workflow
and index sections; for an Entity, design/columns/timezone/lifecycle callbacks; for a Repository, the
repository rules and N+1.

## Output Format

### Summary

| Category | Status (OK / WARN / FAIL) | Issue count |
| --- | --- | --- |
| Multiple EntityManagers | | |
| Table naming conventions | | |
| Entity class design | | |
| Timezone | | |
| Column mapping | | |
| Index strategy | | |
| Lifecycle callbacks | | |
| Repository rules | | |
| Migration workflow | | |
| PostgreSQL-specific features | | |

### Critical Issues (must fix)

For each issue: **[Line N]** `[MUST]` description → recommended fix including a code snippet.

### Improvement Suggestions (recommended)

For each suggestion: **[Line N]** `[SHOULD]` description → recommended approach.

### Refactoring Suggestions

Mark structural changes (swapping the repository base class, eliminating N+1, adding an index, splitting a
destructive change into a two-step migration, etc.) as `[CONSIDER]` and describe them with before/after
code examples. Only `[MUST]` blocks a merge.
