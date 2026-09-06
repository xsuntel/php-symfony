#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Deploy - Dev - Windows - WSL - Process - App
# ----------------------------------------------------------------------------------------------------------------------

# Absolute path: cron runs without PROJECT_PATH, so this must point at the actual Symfony app log dir
LOG_DIR="${HOME}/Repositories/symfony-scripts/app/var/log"
LOG_FILES=(
    "dev.log"
    "prod.log"
    "xdebug.log"
)

for FILE in "${LOG_FILES[@]}"; do
    TARGET="$LOG_DIR/$FILE"
    if [ -f "$TARGET" ]; then
        true | sudo tee "$TARGET" > /dev/null
        echo "Successfully cleaned: $TARGET"
    else
        echo "Skipped (Not found): $TARGET"
    fi
done
