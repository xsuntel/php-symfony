#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Tools - AI - Anthropic - Claude Code - Install
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


# >>>> Claude Code - Resolve the executable
# The installer wires ~/.local/bin into the shell profile, which only affects NEW shells.
# Resolve the binary explicitly so this run works before the profile is re-sourced.
claude_resolve_bin() {
  if command -v claude >/dev/null 2>&1; then
    command -v claude
    return 0
  fi

  if [ -x "${HOME}/.local/bin/claude" ]; then
    echo "${HOME}/.local/bin/claude"
    return 0
  fi

  return 1
}

# >>>> Claude Code - Install                                             https://claude.ai/install.sh
claude_install() {
  local INSTALLER_PATH
  INSTALLER_PATH=$(mktemp -t claude-install.XXXXXX) || return 1
  # setExit sends SIGKILL, which skips traps — every exit path below also removes the file
  trap 'rm -f "${INSTALLER_PATH}"' EXIT

  # Piping curl into bash hides curl's exit status while pipefail is disabled,
  # so download to a file and check it before executing
  if ! curl -fsSL https://claude.ai/install.sh -o "${INSTALLER_PATH}"; then
    echo "[ ERROR ] Failed to download the Claude Code installer"
    rm -f "${INSTALLER_PATH}"
    trap - EXIT
    return 1
  fi

  if [ ! -s "${INSTALLER_PATH}" ]; then
    echo "[ ERROR ] The downloaded installer is empty"
    rm -f "${INSTALLER_PATH}"
    trap - EXIT
    return 1
  fi

  # 'stable' pins the verified release channel; the installer rejects any other token.
  # No sudo — the installer refuses it and would install into root's home.
  bash "${INSTALLER_PATH}" stable
  # One-line assignment is required here: the 2-line form would capture `local`'s own status
  local INSTALL_STATUS=$?

  rm -f "${INSTALLER_PATH}"
  trap - EXIT

  return ${INSTALL_STATUS}
}

# >>>> Claude Code - Verify
claude_verify() {
  local CLAUDE_BIN
  if ! CLAUDE_BIN=$(claude_resolve_bin); then
    echo "[ ERROR ] Claude Code is not found after installation"
    setExit
  fi

  echo ">>>> Claude Code - Version"
  echo
  "${CLAUDE_BIN}" --version
  echo

  echo ">>>> Claude Code - Doctor"
  echo
  "${CLAUDE_BIN}" doctor
  echo

  # PATH is exported before the installer edits the profile, so warn instead of failing
  case ":${PATH}:" in
    *":${HOME}/.local/bin:"*)
      ;;
    *)
      echo "[ WARN ] ${HOME}/.local/bin is not in PATH of this shell"
      echo "         Open a new shell, or run : source ${HOME}/.bashrc"
      echo
      ;;
  esac
}

# ----------------------------------------------------------------------------------------------------------------------
# Abstract
# ----------------------------------------------------------------------------------------------------------------------

if [ -f "${PROJECT_PATH}/scripts/base/_abstract.sh" ]; then
  source "${PROJECT_PATH}/scripts/base/_abstract.sh"
else
  echo "Please check a file : ./scripts/base/_abstract.sh" && exit
fi

# >>>> Environment

setEnvironment() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ENV ] ${PLATFORM_TYPE} - ${PLATFORM_PROCESSOR}"
  echo -e "----------------------------------------------------------------------------------------------------------\n"
  PS3="Menu: "
  select num in "dev" "exit"; do
    case "$REPLY" in
    1)
      # >>>> Dev Environment
      ENVIRONMENT_NAME="dev"
      break
      ;;
    2)
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
  echo "- PROJECT ENV : ${ENVIRONMENT_NAME}"
  echo
}

# >>>> Platform

setPlatform() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Platform"
  echo -e "----------------------------------------------------------------------------------------------------------\n"
}

# >>>> Project

setProject() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Project : ${PROJECT_NAME}"
  echo -e "----------------------------------------------------------------------------------------------------------\n"
}

# >>>> Tools

setTools() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Tools - Claude Code"
  echo -e "----------------------------------------------------------------------------------------------------------\n"

  # >>>> Permission
  # The installer writes into $HOME and refuses sudo; under sudo it would target root's home
  # and the 'claude' command would not resolve from the user's own shell.
  if [ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
    echo "[ ERROR ] Do not run this script with sudo"
    echo "          Claude Code installs into ${HOME} and does not need root access."
    setExit
  fi

  # >>>> Platform - Prerequisites
  if [ "${PLATFORM_TYPE}" == "Linux" ]; then
  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Linux - Ubuntu
  # --------------------------------------------------------------------------------------------------------------------

    # >>>> WSL2 kernel is tagged "-microsoft-standard-WSL2" — informational only
    if grep -qi "microsoft" /proc/sys/kernel/osrelease; then
      echo ">>>> Linux - WSL2 : $(uname -r)"
    else
      echo ">>>> Linux - Kernel : $(uname -r)"
    fi
    echo

    # >>>> Packages — curl is required by the installer, jq stabilises manifest parsing
    echo ">>>> Claude Code - Packages"
    echo

    if command -v dpkg >/dev/null 2>&1; then
      local addPackageList="curl jq"
      for pkgItem in ${addPackageList}; do
        local APT_PKG_INFO
        APT_PKG_INFO=$(dpkg -l | grep -i "${pkgItem}" | awk '{print $2}' | cut -d ':' -f1 | awk "/^${pkgItem}$/")
        if [ "${APT_PKG_INFO}" != "${pkgItem}" ]; then
          sudo apt-get install -y "${pkgItem}"
          echo
        fi
      done
    fi

    if ! command -v curl >/dev/null 2>&1; then
      echo "[ ERROR ] curl is required but not installed"
      setExit
    fi

  elif [ "${PLATFORM_TYPE}" == "Darwin" ]; then
  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Mac - MacOS
  # --------------------------------------------------------------------------------------------------------------------

    echo ">>>> Mac - Release : $(sw_vers -productVersion)"
    echo

    # >>>> Packages — curl ships with macOS, so only jq is installed here
    echo ">>>> Claude Code - Packages"
    echo

    if command -v brew >/dev/null 2>&1; then
      if ! brew list jq >/dev/null 2>&1; then
        brew install jq
        echo
      fi
    else
      echo "[ ERROR ] Homebrew is not installed"
      echo "          Run the base packages script first : ./scripts/deploy/dev/mac/os/deploy.sh"
      setExit
    fi

  elif [ "${PLATFORM_TYPE}" == "Windows" ]; then
  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Windows - WSL2
  # --------------------------------------------------------------------------------------------------------------------

    # `uname -s` reports "Linux" inside WSL2, so this branch is only reached from
    # MSYS/Git Bash shells, where the native installer has no supported target.
    echo "[ ERROR ] Run this script inside a WSL2 Ubuntu shell"
    echo "          Setup guide : ./scripts/tools/ai/anthropic/claude/_ABSTRACT.md"
    setExit

  else
    echo "Please check Operating System"
    setExit
  fi

  # >>>> Claude Code - Install or Update
  local CLAUDE_BIN
  if CLAUDE_BIN=$(claude_resolve_bin); then
    echo ">>>> Claude Code - Update : $("${CLAUDE_BIN}" --version)"
    echo
    "${CLAUDE_BIN}" update
    echo
  else
    echo ">>>> Claude Code - Install"
    echo
    if ! claude_install; then
      echo "[ ERROR ] Claude Code installation failed"
      setExit
    fi
    echo
  fi

  # >>>> Claude Code - Verify
  claude_verify
}


# ----------------------------------------------------------------------------------------------------------------------
# START
# ----------------------------------------------------------------------------------------------------------------------

setStart

# ----------------------------------------------------------------------------------------------------------------------
# Abstract
# ----------------------------------------------------------------------------------------------------------------------

# >>>> Environment
setEnvironment

# >>>> Platform
setPlatform

# >>>> Project
setProject

# >>>> Tools
setTools

# ----------------------------------------------------------------------------------------------------------------------
# END
# ----------------------------------------------------------------------------------------------------------------------

setEnd
