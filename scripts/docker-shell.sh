#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

export UID
export GID="$(id -g)"

if command -v xhost >/dev/null 2>&1; then
  xhost +local:docker >/dev/null 2>&1 || true
fi

# shellcheck source=scripts/lib/memory-safe.sh
source "${ROOT}/scripts/lib/memory-safe.sh"
memory_safe_compose_files

if docker info 2>/dev/null | grep -q 'Runtimes:.*nvidia'; then
  export DOCKER_RUNTIME=nvidia
fi

exec docker compose run --rm dev bash
