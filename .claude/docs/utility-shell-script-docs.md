# Shell Scripts — Operational Reference (scripts/**)

This document provides a **detailed reference and code examples of the operational patterns** for this
project's `source`-based modular deployment-script architecture. The enforced judgment criteria (SoT)
are the rule and the output-style; this document holds their detailed/example edition — if it conflicts,
the rule and output-style win.

@see .claude/rules/utility-shell-script-rule.md — shell script judgment criteria (SoT)
@see .claude/output-styles/utility-shell-script-style.md — shell style/templates (SoT)
@see scripts/base/_abstract.sh — global variables / bootstrap source

---

## 1. Architecture Overview

`scripts/` is a `source`-based modular structure. The top-level entry point sources `_abstract.sh` to
obtain global variables, and each `set*()` lifecycle function sources the needed component helpers
(`_*.sh`) in order.

**Common base sourcing order:** `scripts/base/_abstract.sh` → `_environment.sh` → `_platform.sh` →
`_project.sh`. `_abstract.sh` is sourced first; the rest are sourced inside their respective `set*()` functions.

---

## 2. Bootstrap Pattern

Every top-level entry-point script that is directly executed (not sourced) follows this order:

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

Sourced helper files (`_*.sh`) do **not** repeat this bootstrap — they inherit `PROJECT_PATH`·`PLATFORM_TYPE`
etc. from the calling script.

### Sourcing Guard

Wrap every `source` call in a file existence check (no bare `source`):

```bash
if [ -f "${PROJECT_PATH}/scripts/base/_platform.sh" ]; then
  source "${PROJECT_PATH}/scripts/base/_platform.sh"
else
  echo "Please check a file : ./scripts/base/_platform.sh" && exit
fi
```

---

## 3. Global Variable Catalog

Declared in `scripts/base/_abstract.sh` and available in every script after sourcing. Never re-declare
these as `local`. `setEnd()` unsets them all on normal exit.

| Group | Variables |
| --- | --- |
| Platform | `PLATFORM_TYPE` (`Linux`\|`Darwin`\|`Windows`, `uname -s`), `PLATFORM_PROCESSOR` (`x86_64`\|`arm64`, `uname -m`) |
| Environment | `ENVIRONMENT_NAME` (`dev`\|`prod`) |
| Project | `PROJECT_PATH`, `PROJECT_NAME` |
| App | `PHP_VERSION`, `NODE_VERSION`, `SYMFONY_VERSION` |
| Infrastructure | `REDIS_*`, `POSTGRES_*`, `RABBITMQ_*`, `NGINX_*` |
| Docker | `DOCKER_ENVIRONMENT`, `DOCKER_WORKDIR`, `DOCKERFILE_IMAGE_NAME`, `DOCKERFILE_TAG_NAME` |
| Cloud | `GCLOUD_PROJECT_ID`, `GCLOUD_ARTIFACTS_DOCKER_*` |

Always confirm the exact names/defaults in `scripts/base/_abstract.sh` — this list is for reference.

---

## 4. ShellCheck Configuration (`scripts/base/.shellcheckrc`)

The following rules are disabled project-wide — do not flag them in review:

| Rule | Reason |
| --- | --- |
| SC2034 | Unused variable — the variable is consumed in a sourced script |
| SC2168 | `local` outside a function — sourced files are always called inside a function |
| SC1091 | Cannot follow a dynamic `source` path |
| SC2155 | Declare-and-assign separation rule — intentionally combined |
| SC2225 | Arithmetic comparison style |
| SC2024 | `sudo tee` redirect pattern |

`external-sources=true` and `source-path=SCRIPTDIR` are also set.

---

## 5. Lifecycle Functions

Lifecycle-phase functions use `set<PascalCase>`; reusable helpers use `snake_case`. A top-level deployment
script defines and calls its functions in the order below (skeleton example in the output-style §Lifecycle Structure).

| Function | Purpose |
| --- | --- |
| `setStart()` | Timestamped start banner |
| `setEnvironment()` | Interactive environment menu (sets `ENVIRONMENT_NAME`) |
| `setPlatform()` | OS detection / platform-specific config |
| `setProject()` | Source `.env.app`, initialize the project directory |
| `set<Component>()` | Component install/config (`setPhp`·`setRedis`·`setNginx`·`setPostgreSQL`·`setRabbitMQ`·`setSupervisor`·`setDocker`) |
| `setBuild()` | Symfony deployment steps (composer·cache clear) |
| `setDocker()` | Docker build/run |
| `setProvider()` | Cloud provider config (GCP, etc.) |
| `setUtility()` / `setTools()` | Other tools · VM diagnostics/cleanup |
| `setEnd()` | Unset globals, exit banner, `exit 0` |
| `setExit()` | Immediate `kill -SIGKILL $$` on an unrecoverable error |
| `find_project_root()` | Walk directories up to `.git`/`.env.app` |

---

## 6. Interactive Menu (select + PS3)

```bash
setEnvironment() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ENV ] ${PLATFORM_TYPE} - ${PLATFORM_PROCESSOR}"
  echo -e "----------------------------------------------------------------------------------------------------------\n"
  PS3="Menu: "
  select num in "dev" "prod" "exit"; do
    case "$REPLY" in
    1) ENVIRONMENT_NAME="dev";  break ;;
    2) ENVIRONMENT_NAME="prod"; break ;;
    3) echo "exit()"; setEnd ;;
    *) echo "[ ERROR ] Unknown Command"; setEnd ;;
    esac
  done
  echo
}
```

`case` branches on the numeric input (`$REPLY`), not the text label (`$num`).

---

## 7. Multi-Platform Branching

Every platform branch handles all three OSes and calls `setExit` in the `else` — no silent pass-through.

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

Platform blocks consistently use the single-bracket double-equals `[ == ]`, not `[[ ]]`.

---

## 8. Idempotent Package Install

Do not install packages unconditionally. Always check first with `dpkg -l`:

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

- To remove, invert the condition: `if [ "${APT_PKG_INFO}" == "${pkgItem}" ]; then sudo apt remove -y ...`.
- On macOS, use `brew list | grep <pkg>` as the check guard.

---

## 9. Output Format (runtime banners · step labels)

```bash
# Start/end banner (= line, 111 chars)
echo "==============================================================================================================="
echo ">>>>  START                                                                  $(date)"
echo "==============================================================================================================="

# In-function section header (- line, 111 chars)
echo "---------------------------------------------------------------------------------------------------------------"
echo "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Component - Action"
echo "---------------------------------------------------------------------------------------------------------------"

# Step label — always followed by an empty echo
echo ">>>> PHP - Symfony Framework - Deployment - A) Check Requirements"
echo
```

The in-source comment delimiter (120 chars) and header format follow the output-style §Section Delimiters.

---

## 10. Script Taxonomy

| Category | Path | Purpose |
| --- | --- | --- |
| Base | `scripts/base/` | Environment-independent install/config; sourced by both containers and deploy |
| Containers (dev) | `scripts/containers/dev/` | Local Redis·PostgreSQL·RabbitMQ `docker-compose` definitions |
| Containers (prod) | `scripts/containers/prod/` | Production `Dockerfile`·`entrypoint.sh`·Nginx/Supervisor config |
| Deploy (dev) | `scripts/deploy/dev/` | Per-OS initial machine setup (packages·network·security) |
| Deploy (prod) | `scripts/deploy/prod/` | Production server deployment |

**Entrypoint exception:** `scripts/containers/prod/utility/entrypoint.sh` runs in a minimal Docker image
and uses `#!/bin/sh` with `set -e`, not bash. Do not apply bash-only patterns.

---

## 11. Anti-Patterns

| Anti-pattern | Recommended |
| --- | --- |
| Hardcoded user path (`/home/rlim/...`) | `${PROJECT_PATH}`·`${HOME}`·`${USER}` |
| Sourcing `.env.app` without an existence check | An `if [ -f ... ]` guard first |
| `sleep N` timing assumption | `systemctl is-active`·a polling loop·a proper wait condition |
| Repeating the same `dpkg -l` block inline | Extract a shared helper or a `for pkgItem in ...` loop |
| `exit 1` inside a sourced file | `setExit` (SIGKILL) or `setEnd` (normal exit) |
| `#!/usr/bin/env bash` | `#!/bin/bash` |
| Active `set -euo pipefail` | Commented out + explicit error handling |
| `getopts` for environment selection | A `select` + `PS3` menu |
| Unquoted `$VAR` | Always `"${VAR}"` |
| `rm -rf ${VAR}/...` without a null guard | `rm -rf "${VAR:?}/path"` |
| `cat \| grep`·`ls \| grep` | `grep pattern file`·glob·`find` |

---

## 12. Review Checklist

- [ ] Is the shebang `#!/bin/bash` (not `#!/usr/bin/env bash`)?
- [ ] Is `#set -euo pipefail` commented out?
- [ ] Does it bootstrap with `find_project_root` and source `_abstract.sh`?
- [ ] Is every `source` wrapped in a file existence check?
- [ ] Do global variables match the names defined in `_abstract.sh`?
- [ ] Are local variables in the two-line form (`local` declaration then assignment)?
- [ ] Are all variable expansions `"${VAR}"`?
- [ ] Is the interactive menu `select` + `PS3="Menu: "` + `$REPLY`?
- [ ] Does the platform block cover Linux/Darwin/Windows + `else`+`setExit`?
- [ ] Does package installation use the `dpkg -l` idempotent check?
- [ ] Are output banners 111 chars?
- [ ] Do lifecycle functions follow the `set<Component>()` naming?
- [ ] Is `setEnd` called at the bottom of the entry point?
- [ ] Is `setExit` (not `exit 1`) called on an unrecoverable error?
- [ ] Does `rm -rf` have a `"${VAR:?}"` guard?
