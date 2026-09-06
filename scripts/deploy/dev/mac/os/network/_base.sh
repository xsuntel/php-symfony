#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Deploy - Dev - Mac - MacOS - Network
# ----------------------------------------------------------------------------------------------------------------------
# >>>> Platform
if [ "${PLATFORM_TYPE}" == "Darwin" ]; then
    # ------------------------------------------------------------------------------------------------------------------
    # Platform - Mac - MacOS
    # ------------------------------------------------------------------------------------------------------------------
    # >>>> Environment
    if [ "${ENVIRONMENT_NAME}" == "dev" ]; then
      # >>>> Hosts
      local PROJECT_HOST_NAME
      PROJECT_HOST_NAME=$(grep -i "localhost" /etc/hosts | awk '{print $2}' | head -n 1)
      if [ ! "${PROJECT_HOST_NAME}" ]; then
        echo $'\n127.0.0.1 localhost' | sudo tee -a /etc/hosts
        echo
      fi

      echo ">>>> Mac - Hosts"
      echo
      grep -v '#' /etc/hosts
      echo

      # ----------------------------------------------------------------------------------------------------------------
      # Platform - Mac - MacOS
      # ----------------------------------------------------------------------------------------------------------------
      echo ">>>> Mac - Network - Firewall"
      echo

      # Application Firewall global state — read-only status query
      sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
      echo

    fi
else
  echo "Please check Operating System"
  setExit
fi
