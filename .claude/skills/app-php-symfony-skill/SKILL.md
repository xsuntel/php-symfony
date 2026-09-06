---
name: app-php-symfony-skill
description: Use in this PHP 8.4 / Symfony 8 project to analyze the codebase structure, guide the use of external libraries, or review code changes. Covers the Symfony app layout, the multi-EntityManager topology, Messenger message flow, Composer/importmap package management, and the PR review checklist. Triggered by architecture documentation, domain-boundary mapping, dependency mapping, composer require, importmap:require, library compatibility checks, code review, bug identification, and Pull Request improvement requests.
---

# PHP / Symfony Skill

A unified entry point covering codebase analysis · library usage guidance · code review.
Apply the relevant part depending on the nature of the request.

| Request type                                        | Section to apply             |
| --------------------------------------------------- | ---------------------------- |
| Structure analysis, architecture docs, domain-boundary mapping | Part 1 — Codebase Analysis   |
| Library install/config/usage, package recommendation | Part 2 — Library Usage Guide |
| Reviewing changes, identifying bugs, PR improvement suggestions | Part 3 — Code Review         |

## Information Source (Single Source: the rule files)

The coding standards · architecture · per-layer detailed criteria are **all owned by the rule files as the single source of truth (SoT)**.
This skill does not restate the rules; it provides only the analysis methodology, operational commands, and output format.

@see .claude/rules/app-php-symfony-00-overview-rule.md ~ app-php-symfony-15-scheduler-rule.md — the full PHP/Symfony criteria (SoT)
@see .claude/rules/abstract-structure-rule.md — directory structure · architecture guide
@see CLAUDE.md — stack · out-of-scope policy

Use only project files (source · config · migrations · `composer.json`/`package.json`) as evidence.
If not confirmed, state "This information is not confirmed in the project files." and do not guess versions.

---

# Part 1 — Codebase Analysis

Map top-down. Do not assume a directory exists; confirm it with Glob.

1. **Repository layout** → start by reading `CLAUDE.md` · `abstract-structure-rule.md` (root wrapper + `app/` Symfony root).
2. **Application structure** → map `app/src/` by namespace segment (Controller/Entity/Repository/Service/MessageCommand/MessageQuery/MessageHandler/MessageEvent/EventSubscriber/Scheduler/Form/Twig/Security/Enum).
3. **EntityManager topology** → read `app/config/packages/doctrine.yaml` to confirm the EM ↔ DB ↔ domain mapping (the SoT is the `## Multiple EntityManagers` table in rule `database-postgresql-rule.md`). No associations across managers.
4. **Message flow** → confirm the transport with `#[AsMessage('{transport}')]` + `messenger.yaml`:

```text
Scheduler(#[AsPeriodicTask]) → MessageBus → MessageCommand
  → MessageCommandHandler(RabbitMQ) → HttpClient/persistence(Entity json) → MessageEvent
    → EventSubscriber(follow-up processing/Notifier)
```

The read path is `MessageQuery` + `MessageQueryHandler` (synchronous). RabbitMQ = async, Redis transport = synchronous in-process.

5. **Config file order** → `doctrine.yaml` → `messenger.yaml` → `cache.yaml` (+ per-environment) → `framework.yaml` (scoped HTTP client) → `services.yaml`.

## Output Format

- **Architecture summary**: describe per domain in the order `EntityManager`/`Database` → Entities → Message Flow → External API → Cache.
- **Dependency map**: a directional list of `{Class} depends on → {Dep} (injection method)`. Do not generate UML unless requested.
- **Gap report**: report undiscovered classes · unmapped EMs · unconfigured transports at the end as a `## Gaps Found` checklist.

---

# Part 2 — Library Usage Guide

## Check Before Recommending

1. Already installed? → check `composer.json`/`package.json` (and `.lock`).
2. PHP 8.4 / Symfony 8 compatible? → check the package constraints.
3. Conflicts with project rules? → cross-check `.claude/rules/` and the CLAUDE.md out-of-scope policy (no Laravel/Vue/React).
4. Already abstracted? → e.g. Redis is accessed only via a Symfony Cache pool.

If any of these fail, report that fact before presenting an example.

## Version Check · Install (Bash)

```bash
# Version: lock → json order. Do not assert a version without confirming
grep '"vendor/package"' app/composer.lock | head -1
grep '"vendor/package"' app/composer.json

# Install (prod / dev)
cd app && composer require vendor/package
cd app && composer require --dev vendor/package
grep 'BundleClass' app/config/bundles.php    # confirm auto-registration

# JS uses AssetMapper, not npm
cd app && php bin/console importmap:require package-name
grep 'package-name' app/importmap.php
```

## Prohibited · Replacement Libraries (Rule-based)

| Prohibited                                     | Replacement / rule                                                      |
| ---------------------------------------------- | ----------------------------------------------------------------------- |
| `guzzlehttp/guzzle`, cURL, `file_get_contents` | `HttpClientInterface` (`rules/app-php-symfony-04-service-rule.md`)      |
| `ServiceEntityRepository`                      | Extend `EntityRepository` (`rules/database-postgresql-rule.md`)         |
| Direct `\Redis` calls                          | `#[Target('cache_pool_{domain}')]` (`rules/cache-redis-rule.md`)        |
| `react`/`vue`/Laravel packages                 | Out of scope (`CLAUDE.md`)                                              |
| `knp-paginator`, manual LIMIT/OFFSET           | `babdev/pagerfanta-bundle`                                              |

Authentication uses `LexikJWTAuthenticationBundle` + `scheb/2fa-*`. When blocking, cite the underlying rule file.

---

# Part 3 — Code Review

## Procedure

```bash
git diff main...HEAD --name-only   # changed files
git diff main...HEAD               # full diff
```

Group the changed files by layer, and **apply the detailed judgment criteria for each layer based on the rule files below** —
the skill does not restate the criteria.

| Layer                       | Judgment criteria (SoT)                                           |
| --------------------------- | ----------------------------------------------------------------- |
| Architecture · messaging · scheduler | `rules/app-php-symfony-01-architecture-rule.md`          |
| Controller · service · form | `app-php-symfony-03-controller-rule.md`, `app-php-symfony-04-service-rule.md`, `app-php-symfony-06-form-rule.md`  |
| Doctrine / DB               | `rules/database-postgresql-rule.md`, `app-php-symfony-05-doctrine-rule.md`        |
| External API                | `rules/api-platform-rule.md` (per-provider rules: planned)     |
| Cache / Redis               | `rules/cache-redis-rule.md`                                       |
| Security                    | `app-php-symfony-08-security-rule.md`                                             |
| Performance                 | `app-php-symfony-11-performance-rule.md`                                          |
| Template · frontend         | `app-php-symfony-07-template-rule.md`, `app-php-symfony-10-frontend-rule.md`                      |

## Cross-cutting Core Checks (Fast, Rule-violation Only)

- Is `Asia/Seoul` specified on a `\DateTimeImmutable` for Korean business time
- Is a decrypted API key kept out of the logs (masked prefix only)
- Is fetch→persist (raw JSON)→MessageEvent separated, with a rate-limit Lock guard
- Is the correct EM/cache pool/HTTP client injected via `#[Target]`
- Does the user-input DTO have a Validator, and the state-changing form a CSRF

## Severity · Output

| Severity     | When to use                                    |
| ------------ | ---------------------------------------------- |
| `[MUST]`     | Bug · security · rule violation · data loss (merge-blocking) |
| `[SHOULD]`   | Performance · maintainability · convention deviation |
| `[CONSIDER]` | Optional improvement · style                   |

Output order: **Summary → [MUST] → [SHOULD] → [CONSIDER] → positive feedback (at least 1, cite file:line)**.
