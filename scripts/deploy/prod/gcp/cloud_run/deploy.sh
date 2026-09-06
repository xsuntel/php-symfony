#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Deploy - Prod - GCP (Google Cloud Platform) - Code Run
# ----------------------------------------------------------------------------------------------------------------------

find_project_root() {
    local PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    while [[ "${PROJECT_DIR}" != "/" ]]; do
        if [[ -d "${PROJECT_DIR}/.git" ]] || [[ -f "${PROJECT_DIR}/.env.app" ]]; then
            echo "${PROJECT_DIR}"
            return 0
        fi
        PROJECT_DIR="$(dirname "${PROJECT_DIR}")"
    done
    return 1
}

PROJECT_PATH=$(find_project_root)
PROJECT_NAME=$(basename "$(realpath "${PROJECT_PATH}")")
cd "${PROJECT_PATH}" || exit

# ----------------------------------------------------------------------------------------------------------------------
# Abstract
# ----------------------------------------------------------------------------------------------------------------------

if [ -f "${PROJECT_PATH}/scripts/base/_abstract.sh" ]; then
  source "${PROJECT_PATH}/scripts/base/_abstract.sh"
else
  echo "Please check a file : ./scripts/base/_abstract.sh" && exit
fi

# >>>> Environment

setEnvironment() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ENV ] ${PLATFORM_TYPE} - ${PLATFORM_PROCESSOR}"
  echo -e "----------------------------------------------------------------------------------------------------------\n"
  # >>>> Select one of some environments
  PS3="Menu: "
  select num in "prod" "exit"; do
    case "$REPLY" in
    1)
      # >>>> Prod Environment
      ENVIRONMENT_NAME="prod"
      break
      ;;
    2)
      echo "exit()"
      setEnd
      ;;
    *)
      echo "[ ERROR ] Unknown Command"
      setEnd
      ;;
    esac
  done
  echo
}

# >>>> Platform

setPlatform() {
  echo "---------------------------------------------------------------------------------------------------------------"
  echo "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Platform "
  echo "---------------------------------------------------------------------------------------------------------------"
  echo

  # >>>> Base
  if [ -f "${PROJECT_PATH}/scripts/base/_platform.sh" ]; then
    source "${PROJECT_PATH}/scripts/base/_platform.sh"
  else
    echo "Please check a file : ./scripts/base/_platform.sh" && exit
  fi
}

# >>>> Project

setProject() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Project : ${PROJECT_NAME}"
  echo -e "----------------------------------------------------------------------------------------------------------\n"

  # >>>> Directory
  if [ -f "${PROJECT_PATH}/scripts/base/_project.sh" ]; then
    source "${PROJECT_PATH}/scripts/base/_project.sh"
  else
    echo "Please check a file : ./scripts/base/_project.sh" && exit
  fi
}

# ----------------------------------------------------------------------------------------------------------------------
# Architecture
# ----------------------------------------------------------------------------------------------------------------------

# >>>> App

setPhp() {
  echo "---------------------------------------------------------------------------------------------------------------"
  echo "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Base - App - Packages"
  echo "---------------------------------------------------------------------------------------------------------------"
}

# >>>> Cache

setRedis() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Base - Cache - Packages"
  echo -e  "---------------------------------------------------------------------------------------------------------\n"
}

# >>>> Database

setPostgreSQL() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Base - Database - Packages"
  echo -e "----------------------------------------------------------------------------------------------------------\n"
}

# >>>> Message

setRabbitMQ() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Base - Message - Packages"
  echo -e "----------------------------------------------------------------------------------------------------------\n"
  echo
}

# >>>> Server

setNginx() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Base - Server - Packages"
  echo -e "----------------------------------------------------------------------------------------------------------\n"
}

# ----------------------------------------------------------------------------------------------------------------------
# Build Scripts
# ----------------------------------------------------------------------------------------------------------------------

setBuild() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Build"
  echo -e "----------------------------------------------------------------------------------------------------------\n"

  # >>>> PHP - Symfony Framework - Deployment
  if [ -f "${PROJECT_PATH}/scripts/base/app/symfony/config/_deployment.sh" ]; then
    source "${PROJECT_PATH}/scripts/base/app/symfony/config/_deployment.sh"
  else
    echo "Please check a file : ./scripts/base/app/symfony/config/_deployment.sh" && exit
  fi
  echo

  # >>>> PHP - Symfony Framework - Deployment - Back-End  - Permissions - (Optional)


  # >>>> PHP - Symfony Framework - Deployment - Back-End  - Database    - (Optional)
  #if [ -f "${PROJECT_PATH}"/scripts/base/app/symfony/common/_database.sh ]; then
  #  source "${PROJECT_PATH}"/scripts/base/app/symfony/common/_database.sh
  #else
  #  echo "Please check a file : ./scripts/base/app/symfony/common/_database.sh" && exit
  #fi
  #echo

  # >>>> PHP - Symfony Framework - Deployment - Back-End  - Cron jobs   - (Optional)
  #if [ -f "${PROJECT_PATH}"/scripts/base/app/symfony/common/_cron.sh ]; then
  #  source "${PROJECT_PATH}"/scripts/base/app/symfony/common/_cron.sh
  #else
  #  echo "Please check a file : ./scripts/base/app/symfony/common/_cron.sh" && exit
  #fi
  #echo

  # >>>> PHP - Symfony Framework - Deployment - Back-End  - Messenger   - (Optional)


  # >>>> PHP - Symfony Framework - Deployment - Front-End - AssetMapper - (Optional) OR Webpack Encore
  #if [ -f "${PROJECT_PATH}/scripts/base/app/symfony/component/assets/_assetmapper.sh" ]; then
  #  source "${PROJECT_PATH}/scripts/base/app/symfony/component/assets/_assetmapper.sh"
  #else
  #  echo "Please check a file : ./scripts/base/app/symfony/component/assets/_assetmapper.sh" && exit
  #fi
  #echo

  #if [ -f "${PROJECT_PATH}"/scripts/base/app/symfony/component/assets/_webpack.sh ]; then
  #  source "${PROJECT_PATH}"/scripts/base/app/symfony/component/assets/_webpack.sh
  #else
  #  echo "Please check a file : ./scripts/base/app/symfony/component/assets/_webpack.sh" && exit
  #fi
  #echo
}

# ----------------------------------------------------------------------------------------------------------------------
# Docker - Containers
# ----------------------------------------------------------------------------------------------------------------------

setDocker() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Docker - Containers"
  echo -e "----------------------------------------------------------------------------------------------------------\n"

  echo ">>>> Docker - Dockerfile"
  echo

  if [ -f "${PROJECT_PATH}/scripts/containers/prod/Dockerfile" ]; then
    cp -fv "${PROJECT_PATH}/scripts/containers/prod/Dockerfile" "${PROJECT_PATH}"
    echo
  fi

  echo ">>>> Docker - Build"
  echo

  DOCKERFILE_TAG_NAME=$(date +%Y.%m.%d)

  docker build --network=host -t "${DOCKERFILE_IMAGE_NAME}:${DOCKERFILE_TAG_NAME}" ./ --no-cache
  echo

  echo ">>>> Docker - Tag"
  echo

  docker image tag "${DOCKERFILE_IMAGE_NAME}:${DOCKERFILE_TAG_NAME}" "${GCLOUD_ARTIFACTS_DOCKER_LOCATION}-docker.pkg.dev/${GCLOUD_PROJECT_ID}/${GCLOUD_ARTIFACTS_DOCKER_REPOSITORY_NAME}/${GCLOUD_ARTIFACTS_DOCKER_IMAGE_NAME}:latest"
  echo

  docker rmi "${DOCKERFILE_IMAGE_NAME}:${DOCKERFILE_TAG_NAME}"
  echo
}

# ----------------------------------------------------------------------------------------------------------------------
# Provider ( Cloud Service Providers )
# ----------------------------------------------------------------------------------------------------------------------

setProvider() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Provider ( Cloud Service Providers )"
  echo -e "----------------------------------------------------------------------------------------------------------\n"
  echo

  # >>>> GCP - CLI
  if [ -f "${PROJECT_PATH}/scripts/deploy/prod/gcp/base/_cli.sh" ]; then
    source "${PROJECT_PATH}/scripts/deploy/prod/gcp/base/_cli.sh"
  else
    echo "Please check a file : ./scripts/deploy/prod/gcp/base/_cli.sh" && exit
  fi
  echo

  # >>>> GCP - Cloud Storage
  if [ -f "${PROJECT_PATH}/scripts/deploy/prod/gcp/base/_cloud_storage.sh" ]; then
    source "${PROJECT_PATH}/scripts/deploy/prod/gcp/base/_cloud_storage.sh"
  else
    echo "Please check a file : ./scripts/deploy/prod/gcp/base/_cloud_storage.sh" && exit
  fi
  echo

  echo ">>>> GCP - Artifact Registry - Auth"
  echo

  gcloud auth configure-docker "${GCLOUD_ARTIFACTS_DOCKER_LOCATION}-docker.pkg.dev"
  echo

  echo ">>>> GCP - Artifact Registry - Push"
  echo

  docker push "${GCLOUD_ARTIFACTS_DOCKER_LOCATION}-docker.pkg.dev/${GCLOUD_PROJECT_ID}/${GCLOUD_ARTIFACTS_DOCKER_REPOSITORY_NAME}/${GCLOUD_ARTIFACTS_DOCKER_IMAGE_NAME}:latest"
  echo

  echo ">>>> GCP - Cloud Run - Deploy image"
  echo

  gcloud run deploy "${GCLOUD_RUN_DEPLOY_SERVICE_NAME}" \
    --image "${GCLOUD_ARTIFACTS_DOCKER_LOCATION}-docker.pkg.dev/${GCLOUD_PROJECT_ID}/${GCLOUD_ARTIFACTS_DOCKER_REPOSITORY_NAME}/${GCLOUD_ARTIFACTS_DOCKER_IMAGE_NAME}:latest" \
    --region "${GCLOUD_RUN_DEPLOY_REGION}" \
    --network "${GCLOUD_RUN_DEPLOY_NETWORK}" \
    --subnet "${GCLOUD_RUN_DEPLOY_SUBNET}" \
    --vpc-egress all-traffic
  echo
}

# ----------------------------------------------------------------------------------------------------------------------
# Tools for VM ( Instance )
# ----------------------------------------------------------------------------------------------------------------------

setTools() {
  echo "---------------------------------------------------------------------------------------------------------------"
  echo "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Tools for VM ( Instance )"
  echo "---------------------------------------------------------------------------------------------------------------"


  # >>>> Docker - Process
  echo ">>>> Docker - Process"
  echo
  docker ps -a
  echo

  # >>>> Docker - Images
  echo ">>>> Docker - images"
  echo

  docker image ls
  echo
}

# ----------------------------------------------------------------------------------------------------------------------
# Utility
# ----------------------------------------------------------------------------------------------------------------------

setUtility() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Utility"
  echo -e "----------------------------------------------------------------------------------------------------------\n"
}

# ----------------------------------------------------------------------------------------------------------------------
# START
# ----------------------------------------------------------------------------------------------------------------------

setStart

# ----------------------------------------------------------------------------------------------------------------------
# Abstract
# ----------------------------------------------------------------------------------------------------------------------

# >>>> Environment
setEnvironment

# >>>> Platform
setPlatform

# >>>> Project
setProject

# ----------------------------------------------------------------------------------------------------------------------
# Architecture
# ----------------------------------------------------------------------------------------------------------------------

# >>>> App
#setPhp

# >>>> Cache
#setRedis

# >>>> Database
#setPostgreSQL

# >>>> Message
#setRabbitMQ

# >>>> Server
#setNginx

# ----------------------------------------------------------------------------------------------------------------------
# Build Scripts
# ----------------------------------------------------------------------------------------------------------------------
setBuild

# ----------------------------------------------------------------------------------------------------------------------
# Docker - Containers
# ----------------------------------------------------------------------------------------------------------------------
setDocker

# ----------------------------------------------------------------------------------------------------------------------
# Provider ( Cloud Service Providers )
# ----------------------------------------------------------------------------------------------------------------------
setProvider

# ----------------------------------------------------------------------------------------------------------------------
# Tools for VM ( Instance )
# ----------------------------------------------------------------------------------------------------------------------
setTools

# ----------------------------------------------------------------------------------------------------------------------
# Utility
# ----------------------------------------------------------------------------------------------------------------------
#setUtility

# ----------------------------------------------------------------------------------------------------------------------
# END
# ----------------------------------------------------------------------------------------------------------------------

setEnd
