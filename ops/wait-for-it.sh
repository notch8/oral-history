#!/usr/bin/env bash
# Wait until a service is ready
# From https://github.com/vishnubob/wait-for-it

HOST=$1
shift
CMD="$@"

until nc -z ${HOST%:*} ${HOST#*:}; do
  echo "Waiting for $HOST..."
  sleep 2
done

exec $CMD
