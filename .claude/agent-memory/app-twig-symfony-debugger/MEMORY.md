# app-twig-symfony-debugger memory

## Frequent root causes

- Custom filter/function `Unknown` → Twig Extension not registered · `AsTwigFilter`/`AsTwigFunction` typo · Runtime not wired. Check: `app/src/Twig/`, `php bin/console debug:twig --filter=x`.
- Undefined variable / double or missing escaping / block not inherited / include-macro path error / form theme not applied are common render-exception causes.

## Conventions

- Keep auto-escaping on at all times (`|raw` only on trusted server-generated HTML).
- Confirm registered filters, functions, globals, and paths against actual values with `debug:twig` — no guessing.

## SoT

- .claude/rules/app-twig-symfony-00-overview-rule.md
- .claude/rules/app-php-symfony-07-template-rule.md
