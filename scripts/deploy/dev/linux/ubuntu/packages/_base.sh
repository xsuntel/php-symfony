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

      echo ">>>> Linux - Packages - Install default applications"
      echo

      local addPackageList="curl git wget unzip net-tools ibus-hangul"
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

      echo ">>>> Linux - Packages - Remove default applications"
      echo

      # >>>> Packages - Remove default applications
      local delPackageList="gnome-mahjongg gnome-sudoku aisleriot tss speech-dispatcher"
      for pkgItem in ${delPackageList}; do
        local APT_PKG_INFO
        APT_PKG_INFO=$(dpkg -l | grep -i "${pkgItem}" | awk '{print $2}' | cut -d ':' -f1 | awk "/^${pkgItem}$/")
        if [ "${APT_PKG_INFO}" == "${pkgItem}" ]; then
          sudo apt remove -y "${pkgItem}"
          echo
        fi
      done

      # >>>> Packages - Disable gnome-shell extensions            https://manpages.ubuntu.com/manpages/focal/en/man1/gsettings.1.html
      local delPackageList="evolution evolution-common evolution-plugins evolution-data-server"
      for pkgItem in ${delPackageList}; do
        local APT_PKG_INFO
        APT_PKG_INFO=$(dpkg -l | grep -i "${pkgItem}" | awk '{print $2}' | cut -d ':' -f1 | awk "/^${pkgItem}$/")
        if [ "${APT_PKG_INFO}" == "${pkgItem}" ]; then
          sudo apt purge -y "${pkgItem}"
          echo
        fi
      done

      if [ -d ~/.local/share/gnome-shell/extensions ]; then
        # Glob the directory rather than parsing ls — an extension name may contain whitespace.
        # The -d test also skips the unexpanded glob when no extension is installed.
        for ext in ~/.local/share/gnome-shell/extensions/*/; do
          [ -d "${ext}" ] || continue
          gnome-shell-extension-tool -d "$(basename "${ext}")"
        done
      fi
      gsettings set org.gnome.shell disable-user-extensions true
      echo

      service --status-all | grep '\[ + \]'
      echo

    fi
else
  echo "Please check Operating System"
  setExit
fi
