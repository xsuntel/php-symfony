#!/bin/sh
set -e
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Docker - Containers - Prod - Entrypoint
# ----------------------------------------------------------------------------------------------------------------------
# Minimal container entrypoint: #!/bin/sh + `set -e`, per the entrypoint exception in
# .claude/rules/utility-shell-script-rule.md — the bash-only project patterns do not apply here.
#
# Supervisor is exec'd as PID 1 and owns every process (php-fpm, nginx, messenger workers).
# It must NOT start them itself beforehand: a backgrounded `php-fpm -D` plus a non-exec'd nginx leaves
# the shell as PID 1, so SIGTERM is never forwarded and `docker stop` waits the full 10s for SIGKILL.

# >>>> OPcache preloading
# A missing preload script is a PHP startup FATAL, not a warning: php-fpm refuses to start, and
# because the nginx health check is short-circuited the container would still report healthy while
# serving no PHP at all. Drop the optimization rather than the pool.
PRELOAD_INI="/usr/local/etc/php/conf.d/docker-php-ext-opcache-preload.ini"
if [ -f "${PRELOAD_INI}" ] && [ ! -f /var/www/app/config/preload.php ]; then
  echo "[ Entrypoint ] config/preload.php not found — disabling OPcache preloading"
  rm -f "${PRELOAD_INI}"
fi

echo "[ Entrypoint ] Starting Supervisor (php-fpm, nginx, messenger)..."

# exec: replace the shell so supervisord becomes PID 1 and receives SIGTERM directly.
# -n: run in the foreground; without it supervisord daemonizes and the container exits immediately.
exec /usr/bin/supervisord -n -c /etc/supervisord.conf
