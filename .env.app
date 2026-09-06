# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Default variables
# ----------------------------------------------------------------------------------------------------------------------

# >>>> Platform                                                              https://www.php.net/manual/en/timezones.php
PLATFORM_TIMEZONE="Asia/Seoul"

# >>>> Project
PROJECT_DOMAIN="symfony.com"

# ----------------------------------------------------------------------------------------------------------------------
# Architecture
# ----------------------------------------------------------------------------------------------------------------------

# >>>> App      - PHP                                                                       https://symfony.com/releases
PHP_VERSION=8.5
SYMFONY_VERSION=8.1.*

NODE_VERSION=24

# >>>> Cache    - Redis
REDIS_VERSION=7.0

# >>>> Database - PostgreSQL
POSTGRES_VERSION=16

# >>>> Message  - RabbitMQ
RABBITMQ_VERSION=3.13

# >>>> Server   - Nginx
NGINX_VERSION=1.24

# ----------------------------------------------------------------------------------------------------------------------
# Docker - Containers
# ----------------------------------------------------------------------------------------------------------------------

# >>>> Dockerfile - App
DOCKERFILE_IMAGE_NAME=symfony-php
DOCKERFILE_TAG_NAME=0.0
DOCKERFILE_LOCALHOST_PORT=8080

# ----------------------------------------------------------------------------------------------------------------------
# Provider ( Cloud Service Providers )
# ----------------------------------------------------------------------------------------------------------------------

# >>>> AWS (Amazon Web Services)
#AWS_CLI_VERSION=

#AWS_SES_ACCESS_KEY=
#AWS_SES_SECRET_KEY=

#AWS_S3_DOMAIN=
#AWS_S3_KEY=
#AWS_S3_SECRET=
#AWS_S3_BUCKET=
#AWS_S3_REGION=
#AWS_S3_VERSION=

# >>>> GCP (Google Cloud Platform)

#GCLOUD_PROJECT_ID=

#GCLOUD_ARTIFACTS_DOCKER_LOCATION=
#GCLOUD_ARTIFACTS_DOCKER_REPOSITORY_NAME=
#GCLOUD_ARTIFACTS_DOCKER_REPOSITORY_DESCRIPTION="Docker Repository"
#GCLOUD_ARTIFACTS_DOCKER_IMAGE_NAME=${DOCKERFILE_IMAGE_NAME}
#GCLOUD_ARTIFACTS_DOCKER_IMAGE_TAG=latest

#GCLOUD_RUN_DEPLOY_SERVICE_NAME=
#GCLOUD_RUN_DEPLOY_REGION=
#GCLOUD_RUN_DEPLOY_NETWORK=
#GCLOUD_RUN_DEPLOY_SUBNET=

# ----------------------------------------------------------------------------------------------------------------------
# Utility
# ----------------------------------------------------------------------------------------------------------------------

# >>>> Git
GIT_REMOTE_ORIGIN_URL=""
GIT_CONFIG_LOCAL_USER_NAME=""
GIT_CONFIG_LOCAL_USER_EMAIL=""
