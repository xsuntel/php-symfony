# ----------------------------------------------------------------------------------------------------------------------
# App - Dockerfile - PHP-FPM & Nginx & Supervisor                                           https://hub.docker.com/_/php
# ----------------------------------------------------------------------------------------------------------------------
# Build context is the REPOSITORY ROOT (scripts/containers/prod/deploy.sh passes "${PROJECT_PATH}").
# What reaches this build is filtered by /.dockerignore — secrets (app/.env.*.local), runtime artifacts
# (app/var/**) and dev-only sources are excluded there rather than being `rm`'d after the fact.
#
# This image is NOT hermetic by design: `composer install --no-dev`, `composer dump-env prod` and
# `asset-map:compile` run on the host in deploy.sh setBuild() BEFORE `docker build`, so app/vendor and
# app/public/assets are copied in already built. See scripts/base/app/symfony/config/_deployment.sh.
ARG PHP_VERSION="8.4"

# ----------------------------------------------------------------------------------------------------------------------
# STEP - 01 : Pull official base image
# ----------------------------------------------------------------------------------------------------------------------
FROM php:${PHP_VERSION}-fpm-alpine

LABEL title="Symfony"
LABEL purpose="webapp"
LABEL description="Prod Environment"

# ----------------------------------------------------------------------------------------------------------------------
# STEP - 02 : Set environment variables
# ----------------------------------------------------------------------------------------------------------------------
RUN echo "[ PHP ] Set environment variables"

ENV LANG="C.UTF-8" \
    LC_ALL="C.UTF-8" \
    TZ="Asia/Seoul"

# ----------------------------------------------------------------------------------------------------------------------
# STEP - 03 : Set Work directory
# ----------------------------------------------------------------------------------------------------------------------
RUN echo "[ PHP ] Set Work directory "

WORKDIR /var/www/app

# ----------------------------------------------------------------------------------------------------------------------
# STEP - 04 : Install packages
# ----------------------------------------------------------------------------------------------------------------------
RUN echo "[ PHP ] Install packages"

RUN set -eux; \
    # [Runtime-deps]
    apk add --no-cache \
        nginx \
        supervisor \
        libpq \
        libzip \
        libxml2 \
        libpng \
        libjpeg-turbo \
        freetype \
        icu \
        icu-libs \
        curl \
        rabbitmq-c \
        tzdata; \
    \
    # [Build-deps]
    apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        linux-headers \
        libzip-dev \
        libpq-dev \
        libxml2-dev \
        libpng-dev \
        libjpeg-turbo-dev \
        freetype-dev \
        icu-dev \
        curl-dev \
        rabbitmq-c-dev; \
    \
    # PHP Core Extensions
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    docker-php-ext-install -j$(nproc) \
        gd \
        sockets \
        intl \
        zip \
        pdo \
        pdo_pgsql \
        bcmath; \
    \
    # PECL Extensions (Redis, AMQP)
    pecl install redis amqp; \
    docker-php-ext-enable redis amqp opcache; \
    \
    # Clean up
    apk del .build-deps; \
    rm -rf /tmp/pear /var/cache/apk/*; \
    docker-php-source delete;

# ----------------------------------------------------------------------------------------------------------------------
# STEP - 05 : Update configuration
# ----------------------------------------------------------------------------------------------------------------------
RUN echo "[ PHP ] Update a configuration"

# >>>> PHP
RUN rm -f "$PHP_INI_DIR/conf.d/php.ini"
RUN rm -f "$PHP_INI_DIR/php.ini-development"

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
COPY scripts/containers/prod/app/php/etc/conf.d/docker-php-ext-opcache.ini "$PHP_INI_DIR/conf.d/docker-php-ext-opcache.ini"
# Separate file so entrypoint.sh can drop it when the app ships no config/preload.php.
COPY scripts/containers/prod/app/php/etc/conf.d/docker-php-ext-opcache-preload.ini "$PHP_INI_DIR/conf.d/docker-php-ext-opcache-preload.ini"

# >>>> PHP-FPM
RUN rm -f /usr/local/etc/php-fpm.conf.default
RUN rm -f /usr/local/etc/php-fpm.d/www.conf.default
# zz-docker.conf overrides the pool to listen on [::]:9000; removing it keeps the 127.0.0.1:9000 that
# server/nginx/.../www.conf fastcgi_pass targets. Our own www.conf below re-states that listen explicitly.
RUN rm -f /usr/local/etc/php-fpm.d/zz-docker.conf
COPY scripts/containers/prod/app/php/etc/php-fpm.d/www.conf /usr/local/etc/php-fpm.d/www.conf

# >>>> Nginx
RUN rm -f /etc/nginx/http.d/default.conf
COPY scripts/containers/prod/server/nginx/etc/nginx/nginx.conf /etc/nginx/nginx.conf
COPY scripts/containers/prod/server/nginx/etc/nginx/http.d/www.conf /etc/nginx/http.d/www.conf

# >>>> Supervisor
RUN mkdir -p /etc/supervisor.d
COPY scripts/containers/prod/utility/supervisor/etc/supervisord.conf /etc/supervisord.conf
COPY scripts/containers/prod/utility/supervisor/etc/supervisor.d/messenger-consume.ini /etc/supervisor.d/messenger-consume.ini

# >>>> Entrypoint
COPY scripts/containers/prod/utility/entrypoint.sh /usr/local/bin/entrypoint

# ----------------------------------------------------------------------------------------------------------------------
# STEP - 06 : Copy source files
# ----------------------------------------------------------------------------------------------------------------------
RUN echo "[ PHP ] Copy source files"

# >>>> App - PHP - Symfony Framework
COPY --chown=www-data:www-data ./app /var/www/app

RUN set -eux; \
    # The base image ships these; neither is this app's document root.
    rm -rf /var/www/html; \
    rm -rf /var/www/localhost; \
    # /.dockerignore excludes var/{cache,log,sessions}, so recreate them writable by the pool user.
    mkdir -p /var/www/app/var/cache /var/www/app/var/log /var/www/app/var/sessions; \
    chown -R www-data:www-data /var/www/app/var; \
    chmod -R 775 /var/www/app/var;

# >>>> Nginx & Supervisor - runtime directories
RUN set -eux; \
    mkdir -p /var/log/nginx /var/log/supervisor /run/supervisor; \
    chmod -R 775 /var/log/nginx /var/log/supervisor;

# >>>> Entrypoint
RUN set -eux; \
    chmod +x /usr/local/bin/entrypoint;

# ----------------------------------------------------------------------------------------------------------------------
# STEP - 07 : Start the service
# ----------------------------------------------------------------------------------------------------------------------
EXPOSE 8080/tcp

# Short-circuited by the `location = /healthcheck.php { return 200; }` block in www.conf, so it proves
# nginx is serving without going through PHP-FPM.
HEALTHCHECK --interval=30s --timeout=3s --start-period=20s --retries=3 \
    CMD curl -fsS http://127.0.0.1:8080/healthcheck.php || exit 1

# >>>> Shell-script
ENTRYPOINT ["entrypoint"]
