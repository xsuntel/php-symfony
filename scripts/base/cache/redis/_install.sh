#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Deploy - Dev - Linux - Ubuntu - Redis - Install
# ----------------------------------------------------------------------------------------------------------------------
# >>>> Platform
if [ "${PLATFORM_TYPE}" == "Linux" ]; then

  # --------------------------------------------------------------------------------------------------------------------
  # Redis - Install the packages
  # --------------------------------------------------------------------------------------------------------------------
  # >>>> Redis
  echo ">>>> Redis"
  echo

  local REDIS_STATUS
  REDIS_STATUS=$(dpkg -l | grep -i "redis-server" | awk '{print $2}' | cut -d ':' -f1 | awk "/^redis-server$/")
  if [ "${REDIS_STATUS}" != "redis-server" ]; then
    sudo apt install -y redis-server
    echo

    sudo systemctl enable redis-server
    echo
  fi

  # --------------------------------------------------------------------------------------------------------------------
  # Redis - Update the configuration                                            https://redis.io/docs/management/config/
  # --------------------------------------------------------------------------------------------------------------------
  echo ">>>> Redis - Configuration"
  echo

  # >>>> Redis - Configuration
  if [ -f /etc/redis/redis.conf ]; then
    sudo cp -fv "${PROJECT_PATH}/scripts/base/cache/redis/redis_${ENVIRONMENT_NAME}.conf" /etc/redis/redis.conf
    sudo chown redis:redis /etc/redis/redis.conf
  fi

  # >>>> Redis - Remove log files
  if [ -f /var/log/redis/redis-server.log ]; then
    cat /dev/null > /var/log/redis/redis-server.log
    if [ -f /var/log/redis/redis-server.log.1 ]; then
      sudo rm -fv /var/log/redis/redis-server.log.*
      echo
    fi
  fi

  # --------------------------------------------------------------------------------------------------------------------
  # Redis - Check status
  # --------------------------------------------------------------------------------------------------------------------
  echo ">>>> Redis - Status"
  echo

  local REDIS_STATUS
  REDIS_STATUS=$(systemctl is-active redis-server)
  if [ "${REDIS_STATUS}" != "active" ]; then
    sudo systemctl start redis-server
    echo
  fi

  redis-server -v


elif [ "${PLATFORM_TYPE}" == "Darwin" ]; then
  # --------------------------------------------------------------------------------------------------------------------
  # Redis - Install the packages
  # --------------------------------------------------------------------------------------------------------------------
  # >>>> Redis
  echo ">>>> Redis"
  echo

  local PECL_STATUS
  PECL_STATUS=$(pecl list | awk '/redis/ {print $0}' | cut -c 1-6)
  if [ -n "${PECL_STATUS}" ]; then
    pecl list | grep -i redis
  else
    export LC_CTYPE=en_US.UTF-8
    export LC_ALL=en_US.UTF-8

    pecl install redis
  fi
  echo

  # --------------------------------------------------------------------------------------------------------------------
  # Redis - Update the configuration
  # --------------------------------------------------------------------------------------------------------------------
  echo ">>>> Redis - Configuration"
  echo

  local REDIS_PKG
  REDIS_PKG=$(brew list | grep 'redis$')
  if [ "${REDIS_PKG}" ]; then
    brew services info redis
  else
    brew install redis
  fi
  echo

  # >>>> Process : Background
  brew services restart redis
  echo

elif [ "${PLATFORM_TYPE}" == "Windows" ]; then
  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Windows - WSL2
  # --------------------------------------------------------------------------------------------------------------------
  # >>>> Environment
  if [ "${ENVIRONMENT_NAME}" == "dev" ]; then
    # >>>> Redis
    echo ">>>> Redis"
    echo
  fi
  echo

else
  echo "Please check Operating System"
  setExit
fi
