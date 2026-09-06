# Claude Code Hooks (`.claude/hooks/**`)

This directory holds this project's **Claude Code hook scripts**, organized by event. A hook is a shell
command that Claude Code **runs automatically** at a specific point (before/after a tool runs, at
session start/end, when a response finishes, and so on).

## Convention (how hooks are wired)

A hook's **behavior (logic)** lives in a per-event `*.sh` script in this directory, and its
**registration (wiring)** references that script from `hooks.<EventName>` in `.claude/settings.json`.
Do not write an inline shell command directly into `settings.json` — separating the logic into a script
makes it easy to version, review, and test, and keeps `settings.json` thin.

```jsonc
// .claude/settings.json
"hooks": {
  "PostToolUse": [
    { "matcher": "Edit|Write",
      "hooks": [{ "type": "command",
                  "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/post-tool-use/app-php-cs-fixer.sh",
                  "timeout": 30, "statusMessage": "Running php-cs-fixer..." }] }
  ]
}
```

- Prefix the script path with **`${CLAUDE_PROJECT_DIR}`**, the same way `settings.json` writes
  `statusLine`. A bare relative path resolves against **the process working directory** rather than the
  repository root, and `${CLAUDE_PROJECT_DIR}` additionally stays pinned to the directory the session
  started in even after Claude enters a worktree. `[Verified]` 2026-08-31
  [WebFetch: <https://code.claude.com/docs/en/hooks>]
  > ⚠️ **The convention is currently not met, and this paragraph used to claim otherwise.**
  > `[Verified]` 2026-09-02 [Read: .claude/settings.json] — of the 14 `command` values, **only
  > `statusLine` carries the prefix**; all **13 hook commands are bare relative paths**. This text
  > previously asserted that all of them carried it, which was false.
  >
  > This is the same regression the next paragraph records as already having happened once. The damage
  > is not cosmetic — `pre-tool-use/agent-roster-guard.sh` resolves `.claude/agents/<target>.md` to
  > decide whether a spawn target exists, so from any other working directory the guard reports every
  > agent as missing. `env.CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR: "1"` pins the *Bash tool's* working
  > directory and partly masks this, but it is not a guarantee for hook execution `[Uncertain]`.
  > A hook that reads a project file needs the prefix *and* an internal `PROJECT_PATH` fallback; the
  > sibling scripts show the pattern. **Re-adding the prefix to the 13 hook commands is an open task
  > requiring a `settings.json` edit — it is not done.**
- Scripts need the execute permission: `chmod +x .claude/hooks/<event>/<name>.sh`.
  This requirement applies to **every** script `settings.json` references via `command` — not only
  hooks, but also the `.claude/scripts/**` that `statusLine` points at. Without the permission Claude
  Code does not fail quietly: the whole feature dies with `Permission denied`.
- **`"type": "command"` is a project convention, not the only option.** The hook schema also accepts
  `http` (POST to a URL), `mcp_tool` (call a tool on a configured MCP server), `prompt` (evaluate an
  LLM prompt) and `agent` (run a subagent). `[Verified]` 2026-08-30
  [WebFetch: <https://code.claude.com/docs/en/hooks>] This project deliberately uses `command` only, so
  that every hook's behaviour is a reviewable file in this directory. Beyond the keys shown above, a
  command hook also accepts `if` (a permission-rule filter, e.g. `"if": "Bash(rm *)"`), `args` (exec-form
  argument list), `shell` (`bash` | `powershell`) and `once` — none are used here, but none are unknown
  keys either.

## Directory → Event Mapping

Directory names are kebab-case and mirror Claude Code's PascalCase hook events. The 18 scaffolds below
exist. `[Verified]` [WebFetch: https://code.claude.com/docs/en/hooks]

| Directory | Event | When it fires |
| --- | --- | --- |
| `config-change/` | `ConfigChange` | A config file changes mid-session (exit 2 = block the change) |
| `instructions-loaded/` | `InstructionsLoaded` | CLAUDE.md and `.claude/rules/*.md` are loaded (exit code ignored) |
| `notification/` | `Notification` | Claude Code sends a notification |
| `permission-request/` | `PermissionRequest` | A tool call needs a permission decision (exit 2 = deny) |
| `post-tool-use/` | `PostToolUse` | After a tool call succeeds |
| `post-tool-use-failure/` | `PostToolUseFailure` | After a tool call fails |
| `pre-compact/` | `PreCompact` | Just before context compaction (exit 2 = block compaction) |
| `pre-tool-use/` | `PreToolUse` | Just before a tool call executes (exit 2 = block the tool) |
| `session-end/` | `SessionEnd` | At session end (**budget-capped — see the trap note below**; runs the two `*-clear.sh` refresh hooks, each `timeout: 60`) |
| `session-start/` | `SessionStart` | At session start/resume (stdout is injected into context) |
| `stop/` | `Stop` | When Claude finishes a response (exit 2 = prevent stopping and continue the conversation) |
| `sub-agent-start/` | `SubagentStart` | When a subagent is spawned |
| `sub-agent-stop/` | `SubagentStop` | When a subagent terminates (exit 2 = prevent termination) |
| `task-completed/` | `TaskCompleted` | When a task is marked complete (exit 2 = prevent completion) |
| `teammate-idle/` | `TeammateIdle` | Just before an agent-team teammate goes idle (exit 2 = keep working) |
| `user-prompt-submit/` | `UserPromptSubmit` | On prompt submission, before processing (exit 2 = block the prompt) |
| `worktree-create/` | `WorktreeCreate` | When a worktree is created (**any non-zero exit = creation fails**) |
| `worktree-remove/` | `WorktreeRemove` | When a worktree is removed, e.g. at session end |

> **The table above is the complete inventory of what this repository scaffolds — not of what Claude
> Code supports.** The official list is longer and grows; when you need an event that has no directory
> here, read the [hooks reference](https://code.claude.com/docs/en/hooks) for the current set and
> create a new kebab-case directory named after its PascalCase event. `PreModelSwitch` and
> `PostModelSwitch`, added to the official list by 2026-08-30, are examples of events with no scaffold.
>
> **Why this section no longer enumerates the unscaffolded events.** It used to carry a hand-copied
> list of every event Claude Code supports, plus arithmetic (`18 scaffolded + N unscaffolded = total`)
> that had to be re-derived on every documentation sweep. It drifted twice in two days — the total went
> 31 → 33 on 2026-08-30 when two model-switch events turned out to be missing — because it was a second
> copy of upstream data with no local meaning. The scaffolded table earns its keep: it maps *our*
> directories to *our* exit-code conventions. The remainder is the official reference's job.
>
> **One trap worth keeping.** `SessionEnd` **exists** and the `session-end/` scaffold above is valid.
> A summarised fetch of the event list omitted it on 2026-08-30, which would have condemned that
> scaffold as dead; a targeted re-fetch quoting its description confirmed it is live. Never delete a
> scaffold because one rendering of the official list left the event out — confirm the event itself
> first.
>
> **A second trap, about what may be *put* in that scaffold.** `SessionEnd` is live but **cannot report
> a verdict.** `[Verified]` 2026-09-02 [WebFetch: <https://code.claude.com/docs/en/hooks>]: `SessionEnd`
> hooks share a **1.5-second total budget**; when a single hook sets a longer `timeout`, Claude Code
> raises the budget to match, **up to a 60-second maximum**. And `SessionEnd` is **absent from the
> exit-code-2 table**, so an exit 2 there reaches nobody.
>
> **The resolution was to split the pipeline, not to move it wholesale.** An earlier design ran
> `composer install` → `cache:clear` → PHPStan as one `SessionEnd` job, which could not fit the 60s
> ceiling and discarded its gate report on the way out. Today the halves sit on different events, and
> each is where it is for a reason the other event cannot satisfy:
>
> - **Housekeeping → `SessionEnd`** (`app-php-symfony-clear.sh`, `app-javascript-stimulus-clear.sh`,
>   both `timeout: 60` to claim the ceiling). `composer install` and `cache:clear` are too heavy to
>   repeat once per turn, and they have nothing to report.
> - **Quality gates → `Stop`** (`app-php-symfony-gate.sh`, `asyncRewake`, `timeout: 600`). PHPStan,
>   `lint:twig`, `lint:container` and `lint:yaml` exist to be reported, and `Stop` is the only event
>   where an exit 2 still has a turn to wake.
>
> So reserve `session-end/` for work that reports nothing — not for work that is merely short.
> Whether `async` / `asyncRewake` are honoured on `SessionEnd` is **not documented** either way
> `[Uncertain]` — do not design around an answer the reference does not give.

## Execution Contract (stdin · exit code)

- Every hook receives a **JSON payload on stdin**. Parse the edited file path and similar fields with
  `jq` (e.g. `.tool_input.file_path // .tool_response.filePath`).
  `[Verified]` [WebFetch: https://code.claude.com/docs/en/hooks]
- **exit 0** = success. For `SessionStart` and `UserPromptSubmit`, stdout is injected into Claude's
  context; for every other event, stdout goes only to the debug log.
- **exit 2** = a per-event block (see the table above). stderr is passed to Claude as an error.
- **Any other exit** = a non-blocking error. Execution continues and the first line of stderr is shown.
  (Exception: `WorktreeCreate` treats any non-zero code as a failure.)

A hook that **must not block the workflow**, such as a formatter or a notifier, always ends with
`exit 0`.

### The Two Faces of exit 2 — Choosing a Feedback Path

`[Verified]` [WebFetch: https://code.claude.com/docs/en/hooks]

- exit 2 on `PostToolUse` **blocks nothing** — the tool has already run, and stderr is merely shown to
  Claude. That makes it a **safe feedback path** for getting an error in an edited file corrected
  within the same turn.
- exit 2 on `Stop` **prevents Claude from stopping and continues the conversation**. The official
  documentation describes no loop guard, so do not use it for a heavy gate.
- **`asyncRewake: true`** runs in the background and wakes Claude only on exit 2, showing stderr
  (or stdout when stderr is empty) as a system reminder. It implies `async`. A Stop gate that must
  deliver a result without delaying the turn uses this.

## Script Style

Hook scripts are **standalone utilities**, unrelated to the `source`-based deployment architecture.
Follow the project's shell-script SoT for shell style — shebang, quoting, guards — but do not use
`_abstract.sh`, the lifecycle functions, or the `select` menu.

@see .claude/output-styles/utility-shell-script-style.md — shell style SoT (shebang · quoting · `rm -rf` guard · `set -euo pipefail` permitted for standalone utilities)
@see .claude/rules/utility-shell-script-rule.md — shell safety · quality gate

> Note: the shell-script rule's `paths` is `scripts/**`, so it is not auto-applied to
> `.claude/hooks/**/*.sh`. Apply the same SoT to hook scripts when reviewing them.

## Currently Active Hooks

**13 hooks across 5 events.** `[Verified]` 2026-09-02 [Read: .claude/settings.json] — the table below
is in `settings.json` array order, which for `PostToolUse` is execution order.

> This heading read "12 hooks across 4 events" with a `[Verified] 2026-08-31` stamp until 2026-09-02.
> `settings.json` changed after that stamp — the two `*-clear.sh` scripts moved from `Stop` to
> `SessionEnd` and `stop/app-php-symfony-gate.sh` was added — so the citation had become false rather
> than merely stale. Re-derive this table from `settings.json`; never re-date the stamp without doing so.

| Event | Script | Purpose |
| --- | --- | --- |
| `PreToolUse` (`Agent\|Task`) | `pre-tool-use/agent-roster-guard.sh` | Enforces the closed-roster invariant of the three orchestrators — matches the calling `agent_type` against the spawn target's `subagent_type` and **blocks with exit 2** when a team reaches outside its own prefix set. Non-orchestrator callers pass through untouched |
| `PostToolUse` (`Edit\|Write`) | `post-tool-use/app-javascript-stimulus-guard.sh` | Greps edited `app/assets/**/*.js` against JS quality rules (innerHTML, eval, `require()`, `console.log`, etc.) — exit 2 on a violation |
| `PostToolUse` (`Edit\|Write`) | `post-tool-use/app-php-lint.sh` | Syntax-checks edited `*.php` with `php -l` — feeds back to Claude via exit 2 on failure |
| `PostToolUse` (`Edit\|Write`) | `post-tool-use/app-php-cs-fixer.sh` | Auto-formats edited PHP files under `app/{src,tests,config,public,migrations}` with php-cs-fixer |
| `PostToolUse` (`Edit\|Write`) | `post-tool-use/app-twig-lint.sh` | Checks edited `*.twig` with `lint:twig` — feeds back to Claude via exit 2 on failure |
| `PostToolUse` (`Edit\|Write`) | `post-tool-use/utility-git-commit-draft.sh` | Checks `.claude/tmp/utility/git/commit-message-draft.md` against the Conventional Commits rule (format · subject length · markdown · non-ASCII · trailers · body shape) — exit 2 on a `[MUST]` |
| `PostToolUse` (`Edit\|Write`) | `post-tool-use/utility-drawio-diagram-draft.sh` | Checks `.claude/tmp/utility/drawio/diagram-draft.xml` for structural integrity (root cells · id uniqueness · dangling parent/source/target · geometry) and conventions (palette · grid · page spec) — exit 2 on a `[MUST]` |
| `SessionStart` (no matcher) | `session-start/app-node_modules.sh` | Injects Node toolchain environment variables (`NODE_ENV`, `app/node_modules/.bin` on PATH) via `CLAUDE_ENV_FILE` |
| `SessionStart` (no matcher) | `session-start/app-toolchain-status.sh` | Warns into context when `app/vendor`, `app/assets/vendor`, or `jq` is missing — surfaces a quality gate that is silently inert |
| `SessionEnd` (`logout\|prompt_input_exit\|other`, `async`, `timeout: 60`) | `session-end/app-php-symfony-clear.sh` | Housekeeping half of the old Stop pipeline — refreshes the dev Symfony app (php-cs-fixer → composer install → cache:clear). Reports nothing; the gates moved to `stop/app-php-symfony-gate.sh` |
| `SessionEnd` (`logout\|prompt_input_exit\|other`, `async`, `timeout: 60`) | `session-end/app-javascript-stimulus-clear.sh` | Refreshes the dev frontend assets (importmap:install when missing → tailwind:build → asset-map:compile). Sole owner of `asset-map:compile`; reports nothing, having no wake channel |
| `Stop` (`async`) | `stop/notify-complete.sh` | Plays a completion sound when the response ends |
| `Stop` (`asyncRewake`, `timeout: 600`) | `stop/app-php-symfony-gate.sh` | Gate half of the split — runs the merge-blocking checks over the working tree (PHPStan on the changed set → lint:twig → lint:container → lint:yaml) and **wakes Claude via exit 2** on failure. On a skipped turn it leaves a rerun marker so the lock holder makes one more pass — "gate did not run" and "gate passed" would otherwise be indistinguishable |

> The six PostToolUse hooks run in the array order given in `settings.json`. `app-php-lint.sh` must come
> **before** `app-php-cs-fixer.sh` — on a file with broken syntax the fixer is a silent no-op, so lint is
> the only thing that can report the cause. Every other pair is order-independent, because each script
> filters to a disjoint set of paths by itself: `*.twig`, `app/assets/**/*.js`, and one specific draft
> file each for the two `utility-*-draft.sh` guards. That per-script filtering is also why one
> `Edit|Write` matcher suffices for all six, and why the two draft guards need no `if` filter.

> The two `utility-*-draft.sh` guards are **dual entry points**: the same file runs as a hook (path from
> the stdin payload) and as a CLI checker (path as `$1`), the latter invoked by the author agent as its
> self-gate and by the reviewer agent as the evidence its verdict rests on. One implementation means the
> hook verdict and the review verdict cannot drift apart. Neither guard ever rewrites the draft — for
> the commit draft, `git commit -F` reads the file byte for byte, so an autofix would silently change
> what gets committed.

> **All three heavy hooks share one lock file**, `app/var/.claude-app-clear.lock`, and take it in
> different modes. `[Verified]` 2026-09-02 [Read: the three scripts]
>
> - `session-end/app-php-symfony-clear.sh` — `flock -w 45` (queue behind, bounded)
> - `session-end/app-javascript-stimulus-clear.sh` — `flock -w 45` (queue behind, bounded)
> - `stop/app-php-symfony-gate.sh` — `flock -n` (skip the turn) **plus a rerun marker**, so any number
>   of skipped turns coalesce into one extra pass
>
> The lock spans two *different* events on purpose: `cache:clear` and `composer install` on `SessionEnd`
> empty the very container cache that `lint:container` rebuilds on `Stop`, and `asset-map:compile` would
> otherwise publish against a half-built cache. Two separate lock files would silently reintroduce the
> race.
>
> This paragraph previously named `app/var/.claude-stop-clear.lock`, listed only the two clear hooks as
> sharing it, and gave their modes as `flock -n` / `flock -w 300`. All four details were wrong.

> `app-javascript-stimulus-guard.sh` has no dependencies — no JS linter or formatter is installed in the project and the
> decision was made not to introduce a new dependency, so it uses grep only and **does not rewrite
> files**. The SoT for JS formatting is `app/.prettierrc.json` (4 spaces, semicolons), which
> `app/.editorconfig` and `.claude/output-styles/app-javascript-stimulus-style.md` follow — never
> change just one of the three.

> `app-twig-lint.sh` **does not use** `--show-deprecations`. Symfony promotes a deprecation to a lint
> error, so attaching the flag at edit time makes every unrelated template edit fire on one
> pre-existing deprecation. Use the flag only in a full sweep (`stop/app-php-symfony-gate.sh`).

> The `CLAUDE_ENV_FILE` that `app-node_modules.sh` uses is injected only for `SessionStart`, `Setup`, `CwdChanged`,
> and `FileChanged`, and that file **runs as a script preamble** on every Bash command. To preserve
> variables set by another hook, append with `>>` rather than `>`.
> `[Verified]` [WebFetch: https://code.claude.com/docs/en/hooks#persist-environment-variables]

> `app-php-symfony-gate.sh` fires **every turn** (`Stop`), and async hooks are **not deduplicated**
> `[Verified]` [WebFetch: https://code.claude.com/docs/en/hooks#limitations]. If the previous turn's run
> has not finished, `flock -n` skips this turn to avoid contention on the `app/var/cache` and vendor
> trees — leaving a rerun marker so the skip is not mistaken for a pass.
>
> `app-php-symfony-clear.sh` does **not** fire every turn: it is on `SessionEnd`, which is why the heavy
> `composer install` / `cache:clear` work can live there at all. It re-fires on clear/resume within one
> process, which is what its own `flock -w 45` guards against.

> `app-php-cs-fixer.sh` only does real work when `jq` and `app/vendor/bin/php-cs-fixer` are present. If
> either is missing the script degrades silently to `exit 0` (non-blocking). Install vendor with
> `composer install`, and `jq` must be present on the system.

## Adding a New Hook

1. Write `.claude/hooks/<event>/<name>.sh` (parse the stdin JSON, use an appropriate exit code,
   `exit 0` if non-blocking).
2. Grant the execute permission with `chmod +x`.
3. Register the script under `hooks.<EventName>` in `.claude/settings.json` as
   `"${CLAUDE_PROJECT_DIR}/.claude/hooks/<event>/<name>.sh"` — using the `update-config` skill is the
   safe way.
4. Confirm `shellcheck .claude/hooks/<event>/<name>.sh` passes, then verify with a mock payload:
   `printf '%s' '{"tool_input":{"file_path":"..."}}' | .claude/hooks/<event>/<name>.sh; echo "exit=$?"`
