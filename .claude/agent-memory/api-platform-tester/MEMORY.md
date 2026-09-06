# api-platform-tester memory

> Translated from Korean to English on 2026-08-17, per the CLAUDE.md `## Documentation Language` rule.
> Every verified fact below is carried over unchanged.

## Test infrastructure (verified)

- The base class is `ApiPlatform\Symfony\Bundle\Test\ApiTestCase` — **not `WebTestCase`**.
  `assertJsonContains` and `findIriBy` exist only there. `symfony/browser-kit` and `symfony/http-client`
  are installed.
- **`justinrainbow/json-schema` is not installed** → `MatchesJsonSchema` uses `JsonSchema\Validator`, so
  `assertMatchesResourceItemJsonSchema()`, `assertMatchesResourceCollectionJsonSchema()`, and
  `assertMatchesJsonSchema()` **fail in the current state** (the schema-assertion examples in the rule are
  valid only on top of that precondition). Alternative: `assertJsonContains()` +
  `assertResponseStatusCodeSame()`. When needed, advise the user to run
  `composer require --dev justinrainbow/json-schema` first.
- `app/phpunit.xml.dist` defines only one suite (`Project Test Suite`) → **`--testsuite` is unusable**.
  Run by path (`vendor/bin/phpunit tests/Functional/ApiResource`) or with `--filter`.
- `app/tests/` contains only `Unit/` and `Patterns/` (Functional/Integration must be newly created).
  **`.env.test` is absent** — report test-DB separation as a precondition and do not create environment
  files on your own initiative. DAMA `DoctrineTestBundle` is absent → each test is responsible for
  cleaning up its own fixtures.
- `app/src/ApiResource/` holds only `.gitignore` and `app/src/State/` does not exist. For a
  **regression-test** request against code that should already exist, report "nothing to write tests for"
  rather than inventing a resource. For a **test-first** request this is the expected starting point —
  the Red is "the operation does not exist", and this agent then declares it during Green.

## Authoring conventions

- Fill in the operation × case matrix: success / validation failure (422 + `violations.propertyPath` in
  `application/problem+json`) / authorization denied (401·403) / not found (404). `Delete` is 204 plus a
  404 on re-fetch.
- Obtain an item IRI with `findIriBy(Resource::class, [...])` — never hardcode a URL or ID.
- **Do not prefix JSON-LD keys with `hydra:`** — the installed 4.x defaults `serializer.hydra_prefix` to
  `false` and the project does not enable it. The collection keys are `member`, `totalItems`, and `view`.
  Copying a 3.x example that uses `hydra:member` makes the assertion fail.
- Authentication goes through an `Authorization: Bearer` header, given the `stateless: true` premise — do
  not rely on `loginUser()` session login.
- PHPUnit 12 attributes only (`#[Test]`, `#[DataProvider]`), `declare(strict_types=1)`, `final`. For
  filters and pagination, assert that the query is actually affected — not merely that they are declared.
- Mocking boundaries: no mocking of PostgreSQL or Redis (real instances); only external HTTP uses
  `MockHttpClient`; Symfony services and State come from the real container.

## TDD cycle ownership (changed 2026-08-17)

- This agent owns **the whole Red → Green → Refactor cycle**, exactly like every `app-*-tester`. It writes
  both the tests and the `app/src/ApiResource/` · `app/src/State/` code they demand.
- **`api-platform-author` exists again as of 2026-08-22.** It was dissolved on 2026-08-17 (renamed to
  `api-platform-analyzer`, which became a read-only axis) and revived to restore the author→reviewer
  pair. An earlier version of this note said it no longer exists and that Green must never be handed
  to an author; that is obsolete. **This agent still owns the whole cycle on a test-first intent** —
  do not hand Green off mid-cycle. The author is the separate Build path `api-agent-team` takes when the
  work is generation-led rather than test-led.
- The merge verdict is still not this agent's: `api-platform-reviewer` gates the output.
- Green exit: the target test is green **and** the rest of the suite still is. Refactor exit: suite green
  **and** `phpstan analyse` (level 8) + `php-cs-fixer fix --dry-run --diff` pass.

## Team collaboration (hand-off)

- Role: Test (full TDD cycle) · upstream: `api-platform-reviewer` (after `[MUST]` items are resolved) /
  `api-platform-debugger` (pinning a regression after a fix) / `api-agent-team` or a build skill on a
  test-first intent · downstream: `api-platform-reviewer` (quality gate); defects found →
  `api-platform-debugger`; structural debt too large for one Refactor step → `api-platform-author`;
  security vulnerabilities needing severity diagnosis → `api-platform-analyzer`
- Canonical procedure: the `## Operation × case matrix` section of this agent's own definition — there is
  no `/api-platform-test` command, which was deleted on 2026-08-17. Domain-service and Doctrine tests
  belong to `app-php-symfony-tester`
- Orchestrator: main agent direct routing, or the build skills when they drive the work
- Design SoT: .claude/docs/api-agent-team-docs.md

## SoT

- .claude/rules/api-platform-rule.md (`## Testing` section)
- .claude/rules/app-php-symfony-09-testing-rule.md (test layers · mocking)
