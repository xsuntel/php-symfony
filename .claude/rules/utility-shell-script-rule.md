---
paths:
  - "scripts/**/*.sh"
  - "scripts/**/entrypoint.sh"
---

# Shell Script Rules (scripts/\*\*)

This rule is the judgment criteria (SoT) for Bash scripts under `scripts/**`. It enforces the safety,
portability, and structure of this project's `source`-based **modular deployment-script architecture**.

**Responsibility split (no duplication):** the single source of truth for **shell style** — shebang,
naming, delimiters, lifecycle skeleton — is the output-style. This rule does not restate style; it
enforces the **operational/architectural criteria** — bootstrap, global variables, sourcing, idempotency,
taxonomy. Detailed examples and reference live in the docs.

@see .claude/output-styles/utility-shell-script-style.md — shell style criteria/templates (SoT)
@see .claude/docs/utility-shell-script-docs.md — detailed examples: global variables, bootstrap, idempotent install, anti-patterns
@see scripts/base/\_abstract.sh — global variables / bootstrap source
@see scripts/base/.shellcheckrc — the project's disabled ShellCheck rules

## Shebang · Strict Mode (non-negotiable)

- Entry-point scripts use `#!/bin/bash`; minimal container entrypoints use `#!/bin/sh`. `#!/usr/bin/env bash` is forbidden.
- `set -euo pipefail` stays **commented out** (`#set -euo pipefail`) — an intentional design of the source-based, interactive, multi-stage scripts; termination is controlled by the project's `setExit`/`setEnd` instead of shell strict mode. Enabling it is allowed only in standalone utilities.

## Bootstrap · Sourcing

- A directly-executed entry point follows `find_project_root` → `cd "${PROJECT_PATH}"` → source `_abstract.sh`.
- Sourced helpers (`_*.sh`) do not repeat the bootstrap — they inherit `PROJECT_PATH`·`PLATFORM_TYPE` etc. from the calling script.
- Wrap every `source` in an existence check: `if [ -f ... ]; then source ... else echo "Please check ..." && exit fi`. No bare `source`.

## Global Variable Discipline

- Use only global variable names declared in `scripts/base/_abstract.sh` (catalog in the docs). Do not invent non-existent globals.
- Do not re-declare a global as `local` inside a function. On normal exit, `setEnd()` unsets all globals.
- Always expand variables quoted and braced (`"${VAR}"`). Function-local-only variables are `local`-declared before assignment (two-line form).

## Naming · Structure

- Lifecycle-phase functions use `camelCase` (`setStart`·`setPhp`·`setEnd`); reusable helpers use `snake_case` (`find_project_root`·`log_error`). Detailed order/skeleton is in the output-style.

## Safety (non-negotiable)

- `rm -rf` with a variable uses the `rm -rf "${VAR:?}/path"` guard — `:?` aborts on unset/empty.
- A fatal error inside a sourced file terminates via `setExit` (`kill -SIGKILL $$`), not a bare `exit` (a bare `exit` ends only the subshell). Normal exit uses `setEnd`.
- No hardcoded user paths (`/home/rlim/...`) → use `${PROJECT_PATH}`·`${HOME}`·`${USER}`. No hardcoded secrets → use `.env.app`·`read -s`.
- No `eval`; temp files use `mktemp`+`trap`; instead of a `sleep N` timing assumption use `systemctl is-active`·polling.

## Portability · Idempotency

- Platform branching handles Linux/Darwin/Windows and must call `setExit` in the `else` (no silent pass-through). String comparison uses single brackets `[ "${X}" == "Y" ]`.
- Do not install packages unconditionally — install after a `dpkg -l` (or `brew list` on macOS) check guard (idempotent pattern in the docs).
- Branch macOS/Linux command differences (`sed -i`·`date -d`) on `PLATFORM_TYPE`.

## Interactive Menu

- Environment selection uses `select` + `PS3="Menu: "` + `$REPLY` (not the text label), not `getopts`/positional arguments.

## Script Taxonomy

- `scripts/base/` (environment-independent install/config, sourced by both containers and deploy) / `scripts/containers/{dev,prod}/` / `scripts/deploy/{dev,prod}/`. Details in the docs.
- **Entrypoint exception:** `scripts/containers/prod/utility/entrypoint.sh` uses `#!/bin/sh` + `set -e` and does not apply bash-only patterns.

## Quality Gate (required before merge)

```bash
# ShellCheck (respects the disabled rules in scripts/base/.shellcheckrc)
shellcheck scripts/path/to/script.sh
```

- ShellCheck passes (excluding disabled rules); destructive-command guards confirmed; bootstrap/source guards confirmed.
- Classify review severity as `[MUST]` / `[SHOULD]` / `[CONSIDER]`; only `[MUST]` blocks a merge. Warn about dangerous commands with `> ⚠️ Caution:`.
- New scripts use the `utility-shell-script-skill` skill (author→reviewer loop); quality review of an existing file uses the `/utility-shell-script-review` command.
