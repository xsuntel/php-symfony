#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Base - Project
# ----------------------------------------------------------------------------------------------------------------------

# >>>> Environment
# setExit, not exit — this file is sourced, so a bare exit would only end the subshell.
if [ -z "${ENVIRONMENT_NAME}" ]; then
  echo "Error: ENVIRONMENT_NAME variable is not set."
  setExit
fi

# >>>> Platform
if [ -z "${PLATFORM_TYPE}" ]; then
  echo "Error: PLATFORM_TYPE variable is not set."
  setExit
fi

# >>>> Projects
if [ -f "${PROJECT_PATH}"/.env.app ]; then
  source "${PROJECT_PATH}"/.env.app
else
  echo "Please check .env file : ${PROJECT_PATH}/.env.app" && exit
fi

# ----------------------------------------------------------------------------------------------------------------------
# Directory - App
# ----------------------------------------------------------------------------------------------------------------------

if [ -d app ]; then
  (
    cd app || return

    # >>>> PHP - Symfony Command                                         https://symfony.com/doc/current/deployment.html
    if [ -f bin/console ]; then

      # ----------------------------------------------------------------------------------------------------------------
      # Directory
      # ----------------------------------------------------------------------------------------------------------------

      # >>>> assets
      if [ -f ./assets/stimulus_bootstrap.js ]; then
        TARGET_FILE="${1:-./assets/stimulus_bootstrap.js}"

        LINE1=$(sed -n '1p' "$TARGET_FILE")
        LINE2=$(sed -n '2p' "$TARGET_FILE")
        LINE3=$(sed -n '3p' "$TARGET_FILE")

        EXPECTED_LINE1="import { startStimulusApp } from '@symfony/stimulus-bundle';"
        EXPECTED_LINE2=""
        EXPECTED_LINE3="const app = startStimulusApp();"

        if [ "$LINE1" = "$EXPECTED_LINE1" ] && \
           [ "$LINE2" = "$EXPECTED_LINE2" ] && \
           [ "$LINE3" = "$EXPECTED_LINE3" ]; then

          sed -i '1,3d' "$TARGET_FILE"
          echo "✅  Modified: $TARGET_FILE"
          echo
        fi
      fi

      # >>>> migrations
      if [ ! -d migrations ]; then
        mkdir migrations
      fi

      # >>>> node_modules
      if [ ! -d node_modules ]; then
        mkdir node_modules
      fi

      # >>>> src
      if [ -f ./src/Controller/.gitignore ]; then
        rm -f ./src/Controller/.gitignore
      fi

      # >>>> translations
      if [ -f ./translations/.gitignore ]; then
        rm -f ./translations/.gitignore
      fi

      # ----------------------------------------------------------------------------------------------------------------
      # Files
      # ----------------------------------------------------------------------------------------------------------------

      # >>>> .gitignore
      if [ -f ./.gitignore ]; then
        rm -f ./.gitignore
      fi

    fi
  )
else
  echo
  echo "[ ERROR ] There is not a folder : app"
  echo
  setExit
fi

# >>>> Node
if [ -d node_modules ]; then
  rm -rf node_modules
fi

if [ -d vendor ]; then
  rm -rf vendor
fi

if [ -d var ]; then
  rm -rf var
fi

# >>>> Project Files
FILES_TO_DELETE=(
  # Composer
  "composer.phar"
  "composer.json"
  "composer.lock"
  # Node
  "package.json"
  "package-lock.json"
  "npm-debug.log"
  "yarn-error.log"
  # Tools
  "phing-latest.phar"
  ".php-cs-fixer.cache"
  ".phpunit.result.cache"
  "./tests/.phpunit.result.cache"
  # Docker
  "./app/Dockerfile"
  "./app/docker-compose.yml"
)

for file in "${FILES_TO_DELETE[@]}"; do
  if [ -f "$file" ]; then
    rm -f "$file"
  fi
done

# ----------------------------------------------------------------------------------------------------------------------
# Directory - Scripts
# ----------------------------------------------------------------------------------------------------------------------

# >>>> Platform - Linux
find ./ -name "sudo" -type f -exec rm -f {} \;

# >>>> Platform - Mac

# >>>> Platform - Windows
find ./ -name ".DS_Store" -type f -exec rm -f {} \;
find ./ -name ".DS_Store" -type d -exec rm -rf {} \;
echo
