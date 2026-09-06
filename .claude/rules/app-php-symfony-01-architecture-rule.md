---
paths:
  - "app/src/**/*.php"
---

# Architecture Rule

@see https://symfony.com/doc/current/best_practices.html#use-the-default-directory-structure

## Directory Structure

Always follow the standard Symfony directory layout. The Symfony application root is `app/`.

```text
xsun-app/                             ← Repository root
└── app/
    └── src/                                 # PHP source code (namespace: App\)
        ├── ApiResource/                     # API Platform resource classes
        ├── Command/                         # Symfony Console commands
        ├── Controller/                      # HTTP controllers (thin glue code only)
        ├── DataFixtures/                    # DoctrineFixturesBundle fixture classes
        ├── Entity/                          # Doctrine entities (PostgreSQL)
        ├── EntityRepository/                # Doctrine Repository classes
        ├── EventListener/                   # Single-event listeners (#[AsEventListener])
        ├── EventSubscriber/                 # Multi-event subscribers (getSubscribedEvents)
        ├── Form/                            # Symfony Form types
        ├── MessageCommand/                  # Messenger write-side messages (Command)
        ├── MessageCommandHandler/           # Handlers for MessageCommand classes
        ├── MessageEvent/                    # Messenger domain events
        ├── MessageEventHandler/             # Handlers for MessageEvent classes
        ├── MessageQuery/                    # Messenger read-side messages (Query)
        ├── MessageQueryHandler/             # Handlers for MessageQuery classes
        ├── Messenger/                       # Shared Messenger middleware / stamps
        ├── Scheduler/                       # Symfony Scheduler periodic tasks
        ├── Serializer/                      # Custom Symfony Serializer normalizers
        ├── Service/                         # Application and domain services
        ├── Twig/                            # Twig extensions and components
        ├── CLAUDE.md
        ├── Kernel.php
        └── Schedule.php
```

## Environments

- Three built-in environments: `dev`, `prod`, `test`.
- Per-environment configuration: a `config/packages/{env}/` directory or the `when@{env}:` key in YAML.
- The active environment is determined by the `APP_ENV` environment variable.

@see https://symfony.com/doc/current/configuration.html#configuration-environments

## Kernel

- `src/Kernel.php` is the application entry point.
- The `HttpKernel` handles the entire Request → Response conversion cycle.
- Always consult the official docs first before modifying the Kernel.

@see https://symfony.com/doc/current/components/http_kernel.html

## Bundle Policy

- **Prohibited**: creating a Bundle to separate application logic.
- **Allowed**: extracting a genuinely reusable, cross-project shared package as a Bundle (private repository).
- Organize code logically with PHP namespaces, not Bundles.

@see https://symfony.com/doc/current/best_practices.html#don-t-create-any-bundle-to-organize-your-application-logic

## Listener vs. Subscriber

- Use `EventListener` + `#[AsEventListener]` when a class handles **exactly one** kernel or domain event.
- Use `EventSubscriber` + `getSubscribedEvents()` when a class handles **multiple** events.

This distinction keeps the single-responsibility principle clear and avoids unnecessary boilerplate.

## Domain Layer Structure

This project is divided into the following top-level domains. Every subdirectory under `app/src/` mirrors this hierarchy exactly.

| Domain               | Purpose                                                      |
| -------------------- | ------------------------------------------------------------ |
| `Abstract`           | Shared base logic (Users, Base, Connect) — no business logic |
| `Company`            | Company introduction pages and content                       |
| `Partners`           | Partner/store management                                     |
| `Products`           | Product catalog                                              |
| `Providers/Data`     | External data-provider integration (generic)                 |
| `Providers/Finance`  | Financial-provider integration (KoreaInvestment, UPbit)      |
| `Providers/Property` | Real-estate-provider integration (VWorld)                    |
| `Resources`          | Content resources (Blog, Developers, YouTube)                |
| `Team`               | Internal team tools (Agents, Support)                        |
| `Tools`              | Application tools (Chat, Email)                               |

## Namespace → Directory Mapping

Every PHP class namespace maps 1:1 to a filesystem path under `app/src/`:

```
App\{Layer}\{Domain}\{Name}
→ app/src/{Layer}/{Domain}/{Name}.php
```

For deeply nested provider entities, the full provider path is preserved as-is:

```
App\Entity\Providers\Finance\App\Securities\KoreaInvestment\Domestic\Stock\API\REST\Enterprise\ChkHoliday
→ app/src/Entity/Providers/Finance/App/Securities/KoreaInvestment/Domestic/Stock/API/REST/Enterprise/ChkHoliday.php
```

- **Never flatten** a deeply nested provider namespace for convenience — this path mirrors the hierarchy of the external provider's API.
- **Never create a file** directly in `app/src/` without a domain subdirectory — every class belongs to a domain.

## Cross-Domain Rules

- A domain class may depend on an `Abstract` class.
- A domain class **must not** depend on another domain's internal classes (e.g. `Company` must not import from `Partners`).
- Cross-domain data sharing must go through a shared Entity or a MessageQuery dispatch — never direct cross-domain Service injection.
- `Providers/*` domains are read-only data sources — they expose data only via MessageQuery, and other domains do not write to their Entities directly.

## Layer Placement Rules

| What you're building                    | Correct layer                              | Example path                                                              |
| --------------------------------------- | ------------------------------------------ | -------------------------------------------------------------------------- |
| Database record                         | `Entity`                                   | `app/src/Entity/Providers/Finance/.../ChkHoliday.php`                     |
| DB query logic                          | `EntityRepository`                         | `app/src/EntityRepository/Providers/Finance/.../ChkHolidayRepository.php` |
| Async write operation                   | `MessageCommand` + `MessageCommandHandler` | `app/src/MessageCommand/Providers/Finance/...`                            |
| Async read operation                    | `MessageQuery` + `MessageQueryHandler`     | `app/src/MessageQuery/Providers/Finance/...`                              |
| Domain event / side effect              | `MessageEvent` + `MessageEventHandler`     | `app/src/MessageEvent/Providers/Finance/...`                              |
| Reusable business logic                 | `Service`                                  | `app/src/Service/Providers/Finance/...`                                   |
| HTTP request handling                   | `Controller`                               | `app/src/Controller/Providers/Finance/...`                                |
| Background task                         | `Scheduler`                                | `app/src/Scheduler/Providers/Finance/...`                                 |
| Serialization format                    | `Serializer`                               | `app/src/Serializer/Providers/Finance/...`                                |
| Input form                              | `Form`                                     | `app/src/Form/Providers/Finance/...`                                      |
| Domain event listener (multiple events) | `EventSubscriber`                          | `app/src/EventSubscriber/Providers/Finance/...`                           |
| Kernel event listener (single event)    | `EventListener`                            | `app/src/EventListener/Providers/Finance/...`                             |

When a class subscribes to multiple events via `getSubscribedEvents()`, use `EventSubscriber`.
When a class handles exactly one event, use `EventListener` with `#[AsEventListener]` — it is simpler and avoids boilerplate.

## Naming Conventions

- **Class**: PascalCase, with no suffix except the layer suffix required by convention:
  - Repository: `{Name}Repository`
  - Handler: the same class name as the message it handles (distinguished at the handler-layer folder level)
  - EventSubscriber: `{Name}Subscriber`
  - EventListener: `{Name}Listener`
  - Form type: `{Name}Type`
  - Twig component: `{Name}` (no suffix)
- **Enum**: `{DescriptiveName}Enum` (e.g. `OrdersStatusEnum`, `TwoFactorTypeEnum`).
- **Route**: `{domain}_{subdomain}_{action}` in snake_case (e.g. `providers_finance_korea_investment_list`).
- **Twig template**: mirrors the controller path exactly — `templates/{domain}/{subdomain}/{action}.html.twig`.

## Abstract Domain

The `Abstract` subdomain holds shared infrastructure for cross-domain concerns:

- `Abstract/Base` — base Controller, base EventSubscriber, base Fixture setup
- `Abstract/Connect` — the OAuth2 connection flow shared by multiple providers
- `Abstract/Users` — user-account handling shared across the entire application

Classes in `Abstract` must be interfaces or abstract classes — a `final` concrete implementation is not allowed.
