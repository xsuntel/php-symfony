#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Deploy - Prod - GCP (Google Cloud Platform) - CLI
# ----------------------------------------------------------------------------------------------------------------------

echo ">>>> GCP - CLI"
echo

# >>>> Platform
if [ "${PLATFORM_TYPE}" == "Linux" ]; then
  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Linux
  # --------------------------------------------------------------------------------------------------------------------

  # >>>> Install packages
  local addPackageList="apt-transport-https ca-certificates gnupg curl"
  for pkgItem in ${addPackageList}; do
    local APT_PKG_INFO
    APT_PKG_INFO=$(dpkg -l | grep -i "${pkgItem}" | awk '{print $2}' | cut -d ':' -f1 | awk "/^${pkgItem}$/")
    if [ "${APT_PKG_INFO}" != "${pkgItem}" ]; then
      sudo apt install -y "${pkgItem}"
      echo
    fi
  done

  if [ ! -f /usr/share/keyrings/cloud.google.gpg ]; then
    # >>>> Install public key
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
  fi

  if [ ! -f /etc/apt/sources.list.d/google-cloud-sdk.list ]; then

    # >>>> Install public key
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

    # >>>> Install google-cloud-cli
    sudo apt update -y
    sudo apt install -y google-cloud-cli

  fi

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

  # >>>> GCP - CLI


elif [ "${PLATFORM_TYPE}" == "Windows" ]; then
  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Windows - WSL2
  # --------------------------------------------------------------------------------------------------------------------
  # >>>> Python

  # >>>> GCP - CLI
  #(New-Object Net.WebClient).DownloadFile("https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe", "$env:Temp\GoogleCloudSDKInstaller.exe") & $env:Temp\GoogleCloudSDKInstaller.exe
  echo

else
  echo "Please check Operating System"
  setExit
fi
