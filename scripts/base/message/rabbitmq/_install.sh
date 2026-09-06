#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Deploy - Dev - Windows - Desktop - RabbitMQ - Install                        https://www.rabbitmq.com/docs/install-homebrew
# ----------------------------------------------------------------------------------------------------------------------
# >>>> Platform
if [ "${PLATFORM_TYPE}" == "Linux" ]; then

  # --------------------------------------------------------------------------------------------------------------------
  # RabbitMQ - Install the packages             https://velog.io/@thekim12/rabbitmq-%EC%84%A4%EC%B9%98%ED%95%98%EA%B8%B0
  # --------------------------------------------------------------------------------------------------------------------
  # >>>> RabbitMQ
  echo ">>>> RabbitMQ"
  echo

  local RABBITMQ_STATUS
  RABBITMQ_STATUS=$(dpkg -l | grep -i "rabbitmq-server" | awk '{print $2}' | cut -d ':' -f1 | awk "/^rabbitmq-server/")
  if [ "${RABBITMQ_STATUS}" != "rabbitmq-server" ]; then
    echo "- Install packages"
    # >>>> RabbitMQ - Install required packages
    local addPackageList="curl gnupg apt-transport-https"
    for pkgItem in ${addPackageList}; do
      local APT_PKG_INFO
      APT_PKG_INFO=$(dpkg -l | grep -i "${pkgItem}" | awk '{print $2}' | cut -d ':' -f1 | awk "/^${pkgItem}$/")
      if [ "${APT_PKG_INFO}" != "${pkgItem}" ]; then
        sudo apt install -y "${pkgItem}"
        echo
      fi
    done

    # >>>> RabbitMQ - Add GPG Key
    if [ ! -f /usr/share/keyrings/rabbitmq-archive-keyring.gpg ]; then
      curl -fsSL https://www.rabbitmq.com/rabbitmq-release-signing-key.asc | sudo gpg --dearmor -o /usr/share/keyrings/rabbitmq-archive-keyring.gpg
    fi

    # >>>> RabbitMQ - Add repository
    if [ ! -f /etc/apt/sources.list.d/rabbitmq.list ]; then
      echo "deb [signed-by=/usr/share/keyrings/rabbitmq-archive-keyring.gpg] http://www.rabbitmq.com/debian/ testing main" | sudo tee /etc/apt/sources.list.d/rabbitmq.list
    fi

    # >>>> RabbitMQ - Install rabbitmq-server and its dependencies
    sudo apt-get update -y
    sudo apt-get install rabbitmq-server -y --fix-missing
    echo

    sudo systemctl enable rabbitmq-server
    echo

    # >>>> RabbitMQ - Install Plugins
    if [ "${ENVIRONMENT_NAME}" == "dev" ]; then
      sudo rabbitmq-plugins enable rabbitmq_management rabbitmq_stream_management
    else
      sudo rabbitmq-plugins enable rabbitmq_stream_management
    fi

    sudo rabbitmq-plugins list
  fi

  # --------------------------------------------------------------------------------------------------------------------
  # RabbitMQ - Update the configuration
  # --------------------------------------------------------------------------------------------------------------------
  echo ">>>> RabbitMQ - Configuration"
  echo

  # >>>> RabbitMQ - Remove files
  if [ -f /etc/apt/sources.list.d/rabbitmq.list ]; then
    sudo rm -f /etc/apt/sources.list.d/rabbitmq.list
  fi

  if [ -f /etc/apt/sources.list.d/erlang.list ]; then
    sudo rm -f /etc/apt/sources.list.d/erlang.list
  fi

  # --------------------------------------------------------------------------------------------------------------------
  # RabbitMQ - Check status
  # --------------------------------------------------------------------------------------------------------------------
  echo ">>>> RabbitMQ - Status"
  echo

  local RABBITMQ_STATUS
  RABBITMQ_STATUS=$(systemctl is-active rabbitmq-server)
  if [ "${RABBITMQ_STATUS}" != "active" ]; then
    sudo systemctl start rabbitmq-server
    echo
  fi

  dpkg -s rabbitmq-server | grep Version

elif [ "${PLATFORM_TYPE}" == "Darwin" ]; then
  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Mac - MacOS
  # --------------------------------------------------------------------------------------------------------------------
  # >>>> Environment

  # --------------------------------------------------------------------------------------------------------------------
  # RabbitMQ - Install the related packages
  # --------------------------------------------------------------------------------------------------------------------
  # >>>> RabbitMQ
  echo ">>>> RabbitMQ"
  echo

  local RABBITMQ_LIB
  RABBITMQ_LIB=$(brew list | grep 'rabbitmq-c$')
  if [ "${RABBITMQ_LIB}" ]; then
    brew list | grep rabbitmq-c
  else
    export LC_CTYPE=en_US.UTF-8
    export LC_ALL=en_US.UTF-8

    brew install rabbitmq-c
    brew services info rabbitmq-c
  fi
  echo

  local PECL_STATUS
  PECL_STATUS=$(pecl list | awk '/amqp/ {print $0}' | cut -c 1-6)
  if [ -n "${PECL_STATUS}" ]; then
    pecl list | grep -i amqp
  else
    echo "-------------------------------------------------------------------------------------------------------------"
    echo ls -ltr /opt/homebrew/Cellar/rabbitmq-c/
    echo
    echo "Please check the related version"
    echo "Set the path to librabbitmq install prefix [autodetect] : /opt/homebrew/Cellar/rabbitmq-c/0.XX.0"
    echo "-------------------------------------------------------------------------------------------------------------"
    echo

    export LC_CTYPE=en_US.UTF-8
    export LC_ALL=en_US.UTF-8

    pecl install amqp
  fi
  echo

  # --------------------------------------------------------------------------------------------------------------------
  # RabbitMQ - Update the configuration
  # --------------------------------------------------------------------------------------------------------------------
  echo ">>>> RabbitMQ - Configuration"
  echo

  local RABBITMQ_PKG
  RABBITMQ_PKG=$(brew list | grep 'rabbitmq$')
  if [ "${RABBITMQ_PKG}" ]; then
    brew services info rabbitmq
  else
    brew install rabbitmq
  fi
  echo

  # >>>> Process : Background

  # starts a local RabbitMQ node
  brew services start rabbitmq

  # highly recommended: enable all feature flags on the running node
  /opt/homebrew/sbin/rabbitmqctl enable_feature_flag all
  echo

elif [ "${PLATFORM_TYPE}" == "Windows" ]; then
  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Windows - WSL2
  # --------------------------------------------------------------------------------------------------------------------
  # >>>> Environment
  if [ "${ENVIRONMENT_NAME}" == "dev" ]; then
    # >>>> Docker
    echo ">>>> Docker"
    echo
  fi
  echo

else
  echo "Please check Operating System"
  setExit
fi
