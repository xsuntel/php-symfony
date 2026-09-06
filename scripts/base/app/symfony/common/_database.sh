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
      # E) Other Things - Running any database migrations
      # ----------------------------------------------------------------------------------------------------------------
      echo ">>>> PHP - Symfony Framework - Deployment - E) Other Things - Running any database migrations"
      echo

      # >>>> Running any database migrations


    else
      echo "[ ERROR ] There is not a command : app/bin/console"
      setExit
    fi
  )
fi
