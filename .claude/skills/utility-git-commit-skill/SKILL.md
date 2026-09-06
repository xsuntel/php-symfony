---
name: utility-git-commit-skill
description: "Writes, reviews, and commits a Conventional Commits message from the staged changes as a two-agent (author/reviewer) workflow. Always use it for natural-language requests like 'commit message', 'write a commit message', or 'make me a commit message' (in any language). Do not use it for a 'git commit -m' request where the message is already given."
---

# Git Commit Skill

Invokes a two-agent team (utility-git-commit-author → utility-git-commit-reviewer) in sequence to write and review a
Conventional Commits message, and runs the commit on a PASS verdict.

- Commit message language: **English**
- Intermediate artifacts location: `./.claude/tmp/` (gitignored)

@see .claude/rules/utility-git-commit-rule.md — format · types · scope · factual agreement (SoT)
@see .claude/agents/utility-git-commit-author.md — draft role · draft file contract
@see .claude/agents/utility-git-commit-reviewer.md — PASS/REDO verdict role · mechanical checks

---

## Workflow

1. **Precondition check**
   - Run `git diff --cached --quiet`.
   - Exit code 1 (staged changes present) → proceed; exit code 0 (no changes) →
     advise "stage your changes first with `git add`" and stop.

2. **Invoke the author**
   - Call the `utility-git-commit-author` agent to generate `./.claude/tmp/utility/git/commit-message-draft.md`
     and its sidecar `./.claude/tmp/utility/git/commit-message-meta.txt`.
   - **State the round number in the prompt** (`round: 1`, `round: 2`, …). Both agents use it for their
     freshness and anti-thrash gates; `.claude/tmp/` is never cleaned, so without it a leftover draft
     from an earlier run is indistinguishable from a fresh one.
   - The draft holds the commit message and nothing else — `git commit -F` takes it verbatim — so the
     round and the staged fingerprint live in the sidecar instead. The reviewer gates on it in step 3
     and step 4a re-checks it; a run without it cannot proceed.

3. **Invoke the reviewer**
   - Call the `utility-git-commit-reviewer` agent to generate `./.claude/tmp/utility/git/commit-message-review.md`.
   - State the same round number.

4. **Verdict branching**
   - Read **line 1** of `./.claude/tmp/utility/git/commit-message-review.md` and branch on that token
     alone — the reviewer writes exactly `Verdict: PASS` or `Verdict: REDO` there.
     - `Verdict: PASS` → step 4a.
     - `Verdict: REDO` → step 4b.
     - **Anything else** → the verdict is malformed. **Fail closed:** treat it as REDO, say so, and
       count the round.
   - **4a — PASS:** run the **staged-set re-check** below first. If it fails, the index moved while the
     review was in flight and the message now describes a different diff — say so and repeat from step 2
     instead of committing. Otherwise run
     `git commit -F ./.claude/tmp/utility/git/commit-message-draft.md`, report the commit hash and
     message, then stop.

     ```bash
     M=.claude/tmp/utility/git/commit-message-meta.txt
     diff <(sed -n '/^staged-stat:$/,$p' "$M" | tail -n +2) <(git diff --cached --stat) \
       && echo 'SAFE TO COMMIT' || echo 'ABORT — the staged set changed since the draft was written'
     ```

     Do not substitute `git diff --cached --quiet` here. It exits 1 whenever *anything* is staged, so it
     is a presence test, not an identity test — it cannot tell a changed staged set from the original one
     and would wave through exactly the failure this step exists to catch.
   - **4b — REDO:** include the fix instruction from the review file's latest `## Round N` section in the
     author re-invocation prompt and repeat from step 2. The author also reads
     `./.claude/tmp/utility/git/commit-message-review.md` directly, so keep your paraphrase faithful to it
     — the file is what it applies. **Retry at most twice.**

5. **Retry-limit handling**
   - If still REDO after 2 retries, **do not commit.**
   - Present the last draft to the user and stop with the warning "auto-approval limit reached —
     manual review recommended".
