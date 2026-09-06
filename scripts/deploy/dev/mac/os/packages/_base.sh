#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Deploy - Dev - Mac - MacOS - Packages
# ----------------------------------------------------------------------------------------------------------------------
# >>>> Platform
if [ "${PLATFORM_TYPE}" == "Darwin" ]; then
    # ------------------------------------------------------------------------------------------------------------------
    # Platform - Mac - MacOS
    # ------------------------------------------------------------------------------------------------------------------
    # >>>> Environment
    if [ "${ENVIRONMENT_NAME}" == "dev" ]; then

      # >>>> Packages                                                                                    https://brew.sh
      echo ">>>> Mac - Packages"

      # Homebrew prefix differs by CPU: Apple Silicon uses /opt/homebrew, Intel uses /usr/local.
      if [ "${PLATFORM_PROCESSOR}" == "arm64" ]; then
        BREW_PREFIX="/opt/homebrew"
      else
        BREW_PREFIX="/usr/local"
      fi

      if [ -f "${BREW_PREFIX}/bin/brew" ]; then
        ls -ltr "${BREW_PREFIX}/bin/brew"
        echo
      else
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Append brew shellenv only once — re-running must not duplicate the line.
        # Keep $(...) literal (escaped) so login shells evaluate it later; only ${BREW_PREFIX} expands now.
        BREW_SHELLENV="eval \"\$(${BREW_PREFIX}/bin/brew shellenv)\""
        if ! grep -qsF "${BREW_SHELLENV}" "${HOME}/.zprofile"; then
          echo "${BREW_SHELLENV}" >>"${HOME}/.zprofile"
        fi
        # Apply brew paths to the current session without eval (rule: eval is prohibited).
        export PATH="${BREW_PREFIX}/bin:${BREW_PREFIX}/sbin:${PATH}"
        echo
      fi

    fi
else
  echo "Please check Operating System"
  setExit
fi
