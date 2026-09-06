#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Deploy - Dev - Linux - Ubuntu - Status
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

  # >>>> PHP
  echo -e ">>>> PHP\n"

  php -v
  echo

  composer --version
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
  echo

  # >>>> Nginx
  if [ "${ENVIRONMENT_NAME}" == "prod" ]; then
    local NGINX_STATUS
    NGINX_STATUS=$(systemctl is-active nginx)
    if [ "${NGINX_STATUS}" == "inactive" ]; then
      sudo systemctl start nginx
      sudo systemctl status nginx --no-pager
      echo
    fi
    echo -e "NGINX      : ${NGINX_STATUS}\n"

    sudo nginx -v

  else

    symfony server:status
    echo

    symfony server:ls
    echo

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
# CDN - Content Delivery
# ----------------------------------------------------------------------------------------------------------------------

setCDN() {
  echo "---------------------------------------------------------------------------------------------------------------"
  echo "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - CDN ( Content Delivery Networks ) - Upload files"
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

    # >>>> Docker - System
    echo -e ">>>> Docker - System\n"
    docker system df
    echo

    # >>>> Docker - Images
    echo -e ">>>> Docker - images\n"
    docker image ls
    echo

    # >>>> Docker - Container
    echo -e ">>>> Docker - Container\n"
    docker container ls
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
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Tools for VM ( Instance )"
  echo -e "----------------------------------------------------------------------------------------------------------\n"

  # >>>> Environment
  if [ "${ENVIRONMENT_NAME}" == "dev" ]; then

    local HOSTIP

    # >>>> Hosts
    echo -e ">>>> Hosts\n"
    sudo grep -v '#' /etc/hosts
    echo

    # >>>> Hardware
    echo -e ">>>> CPU\n"
    top -b -n 1 | head -n 5
    echo

    echo -e ">>>> Memory\n"
    free -m
    echo

    grep -i anon /proc/meminfo
    echo

    echo -e ">>>> SSD\n"
    df -h
    echo

    echo -e ">>>> Network\n"

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

    echo -e ">>>> Firewall\n"
    sudo ufw status verbose --no-pager
    echo

    echo -e ">>>> Process\n"

    # >>>> Rsyslog
    local RSYSLOG_STATUS
    RSYSLOG_STATUS=$(systemctl is-active rsyslog)
    if [ "${RSYSLOG_STATUS}" == "inactive" ]; then
      sudo systemctl start rsyslog
      systemctl status rsyslog --no-pager
      echo
    fi
    echo -e "Rsyslog    : ${RSYSLOG_STATUS}\n"

    # >>>> Cron
    local CRON_STATUS
    CRON_STATUS=$(systemctl is-active cron)
    if [ "${CRON_STATUS}" == "inactive" ]; then
      sudo systemctl start cron
      sudo systemctl status cron --no-pager
      echo
    fi
    echo -e "Cron       : ${CRON_STATUS}\n"

    # >>>> Host
    namectl
    echo

    uname -n
    echo

    arp
    echo

    # >>>> Hardware
    nmcli general status
    echo

    ip route show
    echo

    ip addr show
    echo

    grep -v '#' /etc/resolv.conf
    echo

    resolvectl status --no-pager
    echo

    # >>>> UFW
    sudo ufw status verbose --no-pager
    echo

    sudo journalctl -u ufw
    echo

    sudo journalctl -k | grep "UFW"
    echo

    sudo grep "BLOCK" /var/log/ufw.log
    echo

    # >>>> ebtables
    sudo dmesg | grep "EBT-"
    echo

    sudo grep "EBT-" /var/log/syslog
    echo

    sudo journalctl -k | grep "EBT-"
    echo

    #sudo tail -f /var/log/kern.log | grep "EBT-"

    # >>>> status
    netstat -r
    echo

    netstat -an | grep LISTEN
    echo

    #netstat -p
    #echo

    netstat -i
    echo

    netstat -s
    echo

    sudo ss -tulpn
    echo

    # ------------------------------------------------------------------------------------------------------------------
    # Security - Logs
    # ------------------------------------------------------------------------------------------------------------------
    YESTERDAY=$(date -d "yesterday" '+%Y-%m-%d 12:00:00')
    TODAY=$(date '+%Y-%m-%d 00:00:00')
    ONE_HOUR_AGO=$(date -d "1 hour ago" '+%Y-%m-%d %H:%M:%S')

    journalctl -p err --since="${ONE_HOUR_AGO}" --no-pager
    echo

    journalctl -u NetworkManager --since="${ONE_HOUR_AGO}" --no-pager
    echo
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
#setRedis

# >>>> Database
#setPostgreSQL

# >>>> Message
#setRabbitMQ

# >>>> Server
setNginx

# ----------------------------------------------------------------------------------------------------------------------
# Build Scripts
# ----------------------------------------------------------------------------------------------------------------------
#setBuild

# ----------------------------------------------------------------------------------------------------------------------
# CDN - Content Delivery
# ----------------------------------------------------------------------------------------------------------------------
#setCDN

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
#setUtility

# ----------------------------------------------------------------------------------------------------------------------
# END
# ----------------------------------------------------------------------------------------------------------------------

setEnd
