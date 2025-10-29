#!/bin/sh
set -eu
if ! command -v nc >/dev/null 2>&1; then
  if command -v apk >/dev/null 2>&1; then apk add --no-cache busybox-extras >/dev/null 2>&1 || true
  elif command -v apt-get >/dev/null 2>&1; then apt-get update -y >/dev/null 2>&1 && apt-get install -y netcat-traditional >/dev/null 2>&1 || true
  fi
fi
i=0
until nc -z "${MYSQL_HOST:-db}" "${MYSQL_PORT:-3306}"; do
  i=$((i+1)); echo "waiting for db at ${MYSQL_HOST:-db}:${MYSQL_PORT:-3306}...";
  [ $i -gt 120 ] && echo "db timeout" && exit 1
  sleep 2
done
exec "$@"
