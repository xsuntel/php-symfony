#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Base - App - Symfony Framework - Front-End                     https://symfony.com/doc/current/frontend.html
# ----------------------------------------------------------------------------------------------------------------------

# >>>> Platform

if [ -f "${PROJECT_PATH}/.env.app" ]; then
  NODE_VERSION=$(grep -i NODE_VERSION "${PROJECT_PATH}"/.env.app | cut -d '=' -f2)
fi

if [ "${PLATFORM_TYPE}" == "Linux" ]; then
  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Linux - Ubuntu
  # --------------------------------------------------------------------------------------------------------------------
  # >>>> Environment
  if [ "${ENVIRONMENT_NAME}" == "dev" ]; then
    # >>>> Nodejs
    local NODEJS_PKG_INFO
    NODEJS_PKG_INFO=$(dpkg -l | grep -i "nodejs" | awk '{print $2}' | cut -d ':' -f1 | awk "/^nodejs$/")
    if [ "${NODEJS_PKG_INFO}" != "nodejs" ]; then

      # >>>> Install packages
      local addPackageList="ca-certificates gnupg"
      for pkgItem in ${addPackageList}; do
        local APT_PKG_INFO
        APT_PKG_INFO=$(dpkg -l | grep -i "${pkgItem}" | awk '{print $2}' | cut -d ':' -f1 | awk "/^${pkgItem}$/")
        if [ "${APT_PKG_INFO}" != "${pkgItem}" ]; then
          sudo apt-get install -y "${pkgItem}"
          echo
        fi
      done

      # >>>> Install a key
      if [ ! -f /etc/apt/keyrings/nodesource.gpg ]; then
        if [ ! -d /etc/apt/keyrings ]; then
          sudo mkdir -p /etc/apt/keyrings
        fi
        curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
      fi

      echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_VERSION}.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
      echo

      # >>>> Install package
      sudo apt-get update && sudo apt-get install nodejs -y
      echo

    fi
  fi

elif [ "${PLATFORM_TYPE}" == "Darwin" ]; then
  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Mac - MacOS
  # --------------------------------------------------------------------------------------------------------------------
  # >>>> Environment
  if [ "${ENVIRONMENT_NAME}" == "dev" ]; then
    # >>>> Nodejs
    local NODE_PKG
    NODE_PKG=$(brew list | grep "node@${NODE_VERSION}")
    if [ ! -f "/opt/homebrew/opt/node@${NODE_VERSION}/bin/node" ]; then
      (
        cd /tmp || return

        brew install "node@${NODE_VERSION}"
        echo

        brew unlink "node@${NODE_VERSION}" && brew link "node@${NODE_VERSION}"
        echo

      )
    fi
  fi

elif [ "${PLATFORM_TYPE}" == "Windows" ]; then
  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Windows - WSL2
  # --------------------------------------------------------------------------------------------------------------------
  # >>>> Environment
  if [ "${ENVIRONMENT_NAME}" == "dev" ]; then
    # >>>> Nodejs

    echo

  fi

else
  echo "Please check Operating System"
  setExit
fi
