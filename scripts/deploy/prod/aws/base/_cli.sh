#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Deploy - Prod - AWS - CLI
# ----------------------------------------------------------------------------------------------------------------------

echo ">>>> AWS - CLI"
echo

# >>>> Platform                      https://docs.aws.amazon.com/ko_kr/cli/latest/userguide/getting-started-install.html
if [ "${PLATFORM_TYPE}" == "Linux" ]; then
  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Linux
  # --------------------------------------------------------------------------------------------------------------------

  # >>>> Python
  local addPackageList="python3-pip awscli"
  for pkgItem in ${addPackageList}; do
    local APT_PKG_INFO
    APT_PKG_INFO=$(dpkg -l | grep -i "${pkgItem}" | awk '{print $2}' | cut -d ':' -f1 | awk "/^${pkgItem}$/")
    if [ "${APT_PKG_INFO}" != "${pkgItem}" ]; then
      sudo apt install -y "${pkgItem}"
      echo
    fi
  done

  # >>>> AWS - CLI

  # >>>> AWS - Keyscripts/deploy/prod/aws/base/_s3.sh

elif [ "${PLATFORM_TYPE}" == "Darwin" ]; then
  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Mac - MacOS
  # --------------------------------------------------------------------------------------------------------------------

  # >>>> Python
  local PYTHON_PKG
  PYTHON_PKG=$(brew list | grep python)
  if [ "${PYTHON_PKG}" ]; then
    echo "Python has been installed"
  else
    brew install python
  fi
  echo

  # >>>> AWS - CLI
  local AWS_CLI
  AWS_CLI=$(which aws)
  if [ "${AWS_CLI}" == "/usr/local/bin/aws" ]; then
    echo aws --version
  else
    (
      if [ -d ~/Downloads ]; then
        cd ~/Downloads || return

        curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
        sudo installer -pkg AWSCLIV2.pkg -target /
      fi
    )
  fi

  # >>>> AWS - Key for Remote EC2
  if [ -f "${HOME}/aws/aws-key/metacoding-aws-key.cer" ]; then
    sudo chmod 700 "${HOME}/aws/aws-key/metacoding-aws-key.cer"
  fi

elif [ "${PLATFORM_TYPE}" == "Windows" ]; then
  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Windows - WSL2
  # --------------------------------------------------------------------------------------------------------------------

  # >>>> Python

  # >>>> AWS - CLI

  # >>>> AWS - Key

  echo - n
else
  echo "Please check Operating System"
  setExit
fi

aws configure list
echo
