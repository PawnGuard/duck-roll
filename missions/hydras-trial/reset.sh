#!/bin/sh
set -eu

cd "$(dirname "$0")"
docker compose down
docker compose up -d --build
docker compose ps
