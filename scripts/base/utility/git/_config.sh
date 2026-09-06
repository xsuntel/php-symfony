#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Base - Tools - Git
# ----------------------------------------------------------------------------------------------------------------------

# >>>> Platform
if [ "${PLATFORM_TYPE}" == "Linux" ]; then
  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Linux - Ubuntu
  # --------------------------------------------------------------------------------------------------------------------

  # >>>> Git - Global - Config
  git config --global core.autocrlf input

  # >>>> Git - Local - Config
  if [ -d .git ]; then
    git config --local core.autocrlf input
  fi

elif [ "${PLATFORM_TYPE}" == "Darwin" ]; then
  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Mac - MacOS
  # --------------------------------------------------------------------------------------------------------------------

  # >>>> Git - Global - Config
  git config --global core.autocrlf input

  # >>>> Git - Local - Config
  if [ -d .git ]; then
    git config --local core.autocrlf input
  fi


elif [ "${PLATFORM_TYPE}" == "Windows" ]; then
  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Windows - WSL2
  # --------------------------------------------------------------------------------------------------------------------

  # >>>> Git - Global - Config
  git config --global core.autocrlf true

  # >>>> Git - Local - Config
  if [ -d .git ]; then
    git config --local core.autocrlf true
  fi

else
  echo "Please check Operating System"
  setExit
fi

# >>>> Git - Global - Config
echo ">>>> Git - Global"
echo

git config --global --list
echo

# >>>> Git - Local - Config

echo ">>>> Git - Local"
echo

local GIT_SAFE_DIRECTORY
GIT_SAFE_DIRECTORY=$(git config --local --list | grep -i "${PROJECT_PATH}")
if [ ! "${GIT_SAFE_DIRECTORY}" ]; then
  git config --local --add safe.directory "${PROJECT_PATH}"
fi

git config --local core.editor vi
git config --local color.ui true
git config --local diff.ui auto
git config --local format.pretty oneline
git config --local pull.rebase true
git config --local push.default simple

git config --local --list
echo
