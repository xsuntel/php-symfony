# The debugger axis — diagnostic agent definition guide

> This document is **a template, not judgment criteria.** Frontmatter, naming and tool-minimality
> verdicts are SoT in `commands/utility-claude-code-review.md`; structure and placement in
> `rules/utility-claude-code-rule.md`. The values below are **measured 2026-09-06**, and when writing a
> new agent you should **read one or two existing files of the same kind first**.

Supplementary reference for `SKILL.md` Phase 3. The debugger axis **traces a runtime bug to its root
cause and fixes it with the minimum change.** Unlike the analyzer (which only diagnoses) it has edit
rights, and unlike the reviewer (which judges) it issues no verdict.

**Existing instances:** `app-php-symfony-debugger` · `app-twig-symfony-debugger` ·
`app-javascript-stimulus-debugger` · `api-platform-debugger` (4, code domains only).

---

## 1. Frontmatter

```yaml
---
name: {domain}-debugger
description: '{domain} work — use for {target scope}. Activate to diagnose {domain} bugs ({4–6 representative symptoms}) and trace their root cause.'
model: opus
memory: project
isolation: worktree
permissionMode: acceptEdits
maxTurns: 30
tools: Read, Grep, Glob, Bash, Write, Edit
---
```

| Key | Value | Rationale |
| --- | --- | --- |
| `maxTurns` | `30` | identical across all 4 |
| `model` | `opus` | causal reasoning is the core of the work |
| `tools` | `Read, Grep, Glob, Bash, Write, Edit` | **it holds minimal edit rights** — this is where it diverges from the analyzer |
| additional `tools` | `WebFetch, WebSearch` — **api-platform and JS only** | added only in domains that need upstream specs checked. PHP and Twig do not have them |
| `permissionMode` | `acceptEdits` | it is one of the 14 write-path agents. Without it the fix is refused under the session's read-only `plan` mode |
| `isolation` | `worktree` | all 4 are scoped to `app/**` sources |
| `color` | **omit it** | only `tools-agent-team` sets a colour. There is no per-axis palette |

**`WebFetch` and `WebSearch` are a domain judgment.** Only 2 of the 4 carry them, so do not copy them
into a new debugger unthinkingly — if the domain can be diagnosed without checking external
documentation, leaving them out is tool minimality.

**Isolation has a cost this axis feels directly.** A worktree holds tracked content only, so
vendor-dependent investigation commands (`bin/console debug:container`, `debug:messenger`, `phpstan`)
**cannot run there** unless dependencies are installed in the worktree. Expect that, and report an
unrun check as unrun rather than as a clean result.

---

## 2. Canonical skeleton (identical across all 4 domains)

```markdown
## Role
## Diagnostic Principles (strictly applied)
## Debugging Methodology
## Symptom Diagnosis Table
## Investigation Commands
## Output Format
## Role Boundaries (handoff)
## Rule Files and Helper Skill References
```

Compared with the analyzer skeleton, **there is no `## Severity Criteria` and no `## Criteria (single
source)`** — debugging establishes causation rather than issuing a verdict, so it assigns no severity,
and the SoT is reached only by `@see` from `## Rule Files`.

---

## 3. The four diagnostic principles

1. **Use sources only** — cite only facts confirmed in `app/src/` sources, `app/config/`, migrations,
   logs (`app/var/log/`) and the project rules.
2. **Do not speculate** — never invent a service ID, transport name, EntityManager name or channel name
   that is not confirmed in the code. When something cannot be confirmed, write "this information was
   not confirmed in the project files".
3. **Fix the cause, not the symptom** — a stopgap such as swallowing an exception or dodging a race with
   `sleep()` is used **only after the root cause is established, and only when justified.**
4. **Check the database for real** — verify schema and migration problems against the actual PostgreSQL
   state. Do not conclude from a mocked state. (Grounds: a past case where mocked tests passed and the
   real migration broke.)

---

## 4. The 7-step debugging methodology — do not skip steps

```text
1. Reproduce     identify which request/command/scheduler triggers it, with which exception and stack trace
2. Isolate       narrow the change scope with: git diff main...HEAD --name-only -- <target path>
3. Identify layer  determine which of Controller / Service / Handler / Repository / Doctrine /
                 Messenger / Scheduler / Security it lives in
4. Check contracts and config  verify DI wiring (debug:container), transport routing (messenger.yaml),
                 entity mapping and migration state against actual values
5. Fix the root cause  pinpoint it as file:line
6. Minimal fix   fix only the cause. Propose refactoring separately
7. Verify        confirm no regression via PHPStan level 8 plus the relevant tests
```

**Steps 2 and 4 are what this axis is worth.** Most misdiagnoses come from guessing without isolating,
or from reading only the code and never the configuration.

---

## 5. The symptom diagnosis table — this axis's core asset

**`## Symptom Diagnosis Table` accounts for more than half of a debugger definition.** It is the section
to invest the most effort in when creating a new debugger, and its format is a fixed three columns:

| Symptom | Common causes | Where to check |
| --- | --- | --- |

Some real rows from `app-php-symfony-debugger`, for format reference:

| Symptom | Common causes | Where to check |
| --- | --- | --- |
| MessageHandler never runs | worker not started · missing transport routing · missing `#[AsMessageHandler]` | `messenger.yaml`, `debug:messenger` |
| message processed twice / race | `symfony/lock` not applied at the idempotency point · lock TTL < processing time | the handler's `LockFactory` usage |
| `LazyInitializationException` | access after `em->clear()` · an entity carried across a session boundary | EntityManager lifecycle |
| changes are not persisted | missing `flush()` · **the wrong EntityManager (multi-em)** | the `--em=` target in `doctrine.yaml` |
| cache is not invalidated | no TTL set · missing tag invalidation · wrong cache pool | the `TagAwareCacheInterface` usage |
| service is not injected | autowiring failure · multiple implementations of an interface · wrong `#[Target]` | `debug:autowiring`, `debug:container {id}` |

**How to write a row:**

- **Write the symptom as the sentence a user observes** (an exception name, or "X doesn't work"). Do not
  phrase it in cause terms — if you know the cause, the diagnosis is already finished.
- **List several causes separated by `·`**, ordered by frequency with the most common first.
- **"Where to check" is a file or a command.** A description like "check the code" carries no value.
- Prioritise this repository's specific traps — **multiple EntityManagers**, the two-transport split,
  named logger channels (`#[Target('monolog.logger.{channel}')]`), and Scheduler guard placement (it
  belongs in the Handler).

Representative symptoms by domain:

| Domain | Representative symptoms |
| --- | --- |
| Twig | undefined variable · double or missing escaping · block not inherited · include/macro path error · form theme not applied |
| JS/Stimulus | controller not registered · target mismatch · Turbo update failure · memory leak · importmap resolution failure |
| API Platform | property not exposed · write field ignored · route 404 · validation returning 500 instead of 422 · 403/401 misjudgment · filter not applied · State never invoked · IRI resolution failure |

---

## 6. Role boundaries (handoff)

```text
upstream: main routing · orchestrator · {domain}-reviewer (when a runtime cause must be established)
  ↓
{domain}-debugger  ← establishes the cause + minimal fix. It issues no quality verdict
  ↓
downstream: {domain}-reviewer (judges the fix) → {domain}-tester (regression test)
            {domain}-author for structural debt (implements the refactor)
            {domain}-analyzer for a security vulnerability (severity diagnosis)
```

**Do not blur the three axes:**

| | Does | Does not |
| --- | --- | --- |
| `-debugger` | establishes the cause · **minimal fix** | severity verdicts · refactoring · adding features |
| `-analyzer` | diagnoses security vulnerabilities · assigns severity | fixing |
| `-reviewer` | judges rule compliance | fixing · tracing causes |

---

## 7. Checklist for creating a new debugger

- [ ] Does the symptom diagnosis table have **at least 8–10 rows**? A thin table means this axis
      produces no value
- [ ] Is each row's "where to check" a real file or an executable command?
- [ ] Do the commands in `## Investigation Commands` actually work (verify the `bin/console`
      subcommands exist)?
- [ ] Are `Edit` and `Write` in `tools` — a debugger has to be able to fix?
- [ ] Is `permissionMode: acceptEdits` present? Without it the fix is refused
- [ ] Does `isolation` match the domain scope (`worktree` for `app/**`), and does the body account for
      vendor-dependent commands being unrunnable there?
- [ ] Were `WebFetch` and `WebSearch` added **only where needed**?
- [ ] Is `color` absent? There is no per-axis palette
- [ ] Is there no severity table — that belongs to the analyzer and reviewer axes?
- [ ] Do all three downstream branches (reviewer, author, analyzer) actually exist?
