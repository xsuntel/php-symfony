#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Base - Utility - Docker
# ----------------------------------------------------------------------------------------------------------------------
# The canonical entry point for the dev compose stack. Sourced from a deploy script's setDocker(), so
# it inherits PROJECT_PATH and ENVIRONMENT_NAME rather than bootstrapping them itself.

if [ -f "${PROJECT_PATH}/.env.app" ] && [ -f "${PROJECT_PATH}/scripts/containers/dev/docker-compose.env" ] && [ -f "${PROJECT_PATH}/scripts/containers/dev/docker-compose.yml" ]; then

  # --------------------------------------------------------------------------------------------------------------------
  # Compose invocation
  # --------------------------------------------------------------------------------------------------------------------
  # --project-directory is mandatory, not cosmetic: every path inside docker-compose.yml (build
  # contexts, dockerfile paths, env_file entries) is written relative to the REPOSITORY ROOT, and
  # Compose otherwise resolves them against the compose file's own directory.
  #
  # No --profile flag here on purpose. The CLI flag OVERRIDES COMPOSE_PROFILES rather than adding to
  # it, so the previous `--profile core` silently suppressed the utility profile and pgadmin never
  # started. Profile selection belongs to COMPOSE_PROFILES in docker-compose.env.
  local COMPOSE_ARGS
  COMPOSE_ARGS=(
    -f "${PROJECT_PATH}/scripts/containers/dev/docker-compose.yml"
    --project-directory "${PROJECT_PATH}"
    --env-file "${PROJECT_PATH}/.env.app"
    --env-file "${PROJECT_PATH}/scripts/containers/dev/docker-compose.env"
  )

  echo ">>>> Docker - Clear Network"
  echo

  docker network prune -f
  echo

  echo ">>>> Docker - Check docker-compose.yml"
  echo

  docker compose "${COMPOSE_ARGS[@]}" config
  echo

  echo ">>>> Docker - Build docker images"
  echo

  if [ "${ENVIRONMENT_NAME}" == "prod" ]; then
    docker compose "${COMPOSE_ARGS[@]}" build --no-cache
  else
    docker compose "${COMPOSE_ARGS[@]}" build
  fi
  echo

  echo ">>>> Docker - Start docker containers"
  echo

  # No --pull always: every service here is built from a local Dockerfile, and the flag makes Compose
  # attempt a registry pull for tags that only exist on this host. The build step above is what
  # refreshes the images.
  docker compose "${COMPOSE_ARGS[@]}" up -d --remove-orphans
  echo

  echo ">>>> Docker - System"
  echo

  # image prune (dangling only), NOT `system prune -a --filter label=purpose=webapp`. That label is
  # set by scripts/containers/prod/Dockerfile and by none of the dev images, so the old command
  # cleaned nothing here while deleting the production app image whenever it happened to be stopped.
  docker image prune -f
  echo

else
  echo "There is not docker-compose.yml"
  echo
fi
