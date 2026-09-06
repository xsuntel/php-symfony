#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Base - App - Symfony Framework - Deployment                  https://symfony.com/doc/current/deployment.html
# ----------------------------------------------------------------------------------------------------------------------

# >>>> App
if [ -d app ]; then
  (
    cd app || return
    if [ -f bin/console ]; then

      # ----------------------------------------------------------------------------------------------------------------
      # A) Check Requirements
      # ----------------------------------------------------------------------------------------------------------------
      echo ">>>> PHP - Symfony Framework - Deployment - A) Check Requirements"
      echo

      if [ "${ENVIRONMENT_NAME}" == "prod" ]; then
        echo "Prod Environment"
        echo

        APP_ENV=prod APP_DEBUG=0 composer require symfony/requirements-checker

      elif [ "${ENVIRONMENT_NAME}" == "dev" ]; then
        echo "Dev Environment"
      else
        echo "Test Environment"
      fi
      echo

      # ----------------------------------------------------------------------------------------------------------------
      # B) Configure your Environment Variables
      # ----------------------------------------------------------------------------------------------------------------
      echo ">>>> PHP - Symfony Framework - Deployment - B) Configure your Environment Variables"
      echo

      # >>>> PHP - Symfony Framework - .env files
      if [ "${ENVIRONMENT_NAME}" == "prod" ]; then
        ls -ltr .env.prod*
        echo

        APP_ENV=prod APP_DEBUG=0 composer dump-env prod
        echo

      elif [ "${ENVIRONMENT_NAME}" == "dev" ]; then
        ls -ltr .env.dev*
        echo

        # >>>> Performance - Optimize Composer Autoloader               https://symfony.com/doc/current/performance.html
        APP_ENV=prod APP_DEBUG=0 composer dump-autoload --no-dev --classmap-authoritative
        echo

      else
        ls -ltr .env.*
      fi
      echo

      # ----------------------------------------------------------------------------------------------------------------
      # C) Install/Update your Vendors
      # ----------------------------------------------------------------------------------------------------------------
      echo ">>>> PHP - Symfony Framework - Deployment - C) Install/Update your Vendors"
      echo

      if [ "${ENVIRONMENT_NAME}" == "prod" ]; then
        APP_ENV=prod APP_DEBUG=0 composer install --no-dev --optimize-autoloader
      else
        APP_ENV=dev  APP_DEBUG=1 composer install --ignore-platform-req=ext-redis --ignore-platform-req=ext-amqp --ignore-platform-req=ext-pdo_pgsql
      fi
      echo

      # ----------------------------------------------------------------------------------------------------------------
      # D) Clear your Symfony Cache
      # ----------------------------------------------------------------------------------------------------------------
      echo ">>>> PHP - Symfony Framework - Deployment - D) Clear your Symfony Cache"
      echo

      # >>>> PHP - Symfony Framework - Clear cache
      if [ -d var/cache ]; then
        if [ "${PLATFORM_TYPE}" == "Linux" ]; then
          if [ "${ENVIRONMENT_NAME}" == "prod" ]; then
            sudo rm -rf var/cache/*
          else
            rm -rf var/cache/*
          fi
        else
          rm -rf var/cache/*
        fi
      else
        mkdir -p var/cache
      fi

      if [ -d var/log ]; then
        if [ "${PLATFORM_TYPE}" == "Linux" ]; then
          if [ "${ENVIRONMENT_NAME}" == "prod" ]; then
            sudo rm -rf var/log/*
          else
            rm -rf var/log/*
          fi
        else
          rm -rf var/log/*
        fi
      else
        mkdir -p var/log
      fi

      if [ -d var/sessions ]; then
        if [ "${PLATFORM_TYPE}" == "Linux" ]; then
          if [ "${ENVIRONMENT_NAME}" == "prod" ]; then
            sudo rm -rf var/sessions/*
          else
            rm -rf var/sessions/*
          fi
        else
          rm -rf var/sessions/*
        fi
      else
        mkdir -p var/sessions
      fi

      # >>>> PHP - Symfony Framework - Clear cache
      if [ "${ENVIRONMENT_NAME}" == "prod" ]; then
        APP_ENV=prod APP_DEBUG=0 php bin/console cache:clear --no-warmup --no-optional-warmers
      else
        APP_ENV=dev  APP_DEBUG=1 php bin/console cache:clear
      fi
      echo

      if [ "${PLATFORM_TYPE}" == "Linux" ]; then
        chown -R "${LOGNAME}:${LOGNAME}" ./*
        if [ -d var ]; then
          chmod 775 -R ./var
        fi
      fi

    else
      echo "[ ERROR ] There is not a command : app/bin/console"
      setExit
    fi
  )
fi
