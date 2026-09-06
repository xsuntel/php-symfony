---
name: api-platform-docs-generator-skill
description: 'Use when configuring, inspecting, exporting, or customizing the API docs that API Platform with Symfony auto-generates (OpenAPI 3.1, JSON-LD/Hydra, Swagger UI/ReDoc). Triggered by questions about global docs config (title/version/description, enable_swagger_ui/enable_re_doc), #[ApiProperty] property metadata, operation openapi:/openapiContext, OpenApiFactory decoration, security scheme documentation (swagger.api_keys/oauth), errors:/#[ErrorResource] error-response documentation, and serialization-group-based schema exposure adjustments.'
---

# API Platform Docs Generator Skill (documentation authoring)

API Platform **auto-generates the OpenAPI 3.1 spec, JSON-LD/Hydra docs, and Swagger UI/ReDoc** from
the `#[ApiResource]` metadata. The purpose of this skill is therefore not to write docs by hand, but
to **configure, inspect, and customize only the necessary parts of the auto-generated result** via
global config, operations, and property metadata. Do not maintain a separate manual spec file
alongside it, and do not introduce `NelmioApiDocBundle` (native generation).

## Information Source (single source of truth: the rule file)

The criteria for resources, operations, serialization, and errors are owned by the rule file as the
single source of truth (SoT). This skill provides only the documentation-perspective procedure.

@see .claude/rules/api-platform-rule.md — `## OpenAPI Documentation Customization`·`## Error Handling`·`## Configuration` sections (SoT)
@see https://api-platform.com/docs/core/openapi/ — OpenAPI customization (official)
@see https://api-platform.com/docs/core/errors/ — error documentation (official)
@see .claude/skills/api-platform-rest-build-skill/SKILL.md — use this instead when the goal is implementing/reviewing resources & State
@see .claude/skills/api-platform-oauth2-build-skill/SKILL.md — when wiring the security scheme (JWT/OAuth2) on the server side
@see .claude/skills/api-platform-oauth2-client-skill/SKILL.md — for configuring the Swagger UI OAuth2 "Authorize" flow

## Accuracy Principles

- Describe the auto-generated schemas/fields/responses only after **exporting and measuring them
  first** — do not invent fields or responses by guessing.
- Do not assert on properties/config keys that may vary by version; mark them "installed version/official docs confirmation required".

## Inspect the Auto-generated Docs (run first)

```bash
# Inspect resource metadata & operations
cd app && php bin/console debug:api-resource "App\\ApiResource\\Company\\BookResource"

# Export the OpenAPI spec
cd app && php bin/console api:openapi:export --yaml                      # YAML (requires symfony/yaml)
cd app && php bin/console api:openapi:export --output=openapi.json       # save to file (JSON)
cd app && php bin/console api:openapi:export --spec-version=3.0.0        # in OpenAPI 3.0 format

# In the browser — Swagger UI: /api/docs, ReDoc: /api/docs?ui=re_doc, JSON-LD/Hydra: /api/docs.jsonld
```

## Global Docs Config (`config/packages/api_platform.yaml`)

Control the docs' metadata and UI via global config — do not write the spec by hand.

```yaml
api_platform:
  title: "XSUN API" # OpenAPI info.title
  description: "Internal REST API" # OpenAPI info.description
  version: "1.0.0" # OpenAPI info.version
  enable_swagger_ui: true # Swagger UI (/api/docs), true by default
  enable_re_doc: true # ReDoc, true by default
  # asset_package: 'docs'            # Symfony Asset Package for the docs UI static assets (optional)
```

- Separate per-environment exposure differences (e.g. disabling docs in `prod`) with `when@prod` or `config/packages/{env}/`.
- **[Needs verification]** The existence/defaults of the above keys may vary by the installed API Platform version, so measure them with `debug:config api_platform`.

## Security Scheme Documentation

To expose the Swagger UI "Authorize" on protected endpoints, declare a scheme matching the
authentication method. Server-side auth wiring follows `api-platform-oauth2-build-skill`, and the OAuth2
consumption flow follows the `api-platform-oauth2-client-skill` skill.

```yaml
api_platform:
  # JWT/Bearer (project standard) — exposed as a header API key
  swagger:
    api_keys:
      JWT:
        name: Authorization
        type: header
  # or an OAuth2 flow (Swagger UI Authorize popup)
  # oauth: { enabled: true, clientId: '%env(OAUTH_CLIENT_ID)%', type: oauth2, flow: authorizationCode, ... }
```

## Customization Means

To adjust the docs, edit the **metadata** rather than code. In low-level → high-level order:

### 1. Property — `#[ApiProperty]`

Adjust per-property documentation such as description, example, read-only, and required.

```php
use ApiPlatform\Metadata\ApiProperty;
use Symfony\Component\Serializer\Attribute\Groups;

#[ApiProperty(
    description: 'ISBN-13',
    example: '978-3-16-148410-0',
    openapiContext: ['format' => 'isbn', 'deprecated' => false],  // detailed OpenAPI hints
)]
#[Groups(['book:read'])]
public string $isbn;
```

### 2. Operation — `openapi:` / `openapiContext`

Adjust the summary, description, response examples, and parameters per operation.

```php
use ApiPlatform\Metadata\Get;
use ApiPlatform\OpenApi\Model\Operation as OpenApiOperation;

#[Get(openapi: new OpenApiOperation(summary: 'Retrieve a single book', description: '...'))]
```

### 3. Error-response documentation — `errors:` / `#[ErrorResource]`

Listing domain exceptions in the operation's `errors:` includes them as possible responses in the
spec. Define a custom error resource with `#[ErrorResource]` + `ProblemExceptionInterface`. The error
body is auto-serialized in the RFC 7807/Hydra format, so do not write the schema by hand.

```php
#[ApiResource(operations: [
    new GetCollection(errors: [BookNotFoundException::class]),
])]
```

### 4. Schema exposure — serialization groups

The response/request schema is derived from the groups of `normalizationContext`/`denormalizationContext`.
To change the exposed fields, **adjust the groups and `#[Groups]`** rather than writing the schema
directly. Put computed fields in a read group and control the name with `#[SerializedName]` if needed.

### 5. Global post-processing — `OpenApiFactory` decoration

For broad changes (global tags, servers, security schemes, etc.), decorate
`ApiPlatform\OpenApi\Factory\OpenApiFactoryInterface` to post-process the generated spec object.

```php
use ApiPlatform\OpenApi\Factory\OpenApiFactoryInterface;
use ApiPlatform\OpenApi\OpenApi;

final readonly class OpenApiDecorator implements OpenApiFactoryInterface
{
    public function __construct(private OpenApiFactoryInterface $decorated) {}

    public function __invoke(array $context = []): OpenApi
    {
        $openApi = ($this->decorated)($context);
        // post-process the global spec (info·servers·securitySchemes, etc.)
        return $openApi;
    }
}
```

## Documentation Checklist

- [ ] Set the global `title`/`description`/`version` in `api_platform.yaml`
- [ ] Configured the docs UI exposure scope (`enable_swagger_ui`/`enable_re_doc`, per-environment `when@prod`) as intended
- [ ] Exposed a security scheme (`swagger.api_keys` or `oauth`) on protected operations so "Authorize" works
- [ ] Filled property descriptions/examples with `#[ApiProperty]` (and `openapiContext` if needed)
- [ ] Filled operation summary/description with `openapi:`/`openapiContext`
- [ ] Documented possible error responses with operation `errors:`/`#[ErrorResource]`
- [ ] Exposed fields are derived from serialization groups (not a hand-written schema)
- [ ] Measured with `api:openapi:export` to confirm no invented fields/responses

## CI Verification (optional)

```bash
# Extract the generated spec to a file for contract (schema) verification/diff
cd app && php bin/console api:openapi:export --yaml --output=var/openapi.yaml
```

## Prohibitions

- Do not maintain a **manual OpenAPI spec file** separate from the auto-generated docs — the metadata is the single source of truth.
- Do not invent fields/responses/error codes in the docs that were not confirmed by export.
- Do not write the schema by hand — derive it from serialization groups and `#[ApiProperty]`.
- Do not introduce a separate docs bundle such as `NelmioApiDocBundle` — use API Platform's native generation.
