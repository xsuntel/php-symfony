# Git Commit Message Rules

This rule is the judgment criteria (SoT) for this repository's commit messages. Both the author and the
reviewer of the commit workflow apply exactly these criteria — neither agent holds its own copy.

**No `paths` frontmatter, by design.** A commit message is not a file, so no path glob can trigger this
rule. It is reached explicitly via `@see` from the skill and the two agents below. See the `†` note in
`.claude/rules/abstract-structure-rule.md`.

@see .claude/skills/utility-git-commit-skill/SKILL.md — orchestration (author → reviewer → commit, max 2 REDO retries)
@see .claude/agents/utility-git-commit-author.md — draft role
@see .claude/agents/utility-git-commit-reviewer.md — PASS/REDO verdict role
@see .claude/rules/abstract-structure-rule.md — rule index

## Format

The subject follows Conventional Commits: `type(scope): subject`, or `type: subject` when no single
area dominates.

- **Allowed types (closed set):** `feat`, `fix`, `refactor`, `perf`, `style`, `test`, `docs`, `build`,
  `ci`, `chore`, `revert`. A type outside this set is a REDO.
- **Type suitability:** the type must match what the diff actually does. A feature addition typed as
  `chore` is a REDO.

## Scope

Derive the scope from the top-level directory of the paths in the diff. This repository's vocabulary:

`app` (Symfony app) · `assets` · `config` · `scripts` · `rules` (`.claude/rules`) ·
`skills` (`.claude/skills`) · `agents` (`.claude/agents`) · `docs` · `nginx`

When a change spans several areas, pick the single dominant area or omit the scope — do not list two.

## Subject & Body

- **Subject:** ≤ 72 characters, imperative mood, no trailing period, English.
- **Body:** ≤ 3 lines, English, focused on the reason (*why*) rather than restating the diff.
- **Language:** English for both, per the `CLAUDE.md` documentation-language rule.
- **Style consistency:** when the last 10 commits (`git log -10 --oneline`) show a mixed style, follow
  the majority.

## Factual Agreement (the REDO trigger that matters)

Every claim in the subject and body must be verifiable from `git diff --cached`. Mentioning a change
that is absent from the staged diff is a REDO, without exception. Do not infer intent, ticket numbers,
or follow-up work that the diff does not show.

## Verdict Discipline

- Judge against these objective criteria only — not subjective writing quality.
- Issue a REDO only when a rewrite is actually needed (format deviation, wrong type, factual error).
- When uncertain, choose REDO over PASS — a miss costs more than a false alarm.
- Each verdict is independent. Retry counting and termination belong to the orchestrating skill.
