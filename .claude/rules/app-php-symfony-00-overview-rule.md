---
paths:
  - "app/src/**/*.php"
---

# Symfony Project — Claude Rules Overview

## Reference Documents

- Official docs: https://symfony.com/doc/current
- Best Practices: https://symfony.com/doc/current/best_practices.html
- Symfony version: 8.1
- Detailed example/pattern reference: `.claude/docs/app-php-symfony-docs.md`

## Rule Files

| File                     | Area of responsibility                     |
| ------------------------ | ------------------------------------------ |
| app-php-symfony-01-architecture-rule.md  | Directory structure, bundle policy         |
| app-php-symfony-02-configuration-rule.md | Environment variables, parameters, secrets |
| app-php-symfony-03-controller-rule.md    | Routing, controller design                 |
| app-php-symfony-04-service-rule.md       | Dependency injection, autowiring, service container |
| app-php-symfony-05-doctrine-rule.md      | Entity mapping, Repository, migrations      |
| app-php-symfony-06-form-rule.md          | Form classes, validation, DTO patterns      |
| app-php-symfony-07-template-rule.md      | Twig naming, template inheritance, components |
| app-php-symfony-08-security-rule.md      | Firewalls, Voters, password hashing         |
| app-php-symfony-09-testing-rule.md       | Unit / Integration / Functional test strategy |
| app-php-symfony-10-frontend-rule.md      | AssetMapper, Stimulus, Symfony UX           |
| app-php-symfony-11-performance-rule.md   | Caching, HTTP Cache, deployment             |
| app-php-symfony-12-workflow-rule.md      | Workflow (state machine), transitions · guards |
| app-php-symfony-13-mailer-notifier-rule.md | Mailer, Notifier, Webhook inbound         |
| app-php-symfony-14-translation-rule.md   | i18n, catalogs, ICU, locale switching       |
| app-php-symfony-15-scheduler-rule.md     | Scheduler, ScheduleProvider, RecurringMessage |

## Absolute Prohibitions

- Do not call `$container->get()` directly — use constructor injection.
- Do not write business logic inside controllers — delegate to a Service.
- Do not create a Bundle to organize application logic — use PHP namespaces instead.
- Do not use YAML/XML for Doctrine mapping or routing — use only PHP Attributes.
- Do not store secrets in committed files — use `.env.local` locally and Symfony Secrets in production.
- Do not introduce another PHP framework such as Laravel or CodeIgniter — use only Symfony unless explicitly requested.
- Do not introduce Vue.js, React, or Angular — use Stimulus/Hotwire; propose an SPA only as an alternative when explicitly requested.
- Do not write raw SQL queries that bypass Doctrine — the exception follows the Native SQL rule in `app-php-symfony-05-doctrine-rule.md`.

## PHP & Symfony Version Constraints

- Target **PHP 8.4** — use property hooks, asymmetric visibility (`public private(set)`), and `#[\Deprecated]` where appropriate.
- Target **Symfony 8.1** — do not use APIs marked `@deprecated` in Symfony 7.x or earlier.
- Target **Doctrine ORM 3.x** — use `EntityRepository` (not `ServiceEntityRepository`) unless DI is needed, and require typed properties.

## Class Design

- Mark every class `final` unless it is explicitly designed for extension.
- Mark a property `readonly` when it is promoted in the constructor and never changed afterward.
- Do not use `abstract` classes unless unavoidable — prefer interfaces + composition.
- Do not use `static` methods unless the function is pure (no state, no I/O).

## Dependency Injection

- Use constructor injection only.
- Use `#[Autowire(param: 'kernel.debug')]` for environment flags.
- Use `#[Target('monolog.logger.{channel}')]` for named loggers.
- Use `#[Autowire(service: 'service.id')]` for services that cannot be autowired.
- Do not fetch from `$container` or use `ContainerAware`.

## Routing & Controllers

- Use the `#[Route]` attribute on the class (prefix) and on each action method.
- Return `$this->render('template.html.twig', $data)` — never use `#[Template]` (a SensioFrameworkExtraBundle legacy, removed in Symfony 7+).
- Route names follow the `{domain}_{subdomain}_{action}` (snake_case) pattern.
- Every state-changing action: use only POST/PUT/PATCH/DELETE — never GET.
- Apply CSRF protection with `#[IsCsrfTokenValid]` on every POST form submission.

## Messenger / CQRS

- Write operations → `MessageCommand` + `MessageCommandHandler`.
- Read operations → `MessageQuery` + `MessageQueryHandler`.
- Events (side effects) → `MessageEvent` + `MessageEventHandler`.
- Set the transport of a message class with `#[AsMessage('{transport}')]`.
- Register handlers with `#[AsMessageHandler]` on the handler class.
- Dispatch through `MessageBusInterface` — do not call the handler directly.
- Async messages must configure a retry policy and a dead-letter queue (failure transport) — use `retry_strategy` and `failure_transport` in `messenger.yaml`.
- Handlers follow the single-responsibility principle — one handler processes exactly one message type.

## Scheduler

@see .claude/rules/app-php-symfony-15-scheduler-rule.md — judgment criteria (SoT)

- Define recurring tasks under `app/src/Scheduler/{Domain}/` as a `ScheduleProviderInterface` + `#[AsSchedule]` class (`RecurringMessage`).
- The Scheduler dispatches a `MessageCommand` — it does not call a Service or Repository directly.
- A schedule definition holds only "when to trigger"; the domain execution guard is the `MessageCommandHandler`'s responsibility (calendar/timezone firing conditions can be expressed via a custom `TriggerInterface` wrapper).

## Workflow

@see .claude/rules/app-php-symfony-12-workflow-rule.md — judgment criteria (SoT)

- Entity state transitions are performed only via `WorkflowInterface::apply()`, and only inside a `MessageCommandHandler`.
- Transition guards are handled through Workflow guard events — not an `if/else` inside a Service.
- Do not set state properties directly in a Service or Controller.

## Mailer / Notifier / Translation

@see .claude/rules/app-php-symfony-13-mailer-notifier-rule.md · app-php-symfony-14-translation-rule.md — judgment criteria (SoT)

- Email uses `TemplatedEmail`; operator notifications go through the Notifier `admin_recipients` (no hardcoded recipients).
- User-facing strings are managed as catalog keys (`app.{locale}.yml`) — no hardcoding, default locale `ko` / fallback `en`.

## Logging

- Use a named channel (`monolog.logger.{module}`) — not the global `logger`.
- Guard every debug log: `if ($this->isDebug) { $this->logger->info(...); }`.
- Use a structured context array in log messages, not string interpolation.

## Pagination

- Always use Pagerfanta together with the Doctrine ORM adapter.
- Do not write manual `LIMIT`/`OFFSET` pagination in a Repository.
- Default page size: 20. Maximum: 100.

## API Platform

- Place resource classes under `app/src/ApiResource/` — do not use Entity classes directly.
- Use `#[ApiResource]` with an explicit `operations` array — do not rely on defaults.
- Use DTO-based input/output via the `input:`, `output:` resource settings.
- Apply rate limiting to every API endpoint with `symfony/rate-limiter`.
