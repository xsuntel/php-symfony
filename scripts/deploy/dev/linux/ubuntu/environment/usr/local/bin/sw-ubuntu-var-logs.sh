#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Deploy - Dev - Linux - Ubuntu - Utility - Clear Logs
# ----------------------------------------------------------------------------------------------------------------------


# ----------------------------------------------------------------------------------------------------------------------
# Section 1: /var/log - Rotated log files
# ----------------------------------------------------------------------------------------------------------------------
echo ">>>> /var/log - Rotated log files"
sudo rm -f /var/log/*.[0-9]
echo "  Cleaned: /var/log/*.[0-9]"
echo


# ----------------------------------------------------------------------------------------------------------------------
# Section 2: Supervisor - Log files
# ----------------------------------------------------------------------------------------------------------------------
# Truncate (not delete): supervisor keeps file handles open, so deleting and recreating would break log output.
echo ">>>> Supervisor - Log files"

SUPERVISOR_LOG_DIR="/var/log/supervisor"
SUPERVISOR_LOG_FILES=(
    "supervisord.log"
    "messenger-consume-stdout.log"
    "messenger-consume-stderr.log"
)

for FILE in "${SUPERVISOR_LOG_FILES[@]}"; do
    TARGET="${SUPERVISOR_LOG_DIR}/${FILE}"
    if [ -f "${TARGET}" ]; then
        true | sudo tee "${TARGET}" > /dev/null
        echo "  Cleaned: ${TARGET}"
    else
        echo "  Skipped (not found): ${TARGET}"
    fi
done
echo
