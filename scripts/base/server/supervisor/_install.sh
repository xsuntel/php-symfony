#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Deploy - Dev - Linux - Ubuntu - Security
# ----------------------------------------------------------------------------------------------------------------------
# >>>> Platform
if [ "${PLATFORM_TYPE}" == "Linux" ]; then

    # >>>> Environment
    if [ "${ENVIRONMENT_NAME}" == "dev" ]; then

        # >>>> Process
        echo ">>>> Linux - Process - Supervisor"
        echo

        local SUPERVISOR_STATUS
        SUPERVISOR_STATUS=$(dpkg -l | grep -i "supervisor" | awk '{print $2}' | cut -d ':' -f1 | awk "/^supervisor$/")
        if [ "${SUPERVISOR_STATUS}" != "supervisor" ]; then
            sudo apt-get install -y supervisor
        echo
        fi

        if [ ! -f /etc/supervisor/conf.d/messenger-consume.conf ]; then
            if [ -f "${PROJECT_PATH}/scripts/base/server/supervisor/conf.d/messenger-consume.conf" ]; then
                sudo cp -fv "${PROJECT_PATH}/scripts/base/server/supervisor/conf.d/messenger-consume.conf" /etc/supervisor/conf.d/messenger-consume.conf
                echo
            fi
        fi

        supervisorctl stop messenger-consume:*
        echo

        supervisorctl status
        echo

    fi
else
  echo "Please check Operating System"
  setExit
fi
