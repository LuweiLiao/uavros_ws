#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

export UID
export GID="$(id -g)"

echo "==> Building uavros_ws:noetic image (UID=${UID}, GID=${GID})"
docker compose build dev
