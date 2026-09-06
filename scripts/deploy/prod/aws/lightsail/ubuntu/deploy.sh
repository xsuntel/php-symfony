#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Deploy - Prod - AWS (Amzon Web Service) - Lightsail - Compute
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
  select num in "prod" "exit"; do
    case "$REPLY" in
    1)
      # >>>> Prod Environment
      ENVIRONMENT_NAME="prod"
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

  # >>>> Linux - Base
  if [ -f "${PROJECT_PATH}/scripts/base/_platform.sh" ]; then
    source "${PROJECT_PATH}/scripts/base/_platform.sh"
  else
    echo "Please check a file : ./scripts/base/_platform.sh" && exit
  fi
  echo

  # >>>> Linux - Server
  if [ -f "${PROJECT_PATH}/scripts/base/server/supervisor/_install.sh" ]; then
    source "${PROJECT_PATH}/scripts/base/server/supervisor/_install.sh"
  else
    echo "Please check a file : ./scripts/base/server/supervisor/_install.sh" && exit
  fi
  echo
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
}

# >>>> Cache

setRedis() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Base - Cache - Packages"
  echo -e  "---------------------------------------------------------------------------------------------------------\n"
  echo

  # >>>> Redis
  if [ -f "${PROJECT_PATH}"/scripts/base/cache/redis/_install.sh ]; then
    source "${PROJECT_PATH}"/scripts/base/cache/redis/_install.sh
  else
    echo "Please check a file : ./scripts/base/cache/redis/_install.sh" && exit
  fi
  echo
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
  echo

  # >>>> RabbitMQ
  if [ -f "${PROJECT_PATH}"/scripts/base/message/rabbitmq/_install.sh ]; then
    source "${PROJECT_PATH}"/scripts/base/message/rabbitmq/_install.sh
  else
    echo "Please check a file : ./scripts/base/message/rabbitmq/_install.sh" && exit
  fi
  echo
}

# >>>> Server

setNginx() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Base - Server - Packages"
  echo -e "----------------------------------------------------------------------------------------------------------\n"

  # >>>> Nginx
  if [ -f "${PROJECT_PATH}"/scripts/base/server/nginx/_install.sh ]; then
    source "${PROJECT_PATH}"/scripts/base/server/nginx/_install.sh
  else
    echo "Please check a file : ./scripts/base/server/nginx/_install.sh" && exit
  fi
  echo
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
  if [ -f "${PROJECT_PATH}"/scripts/base/app/symfony/common/_permissions.sh ]; then
    source "${PROJECT_PATH}"/scripts/base/app/symfony/common/_permissions.sh
  else
    echo "Please check a file : ./scripts/base/app/symfony/common/_permissions.sh" && exit
  fi
  echo

  # >>>> PHP - Symfony Framework - Deployment - Back-End  - Database    - (Optional)
  #if [ -f "${PROJECT_PATH}"/scripts/base/app/symfony/common/_database.sh ]; then
  #  source "${PROJECT_PATH}"/scripts/base/app/symfony/common/_database.sh
  #else
  #  echo "Please check a file : ./scripts/base/app/symfony/common/_database.sh" && exit
  #fi
  #echo

  # >>>> PHP - Symfony Framework - Deployment - Back-End  - Cron jobs   - (Optional)
  #if [ -f "${PROJECT_PATH}"/scripts/base/app/symfony/common/_cron.sh ]; then
  #  source "${PROJECT_PATH}"/scripts/base/app/symfony/common/_cron.sh
  #else
  #  echo "Please check a file : ./scripts/base/app/symfony/common/_cron.sh" && exit
  #fi
  #echo

  # >>>> PHP - Symfony Framework - Deployment - Back-End  - Messenger   - (Optional)
  if [ -f "${PROJECT_PATH}"/scripts/base/app/symfony/common/_messenger.sh ]; then
    source "${PROJECT_PATH}"/scripts/base/app/symfony/common/_messenger.sh
  else
    echo "Please check a file : ./scripts/base/app/symfony/common/_messenger.sh" && exit
  fi
  echo

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

  # >>>> AWS - Base - Import a CLI file
  #if [ -f "${PROJECT_PATH}"/scripts/deploy/prod/aws/base/_cli.sh ]; then
  #  source "${PROJECT_PATH}"/scripts/deploy/prod/aws/base/_cli.sh
  #else
  #  echo "Please check a file : ./scripts/deploy/prod/aws/base/_cli.sh" && exit
  #fi
  #echo

  # >>>> AWS - Base - Import a CDN file
  #if [ -f "${PROJECT_PATH}"/scripts/deploy/prod/aws/base/_s3.sh ]; then
  #  source "${PROJECT_PATH}"/scripts/deploy/prod/aws/base/_s3.sh
  #else
  #  echo "Please check a file : ./scripts/deploy/prod/aws/base/_s3.sh" && exit
  #fi
  #echo
}

# ----------------------------------------------------------------------------------------------------------------------
# Tools for VM ( Instance )
# ----------------------------------------------------------------------------------------------------------------------

setTools() {
  echo "---------------------------------------------------------------------------------------------------------------"
  echo "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Tools for VM ( Instance )"
  echo "---------------------------------------------------------------------------------------------------------------"


  echo ">>>> Operating System"
  echo

  # >>>> Cron
  local CRON_STATUS
  CRON_STATUS=$(systemctl is-active cron)
  if [ "${CRON_STATUS}" == "inactive" ]; then
    sudo systemctl start cron
    sudo systemctl status cron --no-pager
    echo
  fi
  echo "Cron       : ${CRON_STATUS}"
  echo

  # >>>> Supervisor
  local SUPERVISOR_STATUS
  SUPERVISOR_STATUS=$(systemctl is-active supervisor)
  if [ "${SUPERVISOR_STATUS}" == "inactive" ]; then
    sudo systemctl start supervisor
    sudo systemctl status supervisor --no-pager
    echo
  fi
  echo "Supervisor : ${SUPERVISOR_STATUS}"
  echo

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

  echo ">>>> Software Bundles"
  echo

  # >>>> App
  local PHP_STATUS
  PHP_STATUS=$(systemctl is-active "php${PHP_VERSION}-fpm")
  if [ "${PHP_STATUS}" == "inactive" ]; then
    sudo systemctl start "php${PHP_VERSION}-fpm"
    sudo systemctl status "php${PHP_VERSION}-fpm" --no-pager
    echo
  fi
  echo "PHP-FPM    : ${PHP_STATUS}"
  echo

  # >>>> Cache
  local REDIS_STATUS
  REDIS_STATUS=$(systemctl is-active redis)
  if [ "${REDIS_STATUS}" == "inactive" ]; then
    sudo systemctl start redis
    sudo systemctl status redis --no-pager
    echo
  fi
  echo "Cache      : ${REDIS_STATUS}"
  echo

  # >>>> Database
  if [ "${ENVIRONMENT_NAME}" == "dev" ]; then
    local POSTGRESQL_STATUS
    POSTGRESQL_STATUS=$(systemctl is-active postgresql)
    if [ "${POSTGRESQL_STATUS}" == "inactive" ]; then
      sudo systemctl start postgresql
      sudo systemctl status postgresql --no-pager
      echo
    fi
    echo "PostgreSQL : ${POSTGRESQL_STATUS}"
    echo
  fi

  # >>>> Server
  local NGINX_STATUS
  NGINX_STATUS=$(systemctl is-active nginx)
  if [ "${NGINX_STATUS}" == "inactive" ]; then
    sudo systemctl start nginx
    sudo systemctl status nginx --no-pager
    echo
  fi
  echo "NGINX      : ${NGINX_STATUS}"
  echo
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
setRedis

# >>>> Database
#setPostgreSQL

# >>>> Message
setRabbitMQ

# >>>> Server
setNginx

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
setProvider

# ----------------------------------------------------------------------------------------------------------------------
# Tools for VM ( Instance )
# ----------------------------------------------------------------------------------------------------------------------
setTools

# ----------------------------------------------------------------------------------------------------------------------
# Utility
# ----------------------------------------------------------------------------------------------------------------------
#setUtility

# ----------------------------------------------------------------------------------------------------------------------
# END
# ----------------------------------------------------------------------------------------------------------------------

setEnd
