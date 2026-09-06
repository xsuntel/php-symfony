#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Base - App - Symfony - Command Line Interface                                   https://symfony.com/download
# ----------------------------------------------------------------------------------------------------------------------

# >>>> Platform
if [ "${PLATFORM_TYPE}" == "Linux" ]; then
  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Linux - Ubuntu
  # --------------------------------------------------------------------------------------------------------------------
  # >>>> App - PHP - Symfony CLI
  if [ ! -f /bin/symfony ]; then
    (
      cd /tmp || return

      curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.deb.sh' | sudo -E bash
      sudo apt install symfony-cli
      echo
    )
  fi

elif [ "${PLATFORM_TYPE}" == "Darwin" ]; then
  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Mac - MacOS                           https://symfony.com/doc/current/setup/symfony_server.html#getting-started
  # --------------------------------------------------------------------------------------------------------------------
  # >>>> App - PHP - Symfony CLI
  if [ ! -f /usr/local/bin/symfony ]; then
    (
      cd ~/Downloads || return

      curl -sS https://get.symfony.com/cli/installer | bash
      echo
    )

    sudo mv "${HOME}/.config/.symfony-cli/bin/symfony" /usr/local/bin/symfony

    sudo codesign --force --deep --sign - "$(whereis -q symfony)"
  fi

elif [ "${PLATFORM_TYPE}" == "Windows" ]; then
  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Windows - WSL2
  # --------------------------------------------------------------------------------------------------------------------
  # >>>> App - PHP - Symfony CLI
  if [ ! -f "C:\Program Files\Symfony\symfony.exe" ]; then
    # >>>> Scoop
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
    irm get.scoop.sh | iex
    # >>>> App - PHP - Symfony-CLI
    scoop install symfony-cli
  fi

else
  echo "Please check Operating System"
  setExit
fi
