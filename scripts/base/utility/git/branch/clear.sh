#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Tools - Git - Clear history
# ----------------------------------------------------------------------------------------------------------------------

find_project_root() {
    local PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    while [[ "${PROJECT_DIR}" != "/" ]]; do
        if [[ -d "${PROJECT_DIR}/.git" ]] || [[ -f "${PROJECT_DIR}/.env.app" ]]; then
            echo "${PROJECT_DIR}"
            return 0
        fi
        PROJECT_DIR="$(dirname "${PROJECT_DIR}")"
    done
    return 1
}

PROJECT_PATH=$(find_project_root)
PROJECT_NAME=$(basename "$(realpath "${PROJECT_PATH}")")
cd "${PROJECT_PATH}" || exit

# ----------------------------------------------------------------------------------------------------------------------
# Abstract
# ----------------------------------------------------------------------------------------------------------------------

if [ -f "${PROJECT_PATH}/scripts/base/_abstract.sh" ]; then
  source "${PROJECT_PATH}/scripts/base/_abstract.sh"
else
  echo "Please check a file : ./scripts/base/_abstract.sh" && exit
fi

# >>>> Environment

setEnvironment() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ENV ] ${PLATFORM_TYPE} - ${PLATFORM_PROCESSOR}"
  echo -e "----------------------------------------------------------------------------------------------------------\n"
  PS3="Menu: "
  select num in "dev" "exit"; do
    case "$REPLY" in
    1)
      # >>>> Dev Environment
      ENVIRONMENT_NAME="dev"
      break
      ;;
    2)
      echo "exit()"
      setEnd
      ;;
    *)
      echo "[ ERROR ] Unknown Command"
      setEnd
      ;;
    esac
  done

  echo
  echo "- PROJECT ENV : ${ENVIRONMENT_NAME}"
  echo
}

# >>>> Platform

setPlatform() {
  echo "---------------------------------------------------------------------------------------------------------------"
  echo "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Platform "
  echo "---------------------------------------------------------------------------------------------------------------"
  echo

  # >>>> Environment
  if [ "${ENVIRONMENT_NAME}" == "dev" ]; then

    # >>>> Platform
    if [ "${PLATFORM_TYPE}" == "Linux" ]; then
      # ------------------------------------------------------------------------------------------------------------------
      # Platform - Linux - Ubuntu
      # ------------------------------------------------------------------------------------------------------------------

      # >>>> User
      echo ">>>> Linux - Users"
      echo

      if [ -f "/etc/sudoers.d/${USER}" ]; then
        sudo rm -fv "/etc/sudoers.d/${USER}"
      fi

      # >>>> Files
      if [ -d ~/.local/share/Trash ]; then
        rm -rf ~/.local/share/Trash/*
      fi

    elif [ "${PLATFORM_TYPE}" == "Darwin" ]; then
      # ------------------------------------------------------------------------------------------------------------------
      # Platform - Mac - MacOS
      # ------------------------------------------------------------------------------------------------------------------

      # >>>> Files
      echo


    elif [ "${PLATFORM_TYPE}" == "Windows" ]; then
      # ------------------------------------------------------------------------------------------------------------------
      # Platform - Windows - WSL2
      # ------------------------------------------------------------------------------------------------------------------

      # >>>> Files
      echo

    else
      echo "Please check Operating System"
      setExit
    fi

  fi
}

# >>>> Project

setProject() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Project : ${PROJECT_NAME}"
  echo -e "----------------------------------------------------------------------------------------------------------\n"

  # >>>> Directory
  if [ -f "${PROJECT_PATH}/scripts/base/_project.sh" ]; then
    source "${PROJECT_PATH}/scripts/base/_project.sh"
  else
    echo "Please check a file : ./scripts/base/_project.sh" && exit
  fi
}

# ----------------------------------------------------------------------------------------------------------------------
# Architecture
# ----------------------------------------------------------------------------------------------------------------------

# >>>> App

setPhp() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Base - App - Packages"
  echo -e "----------------------------------------------------------------------------------------------------------\n"

  # >>>> Project - App
  if [ -d app ]; then
    (
      cd app || return

      # >>>> PHP - Symfony Command                                        https://symfony.com/doc/current/deployment.html
      if [ -f bin/console ]; then

        # ----------------------------------------------------------------------------------------------------------------
        # Directory
        # ----------------------------------------------------------------------------------------------------------------

        # >>>> migrations
        if [ -d migrations ]; then
          rm -rf ./migrations
        fi

        # >>>> node_modules
        if [ -d node_modules ]; then
          rm -rf ./node_modules
        fi

        # >>>> public
        if [ -d public ]; then
          # >>>> public/assets
          if [ -d public/assets ]; then
            rm -rf public/assets
          fi
          # >>>> public/bundles
          if [ -d public/bundles ]; then
            rm -rf public/bundles
          fi
          # >>>> public/var
          if [ -d public/var ]; then
            rm -rf public/var
          fi
          # >>>> public - meta
          if [ -f public/0.meta.json ]; then
            rm -f public/[0-9]
            rm -f public/[0-9].meta
            rm -f public/[0-9].meta.json
          fi
        fi

        # >>>> var
        if [ -d var ]; then

          if [ -d var/cache ]; then
            find var/cache -mindepth 1 -delete 2>/dev/null || true
          fi

          if [ -d var/log ]; then
            find var/log -mindepth 1 -delete 2>/dev/null || true
          fi

          find var -maxdepth 1 ! -name 'cache' ! -name 'log' ! -name 'var' -exec rm -rf {} + 2>/dev/null || true
        fi

        # >>>> vendor
        if [ -d vendor ]; then
          rm -rf ./vendor
        fi

        # ----------------------------------------------------------------------------------------------------------------
        # Files
        # ----------------------------------------------------------------------------------------------------------------

        # >>>> .env.${ENVIRONMENT_NAME}
        if [ -f .env.dev.local ]; then
          rm -f .env.dev.local
        fi
        if [ -f .env.prod.local ]; then
          rm -f .env.prod.local
        fi
        # >>>> .env.test
        if [ -f .env.test.local ]; then
          rm -f .env.test.local
        fi

        # >>>> composer
        if [ -f composer.phar ]; then
          rm -f composer.phar
        fi

        if [ -f composer.lock ]; then
          rm -f composer.lock
        fi

        # >>>> package
        if [ -f package-lock.json ]; then
          rm -f package-lock.json
        fi

        # >>>> phing-latest.phar
        if [ -f phing-latest.phar ]; then
          rm -f phing-latest.phar
        fi

        # >>>> php-cs-fixer
        if [ -f .php-cs-fixer.cache ]; then
          rm -f .php-cs-fixer.cache
        fi

        # >>>> phpunit
        if [ -f .phpunit.result.cache ]; then
          rm -f .phpunit.result.cache
        fi

        # >>>> Remove related performance files
        if [ -f ./0.meta.json ]; then
          rm -f ./[0-9]
          rm -f ./[0-9].meta
          rm -f ./[0-9].meta.json
        fi

        # >>>> Remove related python files
        rm -f .*.py

      fi
    )
  else
    echo
    echo "[ ERROR ] There is not a folder : app"
    echo
    setExit
  fi
}

# >>>> Cache

setRedis() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Base - Cache - Packages"
  echo -e  "---------------------------------------------------------------------------------------------------------\n"
}

# >>>> Database

setPostgreSQL() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Base - Database - Packages"
  echo -e "----------------------------------------------------------------------------------------------------------\n"
}

# >>>> Message

setRabbitMQ() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Base - Message - Packages"
  echo -e "----------------------------------------------------------------------------------------------------------\n"
}

# >>>> Server

setNginx() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Base - Server - Packages"
  echo -e "----------------------------------------------------------------------------------------------------------\n"
}

# ----------------------------------------------------------------------------------------------------------------------
# Build Scripts
# ----------------------------------------------------------------------------------------------------------------------

setBuild() {
  echo "---------------------------------------------------------------------------------------------------------------"
  echo "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Build"
  echo "---------------------------------------------------------------------------------------------------------------"
}

# ----------------------------------------------------------------------------------------------------------------------
# Docker - Containers
# ----------------------------------------------------------------------------------------------------------------------

setDocker() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Docker - Containers"
  echo -e "----------------------------------------------------------------------------------------------------------\n"

  FILES_TO_DELETE=(
    "./app/Dockerfile"
    "./app/docker-compose.yml"
    "./Dockerfile"
    "./docker-compose.env"
    "./docker-compose.yml"
    "./docker-compose.${ENVIRONMENT_NAME}.env"
    "./docker-compose.${ENVIRONMENT_NAME}.yml"
    "./docker-compose.override.yml"
  )

  for file in "${FILES_TO_DELETE[@]}"; do
    if [ -f "$file" ]; then
      rm -fv "$file"
    fi
  done
  echo
}

# ----------------------------------------------------------------------------------------------------------------------
# Provider ( Cloud Service Providers )
# ----------------------------------------------------------------------------------------------------------------------

setProvider() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Provider ( Cloud Service Providers )"
  echo -e "----------------------------------------------------------------------------------------------------------\n"
}

# ----------------------------------------------------------------------------------------------------------------------
# Utility
# ----------------------------------------------------------------------------------------------------------------------

setUtility() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Utility"
  echo -e "----------------------------------------------------------------------------------------------------------\n"

  # >>>> Project - Content - Git
  echo ">>>> Git - Project"
  echo

  DEFAULT_BRANCH=$(git config --get init.defaultBranch || echo "main")
  RELEASES_VERSION=$(date +%Y.%m.%d)
  TODAY=$(date "+%Y-%m-%d")

  # 1. Create a new branch
  git checkout --orphan temp_branch
  echo "✔ Created orphan branch: temp_branch"
  echo

  # 2. Update all of the files and commit
  git add -A
  git commit -m "Initial Reset"
  echo "✔ Committed all files with message: Backup ${TODAY}"
  echo

  # 3. Delete current main branch
  git branch -D main 2>/dev/null || git branch -D master 2>/dev/null
  echo "✔ Deleted old main branch"
  echo

  # 4. Move from current temp_branch to main branch
  git branch -m main
  echo "✔ Renamed temp_branch to main"
  echo

  # 5. Push it to main branch
  echo ">>>> Pushing to remote origin main..."
  git push -f origin main
  echo

  # 6. Show logs
  echo ">>>> Git Log (Latest 5)"
  git log -5 --graph --date=short --pretty=format:'%C(auto)%h %Cgreen(%ad)%Creset %s %C(bold blue)<%an>%Creset%C(auto)%d%Creset'
  echo
}

# ----------------------------------------------------------------------------------------------------------------------
# Tools for VM ( Instance )
# ----------------------------------------------------------------------------------------------------------------------

setTools() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Tools for VM ( Instance )"
  echo -e "----------------------------------------------------------------------------------------------------------\n"

  if [ "${PLATFORM_TYPE}" == "Linux" ]; then

    # >>>> Tools - IDE : PhpStorm
    if [ -f "${HOME}/java_error_in_phpstorm.hprof" ]; then
      rm -fv "${HOME}/java_error_in_phpstorm.hprof"
      echo
    fi
  fi
}


# ----------------------------------------------------------------------------------------------------------------------
# START
# ----------------------------------------------------------------------------------------------------------------------

setStart

# ----------------------------------------------------------------------------------------------------------------------
# Abstract
# ----------------------------------------------------------------------------------------------------------------------

# >>>> Environment
setEnvironment

# >>>> Platform
setPlatform

# >>>> Project
setProject

# ----------------------------------------------------------------------------------------------------------------------
# Architecture
# ----------------------------------------------------------------------------------------------------------------------

# >>>> App
setPhp

# >>>> Cache
#setRedis

# >>>> Database
#setPostgreSQL

# >>>> Message
#setRabbitMQ

# >>>> Server
#setNginx

# ----------------------------------------------------------------------------------------------------------------------
# Build Scripts
# ----------------------------------------------------------------------------------------------------------------------
#setBuild

# ----------------------------------------------------------------------------------------------------------------------
# Docker - Containers
# ----------------------------------------------------------------------------------------------------------------------
setDocker

# ----------------------------------------------------------------------------------------------------------------------
# Provider ( Cloud Service Providers )
# ----------------------------------------------------------------------------------------------------------------------
#setProvider

# ----------------------------------------------------------------------------------------------------------------------
# Tools for VM ( Instance )
# ----------------------------------------------------------------------------------------------------------------------
setTools

# ----------------------------------------------------------------------------------------------------------------------
# Utility
# ----------------------------------------------------------------------------------------------------------------------
setUtility

# ----------------------------------------------------------------------------------------------------------------------
# END
# ----------------------------------------------------------------------------------------------------------------------

setEnd
