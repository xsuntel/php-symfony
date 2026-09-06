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
      # D) Clear your Symfony Cache
      # ----------------------------------------------------------------------------------------------------------------
      echo ">>>> PHP - Symfony Framework - Deployment - Fixing File Permissions"
      echo

      if [ "${PLATFORM_TYPE}" == "Linux" ]; then
        if [ "${ENVIRONMENT_NAME}" == "prod" ]; then
          # Not pgrep: this is the form published at https://symfony.com/doc/current/setup/file_permissions.html
          # and it needs the user column, which pgrep does not report.
          # shellcheck disable=SC2009
          HTTPDUSER="$(ps axo user,comm | grep -E '[a]pache|[h]ttpd|[_]www|[w]ww-data|[n]ginx' | grep -v root | head -1 | cut -d\  -f1)"

          sudo usermod -a -G "${HTTPDUSER}" "$(whoami)"
          sudo chown "${HTTPDUSER}":"${HTTPDUSER}" -R ./*

          if [ -d var ]; then
            sudo setfacl -dR -m g:"${HTTPDUSER}":rwX -m u:"$(whoami)":rwX ./var
            sudo setfacl -R -m g:"${HTTPDUSER}":rwX -m u:"$(whoami)":rwX ./var

            sudo chmod 777 -R ./var
          fi
        fi

      else
        echo "Please check Operating System"
        setExit
      fi

    else
      echo "[ ERROR ] There is not a command : app/bin/console"
      setExit
    fi
  )
fi
