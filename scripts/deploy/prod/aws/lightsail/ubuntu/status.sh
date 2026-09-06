#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Server - Status
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
  echo

  # >>>> Import a project file
  if [ -f "${PROJECT_PATH}"/scripts/base/_environment.sh ]; then
    source "${PROJECT_PATH}"/scripts/base/_environment.sh
  else
    echo "Please check a file : ./scripts/base/_environment.sh" && exit
  fi
}

# >>>> Platform

setPlatform() {
  echo "---------------------------------------------------------------------------------------------------------------"
  echo "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Platform "
  echo "---------------------------------------------------------------------------------------------------------------"
  echo

  # >>>> Platform
  if [ "${PLATFORM_TYPE}" == "Linux" ]; then
    # ------------------------------------------------------------------------------------------------------------------
    # Platform - Linux - Ubuntu
    # ------------------------------------------------------------------------------------------------------------------
    # >>>> Release
    if [ -f /etc/lsb-release ]; then
      echo ">>>> Release"
      echo

      cat /etc/lsb-release
      echo

      echo ">>>> Services"
      echo

      service --status-all | grep '\[ + \]'
      echo

      # >>>> TimeZone
      echo ">>>> TimeZone"
      timedatectl
      echo
    fi

  elif [ "${PLATFORM_TYPE}" == "Darwin" ]; then
    # ------------------------------------------------------------------------------------------------------------------
    # Platform - Mac - MacOS
    # ------------------------------------------------------------------------------------------------------------------
    # >>>> Release
    echo ">>>> Release"
    echo

    sw_vers
    echo

  elif [ "${PLATFORM_TYPE}" == "Windows" ]; then
    # ------------------------------------------------------------------------------------------------------------------
    # Platform - Windows - WSL2
    # ------------------------------------------------------------------------------------------------------------------
    # >>>> Release
    echo ">>>> Release"
    echo

    ver
    echo

  else
    echo "Please check Operating System"
    setExit
  fi
  echo
}

# >>>> Project

setProject() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Project : ${PROJECT_NAME}"
  echo -e "----------------------------------------------------------------------------------------------------------\n"

  echo ">>>> Git - Global"
  echo

  git config --global --list
  echo

  echo ">>>> Git - Local"
  echo

  git config --local --list
  echo
}

# ----------------------------------------------------------------------------------------------------------------------
# Architecture
# ----------------------------------------------------------------------------------------------------------------------

# >>>> App

setPhp() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Base - App - Packages"
  echo -e "----------------------------------------------------------------------------------------------------------\n"

  # >>>> Platform
  if [ "${PLATFORM_TYPE}" == "Linux" ]; then
    # ------------------------------------------------------------------------------------------------------------------
    # Platform - Linux - Ubuntu
    # ------------------------------------------------------------------------------------------------------------------o

    # >>>> PHP
    echo ">>>> PHP"
    echo

    php -v
    echo

    composer --version
    echo

    # >>>> PHP-FPM
    echo ">>>> PHP-FPM"
    echo

    local PHP_STATUS
    PHP_STATUS=$(systemctl is-active "php${PHP_VERSION}-fpm")
    if [ "${PHP_STATUS}" == "inactive" ]; then
      sudo systemctl start "php${PHP_VERSION}-fpm"
      sudo systemctl status "php${PHP_VERSION}-fpm" --no-pager
      echo
    fi
    echo "PHP-FPM    : ${PHP_STATUS}"
    echo

  elif [ "${PLATFORM_TYPE}" == "Darwin" ]; then
    # ------------------------------------------------------------------------------------------------------------------
    # Platform - Mac - MacOS
    # ------------------------------------------------------------------------------------------------------------------

    # >>>> PHP-FPM
    echo

  elif [ "${PLATFORM_TYPE}" == "Windows" ]; then
    # ------------------------------------------------------------------------------------------------------------------
    # Platform - Windows - WSL2
    # ------------------------------------------------------------------------------------------------------------------

    # >>>> PHP-FPM
    echo

  else
    echo "Please check Operating System"
    setExit
  fi
  echo

  # >>>> Directory
  if [ -d app ]; then
    (
      cd app || return
      # >>>> PHP - Symfony Command
      if [ -f bin/console ]; then

        # >>>> App - PHP - Symfony Framework
        echo -e ">>>> App - PHP - Symfony Framework\n"

        # --------------------------------------------------------------------------------------------------------------
        # Symfony Framework - Requirements:
        # --------------------------------------------------------------------------------------------------------------
        if [ -f composer.lock ]; then
          symfony check:require
        fi
        echo

        # --------------------------------------------------------------------------------------------------------------
        # Symfony Framework - Security Vulnerabilities
        # --------------------------------------------------------------------------------------------------------------
        if [ -f composer.lock ]; then
          symfony check:security
        fi
        echo

        # --------------------------------------------------------------------------------------------------------------
        # Symfony Framework - Variable Export
        # --------------------------------------------------------------------------------------------------------------
        # >>>> Variable Export
        symfony var:export --multiline
        echo

      fi
    )
  else
    echo "[ ERROR ] There is not a folder : app"
    setExit
  fi
}

# >>>> Cache

setRedis() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Base - Cache - Packages"
  echo -e  "---------------------------------------------------------------------------------------------------------\n"
  echo

  # >>>> Platform
  if [ "${PLATFORM_TYPE}" == "Linux" ]; then
    # ------------------------------------------------------------------------------------------------------------------
    # Platform - Linux - Ubuntu
    # ------------------------------------------------------------------------------------------------------------------

    # >>>> Redis
    if [ "${ENVIRONMENT_NAME}" == "dev" ]; then
      local REDIS_STATUS
      REDIS_STATUS=$(systemctl is-active redis)
      if [ "${REDIS_STATUS}" == "inactive" ]; then
        sudo systemctl start redis
        sudo systemctl status redis --no-pager
        echo
      fi
      echo "Cache      : ${REDIS_STATUS}"
      echo

      redis-server -v
    fi

  elif [ "${PLATFORM_TYPE}" == "Darwin" ]; then
    # ------------------------------------------------------------------------------------------------------------------
    # Platform - Mac - MacOS
    # ------------------------------------------------------------------------------------------------------------------

    # >>>> Redis
    echo

  elif [ "${PLATFORM_TYPE}" == "Windows" ]; then
    # ------------------------------------------------------------------------------------------------------------------
    # Platform - Windows - WSL2
    # ------------------------------------------------------------------------------------------------------------------

    # >>>> Redis
    echo

  else
    echo "Please check Operating System"
    setExit
  fi
  echo
}

# >>>> Database

setPostgreSQL() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Base - Database - Packages"
  echo -e "----------------------------------------------------------------------------------------------------------\n"
  echo

  # >>>> Platform
  if [ "${PLATFORM_TYPE}" == "Linux" ]; then
    # ------------------------------------------------------------------------------------------------------------------
    # Platform - Linux - Ubuntu
    # ------------------------------------------------------------------------------------------------------------------

    # >>>> PostgreSQL
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

      psql --version
    fi

  elif [ "${PLATFORM_TYPE}" == "Darwin" ]; then
    # ------------------------------------------------------------------------------------------------------------------
    # Platform - Mac - MacOS
    # ------------------------------------------------------------------------------------------------------------------

    # >>>> PostgreSQL
    echo

  elif [ "${PLATFORM_TYPE}" == "Windows" ]; then
    # ------------------------------------------------------------------------------------------------------------------
    # Platform - Windows - WSL2
    # ------------------------------------------------------------------------------------------------------------------

    # >>>> PostgreSQL
    echo

  else
    echo "Please check Operating System"
    setExit
  fi
  echo
}

# >>>> Message

setRabbitMQ() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Base - Message - Packages"
  echo -e "----------------------------------------------------------------------------------------------------------\n"
  echo

  # >>>> Platform
  if [ "${PLATFORM_TYPE}" == "Linux" ]; then
    # ------------------------------------------------------------------------------------------------------------------
    # Platform - Linux - Ubuntu
    # ------------------------------------------------------------------------------------------------------------------

    # >>>> RabbitMQ
    if [ "${ENVIRONMENT_NAME}" == "dev" ]; then
      local RABBITMQ_STATUS
      RABBITMQ_STATUS=$(systemctl is-active rabbitmq-server)
      if [ "${RABBITMQ_STATUS}" == "inactive" ]; then
        sudo systemctl start rabbitmq-server
        sudo systemctl status rabbitmq-server --no-pager
        echo
      fi
      echo "RabbitMQ   : ${RABBITMQ_STATUS}"
      echo

      dpkg -s rabbitmq-server | grep Version
    fi

  elif [ "${PLATFORM_TYPE}" == "Darwin" ]; then
    # ------------------------------------------------------------------------------------------------------------------
    # Platform - Mac - MacOS
    # ------------------------------------------------------------------------------------------------------------------

    # >>>> RabbitMQ
    echo

  elif [ "${PLATFORM_TYPE}" == "Windows" ]; then
    # ------------------------------------------------------------------------------------------------------------------
    # Platform - Windows - WSL2
    # ------------------------------------------------------------------------------------------------------------------

    # >>>> RabbitMQ
    echo

  else
    echo "Please check Operating System"
    setExit
  fi
  echo
}

# >>>> Server

setNginx() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Base - Server - Packages"
  echo -e "----------------------------------------------------------------------------------------------------------\n"
  echo

  # >>>> Platform
  if [ "${PLATFORM_TYPE}" == "Linux" ]; then
    # ------------------------------------------------------------------------------------------------------------------
    # Platform - Linux - Ubuntu
    # ------------------------------------------------------------------------------------------------------------------o

    # >>>> Nginx
    if [ "${ENVIRONMENT_NAME}" == "prod" ]; then
      local NGINX_STATUS
      NGINX_STATUS=$(systemctl is-active nginx)
      if [ "${NGINX_STATUS}" == "inactive" ]; then
        sudo systemctl start nginx
        sudo systemctl status nginx --no-pager
        echo
      fi
      echo "NGINX      : ${NGINX_STATUS}"
      echo

      sudo nginx -v

    else

      symfony server:status
      echo

      symfony server:ls
      echo

    fi

  elif [ "${PLATFORM_TYPE}" == "Darwin" ]; then
    # ------------------------------------------------------------------------------------------------------------------
    # Platform - Mac - MacOS
    # ------------------------------------------------------------------------------------------------------------------

    # >>>> Nginx
    echo

  elif [ "${PLATFORM_TYPE}" == "Windows" ]; then
    # ------------------------------------------------------------------------------------------------------------------
    # Platform - Windows - WSL2
    # ------------------------------------------------------------------------------------------------------------------

    # >>>> Nginx
    echo

  else
    echo "Please check Operating System"
    setExit
  fi
  echo
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

  # >>>> Environment
  if [ "${ENVIRONMENT_NAME}" == "dev" ]; then

    # >>>> Docker Desktop                                                               https://docs.docker.com/reference/
    echo -e ">>>> Docker Version\n"
    docker version
    echo

    echo -e ">>>> Docker Info\n"
    docker info
    echo

    # >>>> Docker - Process
    echo ">>>> Docker - Process"
    echo
    docker ps -a
    echo

    # >>>> Docker - Images
    echo ">>>> Docker - images"
    echo

    docker images
    echo

  fi
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
  echo "---------------------------------------------------------------------------------------------------------------"
  echo "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Tools for VM ( Instance )"
  echo "---------------------------------------------------------------------------------------------------------------"


  local HOSTIP
  # >>>> Platform
  if [ "${PLATFORM_TYPE}" == "Linux" ]; then
    # ------------------------------------------------------------------------------------------------------------------
    # Platform - Linux - Ubuntu
    # ------------------------------------------------------------------------------------------------------------------
    # >>>> Hosts
    echo ">>>> Hosts"
    echo
    sudo grep -v '#' /etc/hosts
    echo

    # >>>> Hardware
    echo ">>>> CPU"
    echo
    top -b -n 1 | head -n 5
    echo

    echo ">>>> Memory"
    echo

    free -m
    echo

    grep -i anon /proc/meminfo
    echo

    echo ">>>> SSD"
    echo
    df -h
    echo

    echo ">>>> Network"
    echo

    nmcli device status
    echo

    netstat -i
    echo

    netstat -rn
    echo

    netstat -napotl | grep -i LISTEN | grep -v tcp6
    echo

    netstat -napo | grep -i time_wait
    echo

    echo ">>>> Firewall"
    echo

    sudo ufw status verbose --no-pager
    echo

    echo ">>>> Process"
    echo

    # >>>> Rsyslog
    local RSYSLOG_STATUS
    RSYSLOG_STATUS=$(systemctl is-active rsyslog)
    if [ "${RSYSLOG_STATUS}" == "inactive" ]; then
      sudo systemctl start rsyslog
      sudo systemctl status rsyslog --no-pager
      echo
    fi
    echo
    echo "Rsyslog    : ${RSYSLOG_STATUS}"
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

    #ps -ef | grep -i messenger:consume | grep -v grep

    supervisorctl status
    echo

  elif [ "${PLATFORM_TYPE}" == "Darwin" ]; then
    # ------------------------------------------------------------------------------------------------------------------
    # Platform - Mac - MacOS
    # ------------------------------------------------------------------------------------------------------------------
    # >>>> Hosts
    echo ">>>> Hosts"
    echo
    grep -v '#' /etc/hosts
    echo

    HOSTIP=$(ifconfig en0 | grep -e 'inet\s' | awk '{print $2}')
    echo "- HOST     IP : ${HOSTIP}"
    echo

    echo ">>>> Supervisor : ${SUPERVISOR_STATUS}"
    echo

    pgrep -af messenger:consume
    echo

  elif [ "${PLATFORM_TYPE}" == "Windows" ]; then
    # ------------------------------------------------------------------------------------------------------------------
    # Platform - Windows - WSL2
    # ------------------------------------------------------------------------------------------------------------------
    # >>>> Hosts
    echo ">>>> Hosts"
    echo
    grep -v '#' /windows/system32/drivers/etc/hosts
    echo

    #HOSTIP = $(Get-NetIPConfiguration | Where-Object {$_.IPv4DefaultGateway -ne $null}).IPv4Address.IPAddress
    #echo "- HOST     IP : ${HOSTIP}"

  else
    echo "Please check Operating System"
    setExit
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
setPostgreSQL

# >>>> Message
setRabbitMQ

# >>>> Server
setNginx

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
