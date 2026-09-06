# app-javascript-stimulus-tester memory

## Test infrastructure (verified)

- Frontend behavior is verified with Symfony **Functional tests (WebTestCase)** (not a browser JS runner).
- `app/tests/` contains only `Unit/` → create the `Functional/` directory anew.
- `app/phpunit.xml.dist` has a single suite, so `--testsuite` cannot be used → use a path (`tests/Functional`) or `--filter`.

## Verification conventions

- Assert only rendered DOM (presence of `data-controller` / `data-*-target`), form flows, and Turbo Frame/Stream responses.
- Use hardcoded URLs (no `generateUrl()`).

## SoT

- .claude/rules/app-php-symfony-09-testing-rule.md
- .claude/rules/app-javascript-stimulus-00~02-*-rule.md
