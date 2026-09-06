# Artifact Selection Guide

Supplementary reference for `SKILL.md` Phase 2. It decides **what to build**.

**This is not judgment criteria** — frontmatter, naming and tool minimality are SoT in
`commands/utility-claude-code-review.md`, and structure and placement in
`rules/utility-claude-code-rule.md`. This document covers **design judgment** only.

## Contents

1. [Division of labour across the 8 artifact kinds](#1-division-of-labour-across-the-8-artifact-kinds)
2. [Selection decision tree](#2-selection-decision-tree)
3. [Before adding an agent — 3 merge precedents](#3-before-adding-an-agent--3-merge-precedents)
4. [Duplication and reuse review](#4-duplication-and-reuse-review)
5. [How to avoid multiplying the SoT](#5-how-to-avoid-multiplying-the-sot)

---

## 1. Division of labour across the 8 artifact kinds

**Never build two artifacts that answer the same question.** Each kind answers a different one.

| Kind | The question it answers | When to create one |
| --- | --- | --- |
| **rule** `rules/` | *what is correct* (verdict SoT) | when criteria are missing or scattered. **Create it before the executor** |
| **agent** `agents/` | *who does it* | when an independent context genuinely raises verdict or generation quality |
| **skill** `skills/` | *in what order* (entry point) | when retry limits, gates and output paths must be controlled |
| **command** `commands/` | *by what procedure is the verdict reached* | when a user-invocable entry point is needed, or a skill reads it as self-verification criteria |
| **reference doc** `docs/` | *why it was decided that way* | when background, account and examples are too long for the rule. **Do not write criteria here** |
| **output style** `output-styles/` | *how it is written* | when domain code and response notation must be consistent. Only one is active |
| **hook** `hooks/` | *when it is blocked automatically* | when a gate must run even if a person forgets |
| **agent memory** `agent-memory/` | *what burned us last time* | when a specific agent repeatedly steps on the same trap |

**The rule comes first.** An executor built without criteria improvises its verdicts. The reverse — 
criteria with no executor — is a **normal intermediate state**: that is exactly where the analyzer axis
stood before 2026-08-22 (the security rules existed, only the executor to check against them was
missing).

---

## 2. Selection decision tree

```text
Do the judgment criteria (SoT) exist in rules/?
├── No  → build the rule first. Stop here.
└── Yes ↓

Is generation needed, or only a verdict?
├── verdict only ↓
│   ├── the user will invoke it directly → a command (-review)
│   └── only other artifacts invoke it   → keep it a command and let the skill read it
│
└── generation + verification ↓
    Does an independent context genuinely raise verification quality?
    ├── Yes → an author + reviewer agent pair (template ①)
    │         Grounds: is the output large, does it need structural-integrity
    │         verification, and are there defects that get missed when the
    │         verifier is contaminated by the generation context?
    │
    └── No  → a build command + a self-verifying skill (template ②)
              Put the conventions and checklist in one command and have
              the skill check its own output against them
```

**Where templates ① and ② are actually adopted:**

| | Template ① (agent pair) | Template ② (command self-verification) |
| --- | --- | --- |
| Adopted by | PHP · JS · Twig · API Platform · git-commit · drawio | shell script · Claude Code config |
| Grounds | in code domains the gates are external tools (PHPStan, lint), so independent execution is natural. `.drawio` needs id uniqueness and edge references checked without the generation context | the conventions are long and domain-specific, so **gathering them in one place** reduces drift |

> The five provider `*-build-skill` entries that once appeared in the ② column **do not exist on disk**
> (`[Verified]` 2026-09-06). The pattern is sound; that particular instance was never built. See §3-2.

---

## 3. Before adding an agent — 3 merge precedents

**Adding an agent is not the default.** This repository went the other way three times, and the reason
was the same every time: **to stop judgment criteria splitting across several places.**

### 3-1. 2026-08-08 — the Claude Code config domain (2 → 1)

The **2 agents** `utility-claude-code-author` and `utility-claude-code-reviewer` were merged into the
**1 command** `commands/utility-claude-code-review.md`.

- As a result this domain's SoT is **split in two** — structure and placement in the rule file, spec
  verdicts in the **command body**.
- The absence of a `utility-claude-code-style.md` output style is not an omission but a consequence of
  that split.
- Background and trade-offs are in `docs/app-agent-team-docs.md` § 3.5.

### 3-2. 2026-08-15 — the provider domain (10 → 5), **design only**

The plan merged the **10** provider author and reviewer agents into **5** `*-build.md` commands, with
five `*-build-skill` skills running a **self-verification loop** against those commands instead of
spawning agents, and the criteria (SoT) staying in the provider rule files.

> ⚠️ `[Verified]` 2026-09-06 — **none of that survives on disk.** The 5 build commands, the 5
> `*-build-skill` directories and the provider rule files were all removed in the 2026-08-15 flattening
> and were never rebuilt; **only the deletion of the 10 agents actually took effect.** Treat this
> paragraph as the **intended** end state, not the current one. The same gap is recorded in
> `rules/abstract-structure-rule.md` and `docs/abstract-orchestrator-contract-docs.md` §8.

The design intent worth carrying forward: generation conventions, the verification checklist and the
**known gaps** all live in one command body, and the criteria stay in the rules — the command owns the
procedure only.

### 3-3. 2026-08-17 — api-platform (a partially reversed case)

`agents/api-platform-author.md` was merged into 2 build commands and the agent was **repurposed** as an
analyzer. Then **on 2026-08-22 the author was revived.**

**Read the reason it came back separately from what did not come back:**

- The revival was for **symmetry** — filling the 3 app-domain authors at the same time aligned the four
  code domains' routing on the same five axes.
- **The SoT for the generation conventions is still the two build commands.** The revived author
  references them via `@see` rather than duplicating them, so the original "avoid triplicating the
  criteria" premise still holds.
- The same reasoning is why the two build commands **do not carry their own** `## Verification
  Checklist` — `api-platform-reviewer` and `commands/api-platform-review.md` both survived, so a third
  copy would have triplicated the criteria.

**The lesson:** adding an executor (an agent) and adding criteria (an SoT) are **different decisions**.
Adding an executor for symmetry is fine; that executor duplicating the criteria is not.

---

## 4. Duplication and reuse review

Before creating something new, check it against the existing artifacts. Repeatedly extending a harness
tends to accumulate overlapping roles under different names.

| Situation | Action |
| --- | --- |
| an existing artifact **fully covers** the new role | do not create — reuse it and extend only the trigger phrasing |
| **partial** coverage that can be generalized | generalize and extend the existing one. First check how the dependent orchestrators and rosters change |
| partial coverage where the **specialization is intended** | proceed with the new artifact — keep them separate |
| the role scopes are **entirely different** | proceed with the new artifact |

**How far to generalize** — generalization is unbounded, so stop at the **intended scope of
responsibility**. Remove accidental coupling and keep intended specialization.

Worked example, using the naming shape the provider skills were designed around:

| Step | Result | Judgment |
| --- | --- | --- |
| remove the UPbit coupling | "digital-asset REST client" | JWT signing and endpoints differ per provider, so this is **intended** specialization. Stop |
| remove the REST coupling | "HTTP client guide" | `app-php-symfony-skill` already covers it. Do not build it |

**The more one artifact focuses on one role, the more reusable it is and the less it duplicates.** If it
carries two or more roles, check first whether they can be separated.

---

## 5. How to avoid multiplying the SoT

The cost this repository has paid repeatedly is **the same criteria living in several files.** These
rules prevent it.

- **Write criteria in exactly one place.** Point at it with `@see` from everywhere else. When citing a
  section number, verify the section actually holds that content — **number drift is common**, and a
  live example is the `docs/app-agent-team-docs.md` "§2.4" that several documents cited until
  2026-09-06 despite no such section existing.
- **Do not write judgment criteria in a reference document (`docs/`).** It is not auto-applied and the
  rule wins on conflict. Giving it `paths` frontmatter is a `[MUST]` violation.
- **Duplication between an orchestrator prompt and a rule is the exception, and it is intended.** A
  sub-agent starts from an empty context and cannot reach an `@see`, so the instruction must physically
  be present. **Rationale and measurements are not duplicated**, though — those live only in
  `docs/abstract-orchestrator-contract-docs.md`.
- **Share the slug.** The same domain and subject use the same slug across kinds, and that sharing is
  what lets `@see` references find one another.

  ```text
  rules/utility-shell-script-rule.md
  commands/utility-shell-script-review.md
  docs/utility-shell-script-docs.md
  output-styles/utility-shell-script-style.md
  skills/utility-shell-script-skill/SKILL.md
  ```

  **Renaming one kind alone breaks the others' `@see` and the rule's `paths` at the same time.** Rename
  only when every related kind moves in the same change.
