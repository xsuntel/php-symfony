#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Deploy - Dev - Windows - WSL - Security - directories
# ----------------------------------------------------------------------------------------------------------------------
# >>>> Platform
if [ "${PLATFORM_TYPE}" == "Linux" ]; then

    # >>>> Environment
    if [ "${ENVIRONMENT_NAME}" == "dev" ]; then

      echo ">>>> Linux - Security - directories"
      echo

      # >>>> booting - systemd
      sudo chown root:root /etc/sysctl.conf
      sudo chmod 600 /etc/sysctl.conf
      sudo ls -l /etc/sysctl.conf

      # >>>> network - hosts
      sudo chown root:root /etc/hosts
      sudo chmod 644 /etc/hosts
      sudo ls -l /etc/hosts

      if [ -f /etc/hosts.equiv ]; then
        sudo rm -rf /etc/hosts.equiv
      fi

      if [ -d ~/.rhosts ]; then
        sudo rm -rf ~/.rhosts
      fi

      # >>>> process - rsyslog
      sudo chown root:root /etc/rsyslog.conf
      sudo chmod 640 /etc/rsyslog.conf
      sudo ls -l /etc/rsyslog.conf

      # >>>> process - crontab
      sudo chown root:root /etc/crontab
      sudo chmod 640 /etc/crontab

      sudo chown root:root /etc/cron.d/
      sudo chmod 640 /etc/cron.d/

      sudo chown root:root /etc/cron.daily/
      sudo chmod 640 /etc/cron.daily/

      sudo chown root:root /etc/cron.hourly/
      sudo chmod 640 /etc/cron.hourly/

      sudo chown root:root /etc/cron.monthly/
      sudo chmod 640 /etc/cron.monthly/

      sudo chown root:root /etc/cron.weekly/
      sudo chmod 640 /etc/cron.weekly/

      sudo chown root:root /etc/cron.yearly/
      sudo chmod 640 /etc/cron.yearly/

      # >>>> process - services
      sudo chown root:root /etc/services
      sudo chmod 644 /etc/services
      sudo ls -l /etc/services

      # >>>> security - groups
      sudo chown root:root /etc/group
      sudo chmod 644 /etc/group
      sudo ls -l /etc/group

      sudo chown root:root /etc/gshadow
      sudo chmod 644 /etc/gshadow
      sudo ls -l /etc/gshadow

      # >>>> security - users
      sudo chown root:root /etc/passwd
      sudo chmod 644 /etc/passwd
      sudo ls -l /etc/passwd

      sudo chown root:root /etc/shadow
      sudo chmod 400 /etc/shadow
      sudo ls -l /etc/shadow

      sudo chown root:root /etc/login.defs
      sudo chmod 400 /etc/login.defs
      sudo ls -l /etc/login.defs

    fi
else
  echo "Please check Operating System"
  setExit
fi
