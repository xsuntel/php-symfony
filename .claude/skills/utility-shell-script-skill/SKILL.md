---
name: utility-shell-script-skill
description: Use when the user writes, reviews, debugs, or refactors Bash shell scripts on Ubuntu/Linux. Triggered by any work involving '.sh files', 'shell script', 'bash', shebang, POSIX compatibility, ShellCheck, cron jobs, systemd timers, or command-line automation. Also use it when fixing common bash pitfalls such as quoting issues, exit code handling, IFS, variable expansion, or word splitting — even if the user does not explicitly say 'bash'.
---

# Shell Script Skill

A guide for writing and reviewing Bash scripts in this Symfony/Docker project. All conventions below
reflect the actual patterns found under `scripts/` — do not apply generic best-practice overrides
that conflict with the project's conventions.

The single source of truth for shell **style** (shebang, strict mode, naming, `rm -rf` guards, etc.)
is the output-style. This skill does not restate the style; it focuses on **operational patterns**
such as bootstrap, global variables, menus, and idempotent installs.

@see .claude/output-styles/utility-shell-script-style.md — shell style standard (SoT)

---

## 1. Core Conventions

### Shebang

Always use `#!/bin/bash`. Do **not** use `#!/usr/bin/env bash`.

### Strict mode

`set -euo pipefail` is intentionally **commented out** in every script:

```bash
#!/bin/bash

#set -euo pipefail
```

This is by design. The scripts run interactive menus and multi-stage installs that must tolerate
partial failure. Instead of relying on shell strict mode, use the project's own error-exit functions
(`setExit`, `setEnd`).

### ShellCheck configuration (`scripts/base/.shellcheckrc`)

The following rules are disabled project-wide — do not flag them in review:

| Rule   | Reason                                                                  |
| ------ | ----------------------------------------------------------------------- |
| SC2034 | Unused variable — variables are consumed in sourced scripts             |
| SC2168 | `local` outside a function — sourced files are always called inside one |
| SC1091 | Cannot follow dynamic `source` paths                                    |
| SC2155 | Rule to split declaration and assignment — intentionally combined       |
| SC2225 | Arithmetic comparison style                                             |
| SC2024 | `sudo tee` redirect pattern                                             |

`external-sources=true` and `source-path=SCRIPTDIR` are also set.

### Variable quoting

Always wrap variable expansion in double quotes: `"${VAR}"`, not `$VAR` or `"$VAR"`.
Use the long brace form: `"${PLATFORM_TYPE}"`, not `"$PLATFORM_TYPE"`.

### Local variables

Variables used only inside a function must be declared with `local` on a separate line before
assignment (SC2155 is disabled, but the two-line form is still preferred for clarity):

```bash
local MY_VAR
MY_VAR=$(some_command)
```

---

## 2. Script Bootstrap Pattern

Every top-level entry-point script that is executed directly (not sourced) must follow this bootstrap
sequence:

```bash
#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - <Category> - <Description>
# ----------------------------------------------------------------------------------------------------------------------

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

if [ -f "${PROJECT_PATH}/scripts/base/_abstract.sh" ]; then
  source "${PROJECT_PATH}/scripts/base/_abstract.sh"
else
  echo "Please check a file : ./scripts/base/_abstract.sh" && exit
fi
```

Sourced helper files (`_*.sh`) do **not** repeat this bootstrap — they inherit `PROJECT_PATH`,
`PLATFORM_TYPE`, and so on from the calling script.

### Sourcing guard pattern

Wrap every `source` call in a file-existence check:

```bash
if [ -f "${PROJECT_PATH}/scripts/base/_platform.sh" ]; then
  source "${PROJECT_PATH}/scripts/base/_platform.sh"
else
  echo "Please check a file : ./scripts/base/_platform.sh" && exit
fi
```

---

## 3. Global Variables

Declared in `scripts/base/_abstract.sh` and available to every script sourced after it. Never
re-declare these as `local`. `setEnd()` unsets them all on normal termination.

**Platform**

- `PLATFORM_TYPE` — `Linux` | `Darwin` | `Windows` (from `uname -s`)
- `PLATFORM_PROCESSOR` — `x86_64` | `arm64` (from `uname -m`)

**Environment**

- `ENVIRONMENT_NAME` — `dev` | `prod`

**Project**

- `PROJECT_PATH`, `PROJECT_NAME`

**App**

- `PHP_VERSION`, `NODE_VERSION`, `SYMFONY_VERSION`

**Infrastructure**

- `REDIS_*`, `POSTGRES_*`, `RABBITMQ_*`, `NGINX_*`

**Docker**

- `DOCKER_ENVIRONMENT`, `DOCKER_WORKDIR`
- `DOCKERFILE_IMAGE_NAME`, `DOCKERFILE_TAG_NAME`

**Cloud**

- `GCLOUD_PROJECT_ID`, `GCLOUD_ARTIFACTS_DOCKER_*`

---

## 4. Function Naming Convention

All functions use `set<PascalCase>` naming. Every top-level deployment script defines and calls its
functions in this order:

| Function              | Purpose                                                                  |
| --------------------- | ------------------------------------------------------------------------ |
| `setStart()`          | Print the start banner with a timestamp                                  |
| `setEnvironment()`    | Interactive environment menu (sets `ENVIRONMENT_NAME`)                   |
| `setPlatform()`       | OS detection and platform-specific configuration                         |
| `setProject()`        | Source `.env.app`, initialize the project directory                      |
| `set<Component>()`    | Install/configure a component (e.g. `setPhp`, `setRedis`, `setNginx`)    |
| `setBuild()`          | Run Symfony deployment steps (composer, cache clear, etc.)               |
| `setDocker()`         | Build and run Docker containers                                          |
| `setProvider()`       | Configure the cloud provider (GCP, etc.)                                 |
| `setUtility()`        | Miscellaneous tools (local server, git, etc.)                            |
| `setTools()`          | VM/instance diagnostics and cleanup                                      |
| `setEnd()`            | Unset all global variables, print the end banner, `exit 0`               |
| `setExit()`           | On an unrecoverable error, terminate immediately with `kill -SIGKILL $$` |
| `find_project_root()` | Walk up the directory tree until `.git` or `.env.app` is found           |

Component helpers follow the same prefix: `setPhp`, `setRedis`, `setPostgreSQL`, `setRabbitMQ`,
`setNginx`, `setSupervisor`, `setDocker`.

---

## 5. Output Formatting

### Section banners (in-source comment separators)

```bash
# ----------------------------------------------------------------------------------------------------------------------
# Section Title (120 = chars)
# ----------------------------------------------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------------------------------------------
# Subsection Title (120 - chars)
# ----------------------------------------------------------------------------------------------------------------------
```

### Runtime output banners (echo separators)

```bash
echo "==============================================================================================================="
echo ">>>>  START                                                                  $(date)"
echo "==============================================================================================================="
```

- `=` line: 111 chars
- `-` line: 111 chars

### In-function section headers

```bash
echo "---------------------------------------------------------------------------------------------------------------"
echo "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Component - Action"
echo "---------------------------------------------------------------------------------------------------------------"
```

### Step labels

```bash
echo ">>>> PHP - Symfony Framework - Deployment - A) Check Requirements"
echo
```

Always follow a step label with a blank `echo` line. Also always print a blank `echo` line after a
command block ends.

---

## 6. Interactive Menus

For environment selection, use `select` with `PS3` — not `getopts` or positional arguments.

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

In the `case` statement, use the numeric input (`$REPLY`), not the text label (`$num`).

---

## 7. Platform-Specific Code

Every platform branch must handle all three OS types. The `else` branch always calls `setExit` —
never fall through silently.

```bash
if [ "${PLATFORM_TYPE}" == "Linux" ]; then
  # apt, systemctl, dpkg
elif [ "${PLATFORM_TYPE}" == "Darwin" ]; then
  # brew, pecl
elif [ "${PLATFORM_TYPE}" == "Windows" ]; then
  # PowerShell, scoop (Git Bash context)
else
  echo "Please check Operating System"
  setExit
fi
```

In platform blocks, use `[ == ]` (double equals inside single brackets) consistently for string
comparison rather than `[[ ]]`.

---

## 8. Package Installation (idempotency pattern)

Do not install packages unconditionally. Always check first with `dpkg -l`:

```bash
local APT_PKG_INFO
APT_PKG_INFO=$(dpkg -l | grep -i "${pkgItem}" | awk '{print $2}' | cut -d ':' -f1 | awk "/^${pkgItem}$/")
if [ "${APT_PKG_INFO}" != "${pkgItem}" ]; then
  sudo apt install -y "${pkgItem}"
  echo
fi
```

Iterate over package lists with a `for` loop:

```bash
local addPackageList="curl git wget unzip"
for pkgItem in ${addPackageList}; do
  local APT_PKG_INFO
  APT_PKG_INFO=$(dpkg -l | grep -i "${pkgItem}" | awk '{print $2}' | cut -d ':' -f1 | awk "/^${pkgItem}$/")
  if [ "${APT_PKG_INFO}" != "${pkgItem}" ]; then
    sudo apt install -y "${pkgItem}"
    echo
  fi
done
```

For removal, invert the condition: `if [ "${APT_PKG_INFO}" == "${pkgItem}" ]; then sudo apt remove -y ...`.

On macOS, use `brew list | grep <pkg>` as the check guard.

---

## 9. Script Categories

| Category          | Path                       | Purpose                                                                                          |
| ----------------- | -------------------------- | ------------------------------------------------------------------------------------------------ |
| Base              | `scripts/base/`            | Environment-independent install and configuration; sourced by both containers and deploy scripts |
| Containers (dev)  | `scripts/containers/dev/`  | `docker-compose` definitions for local Redis, PostgreSQL, RabbitMQ                               |
| Containers (prod) | `scripts/containers/prod/` | Production `Dockerfile`, `entrypoint.sh`, Nginx/Supervisor configuration                         |
| Deploy (dev)      | `scripts/deploy/dev/`      | Per-OS initial machine setup (packages, networking, security)                                    |
| Deploy (prod)     | `scripts/deploy/prod/`     | Production server deployment                                                                     |

**Common base:** `scripts/base/_abstract.sh` → `_environment.sh` → `_platform.sh` → `_project.sh`.
Source `_abstract.sh` first; the rest are sourced in order inside their respective `set*()` functions.

**Entrypoint exception:** `scripts/containers/prod/utility/entrypoint.sh` runs inside a minimal Docker
image, so it uses `#!/bin/sh` with `set -e` rather than bash. Do not apply bash-only patterns here.

---

## 10. Review Checklist

When reviewing this project's scripts, verify the following:

- [ ] Is the shebang `#!/bin/bash` (not `#!/usr/bin/env bash`)?
- [ ] Is `#set -euo pipefail` commented out (not enabled)?
- [ ] Does it bootstrap with `find_project_root` and source `_abstract.sh`?
- [ ] Is every `source` call wrapped in a file-existence check?
- [ ] Do all global variables match the names defined in `_abstract.sh`?
- [ ] Do local variables use the two-line form (`local` declaration then assignment)?
- [ ] Is every variable expansion quoted as `"${VAR}"`?
- [ ] Does the interactive menu use `select` + `PS3="Menu: "` + `$REPLY`?
- [ ] Does each platform block cover Linux, Darwin, Windows and `else` + `setExit`?
- [ ] Does package installation use the `dpkg -l` idempotency check?
- [ ] Are output separators 111 chars wide?
- [ ] Do functions follow `set<Component>()` naming?
- [ ] Is `setEnd` called at the bottom of every entry-point script?
- [ ] Is `setExit` called on an unrecoverable error (not `exit 1`)?

---

## 11. Anti-Patterns to Flag

| Anti-pattern                                               | Recommended approach                                                    |
| ---------------------------------------------------------- | ----------------------------------------------------------------------- |
| Hardcoded user paths (`/Users/rlim/...`, `/home/rlim/...`) | Use `${PROJECT_PATH}`, `${HOME}`, `${USER}`                             |
| Sourcing `.env.app` without an existence check             | Guard first with `if [ -f ... ]`                                        |
| `sleep N` for timing assumptions                           | Use `systemctl is-active`, a polling loop, or a proper wait condition   |
| Repeating the same `dpkg -l` check block inline            | Extract to a shared helper or use the `for pkgItem in ...` loop pattern |
| `exit 1` inside a sourced file                             | Use `setExit` (SIGKILL) or `setEnd` (normal termination) instead        |
| `#!/usr/bin/env bash` shebang                              | Replace with `#!/bin/bash`                                              |
| An enabled `set -euo pipefail`                             | Comment it out and use explicit error handling                          |
| `getopts` for environment selection                        | Use a `select` + `PS3` menu                                             |
| Unquoted `$VAR` expansion                                  | Always use `"${VAR}"`                                                   |
| `rm -rf ${VAR}/...` without a null guard                   | Use `rm -rf "${VAR:?}/path"` — `:?` aborts if `VAR` is unset or empty   |
