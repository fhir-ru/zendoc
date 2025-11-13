#!/bin/bash
set -e

echo "Starting fhir-ru-zendoc..."

# Ensure git remote uses HTTPS (not SSH) for public repo access
git remote set-url origin https://github.com/fhir-ru/zendoc.git

# Remove GitHub Actions token from git config (it's expired at runtime)
git config --unset-all http.https://github.com/.extraheader || true

# Background process: git pull every 30 seconds
(
  while true; do
    sleep 30
    echo "[$(date)] Pulling latest changes..."
    if ! git fetch origin 2>&1; then
      echo "Warning: git fetch failed with exit code $?"
    fi
    if ! git reset --hard origin/main 2>&1; then
      echo "Warning: git reset failed with exit code $?"
    fi
  done
) &

# Start application with reload mode
clojure -M:run 3333 reload
