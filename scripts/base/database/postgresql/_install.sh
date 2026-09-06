#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Deploy - Dev - Linux - Ubuntu - PostgreSQL - Install
# ----------------------------------------------------------------------------------------------------------------------
# >>>> Platform
if [ "${PLATFORM_TYPE}" == "Linux" ]; then

  # --------------------------------------------------------------------------------------------------------------------
  # PostgreSQL - Install the packages
  # --------------------------------------------------------------------------------------------------------------------
  # >>>> PostgreSQL
  echo ">>>> PostgreSQL"
  echo

  local POSTGRESQL_STATUS
  POSTGRESQL_STATUS=$(dpkg -l | grep -i "postgresql" | awk '{print $2}' | cut -d ':' -f1 | awk "/^postgresql$/")
  if [ "${POSTGRESQL_STATUS}" != "postgresql" ]; then
    sudo apt install -y postgresql
    echo

    sudo systemctl enable postgresql
    echo
  fi

  # --------------------------------------------------------------------------------------------------------------------
  # PostgreSQL - Update the configuration
  # --------------------------------------------------------------------------------------------------------------------
  echo ">>>> PostgreSQL - Configuration"
  echo


  # --------------------------------------------------------------------------------------------------------------------
  # PostgreSQL - Check status
  # --------------------------------------------------------------------------------------------------------------------
  echo ">>>> PostgreSQL - Status"
  echo

  local POSTGRESQL_STATUS
  POSTGRESQL_STATUS=$(systemctl is-active postgresql)
  if [ "${POSTGRESQL_STATUS}" != "active" ]; then
    sudo systemctl start postgresql
    echo
  fi

  psql --version

elif [ "${PLATFORM_TYPE}" == "Darwin" ]; then
  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Mac - MacOS
  # --------------------------------------------------------------------------------------------------------------------
  # >>>> Environment
  if [ "${ENVIRONMENT_NAME}" == "dev" ]; then
    # >>>> Docker
    echo ">>>> Docker"
    echo
  fi
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
