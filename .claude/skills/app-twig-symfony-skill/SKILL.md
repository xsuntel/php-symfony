---
name: app-twig-symfony-skill
description: Use in this Symfony 8 / Twig 3.x project when analyzing template structure, guiding the use of Twig/frontend libraries (AssetMapper, UX), or reviewing template changes. Covers the template inheritance tree, partial/macro/component mapping, path/asset/is_granted usage, auto-escaping/CSRF checks, importmap management, and the render review checklist. Triggered by documenting template structure, understanding Twig Extensions, importmap:require, lint:twig, template review, and identifying render bugs.
---

# Twig / Symfony Skill

A unified entry point for template structure analysis, frontend library guidance, and template review.
Apply the relevant Part based on the nature of the request.

| Request Type                                                                  | Applicable Section           |
| ----------------------------------------------------------------------------- | ---------------------------- |
| Template structure analysis, inheritance tree/component mapping               | Part 1 — Template Analysis   |
| Twig/frontend library install/config/usage                                    | Part 2 — Library Usage Guide |
| Template change review, render bug identification, PR improvement suggestions | Part 3 — Template Review     |

## Information Source (single source of truth: rule files)

Twig syntax, template conventions, and judgment criteria are **all single-sourced (SoT) in the rule files**.
This skill does not restate the rules; it provides only the analysis methodology, operational commands, and output format.

@see .claude/rules/app-twig-symfony-00-overview-rule.md — full Twig criteria (SoT)
@see .claude/rules/app-php-symfony-07-template-rule.md — naming, inheritance, components
@see .claude/rules/app-php-symfony-10-frontend-rule.md — AssetMapper, Stimulus, UX
@see .claude/docs/app-twig-symfony-docs.md — detailed syntax/function examples

Use only project files as evidence (`app/templates/`, `app/src/Twig/`, `app/config/packages/twig.yaml`, `importmap.php`).
If something cannot be confirmed, state "This information is not confirmed in the project files."

---

# Part 1 — Template Analysis

Map top-down. Do not assume directories/templates exist — confirm with Glob.

1. **Layout root** → identify the block list of `app/templates/base.html.twig` (`title`/`stylesheets`/`body`/`javascripts`, etc.).
2. **Inheritance tree** → follow each page's `{% extends %}` target to map the 3 levels base → section layout → page.
3. **Partials/macros/components** → list `_`-prefixed partials (include/embed targets), `{% macro %}`/`{% import %}`, and `app/src/Twig/Components/` (TwigComponent).
4. **Twig Extensions** → confirm the custom filters/functions in `app/src/Twig/` (`#[AsTwigFilter]`/`#[AsTwigFunction]` or `AbstractExtension`) with `php bin/console debug:twig`.
5. **Globals/paths/themes** → list `globals`/`paths` (namespace `@name`)/`form_themes` in `config/packages/twig.yaml`.
6. **Controller bindings** → check the `render()`/`#[Template]`/`renderBlock()` call sites that render page templates against the passed variable keys.
7. **Fragment mapping** → connect `{{ render(controller(...)) }}`/`{{ render(path(...)) }}` call sites to their target controllers to understand the sub-request graph.

## Output Format

- **Inheritance summary**: the `base → {section}/layout → {page}` tree and the blocks each level defines/overrides.
- **Reuse map**: `{template} includes → {_partial}`, `{template} imports → {macro}`, `<twig:Component>` usage.
- **Gap report**: report undefined-variable risks (not passed by the controller), unused partials, and `|raw` usages last as a `## Gaps Found` checklist.

---

# Part 2 — Library Usage Guide

## Before Recommending

1. Already installed? → check `composer.json`/`importmap.php`.
2. Symfony 8 / Twig 3 compatible? → check the package constraints.
3. Conflicts with project rules? → no SPA frameworks (Vue/React/Angular); use Stimulus/Turbo (Hotwire) (`CLAUDE.md`, `app-php-symfony-10-frontend-rule.md`).
4. Already abstracted? → manage JS dependencies with **AssetMapper (importmap)**, not npm.

If any check fails, report it before presenting examples.

## Version Check / Install (Bash)

```bash
# Twig/UX extensions (version: lock → json order; do not assert without confirming)
grep '"twig/' app/composer.lock | head
grep '"symfony/ux' app/composer.json

# Install
cd app && composer require twig/intl-extra          # locale date/number
cd app && composer require symfony/ux-twig-component # components
grep 'Bundle' app/config/bundles.php                # confirm auto-registration

# Frontend JS uses AssetMapper, not npm
cd app && php bin/console importmap:require package-name
grep 'package-name' app/importmap.php
```

## Common Twig Extensions

| Purpose                      | Package / Provides                                                        |
| ---------------------------- | ------------------------------------------------------------------------- |
| Locale date/number/currency  | `twig/intl-extra` (`format_datetime`, `format_currency`, `format_number`) |
| String/inflector             | `twig/string-extra` (`u`, `slug`)                                         |
| Markdown → HTML              | `twig/markdown-extra` + `league/commonmark` (sanitize)                    |
| HTML attribute/class helpers | `twig/html-extra` (`html_classes`, `html_cva`, `html_attr`)               |
| Fragment caching             | `twig/cache-extra` (`{% cache 'key' ttl(n) %}`)                           |
| Reusable components          | `symfony/ux-twig-component`, `symfony/ux-live-component`                  |
| Form rendering               | Symfony Form (`form_*` functions, built-in)                               |

SPA frameworks and direct `<script src=cdn>` injection violate the rules. When blocking, cite the governing rule file.

---

# Part 3 — Template Review

## Procedure

```bash
cd app
git diff main...HEAD --name-only -- app/templates/ app/src/Twig/
php bin/console lint:twig templates/                 # syntax/deprecation gate
```

Group the changed templates by role (layout / page / partial / macro / form theme / component), and **apply
the judgment criteria based on the rule files below** — the skill does not restate the criteria.

| Area                               | Judgment Criteria (SoT)                      |
| ---------------------------------- | -------------------------------------------- |
| Twig syntax, inheritance, escaping | `rules/app-twig-symfony-00-overview-rule.md` |
| Naming, partials, components       | `rules/app-php-symfony-07-template-rule.md`  |
| AssetMapper, Stimulus, UX          | `rules/app-php-symfony-10-frontend-rule.md`  |
| XSS, CSRF                          | `rules/app-php-symfony-08-security-rule.md`  |

## Cross-cutting Core Checks (quickly, rule violations only)

- No `|raw`/`{% autoescape false %}` on user/DB input (auto-escaping preserved).
- URLs/assets referenced via `path()`/`url()`/`asset()` (no hardcoding).
- CSRF (`_token`/`csrf_token()`) on state-changing forms; permission UI wrapped in `is_granted()`.
- No Repository/DB calls or business logic in templates (data prepared in the controller/Extension).
- Duplicated markup removed with inheritance/partials/macros; no leftover `{{ dump() }}`.
- Accessibility such as image `alt` and form `label`.

## Severity · Output

| Severity     | When to Use                                                   |
| ------------ | ------------------------------------------------------------- |
| `[MUST]`     | XSS, CSRF, render exception, rule violation (blocks merge)    |
| `[SHOULD]`   | Duplication, performance, convention deviation, accessibility |
| `[CONSIDER]` | Optional improvement, style                                   |

Output order: **summary → [MUST] → [SHOULD] → [CONSIDER] → positive feedback (at least 1, cite file:line)**.
