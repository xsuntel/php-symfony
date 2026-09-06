---
paths:
  - "app/tests/**/*"
---

# Testing Rule

This rule applies to every file under `app/tests/`.

@see https://symfony.com/doc/current/testing.html

## Test Layers

| Layer | Base class | Directory | Kernel boot | I/O |
|-------|------------|-----------|-------------|-----|
| Unit | `TestCase` | `app/tests/Unit/` | No | None |
| Integration | `KernelTestCase` | `app/tests/Integration/` | Yes | Real PostgreSQL + Redis |
| Functional | `WebTestCase` | `app/tests/Functional/` | Yes | HTTP layer |

- **Unit tests** must not touch the filesystem, database, cache, or network.
- **Integration tests** must use a **real PostgreSQL instance** — a mocked database is prohibited (past case: a mock/prod mismatch once hid a broken migration).
- **Functional tests** verify the HTTP response, redirects, and rendered HTML — not internal service state.

## TDD Cycle (Red-Green-Refactor)

This section is the single source of truth (SoT) for the test-first workflow. The four `*-tester`
agents apply it and add only their domain-specific mechanics on top; none of them holds its own copy.

Decide the layer first (the table above), then run one cycle per behaviour. **Never run two phases in
one step, and never skip Red.**

### Red — write a failing test first

- Write the test **before** the production code, and **run it**. A cycle where the test was never
  executed in the red state is not TDD — it is a test written after the fact.
- The test must fail **for the intended reason**. A fatal error ("class not found", "method does not
  exist") means execution never reached the assertion; that is a scaffolding gap, not a valid Red.
  Create the minimum skeleton (empty class, method signature returning a stub) until the assertion
  actually runs and reports an expected-vs-actual gap.
- **Read the failure message.** If it does not describe the intended behaviour, fix the test, not the code.
- One behaviour per cycle. A test that pins two facts cannot tell you which one Green satisfied.
- Never write a test you have already watched pass — you have not proven it can fail.

### Green — the minimum code that passes

- Write the **smallest** change that turns the target test green. Hardcoding a return value is a
  legitimate step when it is genuinely the smallest one; the next cycle's Red removes it
  (triangulation).
- Add nothing that no test demands — no unrequested abstraction, configuration, error handling,
  logging, or second behaviour. Those belong to a later cycle or to `*-analyzer`.
- **Never edit the test to make it pass.** If the test itself is wrong, return to Red, say so
  explicitly, and rewrite the test before touching production code.
- Exit condition: the target test passes **and every previously passing test still passes**. A Green
  that breaks another test is not Green — revert and take a smaller step.

### Refactor — improve the structure while green

- Change **structure only, never behaviour**. The test set does not change in this phase: no new
  assertion, no relaxed assertion, no deleted test.
- Run the suite after each refactoring step and revert immediately on red. Do not batch several
  structural changes between runs.
- Typical targets: duplication, naming, layer boundaries, dependency direction, injection count,
  branch complexity. Structural debt that exceeds one refactoring step is handed to `*-analyzer`
  rather than fixed opportunistically here.
- Exit condition: the whole suite is green **and** the project static gates pass —
  `declare(strict_types=1)`, `final`/`readonly`, PHPStan level 8, php-cs-fixer.
- Refactoring is not optional. Ending a cycle at Green leaves the duplication that Green deliberately
  introduced.

### Phase executors

The cycle is the same everywhere, and since 2026-08-17 so is its executor: **the domain's `*-tester` runs
all three phases**, with the domain's `*-reviewer` as the quality gate afterwards. No domain delegates
Green to a separate author agent.

| Domain | Red | Green | Refactor |
|--------|-----|-------|----------|
| PHP backend (`app/src/**`) | `app-php-symfony-tester` | `app-php-symfony-tester` | `app-php-symfony-tester` (structural debt → `app-php-symfony-analyzer`) |
| Twig templates (`app/templates/**`) | `app-twig-symfony-tester` | `app-twig-symfony-tester` | `app-twig-symfony-tester` (structural debt → `app-twig-symfony-analyzer`) |
| Stimulus / frontend (`app/assets/**`) | `app-javascript-stimulus-tester` | `app-javascript-stimulus-tester` | `app-javascript-stimulus-tester` (structural debt → `app-javascript-stimulus-analyzer`) |
| API Platform (`app/src/{ApiResource,State}/**`) | `api-platform-tester` | `api-platform-tester` | `api-platform-tester` (structural debt → `api-platform-analyzer`) |

The API Platform row used to be the exception — it delegated Green to an `api-platform-author` agent.
That agent was renamed to `api-platform-analyzer` and converted to the read-only Analyze axis on
2026-08-17, so the row now matches the other three. A tester **never judges its own implementation**: the
domain `*-reviewer` still issues the PASS/REDO gate.

The Stimulus row has a **coverage ceiling, not a process exception**. With no JavaScript test runner
installed, an executable Red exists only for the server-rendered DOM contract (`data-controller`,
`data-*-value`, `data-testid`, `turbo-frame` ids, Turbo Stream Content-Type, PRG redirects). A
controller's in-browser behaviour — click handlers, `connect()`/`disconnect()`, dispatched events —
cannot be turned red at all. Run the cycle for what is reachable, and **report the remainder as an
uncovered gap rather than describing the cycle as complete**. Introducing a browser runner is a new
devDependency and is proposed only when the user asks.

### When the cycle does not apply as written

- **Pinning an already-fixed bug** (handoff from a `*-debugger`): the fix exists, so Red cannot be
  observed against the current tree. Write the test, confirm it fails against the pre-fix state when
  that is reachable (`git stash`, or reverting the fix in a scratch worktree), and otherwise state
  plainly that Red was not observed. Do not claim a red phase you did not run.
- **Untested legacy code**: write a characterization test that captures the *current* behaviour and
  watch it pass first, then start the Red-Green-Refactor cycle for the change itself.
- **Infrastructure that is not yet scaffolded**: if the layer's directory, test suite, or database is
  missing, report it as a prerequisite instead of fabricating a Red you cannot run.

## Namespace Conventions

```
App\Tests\Unit\{Domain}\{ClassName}Test
App\Tests\Integration\{Domain}\{ClassName}Test
App\Tests\Functional\{Domain}\{ControllerName}Test
```

- Unit: `app/tests/Unit/{Domain}/{ClassName}Test.php`
- Integration: `app/tests/Integration/{Domain}/{ClassName}Test.php`
- Functional: `app/tests/Functional/{Domain}/{ControllerName}Test.php`
- Test method names: `it_{describes_behavior}()` (unit/integration), `test_{route}_{assertion}()` (functional).

## Unit Test Template

```php
<?php

declare(strict_types=1);

namespace App\Tests\Unit\{Domain};

use PHPUnit\Framework\TestCase;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\Attributes\Test;

final class {Name}Test extends TestCase
{
    #[Test]
    public function it_{describes_behavior}(): void
    {
        // Arrange
        // ...

        // Act
        // ...

        // Assert
        $this->assertSame(expected: ..., actual: ...);
    }

    #[DataProvider('provide{Scenarios}')]
    #[Test]
    public function it_{describes_data_driven_behavior}(mixed $input, mixed $expected): void
    {
        // ...
    }

    /** @return iterable<string, array{mixed, mixed}> */
    public static function provide{Scenarios}(): iterable
    {
        yield 'scenario description' => [$input, $expected];
    }
}
```

## Integration Test Template

```php
<?php

declare(strict_types=1);

namespace App\Tests\Integration\{Domain};

use Symfony\Bundle\FrameworkBundle\Test\KernelTestCase;
use Doctrine\ORM\EntityManagerInterface;

final class {Name}Test extends KernelTestCase
{
    private EntityManagerInterface $em;

    protected function setUp(): void
    {
        self::bootKernel();
        $this->em = self::getContainer()->get(EntityManagerInterface::class);
    }

    protected function tearDown(): void
    {
        parent::tearDown();
        $this->em->close();
    }
}
```

## Functional Test Template

```php
<?php

declare(strict_types=1);

namespace App\Tests\Functional\{Domain};

use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;

final class {Name}Test extends WebTestCase
{
    public function test_{route}_returns_{expected_status}(): void
    {
        $client = static::createClient();
        $client->request('GET', '/{route}');

        $this->assertResponseStatusCodeSame(200);
        $this->assertSelectorExists('h1');
    }
}
```

## PHPUnit Attributes (PHPUnit 12)

Use PHP Attributes — never use docblock annotations:

```php
use PHPUnit\Framework\Attributes\CoversClass;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\Attributes\Test;

#[CoversClass(InvoiceCalculator::class)]
final class InvoiceCalculatorTest extends TestCase
{
    #[Test]
    public function it_applies_discount_for_premium_users(): void
    {
        // Arrange
        $calculator = new InvoiceCalculator();

        // Act
        $total = $calculator->calculate(amount: 100.0, isPremium: true);

        // Assert
        $this->assertSame(expected: 90.0, actual: $total);
    }

    #[DataProvider('provideDiscountScenarios')]
    #[Test]
    public function it_calculates_correct_discount(float $amount, bool $isPremium, float $expected): void
    {
        $this->assertSame($expected, (new InvoiceCalculator())->calculate($amount, $isPremium));
    }

    /** @return iterable<string, array{float, bool, float}> */
    public static function provideDiscountScenarios(): iterable
    {
        yield 'standard user — no discount' => [100.0, false, 100.0];
        yield 'premium user — 10% off'      => [100.0, true, 90.0];
        yield 'zero amount'                 => [0.0, true, 0.0];
    }
}
```

- Use `#[Test]`, `#[DataProvider]`, `#[CoversClass]`, `#[BeforeClass]`, `#[AfterClass]` — never use docblock annotations.
- Never use the `@covers` docblock annotation — use the `#[CoversClass(MyClass::class)]` PHP attribute instead.
- One assertion per test where possible. Multiple assertions are allowed when they together prove a single logical fact.
- Do **not** assert implementation details (private method calls, exact SQL) — assert observable outcomes (return values, side effects, HTTP responses).

## Smoke Test (Required)

Every public URL must have a smoke test to catch 500 errors early:

```php
#[DataProvider('providePublicUrls')]
public function test_page_returns_successful_response(string $url): void
{
    $client = static::createClient();
    $client->request('GET', $url);

    $this->assertResponseIsSuccessful();
}

/** @return iterable<string, array{string}> */
public static function providePublicUrls(): iterable
{
    yield 'homepage'   => ['/'];
    yield 'post list'  => ['/post'];
    yield 'about page' => ['/about'];
}
```

## Hardcoding URLs in Functional Tests

Use a **hardcoded URL** — do not call the router — so that the test fails when a route changes, revealing that a redirect setting is needed:

```php
// Correct — hardcoded URL
$client->request('GET', '/post/123');

// Wrong — hides route renames
$client->request('GET', $this->generateUrl('post_show', ['id' => 123]));
```

## Fixtures

- Fixtures live in `app/src/DataFixtures/` and mirror the domain namespace (`DataFixtures/{Domain}/`).
- Use `DependentFixtureInterface` to declare load order — do not hardcode fixture dependencies as class-name strings.
- Load them in test `setUp()` with the `--group` flag via `DoctrineFixturesBundle` — do not use manual `persist()`/`flush()`.

## What Not to Mock

- **Database** — always use real PostgreSQL.
- **Redis** — always use real Redis in integration tests.
- **Symfony services** — prefer the real DI container; mock only external HTTP clients.
- **External HTTP clients** — in integration tests, mock provider API calls with `symfony/http-client`'s `MockHttpClient` + `MockResponse`.

@see https://symfony.com/doc/current/best_practices.html#tests

## Test Environment Configuration

- Manage test-only configuration with `.env.test` or `config/packages/test/`.
- Use a dedicated test database (separate from dev).
- Run with `debug: false` in CI for better performance.

```yaml
# config/packages/twig.yaml
when@test:
    twig:
        strict_variables: true  # immediately error on undefined variables
```

## Mocking Services in Tests

In `KernelTestCase`, fetch a service from the container and replace it with a mock when needed:

```php
// Retrieve a real service in an integration test
self::bootKernel();
$service = static::getContainer()->get(MyService::class);

// Replace with a mock
$mock = $this->createMock(MailerInterface::class);
static::getContainer()->set(MailerInterface::class, $mock);
```

@see https://symfony.com/doc/current/testing.html#mocking-dependencies

## Functional Test Pattern

```php
final class PostControllerTest extends WebTestCase
{
    public function test_create_post_redirects_on_success(): void
    {
        $client = static::createClient();

        // Simulate an authenticated user
        $client->loginUser($user);

        // Submit the form
        $client->request('GET', '/post/new');
        $client->submitForm('Save', [
            'post[title]' => 'My Test Post',
        ]);

        // Assert PRG pattern
        $this->assertResponseRedirects('/post/');
        $client->followRedirect();
        $this->assertSelectorTextContains('h1', 'My Test Post');
    }
}
```
