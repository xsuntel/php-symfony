#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Deploy - Dev - Linux - Ubuntu - Security - users
# ----------------------------------------------------------------------------------------------------------------------
# >>>> Platform
if [ "${PLATFORM_TYPE}" == "Linux" ]; then

    # >>>> Environment
    if [ "${ENVIRONMENT_NAME}" == "dev" ]; then

      echo ">>>> Linux - Security - Users"
      echo

      # >>>> User - profile

      PROFILE_PATH="/etc/profile"
      if ! grep -q "umask 022" "$PROFILE_PATH"; then
        sudo bash -c "cat >> $PROFILE_PATH" <<-EOF
# Default File Creation Mask
umask 022
EOF
        echo "${PROFILE_PATH} -> umask 022 "
      fi

      # >>>> User - bashrc

      BASHRC_PATH="$HOME/.bashrc"
      if ! grep -q "umask 022" "$BASHRC_PATH"; then
        cat >> "$BASHRC_PATH" <<-EOF
# Default File Creation Mask
umask 022
EOF
        echo "${BASHRC_PATH} -> umask 022"
      fi

      echo ">>>> Linux - Security - Group"
      echo
      TARGET_GROUP="www-data"
      CURRENT_USER=$USER

      if id -nG "$CURRENT_USER" | grep -qw "$TARGET_GROUP"; then
        echo "Group : [$TARGET_GROUP] "
      else
        # Test usermod directly — this file is sourced, so a bare exit would only end the subshell.
        if sudo usermod -aG "${TARGET_GROUP}" "${CURRENT_USER}"; then
          echo "Run  : 'newgrp ${TARGET_GROUP}'"
        else
          echo "Error: Please check permission"
          setExit
        fi
      fi
      echo

      # >>>> User - List
      local delUserList="list sync games news uucp uuidd irc speech-dispatcher ftp tcpdump snmp snmpd mail proxy"
      for userItem in ${delUserList}; do
        local USER_LIST
        USER_LIST=$(awk -F: '{print $1}' /etc/passwd | grep -i "${userItem}")
        if [ "${USER_LIST}" == "${userItem}" ]; then
          sudo userdel "${userItem}"
        fi
      done

    fi
else
  echo "Please check Operating System"
  setExit
fi
