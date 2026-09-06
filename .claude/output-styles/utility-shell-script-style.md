---
name: utility-shell-script-style
description: A style specialized for writing and reviewing shell scripts. It prioritizes safety, portability, and readability.
keep-coding-instructions: true
---

# Shell Scripts Output Style

This style applies when writing or reviewing Bash scripts in the `scripts/` directory.
Always treat the code's **safety**, **portability**, and **readability** as the top-priority criteria.

---

## Response Format

- Always specify the language identifier on code blocks: ` ```bash ` or ` ```sh `
- When providing a full script, include the shebang and a descriptive comment at the top of the file
- When modifying a script, clearly distinguish before/after
- For dangerous or attention-requiring commands, add a warning below the code block in the `> ⚠️ Caution:` format

---

## Coding Rules

### Shebang Selection Criteria

| Script type | Shebang |
| ------------- | --------- |
| Ordinary project scripts (`deploy.sh`, `cache.sh`, etc.) | `#!/bin/bash` |
| Container entrypoint (`entrypoint.sh`) | `#!/bin/sh` |
| Portability-critical scripts (POSIX only) | `#!/bin/sh` |

Do not use `#!/usr/bin/env bash` — the Bash path is fixed across all target environments.

### Header Format

Every script follows the header structure below:

```bash
#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - {Category} - {Sub-Category} - {Description}
# ----------------------------------------------------------------------------------------------------------------------
```

The `set -euo pipefail` line is **intentionally commented out** in all project scripts.

> ⚠️ **Why `set -euo pipefail` is disabled**: this project uses a modular architecture that loads
> sub-scripts with `source` rather than running them in a subshell. Enabling `set -u` produces false
> positives for variables declared by another sourced script loaded later. The interactive `select`
> menu also misbehaves under `set -e`. The commented-out line is kept as a visible marker that this
> decision is intentional, not forgotten.

For standalone utility scripts that do not source other scripts and do not use an interactive menu, you
**may enable** `set -euo pipefail`:

```bash
#!/bin/bash
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Utility - {Description}
# ----------------------------------------------------------------------------------------------------------------------
set -euo pipefail
IFS=$'\n\t'
```

### Section Separators

Use three separator widths — 118 characters is this project's standard line length:

```bash
# ----------------------------------------------------------------------------------------------------------------------
# Major section (top-level script separator)
# ----------------------------------------------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------------------------------------------
# Sub-section (component block inside a function)
# ----------------------------------------------------------------------------------------------------------------------

# >>>> Category - Item (inline label for a command group)
```

### Variable Rules

```bash
# Global constants — UPPER_CASE + underscore
PLATFORM_TYPE=$(uname -s)
PLATFORM_PROCESSOR=$(uname -m)
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Local variables inside functions — UPPER_CASE + underscore (project convention)
# Note: use 'local' to scope; always quote when expanding
local SUPERVISOR_STATUS
SUPERVISOR_STATUS=$(systemctl is-active supervisord)

# Always quote variable expansions
echo "${SUPERVISOR_STATUS}"
cp "${source_file}" "${dest_dir}/"

# Safe rm -rf: use :? to guard against empty variable
rm -rf "${BUILD_DIR:?BUILD_DIR is not set}"
```

### Function Naming Conventions

This project uses **two naming conventions** depending on context — apply the one that fits the situation:

| Convention | Where used | Example |
| ------ | -------- | ------ |
| `camelCase` | Lifecycle functions that orchestrate deployment phases | `setStart`, `setEnd`, `setExit`, `setEnvironment`, `setPlatform`, `setProject`, `setPhp`, `setRedis`, `setNginx`, `setBuild`, `setDocker`, `setUtility`, `setTools` |
| `snake_case` | Utility/helper functions for reusable logic | `find_project_root`, `log_info`, `log_error`, `cleanup` |

```bash
# Lifecycle phase function (camelCase)
setPhp() {
  echo "---------------------------------------------------------------------------------------------------------------"
  echo "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - App - PHP"
  echo "---------------------------------------------------------------------------------------------------------------"
  echo

  if [ -f "${PROJECT_PATH}/scripts/base/app/php/_install.sh" ]; then
    source "${PROJECT_PATH}/scripts/base/app/php/_install.sh"
  else
    echo "Please check a file : ./scripts/base/app/php/_install.sh" && exit
  fi
}

# Utility helper function (snake_case)
log_error() {
  local message="$1"
  echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') — ${message}" >&2
}
```

### Lifecycle Structure

Every top-level script (`deploy.sh`, `cache.sh`, `status.sh`, etc.) follows the fixed order below:

```bash
# ----------------------------------------------------------------------------------------------------------------------
# START
# ----------------------------------------------------------------------------------------------------------------------

setStart          # Print start banner with timestamp

# Abstract
setEnvironment    # Select dev/prod via interactive menu
setPlatform       # Detect and configure OS-specific settings
setProject        # Source .env.app and prepare project directories

# Architecture (enable the components this script needs)
setPhp
#setRedis
#setPostgreSQL
#setRabbitMQ
#setNginx

# Build
setBuild

# Docker
setDocker

# Providers
#setProvider

# Utility
setUtility

# Tools
setTools

# ----------------------------------------------------------------------------------------------------------------------
# END
# ----------------------------------------------------------------------------------------------------------------------

setEnd            # Unset all exported variables and print end banner
```

Comment out phase functions you do not need instead of deleting them — this is the standard way to skip a phase.

### Project Root Discovery

Every top-level script must find the repository root before sourcing `_abstract.sh`. Use the standard function below:

```bash
find_project_root() {
    local PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    while [[ "${PROJECT_DIR}" != "/" ]]; do
        if [[ -d "${PROJECT_DIR}/.git" ]] || [[ -f "${PROJECT_DIR}/.env.app" ]]; then
            echo "${PROJECT_DIR}"
            return 0
        fi
        PROJECT_DIR="$(dirname "${PROJECT_DIR}")"
    done
    return 1
}

PROJECT_PATH=$(find_project_root)
PROJECT_NAME=$(basename "$(realpath "${PROJECT_PATH}")")
cd "${PROJECT_PATH}" || exit
```

### Sourcing the Abstract Script

Source `_abstract.sh` **immediately after** discovering the project root — it defines `setStart`, `setEnd`, `setExit`,
`PLATFORM_TYPE`, `PLATFORM_PROCESSOR`:

```bash
if [ -f "${PROJECT_PATH}/scripts/base/_abstract.sh" ]; then
  source "${PROJECT_PATH}/scripts/base/_abstract.sh"
else
  echo "Please check a file : ./scripts/base/_abstract.sh" && exit
fi
```

Apply the same guard pattern to **every sourced script** — no bare `source`:

```bash
if [ -f "${PROJECT_PATH}/scripts/base/_platform.sh" ]; then
  source "${PROJECT_PATH}/scripts/base/_platform.sh"
else
  echo "Please check a file : ./scripts/base/_platform.sh" && exit
fi
```

### Multi-Platform Branching

All platform-sensitive code must branch on `PLATFORM_TYPE`, which `_abstract.sh` sets:

```bash
if [ "${PLATFORM_TYPE}" == "Linux" ]; then
  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Linux
  # --------------------------------------------------------------------------------------------------------------------
  ...

elif [ "${PLATFORM_TYPE}" == "Darwin" ]; then
  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Mac - MacOS
  # --------------------------------------------------------------------------------------------------------------------
  ...

elif [ "${PLATFORM_TYPE}" == "Windows" ]; then
  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Windows - WSL2
  # --------------------------------------------------------------------------------------------------------------------
  ...

else
  echo "Please check Operating System"
  setExit
fi
```

### Error Handling

```bash
# Guard missing command
command -v rsync &>/dev/null || { log_error "rsync is not installed."; exit 1; }

# Guard missing directory
[[ -d "${TARGET_DIR}" ]] || { log_error "Directory not found: ${TARGET_DIR}"; exit 1; }

# Guard unset required variable — preferred over bare exit
[[ -n "${ENVIRONMENT_NAME}" ]] || { echo "Error: ENVIRONMENT_NAME is not set."; exit 1; }

# setExit — call when a fatal condition is detected inside a source'd script
# Uses kill -SIGKILL $$ to terminate the parent shell that sourced this script.
# Do NOT use plain 'exit' inside sourced sub-scripts; it would only exit the subshell.
setExit
```

> ⚠️ `setExit` intentionally calls `kill -SIGKILL $$`. When a sub-script is loaded into the parent shell
> with `source`, a plain `exit` only ends the current function scope. `kill -SIGKILL $$` sends SIGKILL to
> the PID of the sourcing parent shell, so the entire script tree is reliably aborted.
> Use `setExit` only for unrecoverable errors.

### Interactive Environment Menu

```bash
setEnvironment() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ENV ] ${PLATFORM_TYPE} - ${PLATFORM_PROCESSOR}"
  echo -e "----------------------------------------------------------------------------------------------------------\n"

  PS3="Menu: "
  select num in "dev" "prod" "exit"; do
    case "$REPLY" in
    1)
      ENVIRONMENT_NAME="dev"
      break
      ;;
    2)
      ENVIRONMENT_NAME="prod"
      break
      ;;
    3)
      echo "exit()"
      setEnd
      ;;
    *)
      echo "[ ERROR ] Unknown Command"
      setEnd
      ;;
    esac
  done
  echo
}
```

### Argument Handling

```bash
function usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Options:
  -d, --dir <path>    Target directory (default: /tmp)
  -v, --verbose       Verbose output
  -h, --help          Show this help
EOF
}

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -d|--dir)   TARGET_DIR="$2"; shift 2 ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -h|--help)  usage; exit 0 ;;
        *) echo "[ ERROR ] Unknown option: $1"; usage; exit 1 ;;
    esac
done
```

---

## ShellCheck Configuration

The project includes a `scripts/base/.shellcheckrc` with the following rules disabled:

| Code | Reason for disabling |
| ------ | ------------- |
| `SC2034` | A variable set in a library script is used by the sourcing parent — ShellCheck sees it as "unused" |
| `SC2168` | `local` used in a sourced sub-script executed outside a named function (e.g. `_platform.sh`) |
| `SC1091` | The source path is dynamic (`${PROJECT_PATH}/…`) and cannot be resolved at lint time |
| `SC2155` | Declaration and assignment on one line — allowed in this codebase for readability |
| `SC2225` | Limited to the compound commands used in this project |
| `SC2024` | Output redirection and `sudo` (intentional in install scripts) |

Always run `shellcheck` before committing a new script:

```bash
shellcheck scripts/deploy/dev/linux/ubuntu/deploy.sh
```

---

## Portability Guidelines

- **Shebang**: `#!/bin/bash` for project scripts; `#!/bin/sh` only for the Docker entrypoint
- **Bash 4+ features** (`associative array`, `mapfile`): state the minimum version when using them
- macOS vs. Linux command differences:
  - `sed -i ''` (macOS) vs `sed -i` (Linux) → prefer `perl -pi -e` for cross-platform
  - `date -d` (GNU) is unavailable on macOS → use `python3 -c "from datetime import …"` when needed
- Do not assume GNU coreutils on macOS — test on both platforms when modifying a multi-platform script

---

## Security Checklist

Automatically review the following items when proposing or reviewing a script:

- [ ] External input (arguments, environment variables) is validated before use
- [ ] No `eval`; if unavoidable, mark it explicitly
- [ ] Temporary files are created with `mktemp` and cleaned up with `trap`
- [ ] Secrets (passwords, tokens) are read from environment variables or `.env.app` — no hardcoding
- [ ] Script permissions: `chmod 700` or `chmod 750`
- [ ] `rm -rf` using a variable always uses the `${VAR:?}` guard

```bash
# Safe rm -rf pattern
rm -rf "${BUILD_DIR:?BUILD_DIR is not set}"
```

---

## Comment Rules

```bash
# ── Section separator (major block) ─────────────────────────────────────────

# >>>> Category - Sub-item (inline group label)

# TODO: items that need future improvement
# FIXME: known bugs or temporary workarounds
# NOTE: non-obvious behavior that would surprise a reader
```

---

## Anti-patterns

Always flag the following patterns when found and propose a safe alternative:

| Anti-pattern | Reason | Alternative |
| --------- | ------ | ------ |
| `cat file \| grep` | Unnecessary use of cat | `grep pattern file` or `< file grep pattern` |
| `cat file \| cmd` | Unnecessary use of cat | `cmd < file` |
| `rm -rf /` or unguarded `rm -rf "${VAR}"` | Can delete the entire filesystem | `rm -rf "${VAR:?}"` |
| `ls \| grep` | Misbehaves on whitespace and special characters | `find` + `-name` |
| Unquoted `[[ $var == *foo* ]]` | Word-splitting risk | Always double-quote: `[[ "$var" == *foo* ]]` |
| `export VAR=password123` | Exposes the secret in the process list | Read from `.env.app` or use `read -s` |
| Broad `2>/dev/null` | Silently hides errors | Explicit error handling |
| `source` without an existence check | Silently fails when the file is missing | Use the guarded source pattern above |

---

## Response Structure

When providing a script, respond in the following order:

1. **One-line purpose summary** — what the script does
2. **Prerequisites** — required tools, permissions, environment variables
3. **Script code block** — complete, runnable code
4. **How to run** — `chmod +x`, example run command
5. **Cautions** (when applicable) — side effects, rollback method, environment dependencies
