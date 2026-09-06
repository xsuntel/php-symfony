#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Base - Platform
# ----------------------------------------------------------------------------------------------------------------------

# >>>> Platform
if [ "${PLATFORM_TYPE}" == "Linux" ]; then
  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Linux - Ubuntu
  # --------------------------------------------------------------------------------------------------------------------
  # >>>> Release
  echo ">>>> Linux - Release"
  echo

  if [ -f /etc/lsb-release ]; then

    local UBUNTU_MAJOR_RELEASE
    UBUNTU_MAJOR_RELEASE=$(grep -i 'DISTRIB_RELEASE' /etc/lsb-release | cut -d "=" -f2 | cut -c 1-2)

    local UBUNTU_UPDATE_MANAGER_PROMPT
    UBUNTU_UPDATE_MANAGER_PROMPT=$(grep -v '#' /etc/update-manager/release-upgrades | grep -i 'Prompt' | cut -d "=" -f2)

    cat /etc/lsb-release
    echo
  fi


elif [ "${PLATFORM_TYPE}" == "Darwin" ]; then
  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Mac - MacOS
  # --------------------------------------------------------------------------------------------------------------------
  # >>>> Release
  echo ">>>> Mac - Release"
  sw_vers
  echo

  # >>>> Rosetta - M1/M2 Chips                                                  https://support.apple.com/en-us/HT211861
  if [ "${PLATFORM_PROCESSOR}" == "arm64" ]; then
    # pgrep exit code (not stdout) signals whether oahd — the Rosetta daemon — is running
    if /usr/bin/pgrep -q oahd; then
      echo "Rosetta has been already installed"
      echo
    else
      echo ">>>> Mac - Rosetta"
      # test softwareupdate directly; an intervening `echo` would clobber $?
      if softwareupdate --install-rosetta --agree-to-license; then
        echo
        echo "This has been successfully installed."
      else
        echo
        echo "This installation failed!"
        setExit
      fi
    fi
  fi


elif [ "${PLATFORM_TYPE}" == "Windows" ]; then
  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Windows - WSL2
  # --------------------------------------------------------------------------------------------------------------------
  # >>>> Release
  echo ">>>> Windows - Release"
  ver
  echo

else
  echo "Please check Operating System"
  setExit
fi
