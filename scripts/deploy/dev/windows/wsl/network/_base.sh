#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Deploy - Dev - Windows - WSL - Network
# ----------------------------------------------------------------------------------------------------------------------
# >>>> Platform
if [ "${PLATFORM_TYPE}" == "Linux" ]; then

    # >>>> Environment
    if [ "${ENVIRONMENT_NAME}" == "dev" ]; then

      # ----------------------------------------------------------------------------------------------------------------
      # Hosts
      # ----------------------------------------------------------------------------------------------------------------

      echo ">>>> Linux - Network"
      echo

      # >>>> Hosts
      local PROJECT_HOST_NAME
      PROJECT_HOST_NAME=$(sudo grep -i "localhost" /etc/hosts | awk '{print $2}' | head -n 1)
      if [ ! "${PROJECT_HOST_NAME}" ]; then
        echo ">>>> Linux - Hosts"
        echo

        echo $'\n127.0.0.1 localhost' | sudo tee -a /etc/hosts
        echo

        sudo grep -v '#' /etc/hosts
        echo
      fi

    fi
else
  echo "Please check Operating System"
  setExit
fi
