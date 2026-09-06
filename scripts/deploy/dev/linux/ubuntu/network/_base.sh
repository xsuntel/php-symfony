#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Deploy - Dev - Linux - Ubuntu - Network
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

      # ----------------------------------------------------------------------------------------------------------------
      # Network
      # ----------------------------------------------------------------------------------------------------------------

      local UBUNTU_MAJOR_RELEASE
      UBUNTU_MAJOR_RELEASE=$(grep -i 'DISTRIB_RELEASE' /etc/lsb-release | cut -d "=" -f2 | cut -c 1-2)
      if [ "${UBUNTU_MAJOR_RELEASE}" -lt 26 ]; then
        # >>>> Kernel - Network - ipv4
        sudo sed -i 's/^net.ipv4.icmp_echo_ignore_all=0/net.ipv4.icmp_echo_ignore_all=1/' /etc/sysctl.conf
        sudo sysctl -w net.ipv4.icmp_echo_ignore_all=1
        echo
      else
        echo ">>>> This Linux is Ubuntu ${UBUNTU_MAJOR_RELEASE}"
      fi

    fi
else
  echo "Please check Operating System"
  setExit
fi
