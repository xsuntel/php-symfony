---
paths:
  - "app/src/ApiResource/**/*.php"
  - "app/src/State/**/*.php"
---

# API Platform (Symfony) Rules

These rules apply to all code where this project **exposes its own REST API (inbound) via
API Platform**. The scope is not outbound clients that consume third-party APIs, but the work
of declaring resources with `#[ApiResource]` and configuring operations, serialization, State,
validation, and security.

This rule is the single source of truth (SoT) for API Platform decisions. `.claude/agents/api-*.md`,
`.claude/commands/api-platform-*.md`, and `.claude/docs/api-platform-docs.md` reference this document.

@see https://api-platform.com/docs/symfony/ — API Platform with Symfony (official)
@see https://api-platform.com/docs/core/serialization/ — Serialization groups
@see https://api-platform.com/docs/core/state-providers/ — State Provider/Processor
@see https://api-platform.com/docs/symfony/testing/ — ApiTestCase
@see .claude/rules/app-php-symfony-00-overview-rule.md — `## API Platform` section
@see .claude/rules/app-php-symfony-08-security-rule.md — Security, CSRF, rate limiting

## Project Standard Layout (convention for app implementation)

> This repository is an infrastructure wrapper, and `app/` (the Symfony application) is populated
> separately. The values below are the **convention to follow when implementing**, not verified
> measured values in the current repo — confirm the actual settings in
> `config/packages/api_platform.yaml` after implementing `app/`.

- Installed packages: `api-platform/symfony`, `api-platform/doctrine-orm` (API Platform 4.x).
- Route prefix: `/api` (`config/routes/api_platform.yaml`).
- Global defaults: `stateless: true`, `cache_headers.vary: [Content-Type, Authorization, Origin]` (`config/packages/api_platform.yaml`).
- Resource location: `app/src/ApiResource/` (namespace `App\ApiResource\`); State location: `app/src/State/` (`App\State\`).

## State Processing Pipeline

API Platform processes requests through a **State Provider/Processor chain**. Decide where to
wire a Provider/Processor based on this flow:

```text
Read (Get/GetCollection): Read(Provider) → Serialize → response
Write (Post/Patch/Put)  : Read(Provider, optional) → Deserialize(denormalizationContext)
                         → Validate(#[Assert]) → Write(Processor) → Serialize(normalizationContext) → response
```

- **Provider** corresponds to the _Read_ stage of the pipeline, **Processor** to the _Write_ stage —
  access control, deserialization, and validation are handled by the framework stages in between,
  so do not reimplement them in the Provider/Processor.
- The Doctrine ORM bridge's default Provider/Processor are already wired into this chain — add a
  custom one only when needed.

@see https://api-platform.com/docs/core/state-providers/ — Provider (Read stage)
@see https://api-platform.com/docs/core/state-processors/ — Processor (Write stage)

## Resource Declaration

- Place resource classes in `app/src/ApiResource/` — do not expose a Doctrine `Entity` class directly by attaching `#[ApiResource]` to it.
- Declare with the `#[ApiPlatform\Metadata\ApiResource]` attribute.
- Specify the operations to expose as an **explicit array** — do not implicitly rely on the default operation set.
- Separate input/output into DTOs — use the `input:` and `output:` options to decouple the resource from the persistence model.

```php
// app/src/ApiResource/Company/BookResource.php
use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Get;
use ApiPlatform\Metadata\GetCollection;
use ApiPlatform\Metadata\Post;

#[ApiResource(
    operations: [new GetCollection(), new Get(), new Post()],
    normalizationContext: ['groups' => ['book:read']],
    denormalizationContext: ['groups' => ['book:write']],
)]
final class BookResource
{
    // ...
}
```

## Operations

- Collection operations: `GetCollection` (list), `Post` (create). Item operations: `Get` (single), `Patch` (partial update), `Delete` (delete).
- `Put` (full replace) is disabled by default — add it explicitly only when needed.
- State-changing operations (`Post`/`Patch`/`Put`/`Delete`) must always wire validation, security, and a State Processor.
- Serialization context, security, URI variables, etc. can be specified per operation — operation-level settings take precedence over resource-level defaults.

### Custom Operations & Controllers

- Express non-CRUD behavior first with a **custom operation + State Provider/Processor** — it works for both REST and GraphQL and has good framework integration.
- The official docs mark custom Symfony controllers as **discouraged** (no GraphQL support). When Symfony-specific features are nonetheless strictly required, connect them only via the sanctioned path — **the operation's `controller:` option + `#[AsController]`** — not a raw route that bypasses API Platform routing.
- Set `read: false` when automatic entity retrieval is unnecessary, and `deserialize: false` when deserialization is unnecessary. For a simple exposure with no logic, use `ApiPlatform\Action\PlaceholderAction`.

```php
use ApiPlatform\Metadata\Post;
use App\Controller\PublishBookController;

#[Post(
    uriTemplate: '/books/{id}/publication',
    controller: PublishBookController::class,   // sanctioned custom controller wiring
    read: false,
)]
```

@see https://api-platform.com/docs/symfony/controllers/ — Custom Operations & Controllers (official, State first)

## Serialization Groups

- On the resource, specify the `groups` of `normalizationContext` (read response) and `denormalizationContext` (write input).
- Assign properties to groups with `Symfony\Component\Serializer\Attribute\Groups` — properties not in a group are not exposed for that operation.
- Group naming: `{resource}:read` / `{resource}:write` (subdivide per operation as needed, e.g. `{resource}:item:read`).
- Relations are exposed as IRIs by default — include a relation property in a read group only when embedding is required (excessive embedding bloats responses and causes N+1).

```php
use Symfony\Component\Serializer\Attribute\Groups;

#[Groups(['book:read', 'book:write'])]
public string $title;

#[Groups(['book:write'])]
public string $author; // write-only
```

## State Provider / Processor

- Implement data retrieval with `ApiPlatform\State\ProviderInterface` and writes with `ApiPlatform\State\ProcessorInterface`.
- Wire them to the operation via the `provider:` / `processor:` arguments.
- If the Doctrine ORM bridge's default provider/processor can be reused, do not create a custom one — implement one only when custom business logic or DTO mapping is required.
- Place Provider/Processor classes in `app/src/State/` and use constructor injection only — do not move controller logic here (delegate domain logic to a `Service`).

```php
namespace App\State;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProviderInterface;

final readonly class BookProvider implements ProviderInterface
{
    public function provide(Operation $operation, array $uriVariables = [], array $context = []): mixed
    {
        // fetch → DTO mapping (delegate domain logic to a Service)
    }
}
```

The Processor implements `process(mixed $data, Operation $operation, array $uriVariables = [], array $context = []): mixed`.

- **Return the result explicitly** — if `process()` returns nothing, API Platform serializes the input `$data` as-is. Always `return` the final post-persist state (DTO).
- **Layer side effects by decorating the default Processor** — delegate the save/delete itself to the Doctrine default Processor, and add only logic like password hashing, mail sending, or event dispatch before/after it. Do not hand-reimplement the save logic.
- Inject the default Processor via `#[Autowire]` using the **exact service ID string** — `api_platform.doctrine.orm.state.persist_processor` (save) and `api_platform.doctrine.orm.state.remove_processor` (delete). A delete operation branches on `DeleteOperationInterface` and delegates to remove_processor.

```php
use ApiPlatform\Metadata\DeleteOperationInterface;
use ApiPlatform\State\ProcessorInterface;
use Symfony\Component\DependencyInjection\Attribute\Autowire;

final readonly class BookProcessor implements ProcessorInterface
{
    public function __construct(
        #[Autowire(service: 'api_platform.doctrine.orm.state.persist_processor')]
        private ProcessorInterface $persistProcessor,
        #[Autowire(service: 'api_platform.doctrine.orm.state.remove_processor')]
        private ProcessorInterface $removeProcessor,
    ) {}

    public function process(mixed $data, Operation $operation, array $uriVariables = [], array $context = []): mixed
    {
        if ($operation instanceof DeleteOperationInterface) {
            return $this->removeProcessor->process($data, $operation, $uriVariables, $context);
        }

        // after domain logic (Service delegation), delegate the save to the default Processor and return the result
        $result = $this->persistProcessor->process($data, $operation, $uriVariables, $context);
        // ... post-persist side effects (mail, event dispatch) ...

        return $result;
    }
}
```

## Messenger Integration (CQRS / async)

Imperative work that needs no synchronous response (fire-and-forget, heavy post-processing) is
**dispatched to the Symfony Messenger bus** via the operation's `messenger:` option instead of a
State Processor — this project's standard async transport is RabbitMQ (the global Messenger
architecture), so routing follows the project Messenger configuration.

- `messenger: true` — dispatches the resource instance as a message. In this case the **Doctrine default Processor is not called**, so persistence is the handler's responsibility. Usually combined with `output: false` and `status: 202` (Accepted).
- `messenger: 'input'` — dispatches the input DTO specified by `input:` as a message (command DTO pattern). Combine with `output: false` and `status: 202`.
- Register the handler with Symfony `#[AsMessageHandler]` and delegate domain logic to a `Service` (do not accumulate it in the handler).
- If synchronous save and an immediate response are required, use a State Processor rather than Messenger.

```php
use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Post;
use App\ApiResource\Command\ResetPasswordRequest;

#[ApiResource(operations: [
    new Post(
        uriTemplate: '/users/reset-password',
        messenger: 'input',
        input: ResetPasswordRequest::class,
        output: false,
        status: 202,                     // Accepted — processing is deferred asynchronously
    ),
])]
final class UserResource { /* ... */ }
```

```php
use Symfony\Component\Messenger\Attribute\AsMessageHandler;

#[AsMessageHandler]
final readonly class ResetPasswordRequestHandler
{
    public function __construct(private PasswordResetService $service) {}

    public function __invoke(ResetPasswordRequest $request): void
    {
        $this->service->reset($request);   // delegate domain logic to a Service
    }
}
```

- When handling a delete asynchronously, API Platform attaches `ApiPlatform\Symfony\Messenger\RemoveStamp` to the envelope — distinguish save/delete in the middleware.

@see https://api-platform.com/docs/symfony/messenger/ — Messenger integration (CQRS / async)
@see .claude/skills/app-php-symfony-skill/SKILL.md — project Messenger/transport flow (RabbitMQ)

## Validation

- Declare input validation on resource/DTO properties with `Symfony\Component\Validator\Constraints` (`#[Assert\...]`) — do not replace it with manual `if` checks inside the Provider/Processor.
- API Platform serializes validation failures in the **Hydra error format / RFC 7807 (Problem Details)** as `422 Unprocessable Entity` with `violations` (property path and message) — do not hand-build a custom error response.

```php
use Symfony\Component\Validator\Constraints as Assert;

#[Assert\NotBlank]
#[Groups(['book:write'])]
public string $title;
```

### Per-operation validation groups

- To apply different constraints per operation, specify validation groups with `validationContext: ['groups' => [...]]` — include `'Default'` to also apply ungrouped constraints.
- When execution order matters, specify a callable returning `Symfony\Component\Validator\Constraints\GroupSequence` as the group (sequential validation). To decide groups by runtime conditions such as user role, return dynamic groups from a callable/service.
- To expose a `payload` field (e.g. `severity`) in the response, whitelist it via `validator.serialize_payload_fields` in `config/packages/api_platform.yaml`.

```php
#[Post(validationContext: ['groups' => ['Default', 'postValidation']])]
#[Put(validationContext:  ['groups' => ['Default', 'putValidation']])]
final class BookResource
{
    #[Assert\NotBlank(groups: ['postValidation'])]
    #[Groups(['book:write'])]
    public string $title;

    #[Assert\Length(min: 2, max: 50, groups: ['postValidation'])]
    #[Assert\Length(min: 2, max: 70, groups: ['putValidation'])]
    #[Groups(['book:write'])]
    public string $author;
}
```

@see https://api-platform.com/docs/symfony/validation/ — Validation with Symfony (validation groups, GroupSequence)

## Security

- Apply access control with the operation's `security:` / `securityPostDenormalize:` expression or a Voter — delegate complex rules to a Voter (`app-php-symfony-08-security-rule.md`). A Voter is called from an expression via `is_granted('ATTR', object)`.
- **[MUST] A collection (`GetCollection`) cannot filter items with a Voter** — a collection's `security:` only decides access to the endpoint as a whole. To **restrict the visible rows** by the current user's permissions, inject `Security` in the State Provider (or the Doctrine query extension `QueryCollectionExtensionInterface`) and filter at the query level.
- The API is `stateless: true` and authentication is token-based (JWT/Bearer) — it does not use cookie sessions, so it is **exempt from CSRF** (distinct from form login).
- Separate sensitive fields into write-only/read-only groups to control exposure — do not put secrets or PII in a response group.
- Customize the denial message with `securityMessage` / `securityPostDenormalizeMessage` — provide a meaningful message instead of the default "Access Denied".
- Apply rate limiting with `symfony/rate-limiter` on every public endpoint, and respond with `429` + `Retry-After` when exceeded.

- `security` is evaluated **before deserialization**, `securityPostDenormalize` **after deserialization** — use `securityPostDenormalize` for ownership rules that must compare the input value (the modified object) or the previous state. A Voter is called from the expression as `is_granted('ATTR', object)`.

Variables available in expressions:

| Variable          | Meaning                                                                           |
| ----------------- | --------------------------------------------------------------------------------- |
| `user`            | Currently logged-in user                                                          |
| `object`          | Current resource (object being deserialized/serialized)                           |
| `previous_object` | Clone of the object before modification (post-denormalize only; `null` on create) |
| `request`         | Current request (available at the resource level only)                            |

```php
#[ApiResource(operations: [
    new Get(security: "is_granted('BOOK_READ', object)"),           // delegate to Voter
    new Post(
        security: "is_granted('ROLE_ADMIN')",
        securityMessage: 'Only administrators can create books.',
    ),
    new Patch(
        // post-denormalize: allow only when the owner is oneself and the owner is not being changed
        securityPostDenormalize: "is_granted('ROLE_ADMIN') or (object.owner == user and previous_object.owner == user)",
        securityPostDenormalizeMessage: 'You can only edit your own books.',
    ),
])]
```

@see https://api-platform.com/docs/symfony/security/ — Security with Symfony (collection filtering, Voter, denial messages)

## Pagination & Filters

### Pagination

- Use API Platform's built-in pagination for collections — do not hand-assemble `LIMIT`/`OFFSET` in the Provider. The default page size follows the project standard (20, max 100).
- Specify page size via operation/resource attributes (option keys confirmed):
  - `paginationItemsPerPage` (default page size)
  - `paginationMaximumItemsPerPage` (client upper bound)
  - `paginationClientItemsPerPage` (whether the client may adjust it via the `itemsPerPage` query)
  - `paginationEnabled` (pagination on/off), `paginationFetchJoinCollection` (accurate count on a to-many join)
- Place global defaults under `defaults` in `config/packages/api_platform.yaml` using snake_case keys: `pagination_items_per_page`, `pagination_maximum_items_per_page`, `pagination_client_items_per_page`, `pagination_enabled`.

### Filters (API Platform 4.x — parameter-based by default)

- **[MUST] New code uses parameter-based filters (`parameters:` + `#[QueryParameter]`) by default.** The official docs recommend this approach in 4.x, and the legacy `#[ApiFilter]` filters (`SearchFilter`/`OrderFilter`, etc.) have been reclassified as _not recommended_.
- Declare filters as attributes — do not parse query parameters directly in the Provider. Filters by type:

| Filter                | Purpose                                                          | Note                                                                            |
| --------------------- | ---------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| `ExactFilter`         | Exact match                                                      | dot notation for nested properties                                              |
| `PartialSearchFilter` | Partial string (LIKE `%..%`)                                     | case-insensitive by default; `new PartialSearchFilter(true)` for case-sensitive |
| `ComparisonFilter`    | Comparison (`gt`/`gte`/`lt`/`lte`/`ne`) decorator                | replaces legacy `Date`/`Numeric`/`Range`                                        |
| `SortFilter`          | Sorting                                                          | replaces legacy `OrderFilter`, supports dot notation                            |
| `IriFilter`           | Relation (IRI) filter                                            | dot notation for nested associations                                            |
| `FreeTextQueryFilter` | Decorator applying a single parameter across multiple properties | `properties: [...]`                                                             |
| `OrFilter`            | Decorator combining conditions with `OR`                         | `properties: [...]`                                                             |

```php
use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\GetCollection;
use ApiPlatform\Metadata\QueryParameter;
use ApiPlatform\Doctrine\Orm\Filter\PartialSearchFilter;
use ApiPlatform\Doctrine\Orm\Filter\ExactFilter;
use ApiPlatform\Doctrine\Orm\Filter\ComparisonFilter;
use ApiPlatform\Doctrine\Orm\Filter\SortFilter;

#[ApiResource(operations: [
    new GetCollection(parameters: [
        'title'     => new QueryParameter(filter: new PartialSearchFilter()),          // ?title=han
        'isbn'      => new QueryParameter(filter: new ExactFilter()),                   // ?isbn=978-...
        'price'     => new QueryParameter(filter: new ComparisonFilter(new ExactFilter()), property: 'price'), // ?price[gte]=10&price[lt]=50
        'order'     => new QueryParameter(filter: new SortFilter(), property: 'createdAt'),                     // ?order=desc
    ]),
])]
final class BookResource { /* ... */ }
```

- The `:property` placeholder can spread a parameter across multiple properties (e.g. `'search[:property]' => new QueryParameter(properties: ['title', 'author'], filter: new PartialSearchFilter())`). **[Needs verification]** A bug in the `:property` + `PartialSearchFilter`/`ExactFilter` combination was reported in 4.2.2, and nameConverter/camelCase property issues in 4.3.x — confirm the behavior on your installed version before adopting.

### Legacy filters (for existing-code compatibility only)

Use only when maintaining/migrating existing `#[ApiFilter]`-based code; use the parameter-based equivalents above for new code.

| Legacy `#[ApiFilter]`                          | New equivalent                                 |
| ---------------------------------------------- | ---------------------------------------------- |
| `SearchFilter` (`partial`)                     | `PartialSearchFilter`                          |
| `SearchFilter` (`exact`)                       | `ExactFilter`                                  |
| `OrderFilter`                                  | `SortFilter`                                   |
| `DateFilter` / `RangeFilter` / `NumericFilter` | `ComparisonFilter`                             |
| `BooleanFilter`                                | `ExactFilter`                                  |
| `ExistsFilter`                                 | (keep where applicable — no direct equivalent) |

```php
// Legacy — for existing code only; prefer #[QueryParameter] for new resources
use ApiPlatform\Metadata\ApiFilter;
use ApiPlatform\Doctrine\Orm\Filter\SearchFilter;
use ApiPlatform\Doctrine\Orm\Filter\OrderFilter;

#[ApiFilter(SearchFilter::class, properties: ['title' => 'partial', 'isbn' => 'exact'])]
#[ApiFilter(OrderFilter::class, properties: ['title', 'createdAt'])]
final class BookResource { /* ... */ }
```

@see https://api-platform.com/docs/core/filters/ — parameter-based filters (recommended) and legacy filters
@see https://api-platform.com/docs/core/pagination/ — pagination options

## Error Handling

- API Platform automatically serializes errors in the **RFC 7807 (Problem Details)** or **Hydra** format (selected by content negotiation). `rfc_7807_compliant_errors` is enabled by default — do not hand-assemble a custom error response.
- Validation failures map to **422 Unprocessable Entity**, expected errors to 4xx, and unexpected errors to 500.
- To map a domain exception to an HTTP status, use `exceptionToStatus` in priority order: operation level > resource level > global (`exception_to_status` in `config/packages/api_platform.yaml`).
- **[MUST] The global `exception_to_status` is not merged with the defaults** — when declaring a custom mapping you must also retain the built-in default mappings (omitting them removes the default handling). Prefer resource/operation-level mappings where possible.
- Create a custom error resource with `#[ErrorResource]` + `ApiPlatform\Metadata\Exception\ProblemExceptionInterface`.
- Listing domain exceptions in the operation's `errors:` includes them as possible responses in the OpenAPI docs.

```php
use ApiPlatform\Metadata\GetCollection;

#[ApiResource(
    operations: [new GetCollection(errors: [BookNotFoundException::class])],
    exceptionToStatus: [BookNotFoundException::class => 404],
)]
```

@see https://api-platform.com/docs/core/errors/ — error format, status mapping, ErrorResource

## OpenAPI Documentation Customization

- The OpenAPI 3.1 spec and the JSON-LD/Hydra and Swagger UI docs are **generated automatically** — do not maintain a manual spec file alongside them (see `## Prohibitions`).
- Adjust property metadata (description, example, read-only, etc.) with `#[ApiProperty]`.
- Adjust operation-level documentation with `openapi:` (`ApiPlatform\OpenApi\Model\Operation`) or `openapiContext`.
- **Include computed/non-persisted fields in a read group** and control the exposed name with `#[SerializedName]` when needed — the Provider fills the value.
- For broad changes, decorate `OpenApiFactoryInterface` to post-process the global spec.
- The response format is JSON-LD/Hydra by default; configure JSON:API, HAL, JSON, XML, or CSV via `formats` when needed.
- (Optional) When real-time updates are required, enable Mercure on the resource with `mercure: true` — a wired Mercure hub is a prerequisite.

```php
use ApiPlatform\Metadata\ApiProperty;
use Symfony\Component\Serializer\Attribute\SerializedName;

#[ApiProperty(description: 'ISBN-13', example: '978-3-16-148410-0')]
#[Groups(['book:read'])]
public string $isbn;

#[Groups(['book:read'])]
#[SerializedName('isOnSale')]
public bool $onSale = false; // computed by Provider
```

@see https://api-platform.com/docs/core/openapi/ — OpenAPI customization

## Configuration

- Manage global settings in `config/packages/api_platform.yaml` — `title`, `version`, `defaults` (`stateless`, `cache_headers`).
- Separate per-environment differences (docs exposure, debug) with `when@{env}` or `config/packages/{env}/`.
- The OpenAPI/Swagger UI and JSON-LD (Hydra) docs are generated automatically by API Platform — do not maintain a manual spec file alongside them.

## Testing

- Functional tests extend `ApiPlatform\Symfony\Bundle\Test\ApiTestCase` — not a plain `WebTestCase`.
- Make requests with `static::createClient()->request(...)` and assert the response with:
  - Status: `assertResponseIsSuccessful()`, `assertResponseStatusCodeSame(201)`
  - Body: `assertJsonContains([...])` (partial match), `assertJsonEquals([...])` (exact match)
  - Headers: `assertResponseHeaderSame('content-type', 'application/ld+json; charset=utf-8')`
  - Schema: `assertMatchesResourceItemJsonSchema(Resource::class)`, `assertMatchesResourceCollectionJsonSchema(Resource::class)`
- Place tests in the Functional suite under `app/tests/`, covering success/validation-failure/authorization-denied cases per operation.
- For **JWT/stateless-authenticated resources**, pass the Bearer token as a header — consolidate token issuance in an `AbstractTest` base for reuse (cache the token to avoid duplicate logins).

```php
use ApiPlatform\Symfony\Bundle\Test\ApiTestCase;
use Symfony\Contracts\HttpClient\HttpClientInterface;

abstract class AbstractTest extends ApiTestCase
{
    private static ?string $token = null;

    protected function createClientWithCredentials(?string $token = null): HttpClientInterface
    {
        $token ??= $this->getToken();

        return static::createClient([], ['headers' => ['Authorization' => 'Bearer ' . $token]]);
    }

    protected function getToken(array $body = []): string
    {
        if (self::$token !== null) {
            return self::$token;
        }

        $response = static::createClient()->request('POST', '/api/login', ['json' => $body ?: [
            'email'    => 'admin@example.com',
            'password' => 'password',
        ]]);

        return self::$token = $response->toArray()['token'];
    }
}

final class BookResourceTest extends AbstractTest
{
    public function testCreate(): void
    {
        $this->createClientWithCredentials()->request('POST', '/api/books', ['json' => ['title' => 'A']]);

        $this->assertResponseStatusCodeSame(201);
        $this->assertMatchesResourceItemJsonSchema(BookResource::class);
    }
}
```

## Symfony-specific Topics & Deployment Alignment

The remaining guides under `/docs/symfony/` align with this project's conventions as follows:

- **Authentication (JWT/OAuth2) & User entity**: server-side configuration is handled by the `api-platform-oauth2-build-skill` skill, and the consumption/Swagger UI flow by the `api-platform-oauth2-client-skill` skill. The authentication standard is stateless JWT (`LexikJWTAuthenticationBundle`).
- **File upload**: handle multipart uploads with a dedicated operation (`inputFormats: ['multipart' => ['multipart/form-data']]`, `deserialize: false` if needed) and persist file fields with `VichUploaderBundle` or similar. **[Needs verification]** Confirm the exact options/bundle wiring against your installed version and the official docs.
- **Debugging**: measure operation/serialization/filter metadata with `php bin/console debug:api-resource "App\\ApiResource\\...\\XxxResource"` — do not describe it by guessing.
- **Web server (Caddy vs Nginx)**: the API Platform default distribution uses FrankenPHP/Caddy, but **this project uses Nginx** (`server-nginx-rule.md`). Do not adopt the Caddy configuration from `/docs/symfony/caddy/`.
- **Legacy integrations (NelmioApiDocBundle, FOSRestBundle, FOSUserBundle)**: do not introduce them — OpenAPI/docs are generated automatically by API Platform, and authentication follows the JWT standard above.

@see https://api-platform.com/docs/symfony/file-upload/ — File Upload with Symfony
@see https://api-platform.com/docs/symfony/debugging/ — Debugging with Symfony
@see .claude/rules/server-nginx-rule.md — this project's web server (Nginx) standard

## Prohibitions

- Do not attach `#[ApiResource]` directly to a Doctrine `Entity` — always go through an `ApiResource` DTO.
- Do not omit operations and rely on the default set — specify the exposure scope explicitly.
- Do not accumulate domain business logic in the Provider/Processor — delegate it to a `Service`.
- Do not hand-assemble a custom error response — use the RFC 7807/Hydra format.
- Do not implement endpoints with a **raw route/controller** that bypasses API Platform routing — express them with an operation + State. Only when unavoidable, connect via the sanctioned operation `controller:` + `#[AsController]` (see custom operations under `## Operations`).
