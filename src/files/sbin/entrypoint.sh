#!/bin/sh
for f in /sbin/entrypoint.d/*.sh; do
  /bin/sh "$f"
done
exec "$@"
