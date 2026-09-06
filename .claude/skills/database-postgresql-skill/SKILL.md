---
name: database-postgresql-skill
description: 'Use when designing Doctrine entities, writing repositories, running migrations, or applying PostgreSQL-specific features in this multi-EntityManager Symfony project. Triggered by questions about #[ORM\, EntityManager, EntityRepository, QueryBuilder, createQueryBuilder, getResult, getArrayResult, doctrine:migrations, JSONB, window functions, #[ORM\PrePersist], or Doctrine mapping.'
---

# PostgreSQL / Doctrine Skill

This is the entry point for implementing and reviewing this project's Doctrine ORM / PostgreSQL work.

## Information Source (single source of truth: the rule file)

**All detailed criteria** — the EntityManager list, table naming, entity design, column type table,
indexes, lifecycle callbacks, Repository rules, migration workflow, JSONB/Window/Advisory Lock — are
in the rule file. This skill does not duplicate the rules; it only provides the work procedure and
verification commands.

@see .claude/rules/database-postgresql-rule.md — full entity/Repository/migration/PostgreSQL-feature standards (SoT)
@see https://symfony.com/doc/current/doctrine.html

Source of truth (configuration): `app/config/packages/doctrine.yaml`

## Work Procedure

1. **Select the EM** → confirm the EntityManager matching the domain in the rule's `## Multiple EntityManagers` table. No cross-manager associations.
2. **Design the entity** → `final` + `#[ORM\Entity(repositoryClass:)]` + `#[ORM\Table(name:)]` + (when using lifecycle) `#[ORM\HasLifecycleCallbacks]`. See the rule's `## Entity Class Design` and `## Column Mapping`.
3. **Repository** → extend `EntityRepository` + inject with `#[Target('...entity_manager')]` (no `ServiceEntityRepository`). See the rule's `## Repository Rules` for the QueryBuilder extraction pattern and N+1 prevention.
4. **Migrations** → diff/migrate/validate per EM with the commands below.

## Migrations & Verification (Bash)

Since this is multi-EM, always specify `--em=` (entity manager) / `--connection=`.

```bash
# Generate a diff (always review the generated SQL before applying — beware of DROP on unmanaged tables)
cd app && php bin/console doctrine:migrations:diff --em=<EM_NAME>

# Apply
cd app && php bin/console doctrine:migrations:migrate --em=<EM_NAME>

# Validate schema consistency (required after applying)
cd app && php bin/console doctrine:schema:validate --em=<EM_NAME>

# Create the DB for a new connection
cd app && php bin/console doctrine:database:create --connection=<CONNECTION>
```

## Checklist (common to implementation & review)

- [ ] Did you inject the EntityManager matching the domain (no cross-manager associations)?
- [ ] Is it `EntityRepository` extension + `#[Target]` injection (not `ServiceEntityRepository`)?
- [ ] Is it a `final` entity + explicit `#[ORM\Table(name:)]` + specified repositoryClass?
- [ ] If it has lifecycle methods, is `#[ORM\HasLifecycleCallbacks]` present?
- [ ] Is the timestamp `new \DateTimeImmutable('now', new \DateTimeZone('Asia/Seoul'))`?
- [ ] Did you map price/decimal as `decimal` (string) (no `float`)?
- [ ] Did you declare `#[ORM\Index]` on FK columns?
- [ ] Does a collection finder have a `@return EntityClass[]` PHPDoc?
- [ ] Did you avoid modifying an already-applied migration, and is there a `DEFAULT` when adding `NOT NULL`?
- [ ] Did you delegate window functions to a Repository (`NativeQuery`+`ResultSetMapping`)?

When a review is requested, report severity as MUST (critical) / SHOULD (recommended) / CONSIDER (optional).
