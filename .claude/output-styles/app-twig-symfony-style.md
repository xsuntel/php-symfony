---
name: app-twig-symfony-style
description: Twig 3.x / Symfony 8 — style guide applied to every file under app/templates/
keep-coding-instructions: true
---

# Twig Style Guide

This document governs **output presentation and formatting**. The details of the coding standards
(inheritance · partial templates · components · auto-escaping · security · performance) and the code
examples are owned by the rules as the single source of truth (SoT) — not restated here.

@see .claude/rules/app-twig-symfony-00-overview-rule.md — Twig template standards (SoT)
@see .claude/rules/app-php-symfony-07-template-rule.md — naming · inheritance · components (SoT)
@see .claude/docs/app-twig-symfony-docs.md — detailed syntax · filter · function examples

## Standards Compliance (Summary)

- File names are **snake_case** with two extensions (`{format}.twig`) — e.g. `index.html.twig`, `report.xml.twig`.
- The template path mirrors the corresponding controller path: `templates/{domain}/{subdomain}/{action}.html.twig`.
- Partial templates meant only for include/embed use the `_` prefix — e.g. `_user_profile.html.twig`.
- 3-level inheritance: `base.html.twig` (root) → `{domain}/layout.html.twig` (section) → page.
- Keep auto-escaping (`html`) always enabled. Use `|raw` only for trusted server-generated HTML. See the rules above for details.

## Naming Conventions

| Symbol | Rule | Example |
| ------ | ------ | ------ |
| Template file | snake_case + double extension | `order_detail.html.twig` |
| Partial template | `_` prefix + snake_case | `_order_row.html.twig` |
| Block | snake_case | `{% block page_content %}` |
| Macro | snake_case | `{% macro form_row() %}` |
| Twig variable | snake_case (matching the value passed from PHP) | `{{ created_at }}` |

## Formatting

- 2-space indentation (no tabs), soft line-length limit of 120 characters.
- One space inside statement delimiters: `{{ value }}`, `{% if x %}` (no `{{value}}` · `{%if x%}`).
- Filter chaining with no space around the pipe: `{{ title|upper|trim }}`.
- Trailing comma on the last item of multi-line tags · hash arguments.
- Align nested blocks · control structures so the opening and closing tags share the same indentation level.

## Code Block Format

- Wrap Twig code in a fenced code block with the `twig` language identifier.
- When creating a file, state the full path relative to `templates/` as a Twig comment on the first line, right before the block:

```
{# templates/order/detail.html.twig #}
```

## Multi-File Responses

When creating multiple files, put the path comment on the first line of each block, immediately followed by the full file content.
When outputting a layout · page · partial together, order them from the inheritance parent (base/layout) → child (page/partial).

## Inline Explanation Format

Use only the following headings after a code block:

- **How it works** — what the template renders, 3–5 items
- **Why this way** — the inheritance · partial-separation or performance rationale
- **Next steps** — `lint:twig`, controller wiring, form-theme registration, etc. (only when relevant)

Prohibited: preambles like "Here is the code:", summaries of what was written, phrases like "Great question!" · "Certainly!".

## Conventions for Generated Templates

- Do not put business logic · aggregation · Repository calls in a template — the Controller/Extension prepares the data.
- Remove repeated markup with `extends`/`block` · `include`/`embed` · `macro`.
- Reference URLs with `path()`/`url()` and static assets with `asset()` — no hardcoded paths.
- Do not leave debug output (`{{ dump() }}` · `{% dump %}`) in the final artifact.

## Test Code Presentation

- Perform render verification with Functional tests (WebTestCase) — assert on the rendered DOM (selectors · text · response code).
- Pass the syntax · deprecation lint with `lint:twig` / `lint:twig --show-deprecations`.
- Review finding severities are `[MUST]` / `[SHOULD]` / `[CONSIDER]` — only `[MUST]` blocks a merge.
