# API Platform (Symfony) Integration Guide

This document describes the procedure for **exposing new REST resources via API Platform** in
this project. The single source of truth (SoT) for decisions is
`.claude/rules/api-platform-rule.md`; this document covers the step-by-step procedure for
actually implementing those rules.

@see <https://api-platform.com/docs/symfony/> — API Platform with Symfony (official)
@see .claude/rules/api-platform-rule.md — API Platform rules (SoT)

## Project Standard Layout (implementation convention)

> This repo is an infrastructure wrapper, and `app/` is populated separately. The following is the
> **convention to follow when implementing**, not currently verified measured values — confirm the
> actual values in the configuration files after implementing `app/`.

| Item | Value |
| --- | --- |
| Packages | `api-platform/symfony`, `api-platform/doctrine-orm` (4.x) |
| Route prefix | `/api` (`config/routes/api_platform.yaml`) |
| Global config | `config/packages/api_platform.yaml` — `title`, `version`, `defaults.stateless: true` |
| Resource location | `app/src/ApiResource/` (`App\ApiResource\`) |
| State classes | `app/src/State/` (`App\State\`) |
| Tests | `app/tests/` Functional (`ApiTestCase`) |

## Core Concepts

API Platform reads the **resource classes** declared with `#[ApiResource]` and automatically
generates REST (and JSON-LD/Hydra, OpenAPI) endpoints. Data retrieval/persistence is handled by
**State Providers/Processors**, input/output field exposure by **serialization groups**, and input
validation by the **Symfony Validator**. Domain business logic still lives in the `Service` layer,
and the Provider/Processor is the glue layer between them.

## Resource Addition Procedure

### 1) Declare the resource DTO

Create a resource class in `app/src/ApiResource/` and specify the operations to expose. Go through
a DTO rather than exposing the Doctrine Entity directly.

```php
// app/src/ApiResource/Company/BookResource.php
namespace App\ApiResource\Company;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Get;
use ApiPlatform\Metadata\GetCollection;
use ApiPlatform\Metadata\Post;
use Symfony\Component\Serializer\Attribute\Groups;
use Symfony\Component\Validator\Constraints as Assert;

#[ApiResource(
    operations: [new GetCollection(), new Get(), new Post()],
    normalizationContext: ['groups' => ['book:read']],
    denormalizationContext: ['groups' => ['book:write']],
)]
final class BookResource
{
    #[Groups(['book:read'])]
    public ?int $id = null;

    #[Assert\NotBlank]
    #[Groups(['book:read', 'book:write'])]
    public string $title = '';
}
```

### 2) Design the serialization groups

Separate read (`{resource}:read`) and write (`{resource}:write`) groups. Make sensitive/server-computed
fields read-only, and exclude from the groups any field the server must not accept. Relations are
exposed as IRIs by default; include a relation property in a read group only when embedding is required.

### 3) Wire the State Provider / Processor

Implement `ProviderInterface` for reads and `ProcessorInterface` for writes, and wire them to the
operation. If the Doctrine default provider/processor is sufficient, do not create a custom one.

```php
// app/src/State/Company/BookProcessor.php
namespace App\State\Company;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProcessorInterface;

final readonly class BookProcessor implements ProcessorInterface
{
    public function __construct(private BookService $bookService) {}

    public function process(mixed $data, Operation $operation, array $uriVariables = [], array $context = []): mixed
    {
        // DTO → domain delegation (Service) → return the saved result as a DTO
        return $this->bookService->create($data);
    }
}
```

Connect it to the operation:

```php
#[Post(processor: BookProcessor::class)]
```

Do not hand-reimplement the save/delete itself; decorate the Doctrine default Processor — inject it
by its exact service ID: `#[Autowire(service: 'api_platform.doctrine.orm.state.persist_processor')]`
(save), `'api_platform.doctrine.orm.state.remove_processor'` (delete, branch on
`DeleteOperationInterface`). See the `## State Provider / Processor` section of the rules for the
detailed pattern.

### 4) Validation

Declare input constraints with `#[Assert\...]`. API Platform automatically serializes failures as
RFC 7807/Hydra errors (422 + `violations`) — do not build a custom error response. When different
constraints are needed per operation, specify validation groups with
`validationContext: ['groups' => ['Default', 'postValidation']]` (use `GroupSequence` for sequential
validation). See the `## Validation › Per-operation validation groups` section of the rules.

### 5) Security & rate limiting

Control access with an operation `security:` expression (or a Voter). The API uses `stateless: true`
token authentication, so it is exempt from CSRF. Apply `symfony/rate-limiter` to public endpoints.

```php
#[Get(security: "is_granted('ROLE_USER')")]
#[Post(security: "is_granted('ROLE_ADMIN')")]
```

### 6) Testing

Verify operations with `ApiTestCase`-based Functional tests.

```php
// app/tests/Functional/ApiResource/Company/BookResourceTest.php
use ApiPlatform\Symfony\Bundle\Test\ApiTestCase;

final class BookResourceTest extends ApiTestCase
{
    public function testCreateBook(): void
    {
        static::createClient()->request('POST', '/api/books', ['json' => [
            'title' => 'The Handmaid\'s Tale',
        ]]);

        $this->assertResponseStatusCodeSame(201);
        $this->assertJsonContains(['title' => 'The Handmaid\'s Tale']);
        $this->assertMatchesResourceItemJsonSchema(BookResource::class);
    }
}
```

### 7) Filters & pagination

When a collection needs search/sort/pagination, declare it with **parameter-based filters
(`parameters:` + `#[QueryParameter]`)** and pagination options — do not parse query parameters
directly in the Provider or hand-assemble `LIMIT/OFFSET`. API Platform 4.x recommends this approach,
and the legacy `#[ApiFilter]` is used only as a fallback for existing-code compatibility.

```php
use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\GetCollection;
use ApiPlatform\Metadata\QueryParameter;
use ApiPlatform\Doctrine\Orm\Filter\PartialSearchFilter;
use ApiPlatform\Doctrine\Orm\Filter\SortFilter;

#[ApiResource(
    paginationItemsPerPage: 20,            // see rules for the upper bound (paginationMaximumItemsPerPage) and client-adjust options
    operations: [
        new GetCollection(parameters: [
            'title' => new QueryParameter(filter: new PartialSearchFilter()),        // ?title=han
            'order' => new QueryParameter(filter: new SortFilter(), property: 'createdAt'), // ?order=desc
        ]),
    ],
)]
final class BookResource { /* ... */ }
```

See the `## Pagination & Filters` section of the rules for the per-type filter list
(`ExactFilter`/`PartialSearchFilter`/`ComparisonFilter`/`SortFilter`/`IriFilter`), the legacy
equivalent mapping, and the pagination option keys.

### 8) Error handling

API Platform automatically serializes errors as RFC 7807/Hydra — do not build a custom error
response. Validation failures are 422. To map a domain exception to a status code, use operation/resource
`exceptionToStatus` (note the global one is not merged with the defaults), and create a custom error
resource with `#[ErrorResource]`. See the `## Error Handling` section of the rules.

### 9) OpenAPI documentation

OpenAPI 3.1 + JSON-LD/Hydra + Swagger UI are generated automatically. Fine-tune with `#[ApiProperty]`
and operation `openapi:`/`openapiContext`; expose computed fields via a read group + `#[SerializedName]`;
and post-process globally by decorating `OpenApiFactoryInterface`. See the
`## OpenAPI Documentation Customization` section of the rules.

```bash
# Inspect/export the generated spec
cd app && php bin/console debug:api-resource App\\ApiResource\\Company\\BookResource
cd app && php bin/console api:openapi:export --yaml
```

### 10) Asynchronous processing (Messenger, optional)

Imperative work that needs no synchronous response is dispatched to the Messenger bus via operation
`messenger:` instead of a State Processor — `messenger: true` (resource as message) or
`messenger: 'input'` (input DTO as message), usually with `output: false` + `status: 202`. Register the
handler with `#[AsMessageHandler]` and delegate domain logic to a `Service`. The project standard async
transport is RabbitMQ. See the `## Messenger Integration` section of the rules.

```php
#[Post(uriTemplate: '/users/reset-password', messenger: 'input',
    input: ResetPasswordRequest::class, output: false, status: 202)]
```

### 11) Custom operations (when needed)

Express non-CRUD behavior first with a custom operation + State. When Symfony-specific features are
strictly required, connect them only via operation `controller:` + `#[AsController]` (not a raw route),
with the `read: false`/`deserialize: false` options, and use `PlaceholderAction` for an exposure with no
logic. See the `## Operations › Custom Operations & Controllers` section of the rules.

## Processing Flow Summary

```text
HTTP request (/api/...) → API Platform routing → operation selection
   → (read)  Read: State Provider.provide()
   → (write) Deserialize(denormalizationContext) → access control(security) → Validator(#[Assert])
             → Write: State Processor.process()  →  Service(domain logic)  →  persistence
   → Serialize(normalizationContext) → JSON-LD/JSON response (errors as RFC 7807/Hydra)
```

## Checklist

- [ ] Resource declared as a DTO in `app/src/ApiResource/` (no direct Entity exposure)
- [ ] Operations listed explicitly (no reliance on the default set)
- [ ] `{resource}:read` / `{resource}:write` groups separated, sensitive field exposure controlled
- [ ] Read=Provider, Write=Processor, domain logic delegated to a Service (Processor returns the result, decorates the default Processor)
- [ ] `#[Assert\...]` validation (per-operation `validationContext` groups), errors in RFC 7807/Hydra auto-format (422 on validation failure, `exceptionToStatus` mapping)
- [ ] Async work via operation `messenger:` (`output: false`+`status: 202`), handler with `#[AsMessageHandler]`, domain logic delegated to a Service
- [ ] Custom behavior with State first, controllers only via operation `controller:`+`#[AsController]` (no raw routes)
- [ ] Operation `security:`/Voter, `symfony/rate-limiter` applied
- [ ] Collection row filtering done in the Provider/query extension (a collection cannot filter items with a Voter)
- [ ] Search/sort/pagination declared with parameter-based filters (`#[QueryParameter]`) and pagination options (legacy `#[ApiFilter]` for existing-code compatibility only)
- [ ] OpenAPI adjusted with `#[ApiProperty]`/`openapi:`/`OpenApiFactory` (no manual spec maintained alongside)
- [ ] Success/validation-failure/authorization-denied cases tested with `ApiTestCase`

## References

- Rules (SoT): `.claude/rules/api-platform-rule.md`
- PHP/Symfony standards: `.claude/rules/app-php-symfony-**`
- Security, CSRF, rate limiting: `.claude/rules/app-php-symfony-08-security-rule.md`
- Official (Symfony): [validation](https://api-platform.com/docs/symfony/validation/) · [security](https://api-platform.com/docs/symfony/security/) · [messenger](https://api-platform.com/docs/symfony/messenger/) · [controllers](https://api-platform.com/docs/symfony/controllers/) · [testing](https://api-platform.com/docs/symfony/testing/)
