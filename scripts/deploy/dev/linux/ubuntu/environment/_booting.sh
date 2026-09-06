#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Deploy - Dev - Linux - Ubuntu - Booting - systemd - service
# ----------------------------------------------------------------------------------------------------------------------
# >>>> Platform
if [ "${PLATFORM_TYPE}" == "Linux" ]; then

    # >>>> Environment
    if [ "${ENVIRONMENT_NAME}" == "dev" ]; then

      # ----------------------------------------------------------------------------------------------------------------
      # systemd - service
      # ----------------------------------------------------------------------------------------------------------------

      echo ">>>> Linux - Service"
      echo

      if [ -f /etc/rc.local ]; then
        sudo cp -fv "${PROJECT_PATH}/scripts/deploy/dev/linux/ubuntu/environment/etc/rc.local" /etc/rc.local
        sudo systemctl status rc-local.service  --no-pager
        echo
      else

        sudo cp -fv "${PROJECT_PATH}/scripts/deploy/dev/linux/ubuntu/environment/etc/rc.local" /etc/rc.local
        sudo chmod +x /etc/rc.local
        echo

        sudo systemctl enable rc-local.service
        sudo systemctl start rc-local.service
        echo

      fi
      echo

      if [ -f /etc/xdg/autostart/org.gnome.SettingsDaemon.Smartcard.desktop ]; then
        systemctl --user mask org.gnome.SettingsDaemon.Smartcard.service
      fi

      if [ -f /etc/xdg/autostart/org.gnome.SettingsDaemon.Wacom.desktop ]; then
        systemctl --user mask org.gnome.SettingsDaemon.Wacom.service
      fi
      echo

    fi
else
  echo "Please check Operating System"
  setExit
fi
