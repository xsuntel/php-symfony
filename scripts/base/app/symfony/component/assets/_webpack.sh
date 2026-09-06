#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Base - App - Symfony Framework - Deployment - Other Things   https://symfony.com/doc/current/deployment.html
# ----------------------------------------------------------------------------------------------------------------------

# >>>> App
if [ -d app ]; then
  (
    cd app || return
    if [ -f bin/console ]; then

      # ----------------------------------------------------------------------------------------------------------------
      # H) Other Things - Webpack Encore or AssetMapper
      # ----------------------------------------------------------------------------------------------------------------
      echo ">>>> PHP - Symfony Framework - Deployment - H) Other Things - Webpack Encore or AssetMapper"
      echo

      # >>>> NPM : Create package.json
      if [ ! -f package.lock ]; then
        npm install
        npx update-browserslist-db@latest

        npm init -y
        echo
      fi

      # >>>> Compile your assets if you're using the AssetMapper component

      # >>>> TailwindBundle                                https://symfony.com/bundles/TailwindBundle/current/index.html
      #if [ "${ENVIRONMENT_NAME}" == "prod" ]; then
      #  echo '--> TailwindBundle : Building'
      #  echo
      #  symfony console tailwind:build --minify
      #  echo

      #else

      #  echo '--> NPM : Update browserslist-db'
      #  echo

      # >>>> NPM : Update browserslist-db
      #  npx -y update-browserslist-db@latest
      #  echo

      #  echo '--> TailwindBundle : Building'
      #  echo

      #  echo
      #  symfony console tailwind:build -v
      #  echo

      #fi
      #  echo '--> Webpack : Compiling'
      #  echo


    else
      echo "[ ERROR ] There is not a command : app/bin/console"
      setExit
    fi
  )
fi
