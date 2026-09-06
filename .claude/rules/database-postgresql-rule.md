---
paths:
  - "app/src/Entity/**/*.php"
  - "app/src/EntityRepository/**/*.php"
  - "app/src/Repository/**/*.php"
---

# Database Rules

This rule is the judgment criteria (SoT) for all Doctrine Entity, Repository, and Migration files. The
EntityManager table, configuration YAML, type matrix, and code examples live in the docs.

@see .claude/docs/database-postgresql-docs.md — EntityManager reference, config, type matrix, examples
@see https://symfony.com/doc/current/doctrine.html — Doctrine with Symfony (official)

## Multiple EntityManagers

@see https://symfony.com/doc/current/doctrine/multiple_entity_managers.html

This project uses a **multi-database architecture** — each domain has its own PostgreSQL database with a dedicated Doctrine connection and EntityManager (see the EntityManager reference table in the docs).

- Never define an association (OneToMany, ManyToOne, etc.) between entities that belong to different EntityManagers — Doctrine does not support cross-manager associations.
- Do not use `ServiceEntityRepository` — it is always resolved through `ManagerRegistry` and can silently bind to the wrong EntityManager. Extend `Doctrine\ORM\EntityRepository` and inject the correct EntityManager explicitly with `#[Target]`.
- An entity must be mapped only inside the EntityManager that matches its namespace directory.

## Table Naming Conventions

- Table names are `snake_case` and reflect a compressed version of the namespace hierarchy: `{subdomain}_{entity_name}` (see the docs for worked examples).
- **Never** rely on Doctrine's auto-generated table name — always declare `#[ORM\Table(name: '...')]` explicitly.
- Do not use PostgreSQL reserved words (`user`, `group`, `order`, `type`, etc.) as table or column names.

## Entity Class Design

@see https://www.doctrine-project.org/projects/doctrine-orm/en/3.3/reference/basic-mapping.html

- Mark every concrete entity class `final` — entities are not designed for extension.
- Always declare `#[ORM\Entity(repositoryClass: XxxRepository::class)]` — never leave the repository class unspecified.
- Always declare `#[ORM\Table(name: '...')]` — never omit it.
- Add `#[ORM\HasLifecycleCallbacks]` to the class if it has any method using `#[ORM\PrePersist]` or `#[ORM\PreUpdate]`.
- Initialize only the primary-key field(s) in the constructor — do not set timestamps or nullable fields there.
- Do not use `#[ORM\GeneratedValue]` for provider data entities that use a natural string PK (market symbol, currency code, etc.).
- Use PHP 8.4 property hooks for one-line normalization at assignment time instead of a separate setter.
- If the natural PK spans multiple columns, declare multiple `#[ORM\Id]` attributes — do not add a surrogate `id` just to avoid a composite key.

## Timezone

@see https://www.php.net/manual/en/class.datetimeimmutable.php

- Every `\DateTimeImmutable` representing a Korean business time must be created with `new \DateTimeImmutable('now', new \DateTimeZone('Asia/Seoul'))`.
- **Never** use `new \DateTime()` — always use `new \DateTimeImmutable()`.
- **Never** create a Korean-time timestamp with `new \DateTimeImmutable()` without an explicit timezone.
- `createdAt` on domain entities: set it once in `#[ORM\PrePersist]`.
- `updatedAt` on provider data entities: call `setUpdatedAt()` explicitly in the batch import handler — `#[ORM\PreUpdate]` alone is not enough, because bulk imports bypass the UoW's change tracking.

## Column Mapping

@see https://www.doctrine-project.org/projects/doctrine-orm/en/3.3/reference/basic-mapping.html#doctrine-mapping-types

- Choose the Doctrine type per the type reference in the docs — use `decimal` (never `float`) for prices, `bigint`→`string`, and `json` (not `json_object`) for API payloads.
- Map PHP backed enums with `enumType:` — do not store enum values as raw strings on the entity class.
- API key columns holding secret values: declare them `type: 'text'`; perform encryption/decryption only in a `Service/{Provider}/ApiKeyService`, never in an entity or repository. Never store a plaintext key.

## Index Strategy

@see https://www.doctrine-project.org/projects/doctrine-orm/en/3.3/reference/attributes-reference.html

- Declare `#[ORM\Index]` explicitly on **every** foreign-key column — Doctrine ORM 3 does not generate these automatically.
- Use a composite index for filter combinations used together (e.g. `[status, createdAt]`, `[market, timestamp]`).
- Use a class-level `#[ORM\UniqueConstraint]` (named, manageable) rather than `unique: true` on an individual column.
- Add a `GIN` index to `json` columns queried with the `@>` operator — via native migration SQL, not a Doctrine attribute.
- Prefer a partial index (via a native SQL migration) for large tables filtered by a status enum.

## Lifecycle Callbacks

@see https://www.doctrine-project.org/projects/doctrine-orm/en/3.3/reference/events.html#lifecycle-callbacks

- The class-level `#[ORM\HasLifecycleCallbacks]` is **required** — without it, `#[ORM\PrePersist]`/`#[ORM\PreUpdate]` methods are silently ignored.
- `#[ORM\PrePersist]` runs once before the initial `INSERT` (set `createdAt`/`updatedAt`); `#[ORM\PreUpdate]` runs before each `UPDATE` (set `updatedAt` only).
- Do not call lifecycle callback methods directly from application code — the UoW calls them.

## Repository Rules

@see https://symfony.com/doc/current/doctrine.html#querying-for-objects-the-repository

- Extend `Doctrine\ORM\EntityRepository` — do **not** use `ServiceEntityRepository` (it cannot resolve the correct EntityManager in this multi-EM setup). Inject the correct EntityManager with `#[Target('...entity_manager')]`.
- Every finder method returning a collection must declare a PHPDoc `@return EntityClass[]`.
- Use `createQueryBuilder()` for every non-trivial query — never use `findBy()` with 3 or more conditions.
- Expose a `findByXxxQueryBuilder(): QueryBuilder` alongside `findByXxx(): array` so callers can append `setMaxResults()`/`orderBy()`/pagination without duplicating query logic.
- Prevent N+1: use `JOIN FETCH` (`->addSelect('r')` + `->leftJoin('e.relation', 'r')`) when the caller always accesses the relation.
- Use `getArrayResult()` when the caller only reads scalar values; use `getOneOrNullResult()` for a single optional result — never `getResult()[0] ?? null`.
- Use Pagerfanta (`BabDev\PagerfantaBundle`) with the Doctrine ORM adapter for all list queries — never manual `LIMIT`/`OFFSET`.

## Migration Workflow

@see https://symfony.com/doc/current/doctrine.html#migrations-creating-the-database-tables-schema

Always specify `--em=` and `--db=` on Doctrine commands (see the docs for the command reference).

- **Never modify** a migration file that has already been applied in any environment.
- Destructive changes require a **two-step migration** (add/backfill first, drop later after verification).
- **Never add** a `NOT NULL` column without a `DEFAULT` in the `up()` SQL — it fails on tables with existing rows.
- Always review the generated SQL before applying — `doctrine:migrations:diff` may emit DROP statements for unmanaged tables.
- Always run `doctrine:schema:validate` after applying migrations to confirm schema consistency.

## PostgreSQL-Specific Features

@see https://www.postgresql.org/docs/current/datatype-json.html

- Use `JSONB` (Doctrine `json` type) for queryable API payloads; add a `GIN` index via raw migration SQL for `@>` queries.
- Window functions in native SQL must go through a Repository method (`NativeQuery` + `ResultSetMapping`) — never inside a Service, never raw PDO.
- For long-running batch imports, PostgreSQL advisory locks (`pg_try_advisory_lock`) are an alternative to `symfony/lock` — do not rely on application-level timeouts for batch coordination.
