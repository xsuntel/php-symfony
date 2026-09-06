---
paths:
  - "app/src/Service/**/*.php"
---

# Service / Dependency Injection Rule

@see https://symfony.com/doc/current/service_container.html

## Autowiring

Every service uses autowiring by default. Dependencies are resolved automatically through constructor type hints.

- Keep `autowire: true` and `autoconfigure: true` in `config/services.yaml` — never remove them.
- Autoconfiguration automatically tags `EventSubscriber`, `Twig\Extension`, `Command`, and so on.

```yaml
# config/services.yaml — keep these defaults
services:
    _defaults:
        autowire: true
        autoconfigure: true
```

## Service Visibility

- Every service is **private** by default — this is correct and intended.
- Mark a service `public` only when you must fetch it directly from the container at runtime (rare: test setup, legacy code).

## Constructor Injection Only

Never use setter injection, property injection, or `ContainerAware`. Use only constructor injection.

```php
final class InvoiceService
{
    public function __construct(
        private readonly InvoiceRepository $invoiceRepository,
        private readonly MailerInterface $mailer,
        #[Autowire(param: 'app.invoice_due_days')]
        private readonly int $dueDays,
    ) {}
}
```

## Interface Binding

When a class depends on an interface, bind the concrete implementation in `config/services.yaml`:

```yaml
services:
    App\Service\PaymentGatewayInterface: '@App\Service\StripeGateway'
```

Or use an explicit alias:

```yaml
services:
    App\Service\StripeGateway: ~

    App\Service\PaymentGatewayInterface:
        alias: App\Service\StripeGateway
```

When multiple implementations exist, specify the concrete class explicitly with `bind` or `alias`.
Controllers and services must type-hint the interface — they do not depend on the concrete implementation directly.

```yaml
# config/services.yaml
services:
    App\Service\PaymentInterface: '@App\Service\StripePayment'

    _defaults:
        bind:
            $mailer: '@App\Mailer\CustomMailer'
```

## Named Services and Attributes

For services that cannot be autowired, use Symfony Attributes instead of manual YAML wiring:

```php
#[Autowire(service: 'monolog.logger.payment')]
private readonly LoggerInterface $logger,

#[Autowire(param: 'kernel.debug')]
private readonly bool $isDebug,

#[Target('paymentLogger')]
private readonly LoggerInterface $logger,
```

## Service Naming

- The service ID is the FQCN by default — never define a short custom ID.
- Define a custom ID only for a third-party class or a service created by a factory.

@see https://symfony.com/doc/current/service_container/autowiring.html

## Debugging Commands

```bash
# List all autowireable service types
php bin/console debug:autowiring

# Filter by keyword
php bin/console debug:autowiring logger

# List all container services
php bin/console debug:container

# Inspect a specific service
php bin/console debug:container App\Service\MyService
```

## Lazy Services

Defer service initialization until the first method call. Apply it to services whose initialization logic is expensive.

```php
use Symfony\Component\DependencyInjection\Attribute\Lazy;

class HeavyService
{
    public function __construct(
        #[Lazy] private readonly SomeHeavyDependency $dependency
    ) {}
}
```

@see https://symfony.com/doc/current/service_container/lazy_services.html
