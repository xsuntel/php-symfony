#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Base - Utility - Docker
# ----------------------------------------------------------------------------------------------------------------------

# >>>> Platform
if [ "${PLATFORM_TYPE}" == "Linux" ]; then
  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Linux                      https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
  # --------------------------------------------------------------------------------------------------------------------
  # >>>> Environment
  if [ "${ENVIRONMENT_NAME}" == "dev" ]; then
    # >>>> Docker
    echo ">>>> Docker - Packages"
    echo
    if [ -d /etc/apt/keyrings ]; then
      if [ ! -f /etc/apt/keyrings/docker.asc ]; then
        sudo install -m 0755 -d /etc/apt/keyrings

        # >>>> Docker - Add Docker's official GPG key:
        sudo apt update -y
        local addPackageList="ca-certificates curl gnupg"
        for pkgItem in ${addPackageList}; do
          local APT_PKG_INFO
          APT_PKG_INFO=$(dpkg -l | grep -i "${pkgItem}" | awk '{print $2}' | cut -d ':' -f1 | awk "/^${pkgItem}$/")
          if [ "${APT_PKG_INFO}" != "${pkgItem}" ]; then
            sudo apt-get install -y "${pkgItem}"
            echo
          fi
        done

        # >>>> Docker - Add the repository to Apt sources:

        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc

sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

        sudo apt update -y

        # >>>> Docker - Install packages

        local addPackageList="docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"
        for pkgItem in ${addPackageList}; do
          local APT_PKG_INFO
          APT_PKG_INFO=$(dpkg -l | grep -i "${pkgItem}" | awk '{print $2}' | cut -d ':' -f1 | awk "/^${pkgItem}$/")
          if [ "${APT_PKG_INFO}" != "${pkgItem}" ]; then
            sudo apt-get install -y "${pkgItem}"
            echo
          fi
        done

        # >>>> Docker - Update a permission
        if [ -f /var/run/docker.sock ]; then
          sudo usermod -aG docker "${USER}"
          sudo chmod 666 /var/run/docker.sock
          newgrp docker
          echo
        fi
      fi
    fi
  fi

elif [ "${PLATFORM_TYPE}" == "Darwin" ]; then
  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Mac - MacOS
  # --------------------------------------------------------------------------------------------------------------------
  # >>>> Environment
  if [ "${ENVIRONMENT_NAME}" == "dev" ]; then
    # >>>> Docker
    echo ">>>> Docker - Packages"
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
    echo ">>>> Docker - Packages"
    echo
  fi
  echo

else
  echo "Please check Operating System"
  setExit
fi
