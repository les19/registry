#!/bin/bash

# View Docker Registry logs

SERVICE=${1:-}

if [ -z "$SERVICE" ]; then
    echo "Showing all logs (use Ctrl+C to exit)..."
    docker compose logs -f --tail=100
else
    echo "Showing logs for $SERVICE (use Ctrl+C to exit)..."
    docker compose logs -f --tail=100 "$SERVICE"
fi
