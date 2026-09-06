#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Console - App - Symfony - Console Commands - Messenger
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
echo "[ Symfony ] Console Commands - Messenger"
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
        select num in "debug" "scheduler" "messenger" "consume" "stats" "failed" "remove" "stop" "exit"; do
          case "$REPLY" in
          1)
            CONSOLE_COMMANDS="debug"
            break
            ;;
          2)
            CONSOLE_COMMANDS="scheduler"
            break
            ;;
          3)
            CONSOLE_COMMANDS="messenger"
            break
            ;;
          4)
            CONSOLE_COMMANDS="consume"
            break
            ;;
          5)
            CONSOLE_COMMANDS="stats"
            break
            ;;
          6)
            CONSOLE_COMMANDS="failed"
            break
            ;;
          7)
            CONSOLE_COMMANDS="remove"
            break
            ;;
          8)
            CONSOLE_COMMANDS="stop"
            break
            ;;
          9)
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
        # 1) debug
        # --------------------------------------------------------------------------------------------------------------
        if [ "${CONSOLE_COMMANDS}" == "debug" ]; then
          echo ">>>> debug"
          symfony console debug:messenger
          echo

          echo ">>>> debug"
          php bin/console debug:container --show-arguments messenger.bus.default.inner
          echo

        # --------------------------------------------------------------------------------------------------------------
        # 2) scheduler
        # --------------------------------------------------------------------------------------------------------------
        elif [ "${CONSOLE_COMMANDS}" == "scheduler" ]; then
          echo ">>>> scheduler"
          symfony console debug:scheduler

        # --------------------------------------------------------------------------------------------------------------
        # 3) messenger
        # --------------------------------------------------------------------------------------------------------------
        elif [ "${CONSOLE_COMMANDS}" == "messenger" ]; then
          echo ">>>> consume"
          symfony console messenger:consume --all -vv

        # --------------------------------------------------------------------------------------------------------------
        # 4) consume
        # --------------------------------------------------------------------------------------------------------------
        elif [ "${CONSOLE_COMMANDS}" == "consume" ]; then
          echo ">>>> consume"
          symfony console messenger:consume --all -vv

        # --------------------------------------------------------------------------------------------------------------
        # 5) stats
        # --------------------------------------------------------------------------------------------------------------
        elif [ "${CONSOLE_COMMANDS}" == "stats" ]; then
          echo ">>>> stats"
          symfony console messenger:stats

        # --------------------------------------------------------------------------------------------------------------
        # 6) failed
        # --------------------------------------------------------------------------------------------------------------
        elif [ "${CONSOLE_COMMANDS}" == "failed" ]; then
          echo ">>>> failed"
          symfony console messenger:failed:show --stats

        # --------------------------------------------------------------------------------------------------------------
        # 7) remove
        # --------------------------------------------------------------------------------------------------------------
        elif [ "${CONSOLE_COMMANDS}" == "remove" ]; then
          echo ">>>> remove"
          symfony console messenger:failed:remove --all

        # --------------------------------------------------------------------------------------------------------------
        # 8) stop
        # --------------------------------------------------------------------------------------------------------------
        elif [ "${CONSOLE_COMMANDS}" == "stop" ]; then
          echo ">>>> stop"
          symfony console messenger:stop-workers
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
