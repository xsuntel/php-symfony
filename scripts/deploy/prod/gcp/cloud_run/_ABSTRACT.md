# Scripts - Deploy - GCP (Google Cloud Platform) - Cloud Run

## Prod Environment

## Platform

* GCP (Google Cloud Platform) - [Console](https://console.cloud.google.com/)
  * API & Services
  * Billing
  * IAM & Admin
  * Cloud Storage                                            ( CDN )
  * VPC Networks
  * Cloud SQL                                                ( Database - PostgreSQL )
  * Monitoring
  * Memorystore                                              ( Cache - Redis )
  * Cloud Run                                                ( App )

### Products

#### 1. API & Services

* Enable services
  * Cloud Run Admin API
  * Cloud Build API
  * Code Run functions
  * Artifact Registry API
  * Serverless VPC Access API

#### 2. IAM & Admin

* Permissions for {project_name on GCP}
  * Principal : {User}
    * Role : Storage Object Viewer

#### 3. VPC Network

* VPC networks

* Serverless VPC access

#### 4. Cloud Storage ( Database - PostgreSQL )

#### 5. Memorystore ( Cache - Redis )

#### 6. Cloud Storage ( CDN )

#### 7. Artifact Registry (Docker Repogitory)

#### 8. Cloud Run (App)

* Docker - Contatiners - Dockerfile
  * App : PHP
  * Server : Nginx

## Project

### App - Symfony Framework

* Create APP_SECRET

```bash
date | md5
```

* Update default variables in Prod Environment

```bash
vi .env.prod

# ----------------------------------------------------------------------------------------------------------------------
# Architecture
# ----------------------------------------------------------------------------------------------------------------------

# >>>> Cache - Redis
REDIS_HOST=
REDIS_PORT=6379

# >>>> Database - PostgreSQL
POSTGRES_VERSION=16
POSTGRES_HOST=
POSTGRES_PORT=5432
POSTGRES_DB=
POSTGRES_USER=
POSTGRES_PASSWORD=

# >>>> Message - RabbitMQ
RABBITMQ_HOST=
RABBITMQ_PORT=5672
RABBITMQ_USER=guest
RABBITMQ_PASSWORD=guest

# >>>> Server - Nginx
NGINX_SCHEME=http
NGINX_HOST=
NGINX_PORT=

# >>>> Utility - Mailer
MAILER_HOST=
MAILER_PORT=
```

### Cloud Service Provider

#### GCP - CLI : [Default Configuration](https://docs.cloud.google.com/artifact-registry/docs/repositories/gcloud-defaults)

* Log into an account of GCP

  ```bash
  gcloud auth login

  gcloud auth application-default login
  ```

  ```bash
  gcloud init
  ```

  ```bash
  gcloud config list

  # PROJECT_ID
  ```

* Update a configuration for this project

  ```bash
  gcloud config set project {PROJECT_ID}

  gcloud config get-value project

  gcloud projects list
  ```

#### GCP - Artifact Registry : [Location](https://docs.cloud.google.com/artifact-registry/docs/repositories/repo-locations)

* Update a configuration for Artifact Registry

  ```bash
  gcloud services enable artifactregistry.googleapis.com
  ```

  ```bash
  gcloud auth configure-docker {GCLOUD_ARTIFACTS_DOCKER_LOCATION}-docker.pkg.dev
  ```

  ```bash
  gcloud config set artifacts/repository {GCLOUD_ARTIFACTS_DOCKER_REPOSITORY_NAME}

  gcloud artifacts packages list --repository={GCLOUD_ARTIFACTS_DOCKER_REPOSITORY_NAME} --project={PROJECT_ID}
  ```

  ```bash
  gcloud config set artifacts/location {GCLOUD_ARTIFACTS_DOCKER_LOCATION}

  gcloud artifacts locations list --project={PROJECT_ID}
  ```

* Create a repogitory on Artifact  : [Deploying](https://docs.cloud.google.com/run/docs/deploying?hl=ko)

  ```bash
  gcloud artifacts repositories create {GCLOUD_ARTIFACTS_DOCKER_REPOSITORY_NAME} --repository-format=docker --location={GCLOUD_ARTIFACTS_DOCKER_LOCATION} --description="{GCLOUD_ARTIFACTS_DESCRIPTION}" --immutable-tags --async --project={PROJECT_ID}

  gcloud artifacts repositories list --project={PROJECT_ID}
  ```

#### GCP - Cloud Storage

* Update a configuration for this project

  ```bash
  gcloud components install gsutil
  ```

  ```bash
  gsutil list
  ```

### Docker Desktop

#### Dockerfile

* Build image in localhost

  ```bash
  docker build . --tag {GCLOUD_ARTIFACTS_DOCKER_LOCATION}-docker.pkg.dev/{PROJECT_ID}/{GCLOUD_ARTIFACTS_NAME}/{image_name}:{tag}
  ```

## Deployment

### GCP - Deploy this project

* Deploy this project

```bash
./scripts/deploy/prod/gcp/cloud_run/deploy.sh
```

### Console

* Cache

```bash
./scripts/base/app/symfony/cache.sh
```

* Migrations

```bash
./scripts/base/app/symfony/database.sh
```

## Reference

### Public Cloud

* GCP (Google Cloud Platform)
  * [Code Run](https://cloud.google.com/run)
    * [Google Cloud CLI](https://docs.cloud.google.com/sdk/docs/install-sdk)
      * [PHP](https://docs.cloud.google.com/run/docs/quickstarts/build-and-deploy/deploy-php-service)
* Docker Desktop : [Download](https://www.docker.com/products/docker-desktop/)
