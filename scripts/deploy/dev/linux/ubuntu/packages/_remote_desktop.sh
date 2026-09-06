#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Deploy - Dev - Linux - Ubuntu - Packages
# ----------------------------------------------------------------------------------------------------------------------
# >>>> Platform
if [ "${PLATFORM_TYPE}" == "Linux" ]; then
    # ------------------------------------------------------------------------------------------------------------------
    # Platform - Linux - Ubuntu
    # ------------------------------------------------------------------------------------------------------------------
    # >>>> Environment
    if [ "${ENVIRONMENT_NAME}" == "dev" ]; then

      # >>>> Packages - Remove gnome-remote-desktop
      local delPackageList="gnome-remote-desktop"
      for pkgItem in ${delPackageList}; do
        local APT_PKG_INFO
        APT_PKG_INFO=$(dpkg -l | grep -i "${pkgItem}" | awk '{print $2}' | cut -d ':' -f1 | awk "/^${pkgItem}$/")
        if [ "${APT_PKG_INFO}" == "${pkgItem}" ]; then
          sudo apt purge -y "${pkgItem}"
          echo
        fi
      done

      local delUserList="gnome-remote-desktop"
      for userItem in ${delUserList}; do
        local USER_LIST
        USER_LIST=$(awk -F: '{print $1}' /etc/passwd | grep -i "${userItem}")
        if [ "${USER_LIST}" == "${userItem}" ]; then
          sudo userdel "${userItem}"
        fi
      done

      if [ -f /etc/xdg/autostart/org.gnome.SettingsDaemon.Sharing.desktop ]; then
        systemctl --user mask org.gnome.SettingsDaemon.Sharing.service
      fi

    fi
else
  echo "Please check Operating System"
  setExit
fi
