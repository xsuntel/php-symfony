#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Deploy - Dev - Mac - MacOS - Security - users
# ----------------------------------------------------------------------------------------------------------------------
# >>>> Platform
if [ "${PLATFORM_TYPE}" == "Darwin" ]; then
    # ------------------------------------------------------------------------------------------------------------------
    # Platform - Mac - MacOS
    # ------------------------------------------------------------------------------------------------------------------
    # >>>> Environment
    if [ "${ENVIRONMENT_NAME}" == "dev" ]; then

      echo ">>>> Mac - Security - Users"
      echo

      # >>>> User - profile
      # macOS default login shell is zsh — set the file creation mask in ~/.zprofile.
      local ZPROFILE_PATH
      ZPROFILE_PATH="${HOME}/.zprofile"
      if ! grep -qsF "umask 022" "${ZPROFILE_PATH}"; then
        {
          echo "# Default File Creation Mask"
          echo "umask 022"
        } >>"${ZPROFILE_PATH}"
        echo "${ZPROFILE_PATH} -> umask 022"
        echo
      fi

      # >>>> User - Group membership (read-only)
      # macOS accounts are managed by Directory Service; system daemons are _-prefixed.
      # Never delete accounts here — only report the current user's groups.
      echo ">>>> Mac - Security - Group"
      echo

      id -Gn "${USER}"
      echo

      dscl . -read "/Users/${USER}" NFSHomeDirectory PrimaryGroupID 2>/dev/null
      echo

    fi
else
  echo "Please check Operating System"
  setExit
fi
