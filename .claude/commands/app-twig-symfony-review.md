---
description: "Assesses the quality of a Twig file and provides structured improvement recommendations."
argument-hint: "[path to the Twig file to analyze]"
---

Analyze the following Twig template:

**`$ARGUMENTS`**

> **When the argument is empty**, review the root templates of the inheritance skeleton as one set,
> cross-checking the block contract between the global root and the theme layouts:
>
> - `app/templates/base.html.twig`
> - `app/templates/themes/corporate/base.html.twig`
> - `app/templates/themes/dashboard/base.html.twig`
>
> To judge a page, partial, component, or Turbo Stream template, pass the target file as an argument
> instead (e.g.  `app/templates/bundles/**`,`app/templates/controller/**`, `app/templates/twig/components/**`,
> `app/templates/turbo/frames/**`,`app/templates/turbo/streams/**`).
> Do not blindly scan `app/templates/**` outside the list above or the argument you were given, and do not guess a target.
>
> **Verify before reading:** the Symfony app is not scaffolded yet (`app/` holds only `.gitkeep`), so
> treat the paths above as the target layout and report which are missing rather than assuming they exist.

The single source of truth (SoT) for the judgment criteria is the rule files. At the start, read the
rules below, cross-check each clause against the target template, flag violations with the **exact line
number**, and provide concrete fixes (improved code snippets). Do not restate the criteria in this
command.

@see .claude/rules/app-twig-symfony-00-overview-rule.md — Twig standards, escaping, security (SoT)
@see .claude/rules/app-php-symfony-07-template-rule.md — naming, inheritance, components
@see .claude/rules/app-php-symfony-10-frontend-rule.md — AssetMapper, Stimulus, UX
@see .claude/rules/app-php-symfony-08-security-rule.md — XSS, CSRF
@see .claude/docs/app-twig-symfony-docs.md — syntax/function details

Follow Part 3 of the `app-twig-symfony-skill` skill for the review methodology, cross-checks, and output format.

## Review Procedure

1. Determine the target template's role (layout / page / `_partial` / macro / form theme / component).
2. Check it against the SoT rules above. Core checks:
   - Auto-escaping preserved — no `|raw`/`{% autoescape false %}` on user/DB input.
   - URLs/assets referenced via `path()`/`url()`/`asset()` (no hardcoding).
   - CSRF (`_token`/`csrf_token()`) on state-changing forms; permission UI wrapped in `is_granted()`.
   - No Repository/DB calls or business logic in the template (data prepared in the controller/Extension).
   - Constants/enums referenced via `enum()`/`enum_cases()`/`constant()` instead of magic strings.
   - No `render(controller())` fragment overuse (simple reuse via `include`/component); global values injected via `twig.yaml globals`.
   - Duplicated markup removed with inheritance/partials/macros; no leftover `{{ dump() }}`; accessibility (alt/label).
3. Statically validate syntax/deprecations with `cd app && php bin/console lint:twig {path}`.

## Output

Classify by severity `[MUST]` (XSS, CSRF, render exception, rule violation — blocks merge) / `[SHOULD]`
(duplication, performance, accessibility) / `[CONSIDER]` (style). Output order: **summary → [MUST] →
[SHOULD] → [CONSIDER] → positive feedback (at least 1, cite file:line)**.
