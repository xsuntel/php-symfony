# The reviewer axis — verdict agent definition guide

> This document is **a template, not judgment criteria.** Frontmatter, naming and tool-minimality
> verdicts are SoT in `commands/utility-claude-code-review.md`; structure and placement in
> `rules/utility-claude-code-rule.md`. The values below are **measured 2026-09-06**, and when writing a
> new agent you should **read one or two existing files of the same kind first**.

Supplementary reference for `SKILL.md` Phase 3. The reviewer is **the largest axis in the repository**
(12 agents) and the only one present across all three families — code, infrastructure and utility.

**Existing instances:** 4 code (`app-php-symfony` · `app-twig-symfony` · `app-javascript-stimulus` ·
`api-platform`) · 6 infrastructure (`cache-redis` · `database-postgresql` · `message-rabbitmq` ·
`server-nginx` · `tools-gcp-cloudrun` · `tools-aws-ecs`) · 2 utility (`utility-git-commit` ·
`utility-drawio-diagram`).

---

## 1. Frontmatter

```yaml
---
name: {domain}-reviewer
description: '{domain} work — use for {target scope}. Activate to review the quality ({3–4 inspection axes}) of {target files} after creating or modifying them.'
model: sonnet
memory: project
maxTurns: 30
tools: Read, Grep, Glob, Bash
disallowedTools: Edit, Write
---
```

| Key | Value | Rationale |
| --- | --- | --- |
| `maxTurns` | `30` | identical across all 12 |
| `model` | **`sonnet` — all 12** | see the note below |
| `tools` | `Read, Grep, Glob, Bash` — **no write** | the deliverable is findings and fix fragments |
| `disallowedTools` | `Edit, Write` | **this line is the enforcement** — see §2 |
| additional `tools` | `WebFetch, WebSearch` on 4 of 12 — `api-platform`, `cache-redis`, `database-postgresql`, `message-rabbitmq` | added only where upstream specs must be checked. The `app-*` reviewers, `server-nginx`, `tools-aws-ecs` and `tools-gcp-cloudrun` do not have them |
| `isolation` | `worktree` on the 3 `app-*` reviewers only | the convention follows domain scope. **`api-platform-reviewer` deliberately omits it** — it is the only non-isolated member of its own roster, which is what lets it read a tmp artifact the other four cannot. Adding `isolation` there is a `[MUST]` |
| `color` | **omit it** | only `tools-agent-team` sets a colour. There is no per-axis palette |
| `permissionMode` | **omit it** | a reviewer must not acquire edit acceptance |

### The two utility reviewers are the deliberate exception

`utility-git-commit-reviewer` and `utility-drawio-diagram-reviewer` declare
`tools: Bash, Read, Write, …` with `disallowedTools: Edit` — they **hold `Write`** because their verdict
goes to a `.claude/tmp/` file. They are still read-only in role: they judge, they do not author. Do not
copy that shape into a code-domain reviewer, whose findings belong in the returned report.

### On `model` — do not read the uniformity as an accident

`[Verified]` 2026-09-06 — **every one of the 12 reviewers is `sonnet`.** The rationale recorded in
`docs/app-agent-team-docs.md` is that a review is *a bounded verdict against a written rule (SoT)*:
enumerate the checklist, cite `file:line`, label MUST/SHOULD/CONSIDER. That is comparison work, and the
whole axis qualifies — which is why the split is by **role**, not by domain.

Choose a new reviewer's `model` from **the nature of the verdict**, and expect the answer to be sonnet.
Reach for opus only if you can state what open-ended reasoning the verdict requires that a written rule
does not already supply — and record that reasoning, because it would make the agent the first
exception in the axis.

---

## 2. It does not edit the source directly

`memory: project` makes the harness grant `Write` and `Edit` regardless of the `tools` list — but
**`disallowedTools` reverses that grant per tool**, so on the 10 reviewers that declare
`disallowedTools: Edit, Write` an edit call **fails outright**. Read-only is harness-enforced here.

Two consequences:

1. **Never assign a code-domain reviewer a tmp output path.** It cannot write, so the spawn fails at its
   last step. Ask for findings **in the returned report**.
2. State the norm in `## Role` anyway — the model should know *why*, not merely be blocked:

> **If the reviewer fixes it, the author→reviewer loop loses its independent verdict.**

Present fix fragments, but **do not apply them to files.**

---

## 3. Canonical skeleton

```markdown
## Role
## Criteria (single source: the rules [+ docs + output style])
## {domain-specific section}      ← the only axis where this varies per domain
## Review Procedure
## Quality Gates (the core; detailed verdicts live in the rules)
## Role Boundaries (handoff)
```

**The `## Criteria` section determines the character of a reviewer definition.** This agent **holds no
criteria or templates of its own** — it `Read`s the relevant SoT at the start of the work and applies
it. Duplicating criteria into the body forks them from the rule and makes it impossible to say which is
right.

The actual shapes of `## {domain-specific section}`:

| Domain | Section name |
| --- | --- |
| PHP | `## Namespace Conventions` + `## Transport Selection` |
| Twig | `## Template Path Conventions` + `## Verification Commands` |
| JS/Stimulus | `## Component Selection (lowest complexity first)` + `## AssetMapper Essentials` |
| API Platform | `## Focus Areas` |

**This section is a quick-reference table, not judgment criteria** — it exists to identify the layer
before reading the rules, and stays short, around seven rows.

---

## 4. Severity protocol

Findings are separated into three values — **`[MUST]` / `[SHOULD]` / `[CONSIDER]`** — and **only
`[MUST]` blocks a merge.**

- This protocol has to be identical across all 12 so the orchestrator can **merge and sort several
  reviewers' results on one scale**. A new reviewer using a different scale mixes them at consolidation.
- The analyzer's Critical/High maps to `[MUST]`, Medium to `[SHOULD]`, Low to `[CONSIDER]`.
- **Duplicate findings on the same file and line merge into one at the strictest severity**, and that
  merge is performed by **the orchestrator, not the reviewer**. Several reviewers matching at once
  across domains is normal.
- **An improvement that requires a structural change is offered as `[CONSIDER]` only** and never applied
  without approval.

---

## 5. Quality gates — a summary of the rules, not a replacement

Keep the `## Quality Gates` section short, around **seven check items**. That is exactly why its heading
reads *"(the core; detailed verdicts live in the rules)"*.

`app-php-symfony-reviewer`'s shape, for reference:

1. Is `declare(strict_types=1)` the first statement?
2. Is every class `final` (documented exceptions aside)?
3. Is there no `mixed` without a type guard — does it pass PHPStan level 8?
4. Are injected dependencies typed `readonly` promoted properties?
5. Is the Repository free of N+1 risk (`JOIN FETCH`)?
6. Are logs wrapped in a debug guard and on a named channel?
7. Is a `symfony/lock` acquired before a write where idempotency matters?

**Do not grow the gates to twenty** — at that point they become a copy of the rules and go stale
silently when the rules change. Keep only "the things most often got wrong".

---

## 6. Interface cross-checking — "read both sides at once"

**The most expensive defects are the ones where two components are each individually "correct" but the
contract between them disagrees.** Reading one side makes both look fine, so **always open both sides
together** and compare.

| Interface | Producer (left) | Consumer (right) | Why it gets missed |
| --- | --- | --- | --- |
| template ↔ controller | the `data-{controller}-target` value in Twig | the Stimulus `static targets` array | each is syntactically fine. A name mismatch is `undefined` **only at runtime** |
| resource ↔ State | the serialization groups on `#[ApiResource]` | the shape the State Provider returns | a property missing from the group vanishes from the response **with no error** |
| message ↔ handler | the routing in `messenger.yaml` | the `#[AsMessageHandler]` declaration | without routing **the dispatch still succeeds**; only the handler never runs |
| entity ↔ migration | the `#[ORM\Column]` mapping | the actual DDL in `migrations/` | mocked tests pass and **the real migration breaks** |
| multi-EM ↔ usage | the EntityManager definitions in `doctrine.yaml` | the injection target in a Service or Handler | `flush()` on the wrong em **silently fails to persist** |
| cache pool ↔ injection | `cache_pool_*` in `cache.yaml` | the channel name in `#[Target(...)]` | a wrong channel name writes to a different pool and **invalidation stops working** |
| roster ↔ hook | the orchestrator's routing table | the `case` table in `agent-roster-guard.sh` | fixing one side alone gets the spawn **blocked with `exit 2`** |

**Prefer "cross-comparison" over "existence check" in a checklist:**

| Weak item | Strong item |
| --- | --- |
| does the handler exist? | is the handler **actually consumed on the routed transport**? |
| are serialization groups declared? | do the declared groups **cover every property the Provider returns**? |
| are the targets defined? | do the template's `data-*-target` names **match down to the spelling**? |

**Do not read a static gate passing as evidence of behaviour** — `phpstan` and `lint:twig` passing
catches none of the interfaces above. That is why this section exists. Under `isolation: worktree` the
point is sharper still: vendor-dependent gates cannot run in the worktree at all, so treat their absence
as **"not run"**, never as a pass.

---

## 7. Role boundaries (handoff)

```text
upstream: main routing (after a code change) · {domain}-author (after generation) ·
          {domain}-analyzer (after a security diagnosis) · {domain}-debugger (after a fix)
  ↓
{domain}-reviewer  ← the sole verdict. It does not fix
  ↓
downstream: {domain}-tester (clear the [MUST]s · prevent regressions)
            {domain}-debugger when a runtime cause must be established
            {domain}-author for structural debt (implements the refactor)
            {domain}-analyzer for a security vulnerability (severity diagnosis)
```

**When reviewing an isolated author's work**, expect the diff to arrive **inline in the prompt**. If you
are pointed at a path and told to run `git diff`, and the diff comes back empty, that is the known
failure mode — **report "cannot judge (diff not received)" rather than returning PASS.** A PASS on work
never read is the most damaging silent failure available here.

**Cross-domain:** overlapping change paths can match several reviewers at once (for example a PHP change
also matching `database-postgresql-reviewer`, `cache-redis-reviewer` and `message-rabbitmq-reviewer`).
That is normal, and **merging duplicate findings is the orchestrator's job**.

---

## 8. Checklist for creating a new reviewer

- [ ] **Do the judgment criteria (rules) already exist?** A reviewer holds none — if not, create the
      rule first
- [ ] Does `## Criteria` reference the SoT with `@see` and **not duplicate** it?
- [ ] Is the `[MUST]`/`[SHOULD]`/`[CONSIDER]` protocol present, with the **only `[MUST]` blocks**
      sentence?
- [ ] Is `disallowedTools: Edit, Write` present, and does the body also state why it does not fix?
- [ ] Are the quality gates **around seven items** — has it become a copy of the rules?
- [ ] Are there interface cross-check items — which contracts does this domain straddle?
- [ ] Is `model: sonnet`? If not, is the open-ended reasoning that justifies opus written down?
- [ ] Are `color` and `permissionMode` absent?
- [ ] Does `isolation` match the domain scope, and is the inline-diff expectation stated if the paired
      author is isolated?
- [ ] If a paired `{domain}-author` exists, does the REDO path hold — if not, this is a standalone
      verdict axis
