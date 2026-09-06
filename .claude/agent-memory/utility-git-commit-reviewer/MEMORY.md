# utility-git-commit-reviewer memory

Standing context for issuing a verdict on `./.claude/tmp/utility/git/commit-message-draft.md`. The SoT
for the judgment criteria is `.claude/rules/utility-git-commit-rule.md`; where they conflict, the rule
wins. The checks are *executions* of that rule's clauses, never a second copy — if a check and the rule
disagree, the check is the bug.

## Artifact Paths

- Input: the draft, plus its sidecar `./.claude/tmp/utility/git/commit-message-meta.txt` (`round` +
  `staged-stat`), plus `git diff --cached`.
- Output: `./.claude/tmp/utility/git/commit-message-review.md`.
  - **Line 1 is exactly `Verdict: PASS` or `Verdict: REDO`** — the orchestrator branches on that token
    and reads nothing else on the line.
  - **Append each round, and rewrite line 1 to the current verdict.** With `Write` only, that means
    Read the file, then Write it back whole: new verdict line + blank + prior `## Round N` blocks
    unchanged + this round's block.

## Order of Work (the body is the SoT — this is the reminder)

1. **Freshness gate** — sidecar present, its `round` equal to the stated round, and its `staged-stat`
   identical to a fresh `git diff --cached --stat`. Any mismatch is `stale-or-missing-draft` REDO, and
   Step 2 is not reached. The draft carries no header, so the sidecar is the only provenance there is.
2. **Mechanical checks** — the `## Step 2` script decides length, format, trailing dot, blank line 2,
   body lines, fence/`#`, and that something is staged. Every `FAIL` is a REDO.
3. **Factual agreement** — the one judged check, and the REDO trigger that matters. Also type
   suitability and scope derivation, neither of which follows from the regex passing.

## The REDO That Matters

**A claim the staged diff does not support.** Map every clause of the subject and body to a path or hunk
in `git diff --cached`, and quote the mapping as the reason. A claim that cannot be mapped is a REDO with
no exception. Watch for the two invented-content failures the rule names: a ticket number, and follow-up
work the diff does not show.

## Verdict Principles

- **Artifact-only.** The draft, the sidecar, and the diff are the evidence; what the author reports it
  did is not. Every REDO reason quotes pasted check output or a path/hunk.
- **Round 1 must be complete.** A finding visible in round 1 but first raised in round 2 is recorded as
  `[SHOULD]` and must not become a REDO — the budget is 2 rounds, and moving the goalposts exhausts it
  without converging.
- Judge objective criteria only, not writing quality. REDO only when a rewrite is actually needed: a
  format deviation, a wrong type, or a factual error.
- **Never mutate the repository and never modify the draft.** `disallowedTools: Edit` enforces the
  second; do not work around it with `Write`. Diagnosing is the job, fixing is the author's.
- When uncertain, choose REDO over PASS — a miss costs more than a false alarm.
- Each call is an independent single verdict. Retry counting and the commit belong to
  `utility-git-commit-skill`.
