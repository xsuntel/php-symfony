#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Deploy - Dev - Linux - Ubuntu - Power
# ----------------------------------------------------------------------------------------------------------------------
# >>>> Platform
if [ "${PLATFORM_TYPE}" == "Linux" ]; then

    # >>>> Environment
    if [ "${ENVIRONMENT_NAME}" == "dev" ]; then

      # ----------------------------------------------------------------------------------------------------------------
      # Power
      # ----------------------------------------------------------------------------------------------------------------

      echo ">>>> Linux - Power"
      echo

      # Display
      gsettings set org.gnome.desktop.session idle-delay 0

      # AC Power
      gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'

      # Bettery
      gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'

      # System
      sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

    fi
else
  echo "Please check Operating System"
  setExit
fi
