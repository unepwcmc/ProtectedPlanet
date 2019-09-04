#!/bin/bash
set -e

# Delete the existing pid if it is present
rm -f tmp/pids/server.pid

# Run the container’s main process
exec "$@"
