# app-php-symfony-tester memory

## Test infrastructure (verified)

- `app/tests/` contains only `Unit/` → when writing Integration/Functional tests, create those directories anew.
- `app/phpunit.xml.dist` defines only a single "Project Test Suite" that scans `tests/` → `--testsuite Unit`/`Integration`/`Functional` cannot currently be used. Run by layer with a **path** (`tests/Integration`) or `--filter`. (CLAUDE.md's `--testsuite` guidance is inaccurate until those suites are added.)

## Mocking boundary

- PostgreSQL and Redis are **never mocked** — always real instances (past: mocked tests passed but the real migration was broken).
- Mock only external HTTP clients (KoreaInvestment, UPbit, etc.) with `symfony/http-client`'s `MockHttpClient` + `MockResponse`.
- Prefer the real DI container for Symfony services (`getContainer()->get(...)`).

## Conventions

- Multi-EntityManager environment → fetch the target EM explicitly in Integration tests (do not assume the default EM).
- Functional tests use hardcoded URLs (no `generateUrl()` calls). Fixtures live in `DataFixtures/{Domain}/` + `DependentFixtureInterface`.

## SoT

- .claude/rules/app-php-symfony-09-testing-rule.md (test layers & mocking)
- .claude/rules/app-php-symfony-05-doctrine-rule.md (Repository & mapping)
