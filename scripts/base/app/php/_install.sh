#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Deploy - Dev - Linux - Ubuntu - PHP - Install
# ----------------------------------------------------------------------------------------------------------------------
# >>>> Platform
if [ "${PLATFORM_TYPE}" == "Linux" ]; then

    # ------------------------------------------------------------------------------------------------------------------
    # PHP - Check Repository
    # ------------------------------------------------------------------------------------------------------------------

    # >>>> PHP - Check Repository
    echo ">>>> PHP - Check Repository"
    echo

    local APT_SW_INFO="software-properties-common"
    APT_SOFTWARE_PROPERTIES_COMMON_INFO=$(dpkg -l | grep -i "software-properties-common" | awk '{print $2}' | cut -d ':' -f1 | awk "/^software-properties-common$/")
    if [ "${APT_SOFTWARE_PROPERTIES_COMMON_INFO}" != "software-properties-common" ]; then
      sudo apt install -y ca-certificates apt-transport-https software-properties-common
      echo
    fi

    local UBUNTU_MAJOR_RELEASE
    UBUNTU_MAJOR_RELEASE=$(grep -i 'DISTRIB_RELEASE' /etc/lsb-release | cut -d "=" -f2 | cut -c 1-2)
    if [ "${UBUNTU_MAJOR_RELEASE}" -lt 26 ]; then
      PPA_STRING="ondrej"
      if grep -rqs "$PPA_STRING" /etc/apt/sources.list /etc/apt/sources.list.d/ubuntu.sources /etc/apt/sources.list.d/; then
          echo "✅ '$PPA_STRING' It has been already registered"

      else
          echo "⚠️ '$PPA_STRING' Installing"
          echo

          LC_ALL=C.UTF-8 sudo add-apt-repository -y ppa:ondrej/php
          sudo apt-get update -y
      fi
      echo
    else
      echo ">>>> This Linux is Ubuntu ${UBUNTU_MAJOR_RELEASE}"
    fi

    # ------------------------------------------------------------------------------------------------------------------
    # PHP - Install the packages
    # ------------------------------------------------------------------------------------------------------------------

    # >>>> Environment
    if [ "${ENVIRONMENT_NAME}" == "prod" ]; then

        # >>>> PHP-FPM
        echo ">>>> PHP-FPM - Install packages"
        echo

        local PHP_FPM_STATUS
        PHP_FPM_STATUS=$(dpkg -l | grep -i "php${PHP_VERSION}-fpm" | awk '{print $2}' | cut -d ':' -f1 | awk "/^php${PHP_VERSION}-fpm$/")
        if [ "${PHP_FPM_STATUS}" != "php${PHP_VERSION}-fpm" ]; then
            (
            cd /tmp || return

            # >>>> PHP-FPM - required packages
            local addPackageList="php${PHP_VERSION}-common php${PHP_VERSION}-cli php${PHP_VERSION}-curl php${PHP_VERSION}-fpm php${PHP_VERSION}-gd php${PHP_VERSION}-mbstring php${PHP_VERSION}-intl php${PHP_VERSION}-uuid php${PHP_VERSION}-xml php${PHP_VERSION}-zip php${PHP_VERSION}-bcmath"
            for pkgItem in ${addPackageList}; do
                local APT_PKG_INFO
                APT_PKG_INFO=$(dpkg -l | grep -i "${pkgItem}" | awk '{print $2}' | cut -d ':' -f1 | awk "/^${pkgItem}$/")
                if [ "${APT_PKG_INFO}" != "${pkgItem}" ]; then
                    sudo apt install -y "${pkgItem}"
                    echo
                fi
            done
            echo

            # >>>> PHP-FPM - additional packages
            local addPackageList="php${PHP_VERSION}-redis php${PHP_VERSION}-pgsql php${PHP_VERSION}-amqp"
            for pkgItem in ${addPackageList}; do
                local APT_PKG_INFO
                APT_PKG_INFO=$(dpkg -l | grep -i "${pkgItem}" | awk '{print $2}' | cut -d ':' -f1 | awk "/^${pkgItem}$/")
                if [ "${APT_PKG_INFO}" != "${pkgItem}" ]; then
                    sudo apt install -y "${pkgItem}"
                    echo
                fi
            done
            echo

            # >>>> PHP-FPM - configuration
            sudo systemctl enable "php${PHP_VERSION}-fpm"
            echo
            )
        fi

    else

        # >>>> PHP - required packages
        local addPackageList="php${PHP_VERSION}-common php${PHP_VERSION}-cli php${PHP_VERSION}-curl php${PHP_VERSION}-fpm php${PHP_VERSION}-gd php${PHP_VERSION}-mbstring php${PHP_VERSION}-intl php${PHP_VERSION}-uuid php${PHP_VERSION}-xml php${PHP_VERSION}-zip php${PHP_VERSION}-bcmath"
        for pkgItem in ${addPackageList}; do
            local APT_PKG_INFO
            APT_PKG_INFO=$(dpkg -l | grep -i "${pkgItem}" | awk '{print $2}' | cut -d ':' -f1 | awk "/^${pkgItem}$/")
            if [ "${APT_PKG_INFO}" != "${pkgItem}" ]; then
                sudo apt install -y "${pkgItem}"
                echo
            fi
        done
        echo

        # >>>> PHP - additional packages
        local addPackageList="php${PHP_VERSION}-redis php${PHP_VERSION}-pgsql php${PHP_VERSION}-amqp"
        for pkgItem in ${addPackageList}; do
            local APT_PKG_INFO
            APT_PKG_INFO=$(dpkg -l | grep -i "${pkgItem}" | awk '{print $2}' | cut -d ':' -f1 | awk "/^${pkgItem}$/")
            if [ "${APT_PKG_INFO}" != "${pkgItem}" ]; then
                sudo apt install -y "${pkgItem}"
                echo
            fi
        done
        echo

        # >>>> PHP - options packages
        local addPackageList="php${PHP_VERSION}-xdebug"
        for pkgItem in ${addPackageList}; do
            local APT_PKG_INFO
            APT_PKG_INFO=$(dpkg -l | grep -i "${pkgItem}" | awk '{print $2}' | cut -d ':' -f1 | awk "/^${pkgItem}$/")
            if [ "${APT_PKG_INFO}" != "${pkgItem}" ]; then
                sudo apt install -y "${pkgItem}"
                echo
            fi
        done
        echo
    fi

    # ------------------------------------------------------------------------------------------------------------------
    # PHP - Update the configuration
    # ------------------------------------------------------------------------------------------------------------------

    # >>>> Environment
    if [ "${ENVIRONMENT_NAME}" == "prod" ]; then

        # >>>> PHP-FPM - Update configurations
        echo ">>>> PHP-FPM - Update configurations"
        echo

        if [ -d "${PROJECT_PATH}/scripts/base/app/php/${PHP_VERSION}" ]; then
            # >>>> PHP-FPM - php.ini
            if [ -f "/etc/php/${PHP_VERSION}/fpm/php.ini" ]; then
                sudo cp -fv "${PROJECT_PATH}/scripts/base/app/php/${PHP_VERSION}/fpm/php.ini" "/etc/php/${PHP_VERSION}/fpm/php.ini"
            fi

            # >>>> PHP-FPM - php-fpm.conf
            if [ -f "/etc/php/${PHP_VERSION}/fpm/php-fpm.conf" ]; then
                sudo cp -fv "${PROJECT_PATH}/scripts/base/app/php/${PHP_VERSION}/fpm/php-fpm.conf" "/etc/php/${PHP_VERSION}/fpm/php-fpm.conf"
            fi

            # >>>> PHP-FPM - pool.d/www.conf
            if [ -f "/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf" ]; then
                sudo cp -fv "${PROJECT_PATH}/scripts/base/app/php/${PHP_VERSION}/fpm/pool.d/www.conf" "/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf"
            fi

            # >>>> PHP-FPM - conf.d/10-opcache.ini
            if [ -f "/etc/php/${PHP_VERSION}/fpm/conf.d/10-opcache.ini" ]; then
                sudo cp -fv "${PROJECT_PATH}/scripts/base/app/php/${PHP_VERSION}/fpm/conf.d/10-opcache.ini" "/etc/php/${PHP_VERSION}/fpm/conf.d/10-opcache.ini"
            fi

        else
            echo "There is not the folder: ${PROJECT_PATH}"
            echo
        fi

        sudo systemctl restart "php${PHP_VERSION}-fpm"

    else

        # >>>> PHP - Update configurations
        echo ">>>> PHP - Update configurations"
        echo

        if [ -d "${PROJECT_PATH}/scripts/base/app/php/${PHP_VERSION}" ]; then
            # >>>> PHP - php.ini
            if [ -f "/etc/php/${PHP_VERSION}/cli/php.ini" ]; then
                sudo cp -fv "${PROJECT_PATH}/scripts/base/app/php/${PHP_VERSION}/cli/php.ini" "/etc/php/${PHP_VERSION}/cli/php.ini"
            fi

            # >>>> PHP - conf.d/20-xdebug.ini
            if [ -f "/etc/php/${PHP_VERSION}/cli/conf.d/20-xdebug.ini" ]; then
                sudo cp -fv "${PROJECT_PATH}/scripts/base/app/php/${PHP_VERSION}/cli/conf.d/20-xdebug.ini" "/etc/php/${PHP_VERSION}/cli/conf.d/20-xdebug.ini"
            fi
        else
            echo "There is not the folder: ${PROJECT_PATH}"
            echo
        fi

    fi

  # --------------------------------------------------------------------------------------------------------------------
  # PHP - Composer
  # --------------------------------------------------------------------------------------------------------------------
  echo ">>>> PHP - Composer"
  echo
  if [ -f /usr/local/bin/composer ]; then
    echo "Composer  : $(composer --version)"
  else
    (
      cd /tmp || return

      echo "    * Install composer"
      export COMPOSER_ALLOW_SUPERUSER=1
      curl -sS https://getcomposer.org/installer -o composer-setup.php
      sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
      sudo ln -s /usr/local/bin/composer /usr/bin/composer
      sudo rm -fv composer-setup.php
      echo

      echo "Composer  : $(composer --version)"
    )
  fi
  echo

  php -v
  echo

elif [ "${PLATFORM_TYPE}" == "Darwin" ]; then
  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Mac - MacOS
  # --------------------------------------------------------------------------------------------------------------------
  # >>>> Environment


  # --------------------------------------------------------------------------------------------------------------------
  # PHP - Install the packages
  # --------------------------------------------------------------------------------------------------------------------
  # >>>> PHP
  echo ">>>> PHP"

  local PHP_PKG
  PHP_PKG=$(brew list | grep php)
  if [ "${PHP_PKG}" ]; then
    local CURRENT_PHP_VERSION
    CURRENT_PHP_VERSION=$(php --version | head -n 1 | cut -d " " -f 2 | cut -c 1-3)
  else
    brew install "php@${PHP_VERSION}"
    echo
  fi

  echo
  echo "extension-dir : $(php-config --extension-dir)"
  echo

  # >>>> PHP - Extension
  local PHP_XDEBUG
  PHP_XDEBUG=$(pecl list | awk '/xdebug/ {print $0}' | cut -c 1-6)
  if [ "${PHP_XDEBUG}" ]; then
    pecl list | grep -i xdebug
  else
    export LC_CTYPE=en_US.UTF-8
    export LC_ALL=en_US.UTF-8

    pecl install xdebug
  fi
  echo

  # --------------------------------------------------------------------------------------------------------------------
  # PHP - Update the configuration
  # --------------------------------------------------------------------------------------------------------------------

    # >>>> Environment
    if [ "${ENVIRONMENT_NAME}" == "prod" ]; then

        # >>>> PHP-FPM - Update configurations
        echo ">>>> PHP-FPM - Update configurations"
        echo

        if [ -d "${PROJECT_PATH}/scripts/base/app/php/${PHP_VERSION}" ]; then
            # >>>> PHP-FPM - php.ini
            if [ -f "/etc/php/${PHP_VERSION}/fpm/php.ini" ]; then
                sudo cp -fv "${PROJECT_PATH}/scripts/base/app/php/${PHP_VERSION}/fpm/php.ini" "/opt/homebrew/etc/php/${PHP_VERSION}/fpm/php.ini"
            fi

        else
            echo "There is not the folder: ${PROJECT_PATH}"
            echo
        fi

    else

        # >>>> PHP - Update configurations
        echo ">>>> PHP - Update configurations"
        echo

        if [ -d "${PROJECT_PATH}/scripts/base/app/php/${PHP_VERSION}" ]; then
            # >>>> PHP - php.ini
            if [ -f "/etc/php/${PHP_VERSION}/cli/php.ini" ]; then
                sudo cp -fv "${PROJECT_PATH}/scripts/base/app/php/${PHP_VERSION}/cli/php.ini" "/opt/homebrew/etc/php/${PHP_VERSION}/php.ini"
            fi

            # >>>> PHP - conf.d/20-xdebug.ini
            if [ -f "/etc/php/${PHP_VERSION}/cli/conf.d/20-xdebug.ini" ]; then
                sudo cp -fv "${PROJECT_PATH}/scripts/base/app/php/${PHP_VERSION}/cli/conf.d/20-xdebug.ini" "/opt/homebrew/etc/php/${PHP_VERSION}/conf.d/20-xdebug.ini"
            fi
        else
            echo "There is not the folder: ${PROJECT_PATH}"
            echo
        fi

    fi



  # --------------------------------------------------------------------------------------------------------------------
  # PHP - Composer
  # --------------------------------------------------------------------------------------------------------------------
  local PHP_COMPOSER
  PHP_COMPOSER=$(brew list | grep composer)
  if [ "${PHP_COMPOSER}" ]; then
    echo "Composer  : $(composer --version)"
  else
    brew install composer
  fi
  echo

  php --version
  echo

  php --ini
  echo

  # --------------------------------------------------------------------------------------------------------------------
  # Symfony - Front-End
  # --------------------------------------------------------------------------------------------------------------------
  # >>>> Node
  local NODE_PKG
  NODE_PKG=$(brew list | grep "node@${NODE_VERSION}")
  if [ ! -f "/opt/homebrew/opt/node@${NODE_VERSION}/bin/node" ]; then
    (
      cd /tmp || return

      brew install "node@${NODE_VERSION}"
      echo

      brew unlink "node@${NODE_VERSION}" && brew link "node@${NODE_VERSION}"
      echo

      brew install yarn
      echo

      brew unlink yarn && brew link yarn
      echo
    )
  fi

elif [ "${PLATFORM_TYPE}" == "Windows" ]; then
  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Windows - WSL2
  # --------------------------------------------------------------------------------------------------------------------
  # >>>> Environment
  if [ "${ENVIRONMENT_NAME}" == "dev" ]; then
    # >>>> PHP
    echo ">>>> PHP"
    echo
  fi
  echo

else
  echo "Please check Operating System"
  setExit
fi

