# utility-git-commit-author memory

Standing context for drafting a commit message from the staged changes, so it does not have to be looked
up each time. The SoT for the judgment criteria is `.claude/rules/utility-git-commit-rule.md`; where they
conflict, the rule wins.

## Artifact Paths

- Draft: `./.claude/tmp/utility/git/commit-message-draft.md` — **this file becomes the commit message
  verbatim** (`git commit -F`). Line 1 subject, line 2 blank, body ≤ 3 lines, nothing else. No code
  fence, no `#` heading, no prose about the message: with `-F` and no editor git's cleanup mode is
  `whitespace`, which strips trailing whitespace but keeps `#` commentary, so any of those land in the
  commit.
- Sidecar: `./.claude/tmp/utility/git/commit-message-meta.txt` — `round: <n>`, then `staged-stat:` and
  `git diff --cached --stat` verbatim. The draft can carry no header, so this is where provenance lives;
  the reviewer gates on it and the skill re-checks it immediately before committing. Write it every
  round.
- Review file: `./.claude/tmp/utility/git/commit-message-review.md` — from round 2 on, **read it** and
  apply its latest `## Round N` block verbatim, rather than the prompt's paraphrase of it.
- Overwrite both outputs in full every round. `Bash(rm:*)` is denied, so a partial write leaves the
  previous run's text mixed into this one's.

## Input Discipline

`git diff --cached --stat` first, always. A whole-diff dump on a large change is the main way this agent
burns its turn budget before writing anything, and `--stat` is usually enough to fix the type and the
scope. Pull `-U0` detail only for the paths the body actually describes.

## The REDO That Happens Most

**A claim the staged diff does not support.** Every clause in the subject and body must map to a hunk
that was actually read — the reviewer maps them one by one. Never infer a ticket number, a motivation,
or follow-up work the diff does not show. When in doubt, write less.

Second most common: a subject over 72 characters. Run the pre-handoff self-check; it costs one turn,
whereas the reviewer catching it costs a round out of a budget of two.

## Never

- Do not run `git commit`, `git add`, `git reset`, or anything else that touches the index, the working
  tree, or history. `Bash` exists here to read the diff and the log. Committing is the orchestrator's
  action, after a PASS.
- On a REDO, do not change what the instruction did not raise.
