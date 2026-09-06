#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Deploy - Dev - Linux - Ubuntu - Nginx - Install
# ----------------------------------------------------------------------------------------------------------------------
# >>>> Platform
if [ "${PLATFORM_TYPE}" == "Linux" ]; then
  # >>>> Environment
  if [ "${ENVIRONMENT_NAME}" == "prod" ]; then

    # >>>> Apache2
    if [ -f /etc/apache2/apache2.conf ]; then
      sudo systemctl stop apache2
      sudo systemctl disable apache2
      sudo apt purge -y apache2
      sudo fuser -k 80/tcp
    fi

    if [ -d /var/www/html ]; then
      sudo rm -rf /var/www/html
    fi

    # ------------------------------------------------------------------------------------------------------------------
    # Nginx - Install the packages
    # ------------------------------------------------------------------------------------------------------------------
    # >>>> Nginx
    echo ">>>> Nginx"
    echo

    local NGINX_STATUS
    NGINX_STATUS=$(dpkg -l | grep -i "nginx" | awk '{print $2}' | cut -d ':' -f1 | awk "/^nginx$/")
    if [ "${NGINX_STATUS}" != "nginx" ]; then
      sudo apt install -y nginx
      echo

      sudo systemctl enable nginx
      echo
    fi

    # ------------------------------------------------------------------------------------------------------------------
    # Nginx - Update the configuration
    # ------------------------------------------------------------------------------------------------------------------
    echo ">>>> Nginx - Configuration"
    echo

    # >>>> Nginx - Configuration
    sudo rm -f /etc/nginx/*.default

    if [ -f /etc/nginx/nginx.conf ]; then
      sudo cp -fv "${PROJECT_PATH}"/scripts/base/server/nginx/nginx.conf /etc/nginx/nginx.conf
    fi

    # >>>> Nginx - Project
    PROJECT_NAME=$(basename "$(realpath "${PROJECT_PATH}")")
    if [ -f /etc/nginx/conf.d/symfony.conf ]; then
      sudo rm -f /etc/nginx/conf.d/symfony.conf
    fi
    sudo cp -fv "${PROJECT_PATH}"/scripts/base/server/nginx/conf.d/symfony.conf /etc/nginx/conf.d/symfony.conf

    if [ -d /etc/nginx/sites-available ]; then
      sudo rm -fv /etc/nginx/sites-available/*
    fi

    if [ -d /etc/nginx/sites-enabled ]; then
      sudo rm -fv /etc/nginx/sites-enabled/*
    fi

    # >>>> Nginx - Create log files
    if [ ! -f /var/log/nginx/www_access.log ]; then
      sudo cat /dev/null > /var/log/nginx/www_access.log
    else
      if [ -f /var/log/nginx/www_access.log.1 ]; then
        sudo rm -fv /var/log/nginx/www_access.log.*
        echo
      fi

      sudo chmod 777 /var/log/nginx/www_access.log
    fi

    if [ ! -f /var/log/nginx/www_error.log ]; then
      sudo cat /dev/null > /var/log/nginx/www_error.log
    else
      if [ -f /var/log/nginx/www_error.log.1 ]; then
        sudo rm -fv /var/log/nginx/www_error.log.*
        echo
      fi

      sudo chmod 777 /var/log/nginx/www_error.log
    fi
    echo

    # >>>> Nginx - Update permissions
    sudo chown -R root:root /etc/nginx
    sudo chown -R root:root /var/log/nginx
    sudo chmod -R 755 /var/log/nginx
    echo

    # >>>> Nginx - Symfony - Setting up or Fixing File Permissions - https://symfony.com/doc/current/setup/file_permissions.html
    # Not pgrep: this is the form published in the Symfony doc linked above, and it needs the
    # user column, which pgrep does not report.
    # shellcheck disable=SC2009
    HTTPDUSER="$(ps axo user,comm | grep -E '[a]pache|[h]ttpd|[_]www|[w]ww-data|[n]ginx' | grep -v root | head -1 | cut -d\  -f1)"
    sudo usermod -a -G "${HTTPDUSER}" "$(whoami)"

    # --------------------------------------------------------------------------------------------------------------------
    # Nginx - Check status
    # --------------------------------------------------------------------------------------------------------------------
    echo ">>>> Nginx - Status"
    echo

    local NGINX_STATUS
    NGINX_STATUS=$(systemctl is-active nginx)
    if [ "${NGINX_STATUS}" != "active" ]; then
      sudo systemctl start nginx
      echo
    fi

    sudo nginx -v
    echo

    sudo nginx -t
    echo

  fi

elif [ "${PLATFORM_TYPE}" == "Darwin" ]; then
  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Mac - MacOS
  # --------------------------------------------------------------------------------------------------------------------
  # >>>> Environment
  if [ "${ENVIRONMENT_NAME}" == "dev" ]; then
    # >>>> Nginx
    echo ">>>> Nginx"
    echo
  fi
  echo

elif [ "${PLATFORM_TYPE}" == "Windows" ]; then
  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Windows - WSL2
  # --------------------------------------------------------------------------------------------------------------------
  # >>>> Environment
  if [ "${ENVIRONMENT_NAME}" == "dev" ]; then
    # >>>> Nginx
    echo ">>>> Nginx"
    echo
  fi
  echo

else
  echo "Please check Operating System"
  setExit
fi

