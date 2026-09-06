#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Base - App - Symfony Framework - Deployment - Other Things   https://symfony.com/doc/current/deployment.html
# ----------------------------------------------------------------------------------------------------------------------

# >>>> App
if [ -d app ]; then
  (
    cd app || return
    if [ -f bin/console ]; then

      # ----------------------------------------------------------------------------------------------------------------
      # F) Other Things - Add/edit CRON jobs
      # ----------------------------------------------------------------------------------------------------------------
      echo ">>>> PHP - Symfony Framework - Deployment - F) Other Things - Add/edit CRON jobs"
      echo

      # >>>> Add/edit CRON jobs

    else
      echo "[ ERROR ] There is not a command : app/bin/console"
      setExit
    fi
  )
fi
