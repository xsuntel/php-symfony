#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Deploy - Dev - Windows - WSL - Cron
# ----------------------------------------------------------------------------------------------------------------------
# >>>> Platform
if [ "${PLATFORM_TYPE}" == "Linux" ]; then

    # >>>> Environment
    if [ "${ENVIRONMENT_NAME}" == "dev" ]; then

      # ----------------------------------------------------------------------------------------------------------------
      # Cron
      # ----------------------------------------------------------------------------------------------------------------

      echo ">>>> Linux - Cron"
      echo

      # >>>> /etc/cron.allow
      if [ ! -f /etc/cron.allow ]; then
        sudo touch /etc/cron.allow

        # Use a dedicated loop variable — reusing USER would clobber the login user's env
        ALLOWED_USERS="root ${USER}"
        for cronUser in $ALLOWED_USERS; do
            if id "$cronUser" &>/dev/null; then
                echo "$cronUser" | sudo tee -a /etc/cron.allow > /dev/null
                echo "  >> User '$cronUser' registered"
            else
                echo "  >> [WARN] User '$cronUser' does not exist on the system. Skipping."
            fi
        done
        sudo chmod 644 /etc/cron.allow
        sudo chown root:root /etc/cron.allow
        echo
      fi

      # >>>> /etc/cron.deny
      if [ -f /etc/cron.deny ]; then
        sudo mv /etc/cron.deny /etc/cron.deny.bak
      fi

      # ----------------------------------------------------------------------------------------------------------------
      # Cron - Copy Files
      # ----------------------------------------------------------------------------------------------------------------

      # >>>> Process - App
      if [ -f "${PROJECT_PATH}/scripts/deploy/dev/windows/wsl/environment/usr/local/bin/symfony-scripts-logs.sh" ]; then
        sudo cp -fv "${PROJECT_PATH}/scripts/deploy/dev/windows/wsl/environment/usr/local/bin/symfony-scripts-logs.sh" /usr/local/bin/symfony-scripts-logs.sh
        sudo chmod +x /usr/local/bin/symfony-scripts-logs.sh
        echo
      fi

      # >>>> Process - Logs
      if [ -f "${PROJECT_PATH}/scripts/deploy/dev/windows/wsl/environment/usr/local/bin/ubuntu-var-logs.sh" ]; then
        sudo cp -fv "${PROJECT_PATH}/scripts/deploy/dev/windows/wsl/environment/usr/local/bin/ubuntu-var-logs.sh" /usr/local/bin/ubuntu-var-logs.sh
        sudo chmod +x /usr/local/bin/ubuntu-var-logs.sh
        echo
      fi

      # ----------------------------------------------------------------------------------------------------------------
      # Cron - Configure Files
      # ----------------------------------------------------------------------------------------------------------------

      TARGET_USER="${USER}"

      CRON_TMP=$(mktemp /tmp/symfony-scripts-cron.XXXXXX)
      trap 'rm -f "${CRON_TMP}"' EXIT

      # 1. Back up the current crontab into the temp file
      sudo -u "${TARGET_USER}" crontab -l 2>/dev/null > "${CRON_TMP}"

      # 2. Drop existing lines for the scripts we are about to register (avoid duplicates)
      sed -i '/symfony-scripts-logs.sh/d' "${CRON_TMP}"
      sed -i '/ubuntu-var-logs.sh/d' "${CRON_TMP}"

      # 3. Append the new rules
      {
        echo "0 * * * * /usr/local/bin/symfony-scripts-logs.sh"
        echo "0 * * * * /usr/local/bin/ubuntu-var-logs.sh"
      } >> "${CRON_TMP}"

      # 4. Install the updated crontab
      sudo -u "${TARGET_USER}" crontab "${CRON_TMP}"

      # ----------------------------------------------------------------------------------------------------------------
      # Cron - List
      # ----------------------------------------------------------------------------------------------------------------

      crontab -l
      echo

    fi
else
  echo "Please check Operating System"
  setExit
fi
