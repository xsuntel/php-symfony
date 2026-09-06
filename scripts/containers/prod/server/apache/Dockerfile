# ----------------------------------------------------------------------------------------------------------------------
# Dockerfile - Apache                                                                     https://hub.docker.com/_/httpd
# ----------------------------------------------------------------------------------------------------------------------
# UNUSED — kept for reference only. Nginx is this project's standard web server (see CLAUDE.md), and
# the served image is scripts/containers/prod/Dockerfile, which bundles nginx + php-fpm + supervisor.
# Nothing builds this file: it is absent from docker-compose.yml and from prod/deploy.sh.
#
# Build context, if it is ever wired up, is the REPOSITORY ROOT — the same as the prod Dockerfile —
# so the COPY paths in STEP 06 are repo-root-relative.
ARG VERSION=2.4

# ----------------------------------------------------------------------------------------------------------------------
# STEP - 01 : Pull official base image
# ----------------------------------------------------------------------------------------------------------------------
FROM httpd:${VERSION}

# ----------------------------------------------------------------------------------------------------------------------
# STEP - 02 : Set environment variables
# ----------------------------------------------------------------------------------------------------------------------
#RUN echo "[ Apache ] Set environment variables"

# ----------------------------------------------------------------------------------------------------------------------
# STEP - 03 : Set Work directory
# ----------------------------------------------------------------------------------------------------------------------
#RUN echo "[ Apache ] Set Work directory "

# ----------------------------------------------------------------------------------------------------------------------
# STEP - 04 : Install packages
# ----------------------------------------------------------------------------------------------------------------------
#RUN echo "[ Apache ] Install packages"

# ----------------------------------------------------------------------------------------------------------------------
# STEP - 05 : Update configuration
# ----------------------------------------------------------------------------------------------------------------------
RUN echo "[ Apache ] Update default configuration"

RUN echo "[ Apache ] Make a directory"


# ----------------------------------------------------------------------------------------------------------------------
# STEP - 06 : Copy source files
# ----------------------------------------------------------------------------------------------------------------------
RUN echo "[ Apache ] Copy the virtual host configuration"

# The httpd image roots at /usr/local/apache2, not the distro-package /etc/httpd — conf/extra/ is the
# directory httpd.conf pulls vhosts from via its own Include lines.
COPY scripts/containers/prod/server/apache/etc/httpd/conf.d/ /usr/local/apache2/conf/extra/

# ----------------------------------------------------------------------------------------------------------------------
# STEP - 07 : Start the service
# ----------------------------------------------------------------------------------------------------------------------
RUN echo "[ Apache ] Start the service"
