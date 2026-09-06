#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Tools - Tutorial - Create a new project
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
  # --------------------------------------------------------------------------------------------------------------------
  # Scripts - Platform - Base
  # --------------------------------------------------------------------------------------------------------------------
  # >>>> Base
  if [ -f "${PROJECT_PATH}/scripts/base/_platform.sh" ]; then
    source "${PROJECT_PATH}/scripts/base/_platform.sh"
  else
    echo "Please check a file : ./scripts/base/_platform.sh" && exit
  fi
}

# >>>> Project

setProject() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Project : ${PROJECT_NAME}"
  echo -e "----------------------------------------------------------------------------------------------------------\n"

  # >>>> Git
  if [ -f "${PROJECT_PATH}"/scripts/base/utility/git/_config.sh ]; then
    source "${PROJECT_PATH}"/scripts/base/utility/git/_config.sh
  else
    echo "Please check a file : ./scripts/base/utility/git/_config.sh" && exit
  fi

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

  # >>>> PHP
  if [ -f "${PROJECT_PATH}"/scripts/base/app/php/_install.sh ]; then
    source "${PROJECT_PATH}"/scripts/base/app/php/_install.sh
  else
    echo "Please check a file : ./scripts/base/app/php/_install.sh" && exit
  fi
  echo

  # >>>> PHP - Symfony Framework - Command Line Interface
  if [ -f "${PROJECT_PATH}"/scripts/base/app/symfony/config/_command.sh ]; then
    source "${PROJECT_PATH}"/scripts/base/app/symfony/config/_command.sh
  else
    echo "Please check a file : ./scripts/base/app/symfony/config/_command.sh" && exit
  fi
  echo

  # >>>> PHP - Symfony Framework - Components
  if [ -f "${PROJECT_PATH}"/scripts/base/app/symfony/config/_components.sh ]; then
    source "${PROJECT_PATH}"/scripts/base/app/symfony/config/_components.sh
  else
    echo "Please check a file : ./scripts/base/app/symfony/config/_components.sh" && exit
  fi
  echo

  # >>>> PHP - Symfony Framework - Delete a directory : ./app
  if [ -f app/bin/console ]; then
    echo
    echo "[ Warning ] Do you want to delete a current project  ? "
    echo
    PS3="Select: "
    select num in "No" "Yes"; do
      case "$REPLY" in
      1)
        echo "Please check your project whether symfony has been installed or not again"
        setEnd
        ;;
      2)
        rm -rf app
        echo
        break
        ;;
      *)
        echo "[ ERROR ] Unknown Command"
        setEnd
        ;;
      esac
    done
  else
    rm -rf app
  fi
  echo

  # >>>> PHP - Symfony Framework - Creating app                               https://symfony.com/doc/current/setup.html
  composer create-project symfony/skeleton:"${SYMFONY_VERSION}.*" app
  echo

  (
    cd app || return

    composer require webapp
    echo
  )

  # >>>> PHP - Symfony Framework - Creating .local files
  if [ "${PLATFORM_TYPE}" == "Linux" ]; then
    # ------------------------------------------------------------------------------------------------------------------
    # Platform - Linux
    # ------------------------------------------------------------------------------------------------------------------
    # >>>> Environment
    if [ "${ENVIRONMENT_NAME}" == "dev" ]; then
      if [ ! -f "${PROJECT_PATH}"/app/.env.dev.local ]; then
        touch "${PROJECT_PATH}"/app/.env.dev.local
      fi
    fi

  elif [ "${PLATFORM_TYPE}" == "Darwin" ]; then
    # ------------------------------------------------------------------------------------------------------------------
    # Platform - Mac - MacOS
    # ------------------------------------------------------------------------------------------------------------------
    # >>>> Environment
    if [ "${ENVIRONMENT_NAME}" == "dev" ]; then
      if [ ! -f "${PROJECT_PATH}"/app/.env.dev.local ]; then
        touch "${PROJECT_PATH}"/app/.env.dev.local
      fi
    fi

  elif [ "${PLATFORM_TYPE}" == "Windows" ]; then
    # ------------------------------------------------------------------------------------------------------------------
    # Platform - Windows - WSL2
    # ------------------------------------------------------------------------------------------------------------------
    # >>>> Environment
    if [ "${ENVIRONMENT_NAME}" == "dev" ]; then
      if [ ! -f "${PROJECT_PATH}"/app/.env.dev.local ]; then
        touch "${PROJECT_PATH}"/app/.env.dev.local
      fi
    fi

  else
    echo "Please check Operating System"
    setExit
  fi
  echo
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
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Build"
  echo -e "----------------------------------------------------------------------------------------------------------\n"

  # >>>> PHP - Symfony Framework - Deployment
  if [ -f "${PROJECT_PATH}/scripts/base/app/symfony/config/_deployment.sh" ]; then
    source "${PROJECT_PATH}/scripts/base/app/symfony/config/_deployment.sh"
  else
    echo "Please check a file : ./scripts/base/app/symfony/config/_deployment.sh" && exit
  fi
  echo

  echo ">>>> PHP - Symfony Framework - Deployment - OS"
  echo
  echo "Please select one of the platform as follows:"
  echo
  echo "- Linux   : ./scripts/deploy/dev/linux/ubuntu/deploy.sh"
  echo "- Mac     : ./scripts/deploy/dev/mac/os/deploy.sh"
  echo "- Windows : ./scripts/deploy/dev/windows/wsl/deploy.sh"
  echo
}

# ----------------------------------------------------------------------------------------------------------------------
# Docker - Containers
# ----------------------------------------------------------------------------------------------------------------------

setDocker() {
  echo "---------------------------------------------------------------------------------------------------------------"
  echo "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Docker - Containers"
  echo "---------------------------------------------------------------------------------------------------------------"
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
}

# ----------------------------------------------------------------------------------------------------------------------
# Tools for VM ( Instance )
# ----------------------------------------------------------------------------------------------------------------------

setTools() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Tools for VM ( Instance )"
  echo -e "----------------------------------------------------------------------------------------------------------\n"
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
setBuild

# ----------------------------------------------------------------------------------------------------------------------
# Docker - Containers
# ----------------------------------------------------------------------------------------------------------------------
#setDocker

# ----------------------------------------------------------------------------------------------------------------------
# Provider ( Cloud Service Providers )
# ----------------------------------------------------------------------------------------------------------------------
#setProvider

# ----------------------------------------------------------------------------------------------------------------------
# Utility
# ----------------------------------------------------------------------------------------------------------------------
#setUtility

# ----------------------------------------------------------------------------------------------------------------------
# Tools for VM ( Instance )
# ----------------------------------------------------------------------------------------------------------------------
#setTools

# ----------------------------------------------------------------------------------------------------------------------
# END
# ----------------------------------------------------------------------------------------------------------------------

setEnd
