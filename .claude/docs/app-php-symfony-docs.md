# PHP / Symfony — Technical Specification

This document provides the **detailed reference and code templates** for the PHP coding standards ·
architecture · domain structure. The enforced judgment criteria (SoT) are the rule files, and this
document holds their detailed/example edition — when it conflicts with a rule, the rule wins.

@see .claude/rules/app-php-symfony-00-overview-rule.md ~ app-php-symfony-15-scheduler-rule.md — judgment criteria (SoT)
@see .claude/rules/abstract-structure-rule.md — directory · path context

---

## 1. Technical Environment

| Item | Version / setting |
| --- | --- |
| PHP | 8.4 (strict_types required) — the local CLI is 8.5 but the code target is 8.4 |
| Symfony | 8.1.x Framework (`composer.json`: `symfony/framework-bundle: 8.1.*`) |
| Doctrine ORM | 3.x (PHP attribute-based mapping) |
| Static analysis | PHPStan (`app/phpstan.neon`) — **level 8**; 2441 pre-existing items are baselined in `app/phpstan-baseline.neon` (burned down gradually), and new code must pass level 8 without a baseline. bigint↔string is an `ignoreErrors` exception per the SoT rule |
| Code style | PHP-CS-Fixer (`app/.php-cs-fixer.dist.php`, Symfony ruleset) |
| Testing | PHPUnit (`app/phpunit.xml.dist`) |
| Source root | `app/src/` (namespace: `App\`) |
| Templates | `app/templates/` (Twig) |
| Realtime | Mercure (SSE) + Turbo Streams (`symfony/mercure-bundle`) — details in §13 |

---

## 2. File Header and Coding Standards

### 2.1 Required Header Structure

Every PHP file follows this order.

```php
<?php

declare(strict_types=1);

namespace App\Domain\SubDomain;

use DateTimeImmutable;                          // Group 1: PHP built-in
use InvalidArgumentException;

use Doctrine\ORM\Mapping as ORM;               // Group 2: Doctrine
use Doctrine\Common\Collections\Collection;

use Symfony\Component\Routing\Attribute\Route; // Group 3: Symfony
use Symfony\Component\Validator\Constraints as Assert;

use App\Domain\Order\Entity\Order;              // Group 4: App
use App\Domain\Order\Repository\OrderRepository;
```

Rules:

- One blank line after `<?php`, then `declare(strict_types=1)`
- **No** closing `?>` tag (except template files)
- Separate `use` groups with a blank line, alphabetically sorted within a group
- 4-space indentation, no tabs
- Soft line limit of 120 characters

### 2.2 Namespace ↔ Path Mapping (PSR-4)

| Path | Namespace |
| --- | --- |
| `app/src/Domain/Order/Entity/Order.php` | `App\Domain\Order\Entity` |
| `app/src/Domain/Order/Repository/OrderRepository.php` | `App\Domain\Order\Repository` |
| `app/src/Controller/Api/OrderController.php` | `App\Controller\Api` |
| `app/src/Scheduler/Finance/DailyReportScheduler.php` | `App\Scheduler\Finance` |

---

## 3. PHP 8.4 Modern Features

### 3.1 Constructor Property Promotion

Dependency-injection properties must use the promotion syntax. The separate-declaration + constructor-assignment pattern is **prohibited**.

```php
// Prohibited
class OrderService
{
    private readonly OrderRepository $repository;

    public function __construct(OrderRepository $repository)
    {
        $this->repository = $repository;
    }
}

// Recommended
final class OrderService
{
    public function __construct(
        private readonly OrderRepository $repository,
        private readonly LoggerInterface $logger,
    ) {}
}
```

### 3.2 readonly Property / readonly class

Declare `readonly` for properties that do not change after construction.
Declare a class whose every property is readonly as a `readonly class`.

```php
// DTOs and value objects are a readonly class
readonly class CreateOrderCommand
{
    public function __construct(
        public string $customerId,
        public string $productId,
        public int    $quantity,
    ) {}
}

// An Entity applies readonly to individual properties
final class Order
{
    public function __construct(
        #[ORM\Id]
        #[ORM\Column(type: 'uuid')]
        public readonly string $id,

        #[ORM\Column(type: Types::DATETIME_IMMUTABLE, nullable: false)]
        public readonly DateTimeImmutable $createdAt,
    ) {}
}
```

### 3.3 match Expression

Replace a `switch` that maps values completely to return values with a `match`.
`match` uses strict comparison (`===`) and throws `UnhandledMatchError` for an unhandled case.

```php
// Prohibited
switch ($status) {
    case 'pending':  $label = 'Pending'; break;
    case 'approved': $label = 'Approved'; break;
    default:         $label = 'Unknown';
}

// Recommended
$label = match($status) {
    'pending'  => 'Pending',
    'approved' => 'Approved',
    default    => throw new InvalidArgumentException("Unknown status: {$status}"),
};
```

### 3.4 Backed Enum

Define related sets of constants (status, type, role, category) as an `enum`.

```php
// Prohibited
class OrderStatus
{
    public const PENDING  = 'pending';
    public const APPROVED = 'approved';
    public const REJECTED = 'rejected';
}

// Recommended
enum OrderStatus: string
{
    case Pending  = 'pending';
    case Approved = 'approved';
    case Rejected = 'rejected';

    public function label(): string
    {
        return match($this) {
            self::Pending  => 'Pending',
            self::Approved => 'Approved',
            self::Rejected => 'Rejected',
        };
    }
}
```

Doctrine column mapping:

```php
#[ORM\Column(type: Types::STRING, enumType: OrderStatus::class, nullable: false)]
private OrderStatus $status = OrderStatus::Pending;
```

### 3.5 Nullsafe Operator

```php
// Prohibited
$city = $user ? ($user->getAddress() ? $user->getAddress()->getCity() : null) : null;

// Recommended
$city = $user?->getAddress()?->getCity();
```

### 3.6 Named Arguments

Use named arguments for a call with several optional parameters to improve readability.

```php
// Prohibited
$this->cache->get('key', null, 3600, true);

// Recommended
$this->cache->get(key: 'key', tags: null, ttl: 3600, checkLockTimeout: true);
```

### 3.7 Property Hooks (PHP 8.4)

Replace a verbose getter/setter pair for a computed/validated property with `get`/`set` hooks.

```php
final class Product
{
    public string $name {
        get => strtoupper($this->name);
        set(string $value) {
            if (strlen($value) < 2) {
                throw new InvalidArgumentException('Name too short');
            }
            $this->name = $value;
        }
    }
}
```

### 3.8 Asymmetric Visibility (PHP 8.4)

Use it when a property is readable externally but writing is restricted to inside the class.

```php
final class Order
{
    // public read, private write
    public private(set) OrderStatus $status = OrderStatus::Pending;

    public function approve(): void
    {
        $this->status = OrderStatus::Approved; // only possible internally
    }
}
```

---

## 4. Type Safety and Static Analysis

### 4.1 Required Type Declarations

Declare parameter types and a return type on every method.

```php
// Prohibited
public function process($order)
{
    return $order->getId();
}

// Recommended
public function process(Order $order): string
{
    return $order->getId();
}
```

Return-type special cases:

- No return value → `void`
- Throws only → `never`
- The class itself → `static` (fluent interface) or `self`
- Nullable → `Type|null` (more explicit than the shorthand `?Type`)

### 4.2 No mixed

`mixed` disables static analysis. Replace it with the most specific union type possible.

```php
// Prohibited
public function getValue(): mixed { }

// Recommended
public function getValue(): string|int|null { }
```

### 4.3 PHPDoc Usage Criteria

Add PHPDoc only when a native type cannot express it.

```php
// Needed: express the array element type
/** @return Order[] */
public function findByStatus(OrderStatus $status): array { }

/** @param array<string, mixed> $context */
public function log(string $message, array $context): void { }

// Unneeded: the native type already states it
/** @return string */  // ← redundant — remove
public function getName(): string { }
```

### 4.4 PHPStan level 8 Compliance

```bash
cd app && vendor/bin/phpstan analyse
```

Main errors detected at level 8:

- Accessing a nullable property without a null check
- Calling a method with an incompatible argument type
- Unreachable code paths
- Missing `@return Order[]` PHPDoc when returning an `array`

---

## 5. Class Design and Architecture

### 5.1 final Classes

Every concrete class not designed for extension must be `final`.

Applies to: `Service`, `Handler`, `EventSubscriber`, `Controller`, `Repository`, `Scheduler`

```php
final class OrderService { }
final class CreateOrderHandler { }
final class OrderEventSubscriber { }
```

Exceptions: abstract classes (`abstract`), interfaces, test-double base classes.

### 5.2 Single Responsibility Principle

- A class exceeding ~200 lines → review responsibility separation
- More than ~7 public methods → possible SRP violation

### 5.3 Immutability

Use a `readonly class` for DTOs and value objects.

```php
readonly class MoneyValue
{
    public function __construct(
        public int    $amount,
        public string $currency,
    ) {}

    public function add(MoneyValue $other): self
    {
        // return a new instance — do not mutate the existing one
        return new self($this->amount + $other->amount, $this->currency);
    }
}
```

### 5.4 No new in the Constructor

```php
// Prohibited
public function __construct()
{
    $this->client = new HttpClient(); // must be injected via DI
}

// Recommended
public function __construct(
    private readonly HttpClientInterface $client,
) {}
```

---

## 6. Dependency Injection and Symfony Conventions

### 6.1 Constructor Injection Only

Setter injection, property injection, and `$container->get()` calls are **prohibited**.

```php
// Prohibited
public function setLogger(LoggerInterface $logger): void
{
    $this->logger = $logger;
}

// Recommended
public function __construct(
    private readonly LoggerInterface $logger,
) {}
```

### 6.2 #[Autowire] Attribute

Use it for scalar values, environment variables, and parameter injection.

```php
use Symfony\Component\DependencyInjection\Attribute\Autowire;

final class PaymentService
{
    public function __construct(
        #[Autowire('%kernel.debug%')]
        private readonly bool $debug,

        #[Autowire(env: 'PAYMENT_API_KEY')]
        private readonly string $apiKey,

        #[Autowire(service: 'cache.app')]
        private readonly CacheInterface $cache,
    ) {}
}
```

### 6.3 #[Target] Attribute

Use it to select a specific service among multiple implementations of the same interface.

```php
use Symfony\Component\DependencyInjection\Attribute\Target;

final class OrderService
{
    public function __construct(
        #[Target('monolog.logger.order')]
        private readonly LoggerInterface $logger,
    ) {}
}
```

### 6.4 Attribute-Based Routing and Security

Use PHP attributes instead of YAML/XML configuration.

```php
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Security\Http\Attribute\IsGranted;

#[Route('/api/v1/orders', name: 'api_orders_')]
#[IsGranted('ROLE_USER')]
final class OrderController extends AbstractController
{
    #[Route('', name: 'list', methods: ['GET'])]
    public function list(): JsonResponse { }

    #[Route('/{id}', name: 'show', methods: ['GET'])]
    #[IsGranted('view', 'order')]
    public function show(Order $order): JsonResponse { }

    #[Route('', name: 'create', methods: ['POST'])]
    #[IsGranted('ROLE_ADMIN', methods: ['POST'])]
    public function create(Request $request): JsonResponse { }
}
```

### 6.5 Thin Controllers

A controller only parses input → calls a service/handler → returns a response.
Delegate business logic to a dedicated Service or MessageCommandHandler.

```php
#[Route('/api/v1/orders', methods: ['POST'])]
public function create(Request $request, MessageBusInterface $bus): JsonResponse
{
    $dto = $this->serializer->deserialize($request->getContent(), CreateOrderDto::class, 'json');
    $errors = $this->validator->validate($dto);

    if (count($errors) > 0) {
        return $this->json(['errors' => (string) $errors], 422);
    }

    $bus->dispatch(new CreateOrderCommand(
        customerId: $dto->customerId,
        productId:  $dto->productId,
        quantity:   $dto->quantity,
    ));

    return $this->json(null, 202);
}
```

---

## 7. Doctrine ORM

### 7.1 Required Entity Mapping Elements

```php
#[ORM\Entity(repositoryClass: OrderRepository::class)]
#[ORM\Table(name: 'orders')]
#[ORM\Index(columns: ['status'], name: 'idx_orders_status')]
#[ORM\Index(columns: ['customer_id'], name: 'idx_orders_customer_id')]
#[ORM\UniqueConstraint(name: 'uq_orders_external_id', columns: ['external_id'])]
final class Order
{
    #[ORM\Id]
    #[ORM\Column(type: 'uuid', nullable: false)]
    private string $id;

    // String column: type, nullable, length must be specified
    #[ORM\Column(type: Types::STRING, length: 255, nullable: false)]
    private string $externalId;

    // Money: decimal (precision + scale required) — no float
    #[ORM\Column(type: Types::DECIMAL, precision: 15, scale: 2, nullable: false)]
    private string $amount;

    // Enum column: use enumType
    #[ORM\Column(type: Types::STRING, enumType: OrderStatus::class, nullable: false)]
    private OrderStatus $status = OrderStatus::Pending;

    // JSON: type: 'json' — no json_object
    #[ORM\Column(type: Types::JSON, nullable: false)]
    private array $metadata = [];

    // DateTime: DateTimeImmutable required — no new \DateTime()
    #[ORM\Column(type: Types::DATETIME_IMMUTABLE, nullable: false)]
    private DateTimeImmutable $createdAt;

    // FK relation: always declare an Index
    #[ORM\ManyToOne(targetEntity: Customer::class)]
    #[ORM\JoinColumn(name: 'customer_id', referencedColumnName: 'id', nullable: false)]
    private Customer $customer;
}
```

### 7.2 Repository Pattern

Handle all query logic in a Repository class. Querying directly from a controller or service is **prohibited**.

```php
final class OrderRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, Order::class);
    }

    // No findAll() — always filter/paginate
    /**
     * @return Order[]
     */
    public function findByStatus(OrderStatus $status, int $limit = 50, int $offset = 0): array
    {
        return $this->createQueryBuilder('o')
            ->where('o.status = :status')
            ->setParameter('status', $status)
            ->orderBy('o.createdAt', 'DESC')
            ->setMaxResults($limit)
            ->setFirstResult($offset)
            ->getQuery()
            ->getResult();
    }

    // Prevent N+1: bulk-load the associated entities with JOIN FETCH
    /**
     * @return Order[]
     */
    public function findWithItems(OrderStatus $status): array
    {
        return $this->createQueryBuilder('o')
            ->addSelect('i')                         // JOIN FETCH
            ->leftJoin('o.items', 'i')
            ->where('o.status = :status')
            ->setParameter('status', $status)
            ->getQuery()
            ->getResult();
    }
}
```

### 7.3 Migration Workflow

```bash
# After changing an entity
cd app && php bin/console make:migration

# Apply after review (run separately per EntityManager)
cd app && php bin/console doctrine:migrations:migrate --no-interaction --em=default --env=prod
```

Rules:

- Do not modify a migration file directly
- Review the SQL with `--dry-run` before a production deploy
- Run separately for each EntityManager (`--em=<name>`)

---

## 8. Messenger / CQRS Pattern

### 8.1 Message Kinds and Roles

| Kind | Directory | Role |
| --- | --- | --- |
| `MessageCommand` | `src/Domain/*/MessageCommand/` | Convey write intent (state change) |
| `MessageCommandHandler` | `src/Domain/*/MessageCommandHandler/` | Process the Command (DB write) |
| `MessageQuery` | `src/Domain/*/MessageQuery/` | Convey read intent (lookup) |
| `MessageQueryHandler` | `src/Domain/*/MessageQueryHandler/` | Process the Query (DB read) |
| `MessageEvent` | `src/Domain/*/MessageEvent/` | Notify a side effect (a fact that occurred) |
| `MessageEventHandler` | `src/Domain/*/MessageEventHandler/` | Process the Event (email, notification, etc.) |

### 8.2 MessageCommand Definition

```php
// src/Domain/Order/MessageCommand/CreateOrderCommand.php
namespace App\Domain\Order\MessageCommand;

use Symfony\Component\Messenger\Attribute\AsMessage;

#[AsMessage('async')]    // specify the async transport
readonly class CreateOrderCommand
{
    public function __construct(
        public string $customerId,
        public string $productId,
        public int    $quantity,
    ) {}
}
```

Do not put an Entity directly in a message. Pass only the ID and look it up via the Repository in the handler.

### 8.3 MessageCommandHandler Definition

```php
// src/Domain/Order/MessageCommandHandler/CreateOrderHandler.php
namespace App\Domain\Order\MessageCommandHandler;

use App\Domain\Order\MessageCommand\CreateOrderCommand;
use Symfony\Component\Messenger\Attribute\AsMessageHandler;

#[AsMessageHandler]
final class CreateOrderHandler
{
    public function __construct(
        private readonly OrderRepository    $orderRepository,
        private readonly MessageBusInterface $eventBus,
        #[Target('monolog.logger.order')]
        private readonly LoggerInterface    $logger,
    ) {}

    public function __invoke(CreateOrderCommand $command): void
    {
        $order = Order::create(
            customerId: $command->customerId,
            productId:  $command->productId,
            quantity:   $command->quantity,
        );

        $this->orderRepository->save($order, flush: true);

        // Separate side effects into an Event
        $this->eventBus->dispatch(new OrderCreatedEvent($order->getId()));

        $this->logger->info('Order created', ['order_id' => $order->getId()]);
    }
}
```

### 8.4 Retry Strategy and Failure Transport

```yaml
# config/packages/messenger.yaml
framework:
    messenger:
        failure_transport: failed

        transports:
            async:
                dsn: '%env(MESSENGER_TRANSPORT_DSN)%'
                retry_strategy:
                    max_retries: 3
                    delay: 1000       # ms
                    multiplier: 2     # 1s → 2s → 4s
                    max_delay: 10000
            failed:
                dsn: 'doctrine://default?queue_name=failed'
```

Handling unrecoverable errors:

```php
use Symfony\Component\Messenger\Exception\UnrecoverableMessageHandlingException;

public function __invoke(CreateOrderCommand $command): void
{
    $customer = $this->customerRepository->find($command->customerId);
    if (null === $customer) {
        // Retrying yields the same result → throw UnrecoverableMessageHandlingException
        throw new UnrecoverableMessageHandlingException(
            "Customer not found: {$command->customerId}"
        );
    }
}
```

### 8.5 CQRS Boundary Rules

- Write operations must be dispatched as a `MessageCommand` (no direct writes in the Controller)
- Read operations call a `MessageQuery` or the Repository directly
- Extract side effects (email, notification) inside a `MessageCommandHandler` into a `MessageEvent`
- Directly instantiating a handler class or calling its method is **prohibited** — always go through `MessageBusInterface`

---

## 9. Security

### 9.1 Input Validation — DTO + Validator

All input goes through a Form type or a DTO with `#[Assert\*]` constraints applied.
Directly accessing `$request->get()`, `$_POST`, `$_GET` is **prohibited**.

```php
// src/Domain/Order/Dto/CreateOrderDto.php
use Symfony\Component\Validator\Constraints as Assert;
use Symfony\Component\Security\Core\Validator\Constraints as SecurityAssert;

readonly class CreateOrderDto
{
    public function __construct(
        #[Assert\NotBlank]
        #[Assert\Uuid]
        public string $customerId,

        #[Assert\NotBlank]
        #[Assert\Uuid]
        public string $productId,

        #[Assert\Positive]
        #[Assert\LessThanOrEqual(value: 1000)]
        public int $quantity,

        #[Assert\NotBlank]
        #[Assert\Email]
        public string $email,

        #[SecurityAssert\UserPassword]
        #[Sensitive]       // masked in logs · stack traces
        public string $currentPassword,
    ) {}
}
```

### 9.2 CSRF Protection

Apply it to every HTML form action that changes state.

```php
use Symfony\Component\Security\Http\Attribute\IsCsrfTokenValid;

#[Route('/orders/{id}/approve', methods: ['POST'])]
#[IsCsrfTokenValid('approve_order', tokenKey: '_token')]
public function approve(Order $order): Response
{
    // ...
}
```

Twig form:

```twig
<form method="POST" action="{{ path('order_approve', {id: order.id}) }}">
    <input type="hidden" name="_token" value="{{ csrf_token('approve_order') }}">
    <button type="submit">Approve</button>
</form>
```

Token-based APIs (JWT) are exempt from CSRF — but `Origin`/`Referer` header validation is required.

### 9.3 XSS Prevention

Disabling Twig auto-escaping is **prohibited**. Use the `|raw` filter only for trusted server-generated HTML.

```twig
{# Prohibited: |raw on user input #}
{{ comment.content|raw }}

{# Recommended: rely on auto-escaping #}
{{ comment.content }}

{# When trusted HTML is needed: sanitize with DOMPurify then |raw #}
{{ purifiedHtml|raw }}
```

### 9.4 SQL Injection Prevention

Use `:param` binding in DQL/QueryBuilder. String interpolation is **prohibited**.

```php
// Prohibited
$this->createQuery("SELECT o FROM Order o WHERE o.status = '{$status}'");

// Recommended
$this->createQueryBuilder('o')
    ->where('o.status = :status')
    ->setParameter('status', $status);
```

### 9.5 Rate Limiting

Apply it to public POST endpoints (login, sign-up, password reset).

```yaml
# security.yaml — login throttling
security:
    firewalls:
        main:
            login_throttling:
                max_attempts: 5
                interval: '15 minutes'
```

API endpoint:

```php
use Symfony\Component\RateLimiter\RateLimiterFactory;

final class AuthController extends AbstractController
{
    public function __construct(
        #[Autowire(service: 'limiter.api_anonymous')]
        private readonly RateLimiterFactory $limiter,
    ) {}

    #[Route('/api/register', methods: ['POST'])]
    public function register(Request $request): JsonResponse
    {
        $limiter = $this->limiter->create($request->getClientIp());
        if (!$limiter->consume()->isAccepted()) {
            return $this->json(['error' => 'Too many requests'], 429);
        }
        // ...
    }
}
```

### 9.6 Protecting Sensitive Data

```php
// Apply #[Sensitive] to sensitive DTO properties
readonly class ChangePasswordDto
{
    public function __construct(
        #[Sensitive]
        public string $currentPassword,
        #[Sensitive]
        public string $newPassword,
    ) {}
}

// Do not include sensitive data in logs
$this->logger->info('Password changed', [
    'user_id' => $userId,
    // 'password' => $password,  // ← never
]);
```

---

## 10. Error Handling and Logging

### 10.1 Exception-Handling Principles

```php
// Prohibited: empty catch block
try {
    $order = $this->repository->findOrFail($id);
} catch (\Exception $e) {
    // does nothing — prohibited
}

// Prohibited: an overly broad exception type
} catch (\Exception $e) { }

// Recommended: a specific exception type + logging + re-throw
} catch (OrderNotFoundException $e) {
    $this->logger->warning('Order not found', ['order_id' => $id, 'error' => $e->getMessage()]);
    throw $e;
} catch (DatabaseException $e) {
    $this->logger->error('Database error', ['order_id' => $id, 'error' => $e]);
    throw new RuntimeException('Order fetch failed', previous: $e);
}
```

### 10.2 Named Logger Channels

Using the global `logger` service is **prohibited**. Use a per-domain channel.

```php
// Prohibited
public function __construct(private readonly LoggerInterface $logger) {}

// Recommended
public function __construct(
    #[Target('monolog.logger.order')]
    private readonly LoggerInterface $logger,
) {}
```

Channel configuration (`config/packages/monolog.yaml`):

```yaml
monolog:
    channels: [order, payment, provider]
```

### 10.3 Structured Log Context

Use a context array instead of string interpolation.

```php
// Prohibited
$this->logger->error("Order {$orderId} failed for user {$userId}");

// Recommended
$this->logger->error('Order processing failed', [
    'order_id' => $orderId,
    'user_id'  => $userId,
    'error'    => $e->getMessage(),
]);
```

### 10.4 Debug-Log Guard

Guard `info`/`debug`-level logs with the `$this->isDebug` flag.

```php
public function __construct(
    #[Autowire('%kernel.debug%')]
    private readonly bool $debug,
) {}

public function process(Order $order): void
{
    if ($this->debug) {
        $this->logger->debug('Processing order', ['order' => $order->getId()]);
    }
    // ...
}
```

---

## 11. Domain Structure Rules

### 11.1 Layer Placement Rules

| Class type | Directory |
| --- | --- |
| Entity | `src/Domain/{Domain}/Entity/` |
| Repository | `src/Domain/{Domain}/Repository/` |
| MessageCommand | `src/Domain/{Domain}/MessageCommand/` |
| MessageCommandHandler | `src/Domain/{Domain}/MessageCommandHandler/` |
| MessageQuery | `src/Domain/{Domain}/MessageQuery/` |
| MessageQueryHandler | `src/Domain/{Domain}/MessageQueryHandler/` |
| MessageEvent | `src/Domain/{Domain}/MessageEvent/` |
| MessageEventHandler | `src/Domain/{Domain}/MessageEventHandler/` |
| Service | `src/Domain/{Domain}/Service/` |
| EventSubscriber | `src/Domain/{Domain}/EventSubscriber/` |
| Scheduler | `src/Scheduler/{Domain}/` |
| Controller | `src/Controller/{Api\|Web}/` |
| DTO / Form | `src/Domain/{Domain}/Dto/` |
| Serializer | `src/Serializer/` |

### 11.2 Domain Dependency Direction

```text
Controller → MessageBus → MessageCommandHandler → Repository → Entity
Controller → MessageBus → MessageQueryHandler  → Repository
MessageCommandHandler → MessageEventHandler (via EventBus)
```

Cross-domain dependency rules:

- One domain class (`Company`) directly importing another domain's (`Partners`) Entity is **prohibited**
- Cross-domain data sharing → use a shared Entity or a `MessageQuery` dispatch
- Direct writes (persist/flush) to a `Providers/*` domain Entity happen only inside that domain's handler

### 11.3 Abstract Domain Rules

Classes in the `Abstract/` directory may be only interfaces or abstract classes.
Place `final` concrete implementations outside `Abstract/`.

---

## 12. Static Analysis and Code Quality Tools

```bash
# PHPStan (level 8)
cd app && vendor/bin/phpstan analyse

# PHP-CS-Fixer (Symfony ruleset)
cd app && vendor/bin/php-cs-fixer fix --dry-run   # preview
cd app && vendor/bin/php-cs-fixer fix              # auto-fix

# PHPUnit
cd app && vendor/bin/phpunit
cd app && vendor/bin/phpunit --testsuite Unit
cd app && vendor/bin/phpunit --testsuite Integration

# Security audit
cd app && composer audit
```

Test boundaries:

| Layer | Base class | I/O |
| --- | --- | --- |
| Unit | `TestCase` | None (mocking) |
| Integration | `KernelTestCase` | Real PostgreSQL + Redis |
| Functional | `WebTestCase` | HTTP layer |

Integration tests use a **real PostgreSQL instance**. DB mocking is **prohibited**.

---

## 13. Mercure / Server-Sent Events (SSE)

Implement realtime server → client push with the **Mercure protocol**. Mercure is an open protocol built on
top of **Server-Sent Events (SSE)** — a modern alternative to polling/WebSocket, natively supported by modern
browsers — that provides authorization, automatic reconnection and message recovery, a presence API, and
automatic discovery via the HTTP `Link` header
[WebFetch: https://symfony.com/doc/current/mercure.html]. For simple cases with very few concurrent
connections, Symfony's native `EventStreamResponse` is also an alternative
[WebFetch: https://symfony.com/doc/current/mercure.html].

### 13.1 Installation and Configuration

```bash
composer require mercure   # symfony/mercure-bundle + symfony/mercure
```

The Flex recipe creates the `.env` environment variables and `config/packages/mercure.yaml`
[WebFetch: https://symfony.com/doc/current/mercure.html].

| Environment variable | Meaning |
| --- | --- |
| `MERCURE_URL` | The internal Hub URL the app (server) **publishes** updates to |
| `MERCURE_PUBLIC_URL` | The public Hub URL the browser (JS) **subscribes** to |
| `MERCURE_JWT_SECRET` | The JWT signing secret — must match the Hub's key |

```yaml
# config/packages/mercure.yaml
mercure:
    hubs:
        default:
            url: '%env(MERCURE_URL)%'
            public_url: '%env(MERCURE_PUBLIC_URL)%'
            jwt:
                secret: '%env(MERCURE_JWT_SECRET)%'
                publish: ['*']
```

- Do not commit secrets such as `MERCURE_JWT_SECRET` — inject them via `.env.local` or Symfony Secrets (§2 · configuration rule).

### 13.2 Publishing (Server)

Use the autowired `Symfony\Component\Mercure\HubInterface` and the `Symfony\Component\Mercure\Update` value object
[WebFetch: https://symfony.com/doc/current/mercure.html].

```php
use Symfony\Component\Mercure\HubInterface;
use Symfony\Component\Mercure\Update;

$hub->publish(new Update(
    'https://example.com/books/1',            // topic (an IRI or arbitrary string)
    json_encode(['status' => 'OutOfStock']),  // data (serialized string)
));
```

- `Update` constructor: `Update($topics, $data, $private = false)`.
- Wrap the publish in a `try/catch` to fail gracefully so a Hub failure does not break domain logic (§10 error handling).
- If asynchronous publishing is needed, an `Update` can be dispatched onto the Messenger bus
  [WebFetch: https://symfony.com/doc/current/mercure.html].

### 13.3 Subscribing (Browser)

The `mercure()` Twig function generates a Hub URL with the topic query attached, and the browser subscribes with the native `EventSource`
[WebFetch: https://symfony.com/doc/current/mercure.html].

```twig
<script>
const es = new EventSource("{{ mercure('https://example.com/books/1')|escape('js') }}")
es.onmessage = e => console.log(JSON.parse(e.data))
</script>
```

- You can subscribe to multiple topics · URI templates (e.g. `https://example.com/reviews/{id}`) at once by passing an array
  [WebFetch: https://symfony.com/doc/current/mercure.html].

### 13.4 public vs private Updates and Authorization

- If you publish a **private** update with `new Update($topic, $data, true)`, the subscriber's JWT must have that topic in its
  `mercure.subscribe` claim to receive it. The publisher's JWT must include the topic in its `mercure.publish` claim
  [WebFetch: https://symfony.com/doc/current/mercure.html].

```json
{ "mercure": { "publish": ["*"], "subscribe": ["https://example.com/books/1"] } }
```

- Cookie-based authorization: `mercure($topic, { subscribe: $topic })` + `new EventSource(url, { withCredentials: true })`,
  or set a subscription cookie on the server with `Symfony\Component\Mercure\Authorization::setCookie()`
  [WebFetch: https://symfony.com/doc/current/mercure.html].

### 13.5 Symfony UX Turbo Integration (This Project's Approach)

`symfony/ux-turbo` implements Turbo Stream push (an SPA-like experience) via Mercure without writing JS
[WebFetch: https://symfony.com/doc/current/mercure.html]. The server publishes a `<turbo-stream>` to a topic, and the
template subscribes by rendering a `<turbo-stream-source>` with `turbo_stream_listen(topic)`. (API Platform can
auto-broadcast CRUD changes with `#[ApiResource(mercure: true)]`
[WebFetch: https://symfony.com/doc/current/mercure.html].)

This repository's realtime order-status reflection uses this approach:

- **Publish** — `App\EventListener\Providers\Finance\App\Trading\OrderStatusStreamListener` calls
  `HubInterface::publish()` on `workflow.orders.entered` to publish `turbo/streams/trading/_order_status.stream.html.twig`
  to each order topic (`trading/orders/{provider}/{id}`).
- **Subscribe** — the open-orders list subscribes to a single URI-template topic (`trading/orders/upbit/{id}`) with
  `turbo_stream_listen`, swapping the status badge of every published order without a per-row subscription.

### 13.6 Testing

- Unit: verify publishing with `Symfony\Component\Mercure\MockHub` (+ `Symfony\Component\Mercure\JWT\StaticTokenProvider`)
  [WebFetch: https://symfony.com/doc/current/mercure.html].
- Functional: replace the `mercure.hub.default` service with a `HubStub` implementing `HubInterface` in `config/services_test.yaml`
  [WebFetch: https://symfony.com/doc/current/mercure.html].

@see <https://symfony.com/doc/current/mercure.html>

---

## 14. Verification Checklist

The review checklist derives from the rules (SoT), so it is not duplicated in this document. After finishing
an implementation, review each PHP file with the `/app-php-symfony-review {file}` command; the judgment criteria's
single source is `.claude/rules/app-php-symfony-00-overview-rule.md` ~ `app-php-symfony-15-scheduler-rule.md`.

---

## 15. Workflow (State Machine)

Manage the state transitions of automated-trading orders (`orders`) with Symfony Workflow (`type: state_machine`).
State transitions are performed only via `WorkflowInterface::apply()` (no direct status setting), and only inside
a `MessageCommandHandler`. The judgment criteria (SoT) is `app-php-symfony-12-workflow-rule.md`, and this section is the detailed/example edition.

### 15.1 State Diagram (`config/packages/workflow.yaml`)

```text
ordered ──submit──▶ waiting ──accept──▶ in progress ──fill──▶ completed
   │                   │                     │
   └──────────────── cancel ────────────────┘  (any → cancel)
```

| Item | Value |
| --- | --- |
| `type` | `state_machine` (one place at a time) |
| `marking_store` | `{ type: method, property: status }` — reads and writes the BackedEnum `status` via a method |
| `initial_marking` | `ordered` |
| `audit_trail.enabled` | `%kernel.debug%` (dev only) |
| `supports` | The 2 UPbit · KoreaInvestment `...\App\Trading\Orders` entities |

### 15.2 Applying a Transition in the Handler (`can()` → `apply()` → `flush()`)

```php
use Symfony\Component\DependencyInjection\Attribute\Target;
use Symfony\Component\Workflow\WorkflowInterface;

#[AsMessageHandler]
final readonly class Orders
{
    public function __construct(
        #[Target('orders')]
        private WorkflowInterface $ordersWorkflow,
        #[Target('providers_finance_app_digitalasset_upbit_domestic.entity_manager')]
        private EntityManagerInterface $entityManager,
        private OrdersRepository $ordersRepository,
    ) {}

    public function __invoke(MessageCommandOrders $message): void
    {
        $order = $this->ordersRepository->find($message->getOrderId())
            ?? throw new UnrecoverableMessageHandlingException('Order not found.');

        // Idempotency guard — stop even on redelivery if the order was already transitioned
        if (!$this->ordersWorkflow->can($order, 'submit')) {
            return;
        }

        $response = /* ... send the order (dry-run/live) ... */ null;
        $order->setResponsePayload($response);

        $this->ordersWorkflow->apply($order, null !== $response ? 'submit' : 'cancel');
        $this->entityManager->flush();
    }
}
```

### 15.3 Guards · Side Effects via Events

Handle transition blocking in a guard event, and post-transition side effects (notification · log) in an entered
event — do not mix them into the handler body as conditional branches.

```php
use Symfony\Component\EventDispatcher\Attribute\AsEventListener;
use Symfony\Component\Workflow\Event\GuardEvent;

#[AsEventListener('workflow.orders.guard.submit')]
final class DisallowSubmitWithoutPayload
{
    public function __invoke(GuardEvent $event): void
    {
        $order = $event->getSubject();
        if (null === $order->getRequestPayload()) {
            $event->setBlocked(true, 'Missing request payload');
        }
    }
}
```

This repository publishes a Turbo Stream via Mercure on `workflow.orders.entered` to update the order-status badge in realtime (§13.5).

### 15.4 Testing

```php
// Verify the transition rules with the real workflow service (KernelTestCase)
$workflow = self::getContainer()->get('state_machine.orders');
self::assertTrue($workflow->can($order, 'submit'));
$workflow->apply($order, 'submit');
self::assertTrue($order->getStatus() === OrdersStatusEnum::Waiting);
```

@see .claude/rules/app-php-symfony-12-workflow-rule.md
@see <https://symfony.com/doc/8.1/the-fast-track/en/19-workflow.html>

---

## 16. Mailer & Notifier

Send email with **Mailer** and multi-channel notifications with **Notifier**. Operator system notifications go
through the Notifier's `admin_recipients`. The judgment criteria (SoT) is `app-php-symfony-13-mailer-notifier-rule.md`.

### 16.1 TemplatedEmail (Twig Body)

```php
use Symfony\Bridge\Twig\Mime\TemplatedEmail;
use Symfony\Component\Mailer\MailerInterface;
use Symfony\Component\Mime\Address;

final class WelcomeVerifier
{
    public function __construct(private readonly MailerInterface $mailer) {}

    public function sendWelcomeMessage(Users $user): void
    {
        $email = (new TemplatedEmail())
            ->to(new Address($user->getEmail()))
            ->subject('Welcome')
            ->htmlTemplate('controller/tools/email/base/_welcome.html.twig')
            ->context(['user' => $user]);   // URLs in the template use url() (absolute path)

        $this->mailer->send($email);
    }
}
```

### 16.2 Custom Notification + admin_recipients

```php
use Symfony\Component\Notifier\Notification\Notification;
use Symfony\Component\Notifier\NotifierInterface;

$notification = (new Notification('KoreaInvestment OAuth2 authentication failed', ['email']))
    ->content('Check the validity of appkey/appsecret and whether the key needs rotation.');

// No recipient specified → delivered to the entire admin_recipients in notifier.yaml
$this->notifier->send($notification);
```

When per-channel custom rendering is needed, extend `Notification` and implement `EmailNotificationInterface`
(email template) or `ChatNotificationInterface` (Slack blocks), and branch channels by severity with
`getChannels(RecipientInterface): array`. The default severity→channel mapping policy is owned by the
`channel_policy` in `notifier.yaml` (SoT).

### 16.3 Async Sending & Webhook

```yaml
# Send bulk · delay-tolerant messages async (the domain transport is owned by message-rabbitmq-rule)
framework:
    messenger:
        routing:
            Symfony\Component\Mailer\Messenger\SendEmailMessage: async_abstract
            Symfony\Component\Notifier\Message\ChatMessage: async_abstract
```

Handle inbound events (bounce · delivery events) with `symfony/webhook`'s `RequestParserInterface`, verifying the
signature and normalizing them into a `RemoteEvent` processed by a `RemoteEventConsumerInterface` — do not parse
the raw payload directly in a controller.

### 16.4 Testing

```php
// WebTestCase — verify email sending
$this->assertEmailCount(1);
$email = $this->getMailerMessage(0);
$this->assertEmailHeaderSame($email, 'To', 'admin@xsun.ai');
$this->assertEmailHtmlBodyContains($email, 'Welcome');
```

@see .claude/rules/app-php-symfony-13-mailer-notifier-rule.md
@see <https://symfony.com/doc/8.1/the-fast-track/en/20-emails.html>
@see <https://symfony.com/doc/8.1/the-fast-track/en/25-notifier.html>

---

## 17. Translation / i18n

Korean by default (`default_locale: ko`), English fallback (`fallbacks: [en]`). User-facing strings are managed
as catalog keys. The judgment criteria (SoT) is `app-php-symfony-14-translation-rule.md`.

### 17.1 Catalog Structure (`translations/app.{locale}.yml`)

The domain is `app`, the extension is `.yml`. Keep keys as a nested structure and access them with dot notation.

```yaml
# translations/app.ko.yml            # translations/app.en.yml
#   (ko values shown as "[ko] …" glosses)
navbar:                              navbar:
    account:                             account:
        user: "[ko] User"                    user: "User"
        profile: "[ko] Profile"              profile: "Profile"
```

```twig
{% trans_default_domain 'app' %}
<span>{{ 'navbar.account.user'|trans }}</span>
```

### 17.2 ICU Plurals · Variables

ICU MessageFormat requires the `+intl-icu` suffix on the domain.

```yaml
# translations/app+intl-icu.ko.yml   (values shown as "[ko] …" glosses)
notification.count: "{count, plural, =0 {[ko] no notifications} other {[ko] # notifications}}"
```

```twig
{{ 'notification.count'|trans({ count: unread })|trans_default_domain('app') }}
```

### 17.3 Locale Switching

Determine the current locale with the `_locale` route parameter, and inject `LocaleSwitcher` for runtime switching.

```php
#[Route('/{_locale}/dashboard', requirements: ['_locale' => 'ko|en'])]
public function dashboard(): Response { /* ... */ }
```

### 17.4 Extraction · Verification

```bash
cd app && php bin/console debug:translation ko --only-missing
cd app && php bin/console translation:extract ko --domain=app --force
```

@see .claude/rules/app-php-symfony-14-translation-rule.md
@see <https://symfony.com/doc/8.1/the-fast-track/en/28-intl.html>

---

## 18. Scheduler

Define recurring tasks as a `ScheduleProviderInterface` + `#[AsSchedule]` class, and delegate execution by
dispatching a `MessageCommand` (the attribute task `#[AsCronTask]` is not used in this project). The judgment
criteria (SoT) is `app-php-symfony-15-scheduler-rule.md`.

### 18.1 ScheduleProvider

```php
#[AsSchedule('providers_property_app_vworld_api_adsigg')]
final class AdSigg implements ScheduleProviderInterface
{
    public function __construct(
        #[Target('cache_pool_providers_property_app_agencies_vworld')]
        private readonly CacheInterface $cache,
    ) {}

    public function getSchedule(): Schedule
    {
        return $this->schedule ??= (new Schedule())
            ->with(RecurringMessage::cron('@daily', new MessageCommandAdSigg(self::ADSIGG_ID)))
            ->stateful($this->cache)
            ->processOnlyLastMissedRun(true);
    }
}
```

| Trigger | Example |
| --- | --- |
| cron expression | `RecurringMessage::cron('@daily', $msg)`, `cron('0 9 * * 1-5', $msg)` |
| interval | `RecurringMessage::every('30 seconds', $msg)`, `every('1 hour', $msg)` |
| custom | `RecurringMessage::trigger(new TradingDayTrigger($inner), $msg)` |

### 18.2 Calendar-Based Custom Trigger

A schedule that must fire only on regular-session · trading days wraps the inner trigger with a `TriggerInterface`
wrapper to skip non-trading days · off-market hours (weekends · Korean holidays are determined with `Yasumi`). This
is the "when to trigger" shape of the schedule; the domain execution guard for "may we run now?" is still the handler's responsibility.

### 18.3 Operations

```bash
cd app && php bin/console debug:scheduler
cd app && php bin/console messenger:consume scheduler_providers_property_app_vworld_api_adsigg -vv
```

@see .claude/rules/app-php-symfony-15-scheduler-rule.md
@see <https://symfony.com/doc/8.1/the-fast-track/en/24-scheduler.html>

---

## 19. Troubleshooting & Profiler (Reference)

A command reference for bug diagnosis · configuration checks. It is a procedural reference, not judgment criteria
(SoT), so there is no rule file for it.

### 19.1 debug:* Commands

| Command | Purpose |
| --- | --- |
| `php bin/console debug:router [name]` | Check route list · path · methods |
| `php bin/console debug:container [id]` | Check service definition · arguments |
| `php bin/console debug:autowiring [keyword]` | Check autowireable types |
| `php bin/console debug:event-dispatcher [event]` | Check event listeners · priority |
| `php bin/console debug:config [ext]` | Check merged bundle configuration |
| `php bin/console debug:messenger` | Check the message→handler mapping |
| `php bin/console debug:translation {locale}` | Check untranslated · unused keys |
| `php bin/console debug:scheduler` | Registered schedules · next run time |

### 19.2 Web Profiler & Dump

- For a dev request, inspect routing · DB queries (N+1) · mail · messages · security tokens in the bottom debug
  toolbar → profiler (`symfony/web-profiler-bundle`).
- For a CLI/worker context, use `server:dump` instead of `dump()` to collect dumps in one place.

```bash
cd app && php bin/console server:dump          # collect dumps in a separate terminal
```

### 19.3 Environment · Requirements

```bash
cd app && php bin/console about                # kernel · environment · path summary
cd app && vendor/bin/requirements-checker      # check PHP extensions · settings (symfony/requirements-checker)
cd app && php bin/console debug:dotenv         # check .env loading priority · final values
```

### 19.4 Log Channels

- Record separately per domain via a named channel (`monolog.logger.{channel}`) — channel configuration is `config/packages/monolog.yaml`.
- Realtime tracing in dev: `tail -f var/log/dev.log` or the profiler Logs panel.

@see <https://symfony.com/doc/8.1/the-fast-track/en/5-debug.html>
@see <https://symfony.com/doc/8.1/the-fast-track/en/29-performance.html>
@see <https://symfony.com/doc/8.1/the-fast-track/en/30-internals.html>
