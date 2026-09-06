---
name: app-php-symfony-style
description: PHP 8.4 / Symfony 8 — style guide applied to every file under app/src/
keep-coding-instructions: true
---

# PHP Style Guide

This document governs **output presentation and formatting**. The details of the coding standards
(PHP 8.4 features · type safety · DI · attributes · Doctrine · testing policy) and the code examples are
owned by the rules as the single source of truth (SoT) — not restated here.

@see .claude/rules/app-php-symfony-00-overview-rule.md ~ app-php-symfony-15-scheduler-rule.md — coding standards (SoT)
@see .claude/docs/app-php-symfony-docs.md — per-layer code templates

## Standards Compliance (Summary)

- Comply with **PSR-1 / PSR-4 / PSR-12**. Namespaces map 1:1 to the `app/src/` path.
- PHP 8.4 features (constructor promotion · `readonly` · `match` · backed `enum` · property hooks · asymmetric visibility),
  type declarations required (avoid `mixed`), constructor injection only — see the rules above for details and examples.

## Naming Conventions (PSR-1 / PSR-12)

| Symbol | Rule | Example |
| ------ | ------ | ------ |
| Class | PascalCase | `OrderStatusService` |
| Interface | PascalCase + `Interface` | `OrderRepositoryInterface` |
| Trait | PascalCase + `Trait` | `TimestampableTrait` |
| Enum | PascalCase + `Enum` | `OrderStatusEnum` |
| Method / property / variable | camelCase | `findActiveOrders()`, `$createdAt` |
| Constant | UPPER_SNAKE_CASE | `MAX_RETRY_COUNT` |

## Formatting Rules (PSR-12)

- 4-space indentation (no tabs), soft line-length limit of 120 characters, one statement per line.
- The opening brace is on the same line as the class/function/control-structure keyword; the closing brace is on its own line.
- No space between a function/method name and the opening parenthesis; one space around binary operators.
- Trailing comma on the last item of multi-line arrays · argument lists.
- Visibility declared on every property · method. `abstract`/`final` before visibility, `static` after visibility.

## File Header Order

Every PHP file follows this order exactly:

1. `<?php` → blank line
2. `declare(strict_types=1);` → blank line
3. `namespace App\...;` → blank line
4. `use` statements — alphabetical, group order: PHP built-in → Doctrine → Symfony (`Symfony\*`, `Twig\*`) → App (`App\*`) → blank line
5. Class declaration

## Code Block Format

- Wrap PHP code in a fenced code block with the `php` language identifier.
- When creating a file, state the full path relative to `app/` as a comment right before the block:

```
// app/src/Entity/Domain/Name.php
```

## Multi-File Responses

When creating multiple files, state the path comment before each block, immediately followed by the full file content.

## Inline Explanation Format

Use only the following headings after a code block:

- **How it works** — what the code does, 3–5 items
- **Why this way** — the architecture or performance rationale
- **Next steps** — migration command, `debug:router`, etc. (only when relevant)

Prohibited: preambles like "Here is the code:", summaries of what was written, phrases like "Great question!" · "Certainly!".

## Comment Style for Generated Code

- No block comments (`/* ... */`) in generated PHP. Inline comments only when the WHY is not self-evident.
- No `@param`/`@return` docblock when a native type expresses the contract.
- Use only the following format for section separators (long controller/handler methods only):

```php
// -----------------------------------------------------------------------------------------------------------------
// Section Name
// -----------------------------------------------------------------------------------------------------------------
```

## Test Code Presentation

- Use only PHPUnit 12 attributes (`#[Test]`, `#[DataProvider]`, `#[CoversClass]`), and the class is `final`.
- Method names: `it_{behavior}()` (Unit/Integration), `test_{route}_{assertion}()` (Functional).
- Testing standards such as layer boundaries · mocking policy are in `.claude/rules/app-php-symfony-09-testing-rule.md`.
