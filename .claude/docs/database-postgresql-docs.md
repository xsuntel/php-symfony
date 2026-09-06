# PostgreSQL / Doctrine — Technical Reference

This document holds the **detailed reference and code examples** for Doctrine Entity, Repository, and
Migration work against PostgreSQL in this project's multi-database architecture. The enforced judgment
criteria (SoT) live in the rule file — if this document conflicts with the rule, the rule wins.

@see .claude/rules/database-postgresql-rule.md — Database judgment criteria (SoT)
@see https://symfony.com/doc/current/doctrine.html — Doctrine with Symfony (official)
@see https://www.doctrine-project.org/projects/doctrine-orm/en/3.3/reference/basic-mapping.html — Doctrine ORM mapping

---

## 1. Multiple EntityManagers

@see https://symfony.com/doc/current/doctrine/multiple_entity_managers.html

This project uses a **multi-database architecture** — each domain has its own PostgreSQL database with a dedicated Doctrine connection and EntityManager. All connections are declared in `app/config/packages/doctrine.yaml`.

| EntityManager name | Database name | Domain |
|--------------------|---------------|--------|
| `abstract` | `abstract` | Abstract / Users |
| `company` | `company` | Company |
| `partners` | `partners` | Partners |
| `products` | `products` | Products |
| `providers_finance_app_agencies_ecos` | `providers_finance_app_agencies_ecos` | Finance / ECOS |
| `providers_finance_app_agencies_kosis` | `providers_finance_app_agencies_kosis` | Finance / KOSIS |
| `providers_finance_app_digitalasset_upbit` | `providers_finance_app_digitalasset_upbit` | Finance / UPbit |
| `providers_finance_app_digitalasset_upbit_domestic` | `providers_finance_app_digitalasset_upbit_domestic` | Finance / UPbit Domestic |
| `providers_finance_app_securities_koreainvestment` | `providers_finance_app_securities_koreainvestment` | Finance / KoreaInvestment |
| `providers_finance_app_securities_koreainvestment_domestic` | `providers_finance_app_securities_koreainvestment_domestic` | Finance / KoreaInvestment Domestic |

```yaml
# config/packages/doctrine.yaml (excerpt)
doctrine:
  dbal:
    default_connection: abstract
    connections:
      abstract:
        driver: pdo_pgsql
        dbname: abstract
        mapping_types: { enum: string }
  orm:
    default_entity_manager: abstract
    entity_managers:
      abstract:
        connection: abstract
        mappings:
          App\Entity\Abstract:
            type: attribute
            dir: '%kernel.project_dir%/src/Entity/Abstract'
            prefix: App\Entity\Abstract
            alias: Abstract
```

---

## 2. Table Naming Conventions

- Table names are `snake_case` and reflect a compressed version of the namespace hierarchy.
- Pattern: `{subdomain}_{entity_name}` — omit the provider path prefix shared by all tables in the same database.
  - `App\Entity\Providers\Finance\App\DigitalAsset\UPbit\Domestic\Coin\API\REST\Exchange\Service\StatusWallet` → `api_rest_exchange_service_status_wallet`
  - `App\Entity\Providers\Finance\App\DigitalAsset\UPbit\Domestic\Coin\API\REST\Quotation\Orderbook\Orderbook` → `api_rest_quotation_orderbook_orderbook`
  - `App\Entity\Abstract\Users` → `users`
- Abstract/shared entities use the `abstract_` prefix: `abstract_users`, `abstract_connect_*`.

---

## 3. Entity Class Design

@see https://www.doctrine-project.org/projects/doctrine-orm/en/3.3/reference/basic-mapping.html

### Constructor Pattern

```php
#[ORM\Entity(repositoryClass: OrderbookRepository::class)]
#[ORM\Table(name: 'api_rest_quotation_orderbook_orderbook')]
#[ORM\HasLifecycleCallbacks]
final class Orderbook
{
    #[ORM\Id]
    #[ORM\Column(type: 'string', nullable: false)]
    private string $market;

    public function __construct(string $market)
    {
        $this->market = $market;
    }
}
```

### PHP 8.4 Property Hooks

Use PHP 8.4 property hooks for inline data normalization at assignment time — do not write a separate setter method when the transformation fits on one line:

```php
#[ORM\Column(nullable: false)]
private ?string $total_ask_size = null {
    set(string|float|null $value) {
        $this->total_ask_size = rtrim(rtrim((string) $value, '0'), '.');
    }
}
```

### Composite Primary Keys

If the natural PK spans multiple columns, declare multiple `#[ORM\Id]` attributes — do not introduce a surrogate `id` column just to avoid a composite key:

```php
#[ORM\Id]
#[ORM\Column(nullable: false)]
private string $currency;

#[ORM\Id]
#[ORM\Column(nullable: false)]
private string $net_type;
```

---

## 4. Timezone

@see https://www.php.net/manual/en/class.datetimeimmutable.php

```php
#[ORM\PrePersist]
public function onPrePersist(): void
{
    $now = new \DateTimeImmutable('now', new \DateTimeZone('Asia/Seoul'));
    $this->createdAt = $now;
    $this->updatedAt = $now;
}

#[ORM\PreUpdate]
public function onPreUpdate(): void
{
    $this->updatedAt = new \DateTimeImmutable('now', new \DateTimeZone('Asia/Seoul'));
}
```

---

## 5. Column Mapping

@see https://www.doctrine-project.org/projects/doctrine-orm/en/3.3/reference/basic-mapping.html#doctrine-mapping-types

### Type Reference

| Use case | Doctrine type | PHP type | Notes |
|----------|--------------|----------|-------|
| Short text | `string` | `string` | Always specify `length:` |
| Long text / keys | `text` | `string` | No length limit |
| API response payload | `json` | `array` | Maps to PostgreSQL `jsonb` |
| Price / decimal | `decimal` | `string` | Always specify `precision:`, `scale:` — no `float` |
| Timestamp | `datetime_immutable` | `\DateTimeImmutable` | Specify the column type explicitly |
| Boolean flag | `boolean` | `bool` | |
| Large integer | `bigint` | `string` | On 32-bit systems PHP does not support 64-bit int |
| Auto-increment PK | `integer` + `#[ORM\GeneratedValue]` | `?int` | Domain entities only |
| Public surrogate PK | `uuid` | `Symfony\Component\Uid\Uuid` | Provider API entities may use a string PK instead |
| Enum column | use `enumType:` | Backed enum | See below |

### Enum Columns

Map PHP backed enums with the `enumType:` parameter — do not store enum values as raw strings on the entity class:

```php
#[ORM\Column(enumType: TwoFactorTypeEnum::class)]
private TwoFactorTypeEnum $twoFactorType;
```

PostgreSQL's native `ENUM` type is mapped to `string` via `doctrine.yaml`:

```yaml
doctrine:
  dbal:
    connections:
      abstract:
        mapping_types: { enum: string }
```

### JSON / JSONB Columns

Use `type: 'json'`, not `type: 'json_object'`, for API response payloads:

```php
#[ORM\Column(type: 'json', nullable: false)]
private ?array $orderbook_units = null;
```

---

## 6. Index Strategy

@see https://www.doctrine-project.org/projects/doctrine-orm/en/3.3/reference/attributes-reference.html

```php
#[ORM\Entity(repositoryClass: ApiKeysRepository::class)]
#[ORM\Table(name: 'upbit_account_api_keys')]
#[ORM\UniqueConstraint(name: 'uniq_api_key_user', columns: ['user_id', 'label'])]
#[UniqueEntity(fields: ['userId', 'label'])]
final class ApiKeys
{
    #[ORM\Index(columns: ['user_id'], name: 'idx_api_keys_user')]
    // ...
}
```

---

## 7. Lifecycle Callbacks

@see https://www.doctrine-project.org/projects/doctrine-orm/en/3.3/reference/events.html#lifecycle-callbacks

For provider data entities that do not track `createdAt`, it is fine to combine both `#[ORM\PrePersist]` and `#[ORM\PreUpdate]` on one method:

```php
#[ORM\PrePersist]
#[ORM\PreUpdate]
public function onPrePersistOrUpdate(): void
{
    $this->updatedAt = new \DateTimeImmutable('now', new \DateTimeZone('Asia/Seoul'));
}
```

---

## 8. Repository

@see https://symfony.com/doc/current/doctrine.html#querying-for-objects-the-repository

### EntityManager Injection

Extend `Doctrine\ORM\EntityRepository`, inject the correct EntityManager with `#[Target('...entity_manager')]`, and call `parent::__construct()`:

```php
use Doctrine\ORM\EntityManagerInterface;
use Doctrine\ORM\EntityRepository;
use Symfony\Component\DependencyInjection\Attribute\Target;

class MarketAllRepository extends EntityRepository
{
    public function __construct(
        #[Target('providers_finance_app_digitalasset_upbit_domestic.entity_manager')]
        EntityManagerInterface $entityManager,
    ) {
        parent::__construct($entityManager, $entityManager->getClassMetadata(MarketAll::class));
    }
}
```

### QueryBuilder Extraction Pattern

Expose a `findByXxxQueryBuilder(): QueryBuilder` method alongside `findByXxx(): array` so callers can append `setMaxResults()`, `orderBy()`, and pagination without duplicating the query logic:

```php
public function findBySearch(?string $query, ?int $limit = null): array
{
    $qb = $this->findBySearchQueryBuilder($query);
    if ($limit) {
        $qb->setMaxResults($limit);
    }
    return $qb->getQuery()->getArrayResult();
}

public function findBySearchQueryBuilder(?string $query): QueryBuilder
{
    $qb = $this->createQueryBuilder('v');
    if ($query) {
        $qb->andWhere('v.korean_name LIKE :query')
            ->setParameter('query', '%'.$query.'%');
    }
    return $qb;
}
```

---

## 9. Migration Workflow

@see https://symfony.com/doc/current/doctrine.html#migrations-creating-the-database-tables-schema
@see https://symfony.com/doc/current/doctrine/multiple_entity_managers.html

Since this project uses multiple EntityManagers, always specify `--em=` (entity manager name) and `--db=` (connection name) when running Doctrine commands:

```bash
# Generate a diff migration for a specific entity manager
cd app && php bin/console doctrine:migrations:diff --em=providers_finance_app_digitalasset_upbit_domestic

# Apply migrations to a specific entity manager
cd app && php bin/console doctrine:migrations:migrate --em=providers_finance_app_digitalasset_upbit_domestic

# Validate the schema of a specific entity manager
cd app && php bin/console doctrine:schema:validate --em=abstract

# Create the database for a specific connection
cd app && php bin/console doctrine:database:create --connection=company
```

A destructive change (dropping a column, changing the type of a production column) requires a **two-step migration**:
1. Add the new column / backfill data / mark the existing column nullable.
2. Drop the existing column in a separate migration after the backfill is verified.

---

## 10. PostgreSQL-Specific Features

@see https://www.postgresql.org/docs/current/datatype-json.html

### JSONB Queries

Use `JSONB` (via the Doctrine `json` type) for API response payloads that need to be queried. Doctrine maps `json` columns to PostgreSQL `jsonb` automatically when the driver is `pdo_pgsql`.

Add a `GIN` index to `jsonb` columns queried with the `@>` operator — this must be done with raw SQL in a migration:

```sql
CREATE INDEX CONCURRENTLY idx_orderbook_units_gin ON api_rest_quotation_orderbook_orderbook USING gin (orderbook_units);
```

### Window Functions

Window functions in native SQL queries must go through a Repository method — never use them in a Service:

```php
use Doctrine\ORM\Query\ResultSetMapping;

public function findRankedByVolume(): array
{
    $rsm = new ResultSetMapping();
    $rsm->addScalarResult('market', 'market');
    $rsm->addScalarResult('acc_trade_volume', 'volume');
    $rsm->addScalarResult('rnk', 'rank');

    $sql = '
        SELECT market, acc_trade_volume,
               RANK() OVER (ORDER BY acc_trade_volume DESC) AS rnk
        FROM api_rest_quotation_ticker_ticker
    ';

    return $this->getEntityManager()
        ->createNativeQuery($sql, $rsm)
        ->getArrayResult();
}
```

### Advisory Locks

For long-running batch imports, you can use PostgreSQL advisory locks as an alternative to `symfony/lock`. Use `pg_try_advisory_lock($key)` via a native query — do not rely on application-level timeouts for batch coordination.
