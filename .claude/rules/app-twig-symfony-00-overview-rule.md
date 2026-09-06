---
paths:
  - "app/templates/**/*.html.twig"
  - "app/templates/**/*.twig"
---

# Twig / Symfony Template Rules Overview

This rule is the single source of truth (SoT) for Twig templates under `app/templates/**` — including
naming/placement, partial conventions, inheritance, auto-escaping, and components. It enforces Twig 3.x
syntax and Symfony 8 template conventions. Detailed examples and syntax reference live in the docs; the
PHP-side `app-php-symfony-07-template-rule.md` delegates its template concerns here.

## Reference Docs

- Twig official docs: https://twig.symfony.com/doc/3.x/
- Symfony templates: https://symfony.com/doc/current/templates.html
- Twig version: 3.x / Symfony version: 8.0

@see .claude/docs/app-twig-symfony-docs.md — detailed syntax/filter/function examples
@see .claude/rules/app-php-symfony-07-template-rule.md — PHP-side controller↔template contract (delegates here)
@see .claude/rules/app-php-symfony-10-frontend-rule.md — AssetMapper, Stimulus, UX
@see .claude/rules/app-php-symfony-08-security-rule.md — XSS, CSRF

## Naming · Placement

- Place templates under `app/templates/` with **snake_case** filenames and a two-part extension (`{format}.twig`) — e.g. `index.html.twig`, `report.xml.twig`.
- Template paths mirror the corresponding controller path exactly: `templates/{domain}/{subdomain}/{action}.html.twig`.
- Prefix include/embed-only partial templates with `_`: `_user_profile.html.twig`.
- Layouts follow 3-level inheritance: `base.html.twig` (root) → `{domain}/layout.html.twig` (section) → page.

## Auto-escaping · Security (non-negotiable)

- Keep auto-escaping (`html` strategy) always active — never disable it globally.
- Use `|raw`/`{% autoescape false %}` **only on trusted, server-generated HTML**. Never on user/DB input.
- To display untrusted HTML, use `|raw` only after server-side sanitization (`league/commonmark`, etc.).
- Use the escape strategy that matches the output context: `|e('js')`, `|e('css')`, `|e('url')`, `|e('html_attr')`.
- Include a CSRF token in every state-changing form — Symfony Form embeds `_token`, and manual forms add `{{ csrf_token('intention') }}` as a hidden field.
- Wrap permission-dependent UI in `is_granted(...)` — this is visibility control only and does not replace server-side authorization (Voter/`#[IsGranted]`).

## URL · Assets

- Never hardcode URLs — use `path()` for internal links and `url()` for absolute URLs (email/RSS).
- Reference static assets with `asset()` (and `absolute_url(asset(...))` when needed) — no path hardcoding.

## Logic Separation (thin templates)

- Do not put business logic, aggregation, or Repository/DB calls in templates — the controller prepares the data, or it is delegated to a Twig Extension/Component.
- Keep heavy transformations/computation in PHP (Twig Extension filters/functions). Templates handle presentation only.
- Remove repeated markup with `extends`/`block`, `include`/`embed`, or `macro`. Macros cannot access outer variables, so pass the needed values as arguments.
- Do not hardcode constants or enum values as magic strings — reference backed enums with `enum('App\\Enum\\...::Case')`/`enum_cases('App\\Enum\\...')` and class constants with `constant(...)`.

## Fragments · Sub-requests

- `render(controller(...))`/`render(path(...))` runs a separate sub-request on every render — overuse accumulates per-request cost. Prefer `include`/`embed` or a TwigComponent for simple reuse.
- Use fragments only when you need to **cache a fragment independently** or dedicated controller logic is required. `render_esi` acts as a real separate cache only when a reverse proxy that supports ESI is present.
- Using `controller()` requires the `framework.fragments.path` setting.

## Configuration Contract (twig.yaml)

- Manage global values via `globals` in `twig.yaml` — do not hardcode them in templates/controllers.
- Set `strict_variables` to `true` (`%kernel.debug%`) in dev to surface undefined/typo'd variables early.
- Give extra template paths a namespace (e.g. `@email`) via `paths` and reference them by it — no path hardcoding.

## Twig Extension · Component

- Put custom filters/functions in `app/src/Twig/`; use `#[AsTwigFilter]`/`#[AsTwigFunction]` attribute-based extensions when there are no dependencies, and `AbstractExtension` + a Runtime class when dependencies/lazy loading are needed.
- Use TwigComponent/LiveComponent for reusable UI with behavior, and `include`/`embed`/`macro` for static fragments.

## Performance

- Warm the Twig compile cache in production (`cache:warmup`).
- Avoid N+1 from repeated includes or lazy association access in templates — load associations in the controller/Repository before rendering a collection.
- Cache expensive, repeatedly rendered fragments with `{% cache 'key' ttl(n) %}` (`twig/cache-extra`) — specify the cache key and TTL.
- Remove debug output (`{{ dump() }}`/`{% dump %}`) before committing to production.

## Quality Gate (required before merge)

```bash
# Syntax/deprecation lint (must pass with no errors to be mergeable)
cd app && php bin/console lint:twig templates/
cd app && php bin/console lint:twig --show-deprecations templates/
```

- Perform render verification with Functional tests (WebTestCase) — assert the rendered DOM (selectors, text, response code).
- Classify review severity as `[MUST]` / `[SHOULD]` / `[CONSIDER]`; only `[MUST]` blocks a merge.
