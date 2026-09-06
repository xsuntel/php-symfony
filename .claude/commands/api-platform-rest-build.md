---
description: "Creates/modifies API Platform (Symfony) resource and State code, then self-verifies it against the SoT rules."
argument-hint: "[implementation target (resource · operation · filter · scope)]"
---

Handle the following API Platform resource implementation/modification target:

**`$ARGUMENTS`**

If no argument is given, **ask once for the implementation target** (resource · operation · filter ·
scope of change) **and stop** — do not widen the scope on your own. Edit the real sources per
`## Authoring Conventions` below, then cross-check the change (`git diff`) via `## Self-Verification`
and issue a PASS/REDO verdict.

Default target paths:

- `app/src/ApiResource/` — `#[ApiResource]` resource DTOs
- `app/src/State/` — State Provider (read) / Processor (write)
- `app/config/packages/api_platform.yaml` · `app/config/routes/api_platform.yaml` — wiring

The single source of truth (SoT) for the criteria (resource declaration · operations · serialization ·
State · validation · errors) is the rule file. Read the following and cross-check each clause — this
command does not restate the criteria.

@see .claude/rules/api-platform-rule.md — judgment criteria (SoT)
@see .claude/docs/api-platform-docs.md — step-by-step resource addition procedure
@see .claude/commands/api-platform-review.md — codebase-specific checkpoints (verification procedure)
@see .claude/rules/app-php-symfony-08-security-rule.md — security · CSRF · rate limiter
@see <https://api-platform.com/docs/symfony/> — official docs

## Authoring Conventions (essentials — details live in the rules)

- Build resources as `#[ApiResource]` DTOs under `app/src/ApiResource/` — **never expose an Entity
  directly**.
- Declare `operations:` explicitly (do not rely on the implicit default set), and wire the
  `normalizationContext`/`denormalizationContext` groups coherently with the property-level `#[Groups]`
  (separate read/write groups; group names are `{resource}:read` / `{resource}:write`).
- Implement reads with `ApiPlatform\State\ProviderInterface` and writes with
  `ApiPlatform\State\ProcessorInterface` under `app/src/State/`, and attach them to the operation via
  `provider:` / `processor:` — **delegate domain logic to a `Service`** (do not let it accumulate in the
  Provider/Processor).
- For DTO resources, **first consider reusing the built-in Doctrine provider/processor** via
  `stateOptions: new Options(entityClass: XEntity::class)` plus the Symfony Object Mapper `#[Map]`. When
  a custom one is genuinely needed, decorate the built-in processor
  (`api_platform.doctrine.orm.state.persist_processor`) with `#[Autowire]`.
- Wire filters **on the Parameter API** through the operation's `parameters:` — e.g.
  `QueryParameter(filter: new ExactFilter())`. The legacy `#[ApiFilter]` is officially discouraged, so
  avoid it in new code. Filter classes come from `ApiPlatform\Doctrine\Orm\Filter\*`
  (`ExactFilter` / `PartialSearchFilter` / `SortFilter` / `DateFilter`, etc.).
- Express pagination through the resource attributes (`paginationItemsPerPage`,
  `paginationMaximumItemsPerPage`) — **no manual LIMIT/OFFSET in a Provider**.
- Validate input with `#[Assert\...]` (per-operation differences via `validationContext` groups). Apply
  access control with the operation's `security:` (pre-denormalization) /
  `securityPostDenormalize:` (post-denormalization) / a Voter (`is_granted('X', object)`), state the
  denial reason in `securityMessage:`, and put `symfony/rate-limiter` on public endpoints. (When security
  is the primary target, use `/api-platform-oauth2-build` instead.)
- Map domain exceptions to status codes with `exceptionToStatus` (operation > resource > global), and
  expose them via `#[ErrorResource]` + `ProblemExceptionInterface` when needed — **never assemble a
  custom error response**.
- Write every PHP file assuming `declare(strict_types=1)`, `final`/`readonly`, constructor promotion
  injection, and PHPStan level 8.
- Write only complete, runnable code — no unrequested `// TODO` or placeholders, and include the `use`
  statements at the top.
- Do not guess an unconfirmed service ID, Entity class, or config key — confirm it in the rules/docs
  instead.
- **On a REDO pass, do not change anything the correction instruction did not ask for.**

## Preflight Checks

The Symfony app is not scaffolded yet — `app/` currently holds only `.gitkeep`, so every `app/**` path in
this command describes the *target* layout, not existing code. Verify each item below against the real
tree before writing anything; do not assume any of it exists.

- Does `app/src/ApiResource/` exist, and is there an `app/src/State/`? When creating the first resource,
  also confirm the `App\State\` namespace is autoconfigured in `config/services.yaml`.
- Is `justinrainbow/json-schema` installed? If not, `assertMatchesResourceItemJsonSchema()` and its
  siblings will fail — use `assertJsonContains()` + `assertResponseStatusCodeSame()` instead, and tell the
  user to run `composer require --dev justinrainbow/json-schema` first if schema assertions are actually
  needed.
- Report what is missing rather than generating code that presumes it.

## Self-Verification

Cross-check the change (`git diff`) in the order below and issue a PASS/REDO verdict. **When the verdict
is uncertain, choose REDO over PASS.**

1. Cross-check each clause of `.claude/rules/api-platform-rule.md` against the changed files (criteria SoT).
2. Sweep the codebase-specific checkpoints via `## Review Procedure` in
   `.claude/commands/api-platform-review.md` (resource declaration · serialization groups · State wiring
   and delegation · validation and errors · security · pagination and filters).
3. Confirm that each item of `## Authoring Conventions` above and `## Preflight Checks` was applied.
4. Classify findings as `[MUST]` / `[SHOULD]` / `[CONSIDER]` and cite **file:line**. A single `[MUST]`
   means REDO.

The static gates (`vendor/bin/phpstan analyse` · `vendor/bin/php-cs-fixer fix`) are recommended after a
PASS verdict; this command neither runs them automatically nor commits.

## Working Principles

- Do not touch files outside the target scope.
- Never include secret values (tokens · PII) exposed through a response group in any output.
- Once the resource is complete, hand off to the `api-platform-tester` agent when regression tests are
  needed.

## Output Format

Present the list of changed files → the self-verification verdict (PASS/REDO + findings) → a summary of
the change under the **How it works / Why this way / Next steps** headings. For a multi-file response,
state the file path in a comment before each code block.
