#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Console - App - Symfony - Console Commands - Asset
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

echo "---------------------------------------------------------------------------------------------------------------"
echo "[ Symfony ] Console Commands - Asset"
echo "---------------------------------------------------------------------------------------------------------------"
echo

  # >>>> Directory
  if [ -d app ]; then
    (
      cd app || return

      # >>>> PHP - Symfony Command                                        https://symfony.com/doc/current/deployment.html
      if [ -f bin/console ]; then

        # >>>> Select one of some environments
        PS3="Menu: "
        select num in "debug" "importmap:audit" "importmap:outdated" "importmap:update" "tailwind:build" "tailwind:watch" "exit"; do
          case "$REPLY" in
          1)
            CONSOLE_COMMANDS="debug"
            break
            ;;
          2)
            CONSOLE_COMMANDS="importmap:audit"
            break
            ;;
          3)
            CONSOLE_COMMANDS="importmap:outdated"
            break
            ;;
          4)
            CONSOLE_COMMANDS="importmap:update"
            break
            ;;
          5)
            CONSOLE_COMMANDS="tailwind:build"
            break
            ;;
          6)
            CONSOLE_COMMANDS="tailwind:watch"
            break
            ;;
          7)
            echo "exit()"
            exit
            ;;
          *)
            echo "[ ERROR ] Unknown Command"
            exit
            ;;
          esac
        done
        echo

        # --------------------------------------------------------------------------------------------------------------
        # 1) asset-map
        # --------------------------------------------------------------------------------------------------------------
        if [ "${CONSOLE_COMMANDS}" == "debug" ]; then
          echo ">>>> asset-map"
          symfony console debug:asset-map

        # --------------------------------------------------------------------------------------------------------------
        # 2) importmap:audit
        # --------------------------------------------------------------------------------------------------------------
        elif [ "${CONSOLE_COMMANDS}" == "importmap:audit" ]; then
          echo ">>>> importmap:audit"
          symfony console importmap:audit

        # --------------------------------------------------------------------------------------------------------------
        # 3) importmap:outdated
        # --------------------------------------------------------------------------------------------------------------
        elif [ "${CONSOLE_COMMANDS}" == "importmap:outdated" ]; then
          echo ">>>> importmap:updated"
          symfony console importmap:outdated

        # --------------------------------------------------------------------------------------------------------------
        # 4) importmap:update
        # --------------------------------------------------------------------------------------------------------------
        elif [ "${CONSOLE_COMMANDS}" == "importmap:update" ]; then
          echo ">>>> importmap:update"
          symfony console importmap:update

        # --------------------------------------------------------------------------------------------------------------
        # 5) tailwind:build
        # --------------------------------------------------------------------------------------------------------------
        elif [ "${CONSOLE_COMMANDS}" == "tailwind:build" ]; then
          echo ">>>> tailwind:build"
          symfony console tailwind:build

        # --------------------------------------------------------------------------------------------------------------
        # 6) tailwind:build --watch
        # --------------------------------------------------------------------------------------------------------------
        elif [ "${CONSOLE_COMMANDS}" == "tailwind:watch" ]; then
          echo ">>>> tailwind:build --watch -v"
          symfony console tailwind:build --watch -v

        fi
        echo

      else
        echo "[ ERROR ] There is not a command : app/bin/console"
        exit
      fi
    )
  else
    echo "[ ERROR ] There is not a folder : app"
    setExit
  fi
  echo
