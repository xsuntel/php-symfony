#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Deploy - Dev - Windows - WSL - Packages
# ----------------------------------------------------------------------------------------------------------------------
# >>>> Platform
if [ "${PLATFORM_TYPE}" == "Linux" ]; then
    # ------------------------------------------------------------------------------------------------------------------
    # Platform - Linux - Ubuntu
    # ------------------------------------------------------------------------------------------------------------------
    # >>>> Environment
    if [ "${ENVIRONMENT_NAME}" == "dev" ]; then

      echo ">>>> Linux - Packages - Install default applications"
      echo

      # ibus-hangul excluded — WSL has no desktop session; input methods are handled by Windows
      # lsof/net-tools back the `lsof -i` and `netstat` calls in deploy.sh and status.sh
      local addPackageList="curl git wget unzip net-tools lsof"
      for pkgItem in ${addPackageList}; do
        local APT_PKG_INFO
        APT_PKG_INFO=$(dpkg -l | grep -i "${pkgItem}" | awk '{print $2}' | cut -d ':' -f1 | awk "/^${pkgItem}$/")
        if [ "${APT_PKG_INFO}" != "${pkgItem}" ]; then
          sudo apt install -y "${pkgItem}"
          echo
        fi
      done

      local addPackageList="shfmt shellcheck"
      for pkgItem in ${addPackageList}; do
        local APT_PKG_INFO
        APT_PKG_INFO=$(dpkg -l | grep -i "${pkgItem}" | awk '{print $2}' | cut -d ':' -f1 | awk "/^${pkgItem}$/")
        if [ "${APT_PKG_INFO}" != "${pkgItem}" ]; then
          sudo apt install -y "${pkgItem}"
          echo
        fi
      done
      echo

      # >>>> Packages - Remove default applications — desktop-only sections omitted (no desktop session on WSL)

      service --status-all | grep '\[ + \]'
      echo

    fi
else
  echo "Please check Operating System"
  setExit
fi
