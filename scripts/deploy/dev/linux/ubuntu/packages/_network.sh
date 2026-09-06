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

      # >>>> Packages - Remove openssh-server
      local SSHD_STATUS
      SSHD_STATUS=$(systemctl is-active sshd)
      if [ "${SSHD_STATUS}" == "active" ]; then
        sudo systemctl stop sshd
        sudo systemctl disable sshd
      fi
      echo

      local delPackageList="openssh-server telnet telnetd ldap-utils openvpn"
      for pkgItem in ${delPackageList}; do
        local APT_PKG_INFO
        APT_PKG_INFO=$(dpkg -l | grep -i "${pkgItem}" | awk '{print $2}' | cut -d ':' -f1 | awk "/^${pkgItem}$/")
        if [ "${APT_PKG_INFO}" == "${pkgItem}" ]; then
          sudo apt purge -y "${pkgItem}"
          echo
        fi
      done

      # >>>> Packages - Remove related network packages
      local delPackageList="putty putty-tools nmap remmina ModemManager amagent openvpn"
      for pkgItem in ${delPackageList}; do
        local APT_PKG_INFO
        APT_PKG_INFO=$(dpkg -l | grep -i "${pkgItem}" | awk '{print $2}' | cut -d ':' -f1 | awk "/^${pkgItem}$/")
        if [ "${APT_PKG_INFO}" == "${pkgItem}" ]; then
          sudo apt purge -y "${pkgItem}"
          echo
        fi
      done

    fi
else
  echo "Please check Operating System"
  setExit
fi
