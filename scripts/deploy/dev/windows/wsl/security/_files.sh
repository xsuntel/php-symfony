#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Deploy - Dev - Windows - WSL - Security - files
# ----------------------------------------------------------------------------------------------------------------------
# >>>> Platform
if [ "${PLATFORM_TYPE}" == "Linux" ]; then

    # >>>> Environment
    if [ "${ENVIRONMENT_NAME}" == "dev" ]; then

      echo ">>>> Linux - Security - files"
      echo

      # WSL2 has no TPM/udev hardware stack — masking these units is a no-op here
      if ! grep -qi "microsoft" /proc/sys/kernel/osrelease; then
        sudo ln -sf /dev/null /etc/tmpfiles.d/tpm-udev.conf

        sudo ln -sf /dev/null /usr/lib/udev/rules.d/60-tpm-udev.rules
      else
        echo ">>>> Skipped on WSL2 : TPM/udev masking (no hardware stack)"
      fi

      sudo find /var/log -type f -regex ".*\.log\.[0-9]+$" -delete

      sudo find /var/log -type f -regex ".*\.[0-9]+\.gz$" -delete

      # >>>> supervisor

      sudo rm -f /var/log/supervisor/messenger-consume*

      # >>>> journalctl
      sudo journalctl --rotate
      sudo journalctl --vacuum-time=1s

      sudo journalctl --vacuum-size=32M

    fi
else
  echo "Please check Operating System"
  setExit
fi
