---
name: utility-git-commit-style
description: Output presentation and formatting style for authoring and reviewing Git commit messages (Conventional Commits). Governs how a message is presented, its layout, and its artifact formats.
keep-coding-instructions: true
---

# Git Commit Output Style

This document governs **output presentation and formatting**. The judgment criteria for the message
content (language · format · allowed types · scope derivation · subject/body rules · factual agreement)
are owned by the rule as the single source of truth (SoT), and the type-selection guide, good/bad
examples, and anti-patterns are held by the reference document — **neither is restated here**.

@see .claude/rules/utility-git-commit-rule.md — commit message judgment criteria (SoT)
@see .claude/docs/utility-git-commit-docs.md — type table · scope examples · good/bad · anti-patterns · checklist
@see .claude/skills/utility-git-commit-skill/SKILL.md — author→reviewer orchestration entry point

## Standards Compliance (summary — detail in the SoT above)

- A commit message is **English in both subject and body**, unconditionally.
- The subject is `type(scope): subject`, 72 characters or fewer, imperative mood, no trailing period.
- The body is 3 lines or fewer and focuses on the *why*. Every claim must be verifiable from
  `git diff --cached`.

## Language Boundary

Two languages coexist in one response. Fix their placement.

| Element | Language |
| --- | --- |
| The commit message body (inside the code block) | English, always |
| Explanation, rationale, and verdict reasons about the message | The active output style's conversation language |
| Quoted identifiers such as types and scopes | Verbatim (`feat` · `app`) |

The commit message is English regardless of which output style is active — it is text that will live in
`git log`. The surrounding prose follows whichever conversation language the active output style
prescribes; `CLAUDE.md` `## Response Constraints` names `settings.json` (`outputStyle`) as the SoT for
that, so never hardcode a language here.

Do not translate the English message inside the code block and present both side by side — it makes it
ambiguous which text the user is meant to commit.

## Response Format

- Always place a commit message inside a fenced ` ```text ` **code block**. Never let it run inline
  through prose — the user has to be able to copy it verbatim.
- Put **only the message body** in the code block. Do not mix in a command such as `git commit -m`, a
  `>` quote marker, or line numbers.
- **Do not list several candidates.** Pick one and give the rationale for that choice in a line or two
  below it. When an alternative is genuinely viable, add its trade-off in one line.
- Put any command to be run in a **separate ` ```bash ` block**, apart from the message block.

```text
fix(app): reuse cached access token in REST client

Re-issuing a token on every call tripped the provider rate limit.
Reuse the Redis-cached token until TTL expires.
```

```bash
git commit -F ./.claude/tmp/utility/git/commit-message-draft.md
```

## Message Layout

```text
<type>(<scope>): <subject>      ← 1 line, 72 characters or fewer
                                ← exactly 1 blank line (only when a body follows)
<body line 1>                   ← hard-wrapped at 72 characters per line
<body line 2>
```

- With no body, end at the subject line — do not leave a trailing blank line behind.
- **Hard-wrap each body line at 72 characters.** Git does not wrap automatically, so a long single line
  appears truncated in `git log` output.
- Do not use markdown in the body — bullets (`-`), headings (`#`), and emphasis (`**`) surface in
  `git log` as literal symbols. Join multiple points into sentences.
- Do not append an issue number to the subject (no `... (#123)`).

## Footers and Trailers

- **This repository does not use commit footers.** Do not add issue trailers (`Refs:` · `Closes:`) on
  your own initiative — there is no precedent, so the format would diverge.
- **Do not add a Co-authored-by trailer** — `settings.json` sets `attribution.commit` to `""`, which
  hides the trailer Claude Code would otherwise add. (This replaced the deprecated
  `includeCoAuthoredBy: false` on 2026-08-30; the documented mapping is exactly `attribution.commit: ""`.)
- A `BREAKING CHANGE:` footer is the sole exception, permitted only for a backward-incompatible change.
  In that case leave a blank line between the body and the footer, and tell the user why the footer is
  present.

## Artifact File Formats

The intermediate artifacts of the author→reviewer loop live in `.claude/tmp/utility/git/` (registered
in `.gitignore`). When writing them via Bash, run `mkdir -p .claude/tmp/utility/git` first — the
**full** parent chain, or the write fails.

**`commit-message-draft.md`** — the file `git commit -F` reads verbatim. Put no markdown headings, code
fences, or explanations in it. It holds **the raw commit message only**.

**`commit-message-review.md`** — the verdict artifact. Write only these three items.

```text
Verdict: PASS | REDO
Reason: [2-3 lines in the active conversation language — name the checklist items violated]
Revision instructions: [REDO only — specific enough for the author to apply directly]
```

## Inline Explanation Format

Only the headings below may follow the message block. Omit any of the three that are not needed.

- **Selection rationale** — why the type and scope were chosen that way, 1-3 items
- **Diff cross-check** — which change each claim in the subject and body came from
- **Next steps** — a proposal to split the staging, retry guidance, etc. (only when relevant)

Prohibited: a preamble such as "Here is the commit message:", restating a summary of what was just
written, and filler phrases such as "Great question" or "Certainly".

## Presentation Anti-patterns

| Anti-pattern | Why | Alternative |
| --- | --- | --- |
| Listing 3-4 candidates | Pushes the judgment onto the user | Pick one and state the rationale |
| Presenting the message as prose with no code block | The copy boundary is ambiguous | A ` ```text ` block |
| Including `git commit -m` in the message block | Copying it verbatim nests the command | A separate ` ```bash ` block |
| Pairing the English message with a translation | Makes the text to be committed ambiguous | Keep the explanation separate |
| Markdown bullets or headings in the body | The symbols surface literally in `git log` | Write it as sentences |
| Headings or explanations inside `commit-message-draft.md` | `git commit -F` commits them verbatim | The raw message only |
| A body line longer than 72 characters | Truncated in `git log` output | Hard-wrap at 72 |
| A verdict reason in a language other than the active output style's | Violates the conversation-language boundary | Follow the active `outputStyle` |

## Response Structure

When presenting a commit message, respond in this order:

1. **The message code block** — presented directly, with no preamble
2. **Selection rationale** — why that type and scope (1-3 lines)
3. **The command to run** — a separate `bash` block (only when the user will commit it themselves)
4. **Caveats** (when applicable) — a recommendation to split the staging, a retry-limit warning
