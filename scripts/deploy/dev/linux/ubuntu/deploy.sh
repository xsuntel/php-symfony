#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Deploy - Dev - Linux - Ubuntu - Deploy
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

# >>>> Environment

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
  echo "---------------------------------------------------------------------------------------------------------------"
  echo "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Platform "
  echo "---------------------------------------------------------------------------------------------------------------"
  echo

  # >>>> Environment
  if [ "${ENVIRONMENT_NAME}" == "dev" ]; then

    # >>>> User - Permission
    if [ ! -f "/etc/sudoers.d/${USER}" ]; then
      sudo touch "/etc/sudoers.d/${USER}"
      sudo echo "${USER} ALL=(ALL) NOPASSWD:ALL" | sudo tee -a "/etc/sudoers.d/${USER}" > /dev/null
      echo
    fi

    echo -e ">>>> Linux - kernel : $(uname -r)\n"

    sudo systemctl daemon-reload
    echo

    # >>>> Keep the running kernel AND the latest installed kernel (rollback fallback),
    #      purge everything older. Prevents deleting a newer, not-yet-booted kernel.
    local CURRENT_VER
    CURRENT_VER=$(uname -r | cut -d'-' -f1,2)

    # >>>> Latest installed image version-abi (e.g. 6.8.0-50); empty on kernels not managed by apt (WSL).
    local LATEST_VER
    LATEST_VER=$(dpkg-query -W -f='${Package}\n' 'linux-image-[0-9]*' 2>/dev/null | \
                 sed -E 's/^linux-image-([0-9]+\.[0-9]+\.[0-9]+-[0-9]+)-.*/\1/' | \
                 sort -V | tail -n1)

    # >>>> Build fixed-string keep filter: always current, plus latest when present.
    local -a KEEP_PATTERNS=("${CURRENT_VER}")
    [ -n "${LATEST_VER}" ] && KEEP_PATTERNS+=("${LATEST_VER}")

    local -a GREP_KEEP=()
    local PATTERN
    for PATTERN in "${KEEP_PATTERNS[@]}"; do
      GREP_KEEP+=(-e "${PATTERN}")
    done

    # >>>> Only fully "installed" versioned kernel packages, minus the ones we keep.
    local -a DEL_PACKAGES
    mapfile -t DEL_PACKAGES < <(dpkg-query -W -f='${Package} ${db:Status-Status}\n' \
                                  'linux-image-[0-9]*' 'linux-headers-[0-9]*' \
                                  'linux-modules-[0-9]*' 'linux-modules-extra-[0-9]*' 2>/dev/null | \
                                  awk '$2 == "installed" { print $1 }' | \
                                  grep -vF "${GREP_KEEP[@]}" || true)

    if [ ${#DEL_PACKAGES[@]} -gt 0 ]; then
      echo ">>>> Found old kernel packages to remove (keeping: ${KEEP_PATTERNS[*]}):"
      printf '       %s\n' "${DEL_PACKAGES[@]}"
      echo

      # >>>> Pass each package as its own argument — never a single newline-joined string.
      sudo DEBIAN_FRONTEND=noninteractive apt-get purge -y "${DEL_PACKAGES[@]}"
      sudo apt-get autoremove --purge -y

      # >>>> update-grub is absent on grub-less systems (e.g. WSL); guard before calling.
      if command -v update-grub > /dev/null 2>&1; then
        sudo update-grub
      fi

      echo ">>>> Old kernels have been cleaned up."
    else
      echo ">>>> No old kernel packages to remove."
    fi
    echo
  fi

  # >>>> Linux - Base

  if [ -f "${PROJECT_PATH}/scripts/base/_platform.sh" ]; then
    source "${PROJECT_PATH}/scripts/base/_platform.sh"
  else
    echo "Please check a file : ./scripts/base/_platform.sh" && exit
  fi

  # >>>> Linux - Environment

  #if [ -f "${PROJECT_PATH}/scripts/deploy/dev/linux/ubuntu/environment/_booting.sh" ]; then
  #  source "${PROJECT_PATH}/scripts/deploy/dev/linux/ubuntu/environment/_booting.sh"
  #else
  #  echo "Please check a file : ./scripts/deploy/dev/linux/ubuntu/environment/_booting.sh" && exit
  #fi
  #echo

  #if [ -f "${PROJECT_PATH}/scripts/deploy/dev/linux/ubuntu/environment/_crontab.sh" ]; then
  #  source "${PROJECT_PATH}/scripts/deploy/dev/linux/ubuntu/environment/_crontab.sh"
  #else
  #  echo "Please check a file : ./scripts/deploy/dev/linux/ubuntu/environment/_crontab.sh" && exit
  #fi
  #echo

  #if [ -f "${PROJECT_PATH}/scripts/deploy/dev/linux/ubuntu/environment/_ntpd.sh" ]; then
  #  source "${PROJECT_PATH}/scripts/deploy/dev/linux/ubuntu/environment/_ntpd.sh"
  #else
  #  echo "Please check a file : ./scripts/deploy/dev/linux/ubuntu/environment/_ntpd.sh" && exit
  #fi
  #echo

  #if [ -f "${PROJECT_PATH}/scripts/deploy/dev/linux/ubuntu/environment/_power.sh" ]; then
  #  source "${PROJECT_PATH}/scripts/deploy/dev/linux/ubuntu/environment/_power.sh"
  #else
  #  echo "Please check a file : ./scripts/deploy/dev/linux/ubuntu/environment/_power.sh" && exit
  #fi
  #echo


  # >>>> Linux - Network

  #if [ -f "${PROJECT_PATH}/scripts/deploy/dev/linux/ubuntu/network/_base.sh" ]; then
  #  source "${PROJECT_PATH}/scripts/deploy/dev/linux/ubuntu/network/_base.sh"
  #else
  #  echo "Please check a file : ./scripts/deploy/dev/linux/ubuntu/network/_base.sh" && exit
  #fi
  #echo

  # >>>> Linux - Packages

  #if [ -f "${PROJECT_PATH}/scripts/deploy/dev/linux/ubuntu/packages/_base.sh" ]; then
  #  source "${PROJECT_PATH}/scripts/deploy/dev/linux/ubuntu/packages/_base.sh"
  #else
  #  echo "Please check a file : ./scripts/deploy/dev/linux/ubuntu/packages/_base.sh" && exit
  #fi
  #echo

  #if [ -f "${PROJECT_PATH}/scripts/deploy/dev/linux/ubuntu/packages/_network.sh" ]; then
  #  source "${PROJECT_PATH}/scripts/deploy/dev/linux/ubuntu/packages/_network.sh"
  #else
  #  echo "Please check a file : ./scripts/deploy/dev/linux/ubuntu/packages/_network.sh" && exit
  #fi
  #echo

  #if [ -f "${PROJECT_PATH}/scripts/deploy/dev/linux/ubuntu/packages/_remote_desktop.sh" ]; then
  #  source "${PROJECT_PATH}/scripts/deploy/dev/linux/ubuntu/packages/_remote_desktop.sh"
  #else
  #  echo "Please check a file : ./scripts/deploy/dev/linux/ubuntu/packages/_remote_desktop.sh" && exit
  #fi
  #echo

  #if [ -f "${PROJECT_PATH}/scripts/deploy/dev/linux/ubuntu/packages/_ubuntu_pro.sh" ]; then
  #  source "${PROJECT_PATH}/scripts/deploy/dev/linux/ubuntu/packages/_ubuntu_pro.sh"
  #else
  #  echo "Please check a file : ./scripts/deploy/dev/linux/ubuntu/packages/_ubuntu_pro.sh" && exit
  #fi
  #echo

  # >>>> Linux - Security

  #if [ -f "${PROJECT_PATH}/scripts/deploy/dev/linux/ubuntu/security/_directories.sh" ]; then
  #  source "${PROJECT_PATH}/scripts/deploy/dev/linux/ubuntu/security/_directories.sh"
  #else
  #  echo "Please check a file : ./scripts/deploy/dev/linux/ubuntu/security/_directories.sh" && exit
  #fi
  #echo

  #if [ -f "${PROJECT_PATH}/scripts/deploy/dev/linux/ubuntu/security/_files.sh" ]; then
  #  source "${PROJECT_PATH}/scripts/deploy/dev/linux/ubuntu/security/_files.sh"
  #else
  #  echo "Please check a file : ./scripts/deploy/dev/linux/ubuntu/security/_files.sh" && exit
  #fi
  #echo

  #if [ -f "${PROJECT_PATH}/scripts/deploy/dev/linux/ubuntu/security/_users.sh" ]; then
  #  source "${PROJECT_PATH}/scripts/deploy/dev/linux/ubuntu/security/_users.sh"
  #else
  #  echo "Please check a file : ./scripts/deploy/dev/linux/ubuntu/security/_users.sh" && exit
  #fi
  #echo

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


  # >>>> PHP - Symfony Framework - Deployment - Front-End - AssetMapper - (Optional) OR Webpack Encore
  #if [ -f "${PROJECT_PATH}/scripts/base/app/symfony/component/assets/_assetmapper.sh" ]; then
  #  source "${PROJECT_PATH}/scripts/base/app/symfony/component/assets/_assetmapper.sh"
  #else
  #  echo "Please check a file : ./scripts/base/app/symfony/component/assets/_assetmapper.sh" && exit
  #fi
  #echo

  #if [ -f "${PROJECT_PATH}"/scripts/base/app/symfony/component/assets/_webpack.sh ]; then
  #  source "${PROJECT_PATH}"/scripts/base/app/symfony/component/assets/_webpack.sh
  #else
  #  echo "Please check a file : ./scripts/base/app/symfony/component/assets/_webpack.sh" && exit
  #fi
  #echo
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

    # >>>> Firewall
    local UFW_STATUS
    UFW_STATUS=$(systemctl is-active ufw)
    if [ "${UFW_STATUS}" == "inactive" ]; then
      sudo systemctl start ufw
      sudo systemctl status ufw --no-pager
      echo
    fi
    echo "Firewall   : ${UFW_STATUS}"
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
