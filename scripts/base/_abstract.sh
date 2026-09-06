#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Base - Abstract
# ----------------------------------------------------------------------------------------------------------------------

# >>>> Platform
PLATFORM_TYPE=$(uname -s)
PLATFORM_PROCESSOR=$(uname -m)

# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Start
# ----------------------------------------------------------------------------------------------------------------------

setStart() {
  echo
  echo "==============================================================================================================="
  echo ">>>>  START                                                                  $(date)"
  echo "==============================================================================================================="
  echo
}

# ----------------------------------------------------------------------------------------------------------------------
# Scripts - End
# ----------------------------------------------------------------------------------------------------------------------

setEnd() {

  # >>>> Environment
  unset ENVIRONMENT_NAME

  # >>>> Platform
  unset PLATFORM_TIMEZONE

  # >>>> Project
  unset PROJECT_NAME
  unset PROJECT_PATH

  # --------------------------------------------------------------------------------------------------------------------
  # Architecture
  # --------------------------------------------------------------------------------------------------------------------

  # >>>> App
  unset PHP_VERSION
  unset PHP_NETWORK_FRONTEND_IP_ADDRESS
  unset PHP_NETWORK_BACKEND_IP_ADDRESS
  unset SYMFONY_VERSION

  unset NODE_VERSION

  # >>>> Cache
  unset REDIS_VERSION
  unset REDIS_NETWORK_FRONTEND_IP_ADDRESS
  unset REDIS_NETWORK_BACKEND_IP_ADDRESS
  unset REDIS_NETWORK_PORT
  unset REDIS_HOST
  unset REDIS_PORT
  unset REDIS_ROOT_USER
  unset REDIS_ROOT_PASSWORD

  # >>>> Database
  unset MYSQL_VERSION
  unset MYSQL_NETWORK_FRONTEND_IP_ADDRESS
  unset MYSQL_NETWORK_BACKEND_IP_ADDRESS
  unset MYSQL_NETWORK_PORT
  unset MYSQL_HOST
  unset MYSQL_PORT
  unset MYSQL_DB
  unset MYSQL_USER
  unset MYSQL_PASSWORD

  unset POSTGRES_VERSION
  unset POSTGRES_NETWORK_FRONTEND_IP_ADDRESS
  unset POSTGRES_NETWORK_BACKEND_IP_ADDRESS
  unset POSTGRES_NETWORK_PORT
  unset POSTGRES_HOST
  unset POSTGRES_PORT
  unset POSTGRES_DB
  unset POSTGRES_USER
  unset POSTGRES_PASSWORD

  # >>>> Message
  unset RABBITMQ_VERSION
  unset RABBITMQ_NETWORK_FRONTEND_IP_ADDRESS
  unset RABBITMQ_NETWORK_BACKEND_IP_ADDRESS
  unset RABBITMQ_HOST
  unset RABBITMQ_PORT
  unset RABBITMQ_USER
  unset RABBITMQ_PASSWORD

  # >>>> Server
  unset APACHE_VERSION
  unset APACHE_NETWORK_FRONTEND_IP_ADDRESS
  unset APACHE_NETWORK_BACKEND_IP_ADDRESS
  unset APACHE_NETWORK_PORT
  unset APACHE_HOST
  unset APACHE_PORT
  unset APACHE_HEALTHCHECK_FILE

  unset NGINX_VERSION
  unset NGINX_NETWORK_FRONTEND_IP_ADDRESS
  unset NGINX_NETWORK_BACKEND_IP_ADDRESS
  unset NGINX_NETWORK_PORT
  unset NGINX_HOST
  unset NGINX_PORT
  unset NGINX_HEALTHCHECK_FILE

  # --------------------------------------------------------------------------------------------------------------------
  # Build Scripts
  # --------------------------------------------------------------------------------------------------------------------

  # --------------------------------------------------------------------------------------------------------------------
  # CDN ( Content Delivery Networks )
  # --------------------------------------------------------------------------------------------------------------------

  # --------------------------------------------------------------------------------------------------------------------
  # Docker - Containers
  # --------------------------------------------------------------------------------------------------------------------

  # >>>> Docker
  unset DOCKER_ENVIRONMENT
  unset DOCKER_WORKDIR
  unset DOCKER_NETWORK_FRONTEND_IPAM_CONFIG_SUBNET
  unset DOCKER_NETWORK_BACKEND_IPAM_CONFIG_SUBNET

  # >>>> Dockerfile
  unset DOCKERFILE_IMAGE_NAME
  unset DOCKERFILE_TAG_NAME

  # --------------------------------------------------------------------------------------------------------------------
  # Provider ( Cloud Service Providers )
  # --------------------------------------------------------------------------------------------------------------------

  # >>>> AWS - CLI
  unset PYTHON_VERSION
  unset AWS_CLI_VERSION

  # >>>> AWS - S3
  unset AWS_S3_DOMAIN
  unset AWS_S3_KEY
  unset AWS_S3_SECRET
  unset AWS_S3_BUCKET
  unset AWS_S3_REGION
  unset AWS_S3_VERSION

  # >>>> AWS - SES
  unset AWS_SES_ACCESS_KEY
  unset AWS_SES_SECRET_KEY

  # >>>> GCP
  unset GCLOUD_PROJECT_ID
  unset GCLOUD_ARTIFACTS_DOCKER_LOCATION
  unset GCLOUD_ARTIFACTS_DOCKER_REPOSITORY_NAME
  unset GCLOUD_ARTIFACTS_DOCKER_REPOSITORY_DESCRIPTION
  unset GCLOUD_ARTIFACTS_DOCKER_IMAGE_NAME
  unset GCLOUD_ARTIFACTS_DOCKER_IMAGE_TAG

  # --------------------------------------------------------------------------------------------------------------------
  # Utility
  # --------------------------------------------------------------------------------------------------------------------

  # >>>> Git
  unset GIT_REMOTE_ORIGIN_URL
  unset GIT_CONFIG_LOCAL_USER_NAME
  unset GIT_CONFIG_LOCAL_USER_EMAIL

  # >>>> Mail
  unset MAILER_NETWORK_BACKEND_IP_ADDRESS
  unset MAILER_NETWORK_HTTP_PORT
  unset MAILER_NETWORK_SMTP_PORT

  # >>>> PgAdmin
  unset PGADMIN_NETWORK_BACKEND_IP_ADDRESS
  unset PGADMIN_HOST
  unset PGADMIN_PORT
  unset PGADMIN_MAIL
  unset PGADMIN_PW

  # --------------------------------------------------------------------------------------------------------------------
  # Tools for VM ( Instance )
  # --------------------------------------------------------------------------------------------------------------------


  echo
  echo "==============================================================================================================="
  echo "<<<<  END                                                                    $(date)"
  echo "==============================================================================================================="
  echo
  exit 0
}

# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Exit
# ----------------------------------------------------------------------------------------------------------------------

setExit() {
  echo
  echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
  echo "  EXIT                                                                      $(date)"
  echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
  echo
  # >>>> Process
  kill -SIGKILL $$
  echo
  exit
}
