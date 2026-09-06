# The tester axis — test-writing agent definition guide

> This document is **a template, not judgment criteria.** Frontmatter, naming and tool-minimality
> verdicts are SoT in `commands/utility-claude-code-review.md`; structure and placement in
> `rules/utility-claude-code-rule.md`. The SoT for test layer boundaries is
> `rules/app-php-symfony-09-testing-rule.md`. The values below are **measured 2026-09-06**, and when
> writing a new agent you should **read one or two existing files of the same kind first**.

Supplementary reference for `SKILL.md` Phase 3. The tester axis **writes regression-preventing tests
through a TDD cycle.** It carries the largest `maxTurns` of the five axes (45) and the longest body,
because it holds several per-layer templates.

**Existing instances:** `app-php-symfony-tester` · `app-twig-symfony-tester` ·
`app-javascript-stimulus-tester` · `api-platform-tester` (4, code domains only).

---

## 1. Frontmatter

```yaml
---
name: {domain}-tester
description: '{domain} work — use for {target scope}. Activate to write {test kind} verifying {what is verified}.'
model: opus
memory: project
isolation: worktree
permissionMode: acceptEdits
maxTurns: 45
tools: Read, Grep, Glob, Bash, Write, Edit
---
```

| Key | Value | Rationale |
| --- | --- | --- |
| `maxTurns` | **45** | identical across all 4, and **the only value above 30 on any axis** — a Red-Green-Refactor cycle runs six or more gate commands per invocation. Do not flag the higher value as a deviation, and do not copy it onto another axis |
| `model` | `opus` | designing test cases is open-ended work |
| `tools` | `Read, Grep, Glob, Bash, Write, Edit` | it writes test files and runs `phpunit` |
| additional `tools` | `WebFetch, WebSearch` — `api-platform-tester` only | upstream spec checking |
| `permissionMode` | `acceptEdits` | it is one of the 14 write-path agents. Without it the Green phase is refused under the session's read-only `plan` mode |
| `isolation` | `worktree` | all 4 are scoped to `app/**` sources |
| `color` | **omit it** | only `tools-agent-team` sets a colour. There is no per-axis palette |
| `effort` | **omit it** | `[Verified]` 2026-09-06 — **no agent in the repository sets `effort` or `background`.** Do not add either on the theory that testing is heavy |

> **Isolation collides with this axis harder than any other.** A worktree holds tracked content only, so
> **`vendor/bin/phpunit` cannot run there** unless the agent installs dependencies in the worktree.
> Establish whether the suite can run at all before starting the cycle, and if it cannot, report that as
> a **precondition failure** rather than as a test failure.

---

## 2. Canonical skeleton

```markdown
## Role
## Layer Selection (decide first)
## TDD Cycle (Red-Green-Refactor)
## Absolute Rules
## Mocking Boundaries (strictly applied)
## Test Templates per {layer}       ← 3–6 per domain
## Public URL Smoke Test (mandatory)
## URL Hardcoding Principle
## Execution
## Turn Budget (against maxTurns exhaustion)
## Role Boundaries (handoff)
## Rule Files and Helper Skill References
```

`api-platform-tester` alone adds `## Known Gaps (verified — reflect before writing)` and
`## operation × case matrix`.

---

## 3. Layer selection — decide this first

The nature of the target fixes the layer, and the layer fixes the base class, directory and I/O.

| Target | Layer | Base class | Directory | I/O |
| --- | --- | --- | --- | --- |
| pure-logic Service · value computation · Entity invariants · Enum · DTO validation | Unit | `TestCase` | `app/tests/Unit/{Domain}/` | none |
| Repository queries · MessageHandler · Doctrine mapping · cache integration | Integration | `KernelTestCase` | `app/tests/Integration/{Domain}/` | real PostgreSQL + Redis |
| Controller · HTTP responses, redirects, rendered HTML | Functional | `WebTestCase` | `app/tests/Functional/{Domain}/` | HTTP layer |
| API operation (JSON-LD · validation · authorization) | Functional | `ApiTestCase` | `app/tests/Functional/{Domain}/` | HTTP layer |

> ⚠️ **`[Verified]` 2026-09-06 — the Symfony application is not scaffolded yet.** `app/` contains only
> `.gitkeep`: there is no `app/src/`, no `app/tests/`, and no `app/vendor/`. **Every `app/**` path in
> this document is a target shape, not an existing tree.** State this in the tester body, or a missing
> directory gets misread as an environment error — and more importantly, do not report a test as
> written and passing when the suite cannot exist yet.

---

## 4. The TDD cycle — classify the reason RED failed

One cycle handles **one logical fact** only. Do not write several cases and make them pass later.

### RED — see the failure with your own eyes

Express the not-yet-existing behaviour as a test **first**. Do not read the implementation and
back-derive the test. **Always run it and confirm the failure** — never move to GREEN without executing.

**This is the most important table on this axis.** Mistaking an environment problem for RED leads to
implementing a feature that does not exist:

| Observation | Interpretation | Next step |
| --- | --- | --- |
| assertion failure (expected ≠ actual) | **a true RED** | proceed to GREEN |
| `Class ... not found` | **a true RED** (the specification does not exist yet) | create the minimal class in GREEN |
| `Service ... not found` (not registered in DI) | **a true RED** | wire the service in GREEN |
| **DB connection failure · migrations not applied** | **an environment problem — not a RED** | report the precondition and **abort the cycle** |
| **`vendor/bin/phpunit` not found** | **an environment problem — not a RED** | report the precondition and **abort the cycle** |

Do not mistake a failure caused by PostgreSQL or Redis not being up, or by dependencies being absent in
an isolated worktree, for a RED.

### GREEN → Refactor

Implement the **minimum** code that passes, and only then tidy up.

---

## 5. Mocking boundaries

The grounds for this section are **a case where mocked tests passed and the real migration broke.** The
judgment criteria live in `rules/app-php-symfony-09-testing-rule.md`, which the tester reaches by `@see`.

| Mock it | Do not mock it |
| --- | --- |
| external HTTP provider responses (UPbit · KoreaInvestment · ECOS · KOSIS) | Doctrine schema and migrations |
| time and randomness | the actual execution of Repository queries |
| notification delivery | transport routing |

---

## 6. Coverage criteria — the operation × case matrix

`api-platform-tester`'s matrix is canonical. The principle — **do not write only the happy path** — is
the same in the other domains.

| operation | success | validation failure | authorization denied | not found |
| --- | --- | --- | --- | --- |
| `GetCollection` | 200 + Hydra collection | — | 401 / 403 | — |
| `Get` | 200 | — | 401 / 403 | 404 |
| `Post` | 201 | **422** | 401 / 403 | — |
| `Patch` | 200 | **422** | 401 / 403 | 404 |
| `Delete` | 204 | — | 401 / 403 | 404 |

**Omitting 422 is the most common gap** — a defect where validation leaks out as a 500 never surfaces if
only the happy path is tested.

**The public URL smoke test is a mandatory section** (all 4 have it). It is the cheapest way to catch
rendering or routing being broken outright.

---

## 7. Execution and turn budget

```bash
cd app
vendor/bin/phpunit --filter {Name}Test      # during a cycle
vendor/bin/phpunit --testsuite Unit         # per layer
vendor/bin/phpunit                          # everything
```

`maxTurns: 45` is the largest on any axis, but **RED→GREEN repetition consumes turns quickly.**

- If the cycle keeps failing, **narrow the scope and report** — do not keep looping automatically.
- Leave the partial output and **state that it is incomplete**. Never report a non-passing test as done.
- **If you aborted on an environment problem, report that as a precondition** — not as a test failure.
- Exhaustion is not signalled by the harness below CLI 2.1.246 (this repository runs 2.1.236), so detect
  it yourself.

---

## 8. Role boundaries (handoff)

```text
upstream: {domain}-reviewer (regression prevention after the [MUST]s are cleared) ·
          {domain}-author (after generation) · {domain}-debugger (regression test after a fix)
  ↓
{domain}-tester  ← writes tests only. It does not design production code
  ↓
downstream: {domain}-debugger when a failure is a production defect (establish the cause)
            {domain}-author when a design change is needed
```

**A tester does not make large production-code changes to force a GREEN** — anything beyond the minimal
implementation is handed to the author.

---

## 9. Checklist for creating a new tester

- [ ] Is the **layer selection table** present — four columns of base class, directory and I/O?
- [ ] Is the **RED failure classification table** present? Mistaking an environment problem for a RED is
      this axis's signature failure
- [ ] Are the per-layer templates **runnable code** (do the base classes and namespaces exist)?
- [ ] Does the body state that `app/` is not scaffolded yet, so a missing directory is not an
      environment error?
- [ ] Does coverage include the **failure cases (422 · 401/403 · 404)**?
- [ ] Is there a public URL smoke test section?
- [ ] Are the mocking boundaries stated — especially **do not mock the DB or migrations**?
- [ ] Are `maxTurns: 45` and the turn budget section both present?
- [ ] Are `color` and `effort` **absent**? No agent sets either
- [ ] Is `permissionMode: acceptEdits` present, and does `isolation` match the domain scope?
- [ ] Is the test-layer SoT (`app-php-symfony-09-testing-rule.md`) referenced with `@see`?
