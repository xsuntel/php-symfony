#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Base - App - Symfony Framework - Deployment - Other Things   https://symfony.com/doc/current/deployment.html
# ----------------------------------------------------------------------------------------------------------------------

# >>>> Platform
if [ "${PLATFORM_TYPE}" == "Linux" ]; then
  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Linux - Ubuntu
  # --------------------------------------------------------------------------------------------------------------------
  # >>>> Environment
  if [ "${ENVIRONMENT_NAME}" == "prod" ]; then
    # >>>> Supervisor - Start process
    supervisorctl reread
    echo

    supervisorctl update
    echo

    supervisorctl start messenger-consume:*
    echo

    supervisorctl status
    echo
  fi

elif [ "${PLATFORM_TYPE}" == "Darwin" ]; then
  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Mac - MacOS
  # --------------------------------------------------------------------------------------------------------------------
  # >>>> Environment
  if [ "${ENVIRONMENT_NAME}" == "prod" ]; then
    # >>>> Supervisor - Start process
    supervisorctl -c /opt/homebrew/etc/supervisord.conf reread
    echo

    supervisorctl update
    echo

    supervisorctl start messenger-consume:*
    echo

    supervisorctl status
    echo
  fi

elif [ "${PLATFORM_TYPE}" == "Windows" ]; then
  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Windows - WSL2
  # --------------------------------------------------------------------------------------------------------------------
  # >>>> Environment
  if [ "${ENVIRONMENT_NAME}" == "prod" ]; then
    # >>>> Supervisor
    echo ">>>> Windows - Processer - Supervisor"
    echo
  fi

else
  echo "Please check Operating System"
  setExit
fi

# >>>> App
if [ -d app ]; then
  (
    cd app || return
    if [ -f bin/console ]; then

      # ----------------------------------------------------------------------------------------------------------------
      # G) Other Things - Restarting your workers for Messenger: Sync & Queued Message Handling
      # ----------------------------------------------------------------------------------------------------------------
      echo ">>>> PHP - Symfony Framework - Deployment - G) Other Things - Restarting your workers for Messenger: Sync & Queued Message Handling"
      echo

      symfony console messenger:setup-transports

      # >>>> Restarting your workers
      if [ "${PLATFORM_TYPE}" == "Linux" ]; then
        if [ "${ENVIRONMENT_NAME}" == "prod" ]; then
          supervisorctl restart messenger-consume:*
          echo
        fi
      fi

    else
      echo "[ ERROR ] There is not a command : app/bin/console"
      setExit
    fi
  )
fi
