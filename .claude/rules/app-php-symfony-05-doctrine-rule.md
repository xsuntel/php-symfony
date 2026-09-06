---
paths:
  - "app/src/Entity/**/*.php"
  - "app/src/EntityRepository/**/*.php"
  - "app/src/Repository/**/*.php"
---

# Doctrine / Database Rule

@see https://symfony.com/doc/current/doctrine.html

## Entity Mapping

- Use only PHP Attributes (`#[ORM\Entity]`, `#[ORM\Column]`, etc.).
- Never use XML or YAML mapping files.
- Always declare `#[ORM\Table(name: '...')]` explicitly — do not rely on the auto-generated table name.
- Mark entity classes `final` unless they are an abstract base entity.

```php
#[ORM\Entity(repositoryClass: PostRepository::class)]
#[ORM\Table(name: 'post')]
#[ORM\HasLifecycleCallbacks]
final class Post
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    private ?int $id = null;

    #[ORM\Column(length: 255)]
    private string $title;

    #[ORM\Column]
    private \DateTimeImmutable $createdAt;

    public const int ITEMS_PER_PAGE = 20;  // domain constants belong on the entity

    #[ORM\PrePersist]
    public function initCreatedAt(): void
    {
        $this->createdAt = new \DateTimeImmutable('now', new \DateTimeZone('Asia/Seoul'));
    }
}
```

## Repository

- Encapsulate every business query in a Repository class — do not use DQL or QueryBuilder in a Controller or Service.
- Extend `Doctrine\ORM\Repository` (do not use `ServiceEntityRepository` unless DI is needed).
- Use `createQueryBuilder()` for queries with two or more filter conditions — do not use `findBy()` for complex conditions.

```php
final class PostRepository extends Repository
{
    /** @return Post[] */
    public function findPublishedOrderedByDate(): array
    {
        return $this->createQueryBuilder('p')
            ->where('p.publishedAt IS NOT NULL')
            ->orderBy('p.publishedAt', 'DESC')
            ->getQuery()
            ->getResult();
    }
}
```

## Repository Query Patterns

- Simple lookups: use `findBy()` and `findOneBy()`.
- Complex queries: use `QueryBuilder` — do not write DQL strings by hand.
- Performance-critical queries: use Native SQL + `ResultSetMapping`.
- Pagination: use Pagerfanta with the Doctrine ORM adapter (no manual `LIMIT`/`OFFSET`).

```php
// Repository method naming conventions
public function findPublishedOrderedByDate(): array {}      // returns a collection
public function findOneBySlugOrFail(string $slug): Post {}  // single result, throws on miss
```

## Preventing N+1 Queries

Always use `JOIN FETCH` when the caller will access the relation:

```php
$this->createQueryBuilder('p')
    ->addSelect('a')
    ->leftJoin('p.author', 'a')
    ->getQuery()
    ->getResult();
```

Declare `#[ORM\Index]` on every foreign-key column — Doctrine ORM 3 does not add it automatically.

## Association Configuration

- `fetch: 'EXTRA_LAZY'` — prevents loading the entire collection when only a count is needed.
- `cascade: ['persist', 'remove']` — use explicitly and carefully; do not cascade by default.
- A bidirectional relation must always declare both `mappedBy` and `inversedBy`.
- A `OneToMany` collection must be initialized as an `ArrayCollection` in the constructor.

```php
#[ORM\OneToMany(targetEntity: Comment::class, mappedBy: 'post',
    fetch: 'EXTRA_LAZY', cascade: ['persist'])]
private Collection $comments;

public function __construct()
{
    $this->comments = new ArrayCollection();
}
```

@see https://symfony.com/doc/current/doctrine.html#relationships-and-associations

## Migration Workflow

```bash
# After creating or modifying an Entity:
cd app && php bin/console doctrine:migrations:diff

# Review the generated file in app/migrations/ before applying
cd app && php bin/console doctrine:migrations:migrate

# Validate schema consistency
cd app && php bin/console doctrine:schema:validate
```

- Never modify a migration that has already been applied in any environment.
- Do not add `NOT NULL` without a `DEFAULT` in the same migration — it breaks existing rows.
- A destructive change (dropping a column, changing the type of a production column) requires a two-step migration: (1) backfill / mark deprecated, (2) drop.

## Bulk Data Processing

Use `toIterable()` (Doctrine ORM 3) for large result sets to avoid loading all data into memory:

```php
foreach ($this->createQueryBuilder('p')->getQuery()->toIterable() as $post) {
    // process $post
    $this->em->detach($post);
}
```

@see https://symfony.com/doc/current/best_practices.html#use-attributes-to-define-the-doctrine-entity-mapping
