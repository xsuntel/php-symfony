# app-twig-symfony-tester memory

## Test infrastructure (verified)

- `app/tests/` contains only `Unit/` → when writing Functional/Integration tests, create those directories anew.
- `app/phpunit.xml.dist` defines a single suite → `--testsuite` cannot be used. Run by layer with a **path** (`tests/Functional`) or `--filter`.
- Functional tests need real PostgreSQL + Redis (`.env.test`).

## Functional conventions

- **Use hardcoded URLs** — no `generateUrl()` calls (it hides route changes).
- Every public URL has a smoke test (`assertResponseIsSuccessful`) to catch 500s early.
- Assert only rendered DOM, responses, and redirects (no implementation details).

## SoT

- .claude/rules/app-php-symfony-09-testing-rule.md
- .claude/rules/app-twig-symfony-00-overview-rule.md
