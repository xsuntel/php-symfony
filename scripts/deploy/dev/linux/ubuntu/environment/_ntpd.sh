#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Deploy - Dev - Linux - Ubuntu - NTP
# ----------------------------------------------------------------------------------------------------------------------
# >>>> Platform
if [ "${PLATFORM_TYPE}" == "Linux" ]; then

    # >>>> Environment
    if [ "${ENVIRONMENT_NAME}" == "dev" ]; then

      echo ">>>> Linux - TimeZone"
      echo

      if ! dpkg -s systemd-timesyncd >/dev/null 2>&1; then
        echo "Installing systemd-timesyncd..."

        sudo apt update -y || true
        sudo apt install -y systemd-timesyncd
      fi

      if systemctl list-unit-files | grep -q "systemd-timesyncd.service"; then
        echo "Service unit found. Configuring..."

        if [ -f "/etc/systemd/timesyncd.conf" ]; then
          sudo sed -i 's/^#NTP=/NTP=0.kr.pool.ntp.org 1.kr.pool.ntp.org/' /etc/systemd/timesyncd.conf
          sudo sed -i 's/^#FallbackNTP=/FallbackNTP=ntp.ubuntu.com/' /etc/systemd/timesyncd.conf
        fi

        sudo systemctl enable systemd-timesyncd
        sudo systemctl restart systemd-timesyncd
        sudo timedatectl set-ntp yes
      else
        echo "Error: systemd-timesyncd package installation failed."
      fi
      echo

      timedatectl
      echo

    fi
else
  echo "Please check Operating System"
  setExit
fi
