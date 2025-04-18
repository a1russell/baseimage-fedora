#!/bin/sh
if [ "$(ls /sbin/entrypoint.d/*.sh 2> /dev/null | wc --lines)" -gt "0" ]; then
  for f in /sbin/entrypoint.d/*.sh; do
    /bin/sh "$f"
  done
fi
exec "$@"
