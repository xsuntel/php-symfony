# Artifact Authoring Guide

Supplementary reference for `SKILL.md` Phase 5. It covers the points where writing a `description` or a
body **fails silently**.

**This is not judgment criteria** — required frontmatter keys, permitted values and tool minimality are
SoT in `commands/utility-claude-code-review.md`. This document holds only the **authoring technique**
for satisfying those criteria.

## Contents

1. [YAML frontmatter — the trap that truncates a value](#1-yaml-frontmatter--the-trap-that-truncates-a-value)
2. [Writing a description — budget and truncation](#2-writing-a-description--budget-and-truncation)
3. [Stating trigger boundaries](#3-stating-trigger-boundaries)
4. [Body-writing principles](#4-body-writing-principles)
5. [Progressive disclosure](#5-progressive-disclosure)
6. [Naming — 64 characters and the suffix](#6-naming--64-characters-and-the-suffix)

---

## 1. YAML frontmatter — the trap that truncates a value

**In an unquoted scalar, `space + #` starts a comment.** Everything from there to the end of the line is
**silently discarded.** The parser raises no error and returns the shortened value, so if review misses
it, it never surfaces.

The most common trigger in this repository is **a PHP 8 attribute used as trigger phrasing**:

```yaml
# Wrong — the value is cut off before '#[ApiResource]'
description: Handles API Platform resources. Use when declaring #[ApiResource].

# Right — wrap it in single quotes
description: 'Handles API Platform resources. Use when declaring #[ApiResource].'
```

- **Use single quotes by default.** Double quotes interpret `\` as an escape and break on values like
  `#[ORM\Column]`. Escape an apostrophe inside the value by doubling it (`''`).
- For the same reason, a `: ` (colon-space) inside the value, a leading `|`, `>`, `&`, `*` or `!`, and
  leading or trailing whitespace all require quoting.
- **A violation is a `[MUST]`** — on a skill the trigger phrasing vanishes from the listing and
  natural-language matching fails; on an agent the basis for the delegation decision vanishes.

The full-sweep detection script is in `harness-verification-guide.md` §4.

---

## 2. Writing a description — budget and truncation

`description` is the **only trigger mechanism** a skill or agent has. Yet **writing a long one is itself
risky** here, because the tail disappears first.

| Constraint | Value | Consequence |
| --- | --- | --- |
| spec cap | 1–1024 characters | over it violates the spec |
| listing truncation | `description` + `when_to_use` combined, **1,536 characters** | over it gets cut. Configurable via `skillListingMaxDescChars`; treat 1,536 as the default, not a hard limit |
| listing budget | a fraction of the context window, set by `skillListingBudgetFraction` | when it overflows, the least-used skills have their **description dropped entirely** |

> `[Verified]` 2026-09-06 — **`skillListingBudgetFraction` is not set in this repository's
> `settings.json` or `settings.local.json`**, so the harness default applies. Do not cite a specific
> local percentage as a measured value.

**So put the key use case at the very front.** The further back a trigger phrase sits, the sooner it
disappears.

```text
[front]  what it does + the 2–3 most important triggers
         ↓
         secondary trigger phrasing
         ↓
[back]   boundary conditions ("but do not use it for …")   ← the first thing lost when the budget overflows
```

A lost boundary condition produces **over-triggering**, so for a skill whose boundary matters most, keep
that sentence short and pull it forward.

**Form:**

- Write in the **third person**, covering both "what it does" and "when it triggers".
- List the **natural-language trigger phrases** a user would actually type, in quotes (for example
  `'write me a commit message'`, `'is it safe to deploy'`).
- Where the skill should match regardless of the language the user writes in, use the repository's
  existing idiom **`(in any language)`**, as `utility-git-commit-skill` does.
- **Weak example:** `"a skill that deals with Redis"` — no task, no trigger occasion.
- **Strong example:** `cache-redis-skill`'s actual description, which lists API symbols
  (`CacheInterface`, `invalidateTags`, `#[Target]`) so it matches from code context too.

**Judge a budget overflow from the listing** — you do not need `/doctor`. If an entry shows a `name`
with no description, the budget overflowed. If it is **absent from the listing entirely**, that is not a
budget problem but **discovery failure**, and raising the budget will not fix it (it is a placement
problem).

---

## 3. Stating trigger boundaries

`[Measured]` 2026-09-06 — there are **35 entry points** (22 skills + 13 commands), so **ambiguous
requests are common**. If the description does not state the boundary, the wrong one is selected.

**The three boundary sentence forms actually in use:**

| Form | Example |
| --- | --- |
| **hand off to another artifact** | `Do not use it when only a quality review is needed — use the /api-platform-review command instead` |
| **exclude an already-complete command** | `Do not use it for a complete command already given, such as "run gcloud run deploy ..."` |
| **authoring vs. asking** | `Do not use it for simple questions about features or usage that do not author or modify a config file` |

**When mentioning a skill, use the full directory name rather than an abbreviation** — this keeps the
invocation identifier and the documented name from diverging (`cloudrun-skill` ✗ →
`tools-gcp-cloudrun-skill` ✓).

---

## 4. Body-writing principles

| Principle | Why |
| --- | --- |
| **Explain the why** | giving the rationale rather than "ALWAYS/NEVER" lets the model judge edge cases correctly. It is why this repository's documents narrate decisions with dates |
| **Do not duplicate criteria** | point at the SoT with `@see`. Duplicating adds a source of drift and makes it impossible to say which copy is right |
| **Write imperatively** | an artifact is an instruction sheet, not a manual |
| **Write in English** | the repository's `.md` convention per `CLAUDE.md § Documentation Language`. `abstract-korean-style.md` is the sole exemption, because a style specifying Korean responses has to demonstrate them |
| **State the silent failures** | the most expensive defects here are the ones that raise no error. Write "if these diverge, it silently …" into the body so review catches it |
| **Read a same-kind file first** | do not invent a new convention. Take the frontmatter, tone and section structure from one or two existing files |

**What not to include:** ancillary documents like a README or CHANGELOG, meta-information about the
authoring process, user-facing manuals (an artifact is an instruction sheet for an agent), and general
knowledge the model already has.

---

## 5. Progressive disclosure

A skill loads in three stages. **Context is a common resource**, so respect each stage's budget.

| Stage | Loaded when | Target |
| --- | --- | --- |
| `name` + `description` | always in context | within 1024 characters, key material first |
| `SKILL.md` body | on skill trigger | **within 500 lines** |
| `references/` | only when needed, via `Read` | no cap |

- As the body approaches 500 lines, split the detail into `references/` and leave a pointer in the body
  saying **when to read that file**. A split without a pointer means the file is never read.
- **Give any reference file over 300 lines a table of contents.**
- **The sub-directory names are `references/`, `scripts/` and `assets/`** (the official bundled-resource
  names). Only the skill root is subject to the flat single-tier constraint; **the directories inside it
  are unconstrained**.

---

## 6. Naming — 64 characters and the suffix

The verdict SoT is `rules/utility-claude-code-rule.md`; below are only the points most easily got wrong
while authoring.

- **`name` character rules** — 1–64 characters, lowercase alphanumerics and hyphens only, no leading or
  trailing hyphen, **no consecutive hyphens (`--`)**.
- **Which constraints come from where.** The 64-character limit, the character set and the reserved
  words (`anthropic`, `claude`) are requirements of the **Agent Skills spec and the Skills API** — the
  packaging and upload path. **Claude Code does not enforce them on a project skill**, which is why
  `utility-claude-code-skill` legitimately carries a reserved word. Never raise that as a finding unless
  a skill is being prepared for packaging.
- **64 characters is nonetheless a real constraint in design.** Do not transcribe every path segment —
  keep only the minimum needed to identify the artifact. The provider skill naming exercise is the
  cautionary case: intermediate forms exceeded 64 characters because they carried the full
  classification hierarchy (`providers`, `finance`, `digitalasset`). **The four axes worth keeping** are
  the domain prefix, the provider identifier, the transport layer and the role. (Design history — those
  skills do not exist on disk; see `artifact-selection-guide.md` §3-2.)
- **The suffix is a collision-avoidance device, not a notational preference.**
  `.claude/commands/<name>.md`, `.claude/skills/<name>/`, `.claude/workflows/<name>.js` and the
  built-ins **share one `/` namespace**, and identical names mean one silently shadows the other. This
  repository has zero collisions across 35 entry points precisely because of the `-skill` /
  `-review` · `-build` · `-test` split.
- **`abstract-` is the permitted non-domain prefix.** A skill bound to no domain takes it instead of
  borrowing a domain prefix; the three `abstract-*-engineering-skill` directories are the instances. It
  relaxes nothing else — the `-skill` suffix, the 64-character cap and `name` = directory name all still
  apply.
- **The harness does not enforce `directory name = name`.** A mismatch produces two diverging identities
  with no error, so **review has to catch it** (`[MUST]`).
- **Rename only when every related kind moves in the same change.** The skill `name`, the reference name
  in a routing table and the command namespace always change together — fixing one side makes the
  artifact uninvocable, and `ls -d .claude/skills/*/ | wc -l` will not catch it.
