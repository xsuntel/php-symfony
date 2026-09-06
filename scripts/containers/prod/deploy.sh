#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Docker - Containers - Prod - Debug
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

# Nothing else in the repository defines this. Without a value, setDocker()'s -p flag becomes
# "127.0.0.1::8080" and Docker binds a random ephemeral port that setUtility() cannot reach.
# Set once here so setNginx() frees, setDocker() publishes and setUtility() curls the same port.
DOCKERFILE_LOCALHOST_PORT=${DOCKERFILE_LOCALHOST_PORT:-8080}

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
  echo

  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Linux
  # --------------------------------------------------------------------------------------------------------------------
  local LOCAL_LISTEN_PORT
  if [ "${PLATFORM_TYPE}" == "Linux" ]; then
    LOCAL_LISTEN_PORT=$(netstat -an | grep -i LISTEN | grep -v tcp6 | grep ".${DOCKERFILE_LOCALHOST_PORT}" | awk '{print $6}')
    if [ "${LOCAL_LISTEN_PORT}" == "LISTEN" ]; then
      sudo fuser -k "${DOCKERFILE_LOCALHOST_PORT}/tcp"
    fi

  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Mac - MacOS
  # --------------------------------------------------------------------------------------------------------------------
  elif [ "${PLATFORM_TYPE}" == "Darwin" ]; then
    LOCAL_LISTEN_PORT=$(netstat -an | grep -i LISTEN | grep -v tcp6 | grep ".${DOCKERFILE_LOCALHOST_PORT}" | awk '{print $6}')
    if [ "${LOCAL_LISTEN_PORT}" == "LISTEN" ]; then
      # xargs, not "$(...)" — lsof can return several PIDs and quoting would pass them as one argument.
      lsof -ti:"${DOCKERFILE_LOCALHOST_PORT}" | xargs -r kill -9
    fi

  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Windows - WSL2
  # --------------------------------------------------------------------------------------------------------------------
  elif [ "${PLATFORM_TYPE}" == "Windows" ]; then
    LOCAL_LISTEN_PORT=$(netstat -an | grep -i LISTEN | grep -v tcp6 | grep "${DOCKERFILE_LOCALHOST_PORT}" | awk '{print $6}')
    if [ "${LOCAL_LISTEN_PORT}" == "LISTEN" ]; then
      sudo fuser -k "${DOCKERFILE_LOCALHOST_PORT}/tcp"
    fi

  else
    echo "Please check Operating System"
    setExit
  fi
  echo
}

# ----------------------------------------------------------------------------------------------------------------------
# Build Scripts
# ----------------------------------------------------------------------------------------------------------------------

setBuild() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Build"
  echo -e "----------------------------------------------------------------------------------------------------------\n"

  # >>>> PHP - Symfony Framework - .env.prod.local
  if [ -f "./scripts/containers/prod/.env.prod.local" ]; then
    cp -fv "./scripts/containers/prod/.env.prod.local" ./app/.env.prod.local
  fi
  echo

  # >>>> PHP - Symfony Framework - Deployment
  if [ -f "${PROJECT_PATH}/scripts/base/app/symfony/config/_deployment.sh" ]; then
    source "${PROJECT_PATH}/scripts/base/app/symfony/config/_deployment.sh"
  else
    echo "Please check a file : ./scripts/base/app/symfony/config/_deployment.sh" && exit
  fi
  echo

  # >>>> PHP - Symfony Framework - Deployment - Back-End  - Permissions - (Optional)


  # >>>> PHP - Symfony Framework - Deployment - Back-End  - Database    - (Optional)


  # >>>> PHP - Symfony Framework - Deployment - Back-End  - Cron jobs   - (Optional)


  # >>>> PHP - Symfony Framework - Deployment - Back-End  - Messenger   - (Optional)


  # >>>> PHP - Symfony Framework - Deployment - Front-End - AssetMapper - (Optional)
  if [ -f "${PROJECT_PATH}/scripts/base/app/symfony/component/assets/_assetmapper.sh" ]; then
    source "${PROJECT_PATH}/scripts/base/app/symfony/component/assets/_assetmapper.sh"
  else
    echo "Please check a file : ./scripts/base/app/symfony/component/assets/_assetmapper.sh" && exit
  fi
  echo
}

# ----------------------------------------------------------------------------------------------------------------------
# Docker - Containers
# ----------------------------------------------------------------------------------------------------------------------

setDocker() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Docker - Containers"
  echo -e "----------------------------------------------------------------------------------------------------------\n"

  echo ">>>> Docker - Container - App"
  echo

  CONTAINER_NAME="symfony-php-prod"
  if [ -n "$(docker ps -aq -f "name=^/${CONTAINER_NAME}$")" ]; then
    docker stop "${CONTAINER_NAME}"
    docker rm -f "${CONTAINER_NAME}"
    echo
  fi
  echo

  echo ">>>> Docker - Build"
  echo

  IMAGE_NAME=${DOCKERFILE_IMAGE_NAME:-"symfony-php"}
  TAG_NAME=$(date +%Y.%m.%d)

  docker build -f "${PROJECT_PATH}/scripts/containers/prod/Dockerfile" --network=host -t "${IMAGE_NAME}:${TAG_NAME}" "${PROJECT_PATH}" --no-cache
  echo

  echo ">>>> Docker - Run"
  echo

  CONTAINER_ID=$(docker run -d \
    --cpus="4.0" \
    --memory="4g" \
    --net symfony_back-end \
    -p "127.0.0.1:${DOCKERFILE_LOCALHOST_PORT}:8080" \
    --name "${CONTAINER_NAME}" \
    "${IMAGE_NAME}:${TAG_NAME}")

  echo ">>>> Docker - Started Container ID: ${CONTAINER_ID}"
  echo

  echo ">>>> Docker - Health"
  echo

  # Poll the Dockerfile HEALTHCHECK instead of assuming the container is serving. The diagnostics and
  # the curl below used to run the instant `docker run -d` returned, racing supervisor's startup.
  local HEALTH_STATUS
  local HEALTH_WAITED
  HEALTH_WAITED=0
  while [ "${HEALTH_WAITED}" -lt 90 ]; do
    HEALTH_STATUS=$(docker inspect --format='{{.State.Health.Status}}' "${CONTAINER_ID}" 2>/dev/null)
    if [ "${HEALTH_STATUS}" == "healthy" ]; then
      break
    fi
    if [ "${HEALTH_STATUS}" == "unhealthy" ]; then
      echo "[ ERROR ] Container reported unhealthy"
      docker logs "${CONTAINER_ID}"
      setExit
    fi
    sleep 2
    HEALTH_WAITED=$((HEALTH_WAITED + 2))
  done

  if [ "${HEALTH_STATUS}" != "healthy" ]; then
    echo "[ ERROR ] Container did not become healthy within ${HEALTH_WAITED}s (last status: ${HEALTH_STATUS})"
    docker logs "${CONTAINER_ID}"
    setExit
  fi
  echo "Healthy after ${HEALTH_WAITED}s"
  echo

  echo ">>>> Docker - Process"
  echo
  docker ps --filter "id=${CONTAINER_ID}"
  echo

  echo ">>>> Docker - Container"
  echo

  docker container ls
  echo

  echo ">>>> Docker - Image"
  echo

  docker image ls
  echo

  docker image inspect "${IMAGE_NAME}:${TAG_NAME}"
  echo

  docker inspect "${CONTAINER_ID}" --format='{{.HostConfig.ExtraHosts}}'
  echo


  echo ">>>> Docker - Port"
  echo

  docker port "${CONTAINER_ID}"
  echo

  echo ">>>> Docker - Exec"
  echo

  docker exec -it "${CONTAINER_ID}" ps aux
  echo

  docker exec -it "${CONTAINER_ID}" cat /etc/hosts | grep host.docker.internal
  echo

  docker exec -it "${CONTAINER_ID}" getent hosts host.docker.internal
  echo

  docker exec -it "${CONTAINER_ID}" netstat -tulpn | grep 8080
  echo

  echo ">>>> Docker - Exec - App"
  echo

  docker exec -it "${CONTAINER_ID}" php /var/www/app/bin/console debug:dotenv
  echo

  echo ">>>> Docker - Exec - PHP-FPM"
  echo

  docker exec -it "${CONTAINER_ID}" php-fpm -t
  echo

  echo ">>>> Docker - Exec - Nginx"
  echo

  docker exec -it "${CONTAINER_ID}" nginx -t
  echo

  echo ">>>> Docker - Exec - Supervisor"
  echo

  # Expect php-fpm, nginx AND messenger-consume_00/_01 all RUNNING. A missing messenger worker means
  # the [include] section of supervisord.conf is not being read.
  #
  # This is asserted, not just printed: the nginx health check is short-circuited with `return 200;`,
  # so a container whose php-fpm died still reports healthy. Supervisor is the only place that outage
  # is visible. No -it here — deploy.sh must stay usable from a non-TTY context.
  # supervisorctl exits non-zero when any program is in a non-RUNNING state, so the exit code is the
  # assertion — no output parsing needed.
  if ! docker exec "${CONTAINER_ID}" supervisorctl status; then
    echo
    echo "[ ERROR ] Not every supervised program is RUNNING"
    docker logs "${CONTAINER_ID}"
    setExit
  fi
  echo

  echo ">>>> Docker - Logs"
  echo

  docker logs "${CONTAINER_ID}"
  echo
}

# ----------------------------------------------------------------------------------------------------------------------
# Provider ( Cloud Service Providers )
# ----------------------------------------------------------------------------------------------------------------------

setProvider() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Provider ( Cloud Service Providers )"
  echo -e "----------------------------------------------------------------------------------------------------------\n"
}

# ----------------------------------------------------------------------------------------------------------------------
# Tools for VM ( Instance )
# ----------------------------------------------------------------------------------------------------------------------

setTools() {
  echo "---------------------------------------------------------------------------------------------------------------"
  echo "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Tools for VM ( Instance )"
  echo "---------------------------------------------------------------------------------------------------------------"
}

# ----------------------------------------------------------------------------------------------------------------------
# Utility
# ----------------------------------------------------------------------------------------------------------------------

setUtility() {
  echo -e "----------------------------------------------------------------------------------------------------------"
  echo -e "[ ${ENVIRONMENT_NAME} ] ${PLATFORM_TYPE} - Utility"
  echo -e "----------------------------------------------------------------------------------------------------------\n"

  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Linux
  # --------------------------------------------------------------------------------------------------------------------
  if [ "${PLATFORM_TYPE}" == "Linux" ]; then
    echo ">>>> Process"
    echo

    pgrep -af docker
    echo

    echo ">>>> Network"
    echo

    netstat -nlp | grep "${DOCKERFILE_LOCALHOST_PORT}"
    echo

    echo ">>>> Port"
    echo

    curl -fsS -o /dev/null -w "healthcheck: %{http_code}\n" \
      "http://localhost:${DOCKERFILE_LOCALHOST_PORT}/healthcheck.php"
    curl -v "http://localhost:${DOCKERFILE_LOCALHOST_PORT}"
    echo

  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Mac - MacOS
  # --------------------------------------------------------------------------------------------------------------------
  elif [ "${PLATFORM_TYPE}" == "Darwin" ]; then
    echo

  # --------------------------------------------------------------------------------------------------------------------
  # Platform - Windows - WSL2
  # --------------------------------------------------------------------------------------------------------------------
  elif [ "${PLATFORM_TYPE}" == "Windows" ]; then
    echo

  else
    echo "Please check Operating System"
    setExit
  fi
  echo
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
setNginx

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
#setProvider

# ----------------------------------------------------------------------------------------------------------------------
# Tools for VM ( Instance )
# ----------------------------------------------------------------------------------------------------------------------
#setTools

# ----------------------------------------------------------------------------------------------------------------------
# Utility
# ----------------------------------------------------------------------------------------------------------------------
setUtility

# ----------------------------------------------------------------------------------------------------------------------
# END
# ----------------------------------------------------------------------------------------------------------------------

setEnd

