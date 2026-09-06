# Review Guidelines

## What "Important" Means Here

Reserve **Important** for findings that can stop the application, leak data, or block a rollback:
wrong logic, unscoped database queries, PII in logs or error messages, and non-backward-compatible migrations.
Style, naming, and refactoring suggestions are **Nit** at most.

## Nit Limit

Report at most **5 Nits** per review.
If you find more, say "plus N similar items" in the summary instead of posting them all inline.
If everything you found is a Nit, begin the summary with **"No blocking issues."**

## Review Output Format

```
### Summary
[One paragraph. Lead with "No blocking issues." if everything is a Nit.]

### Important
- [file:line] Description

### Nit (max 5)
- [file:line] Description
```

## Do Not Report

- Anything CI already enforces: lint, formatting, type errors, PHPStan violations.
- Generated files under `src/gen/` and any `*.lock` files.
- Auto-generated schema comments in `migrations/` files (e.g., column type annotations added by Doctrine diff).
- Test-only code that intentionally violates production rules.

## Always Check

### Security

- Controllers never access `$_POST`, `$_GET`, `$_REQUEST`, or `$request->get()` directly —
  all input flows through a Symfony Form type or a DTO + Validator.
- Every state-mutating HTML form submission includes a CSRF token in the template and
  `#[IsCsrfTokenValid]` on the controller action.
- No `{{ variable|raw }}` applied to any value that originates from user input or the database.
- JWT token values are never logged — only the extracted user identifier.
- Login, registration, password-reset, and public POST endpoints apply `symfony/rate-limiter`.
- API keys for external providers (KoreaInvestment, UPbit) are stored in encrypted JSONB columns
  or environment variables — never in plaintext entity columns or committed files.
- Log lines do not contain email addresses, user IDs, passwords, tokens, or request bodies.

### Database & Migrations

- New API routes have at least one integration test (real PostgreSQL — no mocked DB).
- Database queries are scoped to the caller's tenant — no unscoped `findAll()`-style queries on
  multi-tenant tables.
- No migration adds a `NOT NULL` column without a `DEFAULT` value — that would break existing rows.
- Already-applied migrations are never edited — only new migration files are added.
- Destructive changes (column removal, type change on a live column) use a two-step migration:
  (1) deprecate/backfill, (2) drop.
- Every new Entity declares `#[ORM\Table(name: '...')]` explicitly — no Doctrine auto-generated names.
- Every new foreign-key column has an explicit `#[ORM\Index]` declaration.
- Money/price columns use `type: 'decimal'` with explicit `precision` and `scale` — never `float`.

### Architecture & CQRS

- Write operations dispatch a `MessageCommand` via `MessageBusInterface` — no direct Service/Repository
  calls from Controllers.
- Read operations dispatch a `MessageQuery` — no mixing of reads and writes in the same handler.
- No cross-domain Service injection (e.g., `Company` importing from `Partners`); cross-domain data
  sharing goes through shared Entities or MessageQuery dispatches.
- Entity state transitions go through `WorkflowInterface::apply()` — no direct property mutation from
  a Service or Controller.

### External API Integration

- HttpClient is injected as `HttpClientInterface` — no `curl`, `file_get_contents`, or Guzzle.
- API key values are never logged; only the masked prefix (first 4 chars + `****`) is allowed.
- Fetch and transform are in separate handlers — a handler that fetches raw provider data must not
  also aggregate or transform it.
- Consecutive provider API calls use a Symfony Lock (`lock_korea_investment_{endpoint_tr_id}` pattern)
  to respect per-second/per-day rate limits.

### Performance

- No N+1 queries — relations accessed in a loop must be fetched with `JOIN FETCH` (`addSelect` + `leftJoin`) in the Repository.
- Collection-returning queries use Pagerfanta with the Doctrine ORM adapter — no manual `LIMIT`/`OFFSET`.
- No `findAll()` or `findBy()` with more than two criteria in production paths — use `createQueryBuilder()`.

### Frontend

- Stimulus controllers use `this.*Target` references — never `document.querySelector()` inside a controller.
- No `{{ variable|raw }}` on values originating from user input or the database (duplicated from Security for template reviewers).
- Tailwind utility classes used directly in Twig — no new custom CSS classes for patterns already expressible with utilities.

### Logging

- Named Monolog channels are used (`monolog.logger.{module}`) — not the global `logger` service.
- Debug-level logs are guarded: `if ($this->isDebug) { ... }`.
- Structured context arrays are used in log calls — no string interpolation inside log messages.
