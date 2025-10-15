#!/bin/bash
set -e

echo "Starting fhir-ru-zendoc..."

# Ensure git remote uses HTTPS (not SSH) for public repo access
git remote set-url origin https://github.com/fhir-ru/zendoc.git

# Background process: git pull every 30 seconds
(
  while true; do
    sleep 30
    echo "[$(date)] Pulling latest changes..."
    git fetch origin
    git reset --hard origin/main || echo "Warning: git reset failed"
  done
) &

# Start application
exec clojure -M:run
