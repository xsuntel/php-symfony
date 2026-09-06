---
name: api-platform-style
description: API Platform 4.x / Symfony 8 — style guide applied to app/src/ApiResource/ · app/src/State/
keep-coding-instructions: true
---

# API Platform Style Guide

This document governs **output presentation and formatting**. The details of the coding standards
(resource declaration · operation · serialization · State · validation · security · pagination · filters ·
tests) and the code examples are owned by the rules as the single source of truth (SoT) — not restated here.

@see .claude/rules/api-platform-rule.md — API Platform standards (SoT)
@see .claude/rules/app-php-symfony-00-overview-rule.md — the `## API Platform` section
@see .claude/docs/api-platform-docs.md — detailed resource · State examples

## Standards Compliance (Summary)

- Do not attach `#[ApiResource]` directly to a Doctrine `Entity` — always go through a DTO in `App\ApiResource\`.
- Specify operations as an **explicit array** — do not implicitly rely on the default set.
- Serialization group naming: `{resource}:read` (response) / `{resource}:write` (input).
- Put State Providers/Processors in `App\State\` with constructor injection only — delegate domain logic to a `Service`.
- Validation via `#[Assert\...]`, errors via automatic RFC 7807/Hydra serialization — no custom error assembly. See the rules above for details.

## Naming Conventions (PSR-1 / PSR-12)

| Symbol | Rule | Example |
| ------ | ------ | ------ |
| Resource DTO | PascalCase + `Resource` | `BookResource` |
| State Provider | PascalCase + `Provider` | `BookProvider` |
| State Processor | PascalCase + `Processor` | `BookProcessor` |
| Serialization group | `{resource}:read` / `{resource}:write` | `book:read`, `book:write` |
| Method / property | camelCase | `provide()`, `$title` |

## File Header Order

Every PHP file follows this order exactly:

1. `<?php` → blank line
2. `declare(strict_types=1);` → blank line
3. `namespace App\ApiResource\...;` or `namespace App\State\...;` → blank line
4. `use` statements — alphabetical, group order: PHP built-in → Doctrine → **ApiPlatform (`ApiPlatform\*`)** →
   Symfony (`Symfony\*`) → App (`App\*`) → blank line
5. Class declaration (`final class ... Resource` / `final readonly class ... Provider`)

## Code Block Format

- Wrap PHP code in a fenced code block with the `php` language identifier.
- When creating a file, state the full path relative to `app/` as a comment right before the block:

```
// app/src/ApiResource/Company/BookResource.php
```

## Multi-File Responses

When creating multiple files, state the path comment before each block, immediately followed by the full file content.
Order a resource set as **Resource (DTO) → State Provider/Processor → related Exception**.

## Inline Explanation Format

Use only the following headings after a code block:

- **How it works** — the operation · serialization · State flow, 3–5 items
- **Why this way** — the DTO separation · State delegation or performance rationale
- **Next steps** — `debug:api-resource`, migration, writing tests, etc. (only when relevant)

Prohibited: preambles like "Here is the code:", summaries of what was written, phrases like "Great question!" · "Certainly!".

## Comment Style for Generated Code

- No block comments (`/* ... */`) in generated PHP. Inline comments only when the WHY is not self-evident.
- No `@param`/`@return` docblock when a native type expresses the contract.
- When the operation array is long, mark the intent (security · URI variables, etc.) as a one-line inline comment above each operation.

## Test Code Presentation

- Functional tests extend `ApiPlatform\Symfony\Bundle\Test\ApiTestCase` (not the ordinary `WebTestCase`), and the class is `final`.
- Look up the item IRI with `findIriBy(Resource::class, [...])` — no hardcoded URLs.
- Cover the success / validation-failure (422) / authorization-denied case per operation — see the `## Tests` section of the rules above for details.
