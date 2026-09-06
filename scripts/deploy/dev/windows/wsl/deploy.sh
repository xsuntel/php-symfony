#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Deploy - Dev - Windows - WSL - Deploy
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

if [ "${PLATFORM_TYPE}" != "Linux" ]; then
  echo
  echo "Please check Operating System"
  setExit
fi

# >>>> WSL2 kernel is tagged "-microsoft-standard-WSL2" — block native Ubuntu machines
if ! grep -qi "microsoft" /proc/sys/kernel/osrelease; then
  echo
  echo "Please check WSL2 Environment"
  setExit
fi

# >>>> Environment

# >>>> The systemctl calls below require systemd as PID 1 — WSL2 needs systemd=true in /etc/wsl.conf
if [ ! -d /run/systemd/system ]; then
  echo
  echo "Please enable systemd : set 'systemd=true' under [boot] in /etc/wsl.conf, then run 'wsl --shutdown'"
  setExit
fi

setEnvironment() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ENV ] ${PLATFORM_TYPE} - ${PLATFORM_PROCESSOR}"
  echo -e "----------------------------------------------------------------------------------------------------------\n"
  # >>>> Select one of some environments
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
}

# >>>> Platform

setPlatform() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Platform"
  echo -e "----------------------------------------------------------------------------------------------------------\n"

  # >>>> Environment
  if [ "${ENVIRONMENT_NAME}" == "dev" ]; then

    # >>>> User - Permission
    if [ ! -f "/etc/sudoers.d/${USER}" ]; then
      echo "${USER} ALL=(ALL) NOPASSWD:ALL" | sudo tee "/etc/sudoers.d/${USER}" > /dev/null
      sudo chmod 0440 "/etc/sudoers.d/${USER}"
      # A broken sudoers.d file locks out sudo entirely — validate before keeping it
      if ! sudo visudo -cf "/etc/sudoers.d/${USER}"; then
        sudo rm -f "/etc/sudoers.d/${USER}"
        echo "Please check a file : /etc/sudoers.d/${USER}" && setExit
      fi
      echo
    fi

    # >>>> WSL2 kernel is managed by Windows (wsl --update) — no dpkg kernel packages, no GRUB
    echo -e ">>>> Linux - kernel : $(uname -r)\n"

    sudo systemctl daemon-reload
    echo
  fi

  # >>>> Linux - Base

  if [ -f "${PROJECT_PATH}/scripts/base/_platform.sh" ]; then
    source "${PROJECT_PATH}/scripts/base/_platform.sh"
  else
    echo "Please check a file : ./scripts/base/_platform.sh" && exit
  fi

  # >>>> Linux - Environment

  if [ -f "${PROJECT_PATH}/scripts/deploy/dev/windows/wsl/environment/_crontab.sh" ]; then
    source "${PROJECT_PATH}/scripts/deploy/dev/windows/wsl/environment/_crontab.sh"
  else
    echo "Please check a file : ./scripts/deploy/dev/windows/wsl/environment/_crontab.sh" && exit
  fi
  echo

  # >>>> Linux - Network

  if [ -f "${PROJECT_PATH}/scripts/deploy/dev/windows/wsl/network/_base.sh" ]; then
    source "${PROJECT_PATH}/scripts/deploy/dev/windows/wsl/network/_base.sh"
  else
    echo "Please check a file : ./scripts/deploy/dev/windows/wsl/network/_base.sh" && exit
  fi
  echo

  # >>>> Linux - Packages

  if [ -f "${PROJECT_PATH}/scripts/deploy/dev/windows/wsl/packages/_base.sh" ]; then
    source "${PROJECT_PATH}/scripts/deploy/dev/windows/wsl/packages/_base.sh"
  else
    echo "Please check a file : ./scripts/deploy/dev/windows/wsl/packages/_base.sh" && exit
  fi
  echo

  if [ -f "${PROJECT_PATH}/scripts/deploy/dev/windows/wsl/packages/_network.sh" ]; then
    source "${PROJECT_PATH}/scripts/deploy/dev/windows/wsl/packages/_network.sh"
  else
    echo "Please check a file : ./scripts/deploy/dev/windows/wsl/packages/_network.sh" && exit
  fi
  echo

  if [ -f "${PROJECT_PATH}/scripts/deploy/dev/windows/wsl/packages/_ubuntu_pro.sh" ]; then
    source "${PROJECT_PATH}/scripts/deploy/dev/windows/wsl/packages/_ubuntu_pro.sh"
  else
    echo "Please check a file : ./scripts/deploy/dev/windows/wsl/packages/_ubuntu_pro.sh" && exit
  fi
  echo

  # >>>> Linux - Security

  if [ -f "${PROJECT_PATH}/scripts/deploy/dev/windows/wsl/security/_directories.sh" ]; then
    source "${PROJECT_PATH}/scripts/deploy/dev/windows/wsl/security/_directories.sh"
  else
    echo "Please check a file : ./scripts/deploy/dev/windows/wsl/security/_directories.sh" && exit
  fi
  echo

  if [ -f "${PROJECT_PATH}/scripts/deploy/dev/windows/wsl/security/_files.sh" ]; then
    source "${PROJECT_PATH}/scripts/deploy/dev/windows/wsl/security/_files.sh"
  else
    echo "Please check a file : ./scripts/deploy/dev/windows/wsl/security/_files.sh" && exit
  fi
  echo

  if [ -f "${PROJECT_PATH}/scripts/deploy/dev/windows/wsl/security/_users.sh" ]; then
    source "${PROJECT_PATH}/scripts/deploy/dev/windows/wsl/security/_users.sh"
  else
    echo "Please check a file : ./scripts/deploy/dev/windows/wsl/security/_users.sh" && exit
  fi
  echo

  sudo apt-get autoremove -y && sudo apt-get autoclean -y
  echo
}

# >>>> Project

setProject() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Project : ${PROJECT_NAME}"
  echo -e "----------------------------------------------------------------------------------------------------------\n"

  # >>>> Git
  if [ -f "${PROJECT_PATH}/scripts/base/utility/git/_config.sh" ]; then
    source "${PROJECT_PATH}/scripts/base/utility/git/_config.sh"
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

  # >>>> PHP - Symfony Framework - Deployment - Back-End  - Permissions - (Optional)


  # >>>> PHP - Symfony Framework - Deployment - Back-End  - Database    - (Optional)


  # >>>> PHP - Symfony Framework - Deployment - Back-End  - Cron jobs   - (Optional)


  # >>>> PHP - Symfony Framework - Deployment - Back-End  - Messenger   - (Optional)


  # >>>> PHP - Symfony Framework - Deployment - Front-End - AssetMapper - (Optional)
  if [ -f "${PROJECT_PATH}/scripts/base/app/symfony/component/assets/_assetmapper.sh" ]; then
    source "${PROJECT_PATH}/scripts/base/app/symfony/component/assets/_assetmapper.sh"
  else
    echo "Please check a file : ./scripts/base/app/symfony/component/assets/_assetmapper.sh" && exit
  fi
  echo
}

# ----------------------------------------------------------------------------------------------------------------------
# Docker - Containers
# ----------------------------------------------------------------------------------------------------------------------

setDocker() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Docker - Containers"
  echo -e "----------------------------------------------------------------------------------------------------------\n"

  # >>>> Docker
  if [ -f "${PROJECT_PATH}"/scripts/base/utility/docker/_install.sh ]; then
    source "${PROJECT_PATH}"/scripts/base/utility/docker/_install.sh
  else
    echo "Please check a file : ./scripts/base/utility/docker/_install.sh" && exit
  fi
  echo

  # >>>> Docker - Containers
  if [ -f "${PROJECT_PATH}"/scripts/base/utility/docker/_deploy.sh ]; then
    source "${PROJECT_PATH}"/scripts/base/utility/docker/_deploy.sh
  else
    echo "Please check a file : ./scripts/base/utility/docker/_deploy.sh" && exit
  fi
  echo

  echo -e ">>>> Docker - System Disk Usage\n"

  docker system df
  echo

  echo -e ">>>> Docker - Running Containers\n"

  docker ps
  echo

  sudo lsof -i | grep docker-pr
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
# Tools for VM ( Instance )
# ----------------------------------------------------------------------------------------------------------------------

setTools() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Tools for VM ( Instance )"
  echo -e "----------------------------------------------------------------------------------------------------------\n"

  # >>>> Environment
  if [ "${ENVIRONMENT_NAME}" == "dev" ]; then

    hostnamectl
    echo

    echo ">>>> ${PLATFORM_TYPE} - Process"
    echo

    # >>>> Cron
    local CRON_STATUS
    CRON_STATUS=$(systemctl is-active cron)
    if [ "${CRON_STATUS}" == "inactive" ]; then
      sudo systemctl start cron
      sudo systemctl status cron --no-pager
      echo
    fi
    echo -e "Cron       : ${CRON_STATUS}\n"

    # >>>> Rsyslog
    local RSYSLOG_STATUS
    RSYSLOG_STATUS=$(systemctl is-active rsyslog)
    if [ "${RSYSLOG_STATUS}" == "inactive" ]; then
      sudo systemctl start rsyslog
      sudo systemctl status rsyslog --no-pager
      echo
    fi
    echo "Rsyslog    : ${RSYSLOG_STATUS}"
    echo

    # >>>> User
    echo ">>>> ${PLATFORM_TYPE} - Users"
    echo

    if [ -f "/etc/sudoers.d/${USER}" ]; then
      sudo rm -fv "/etc/sudoers.d/${USER}"
      echo
    fi
  fi
  echo
}

# ----------------------------------------------------------------------------------------------------------------------
# Utility
# ----------------------------------------------------------------------------------------------------------------------

setUtility() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Utility"
  echo -e "----------------------------------------------------------------------------------------------------------\n"

  # >>>> PHP - Symfony Framework - Server
  if [ -f "${PROJECT_PATH}"/scripts/base/app/symfony/config/_local_server.sh ]; then
    source "${PROJECT_PATH}"/scripts/base/app/symfony/config/_local_server.sh
  else
    echo "Please check a file : ./scripts/base/app/symfony/config/_local_server.sh" && exit
  fi
  echo
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
