#!/usr/bin/env bash
# Full workspace build with conservative parallelism. Requires >=12GB RAM recommended.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

# shellcheck source=scripts/lib/memory-safe.sh
source "${ROOT}/scripts/lib/memory-safe.sh"

export UID
export GID="$(id -g)"

total="$(memory_safe_total_mb)"
if [ "$total" -lt 12000 ]; then
  echo "WARNING: ${total}MB RAM detected. Full build may swap on <=12GB hosts." >&2
  echo "         Prefer: ./scripts/docker-build-ws.sh" >&2
fi

memory_safe_preflight

memory_safe_compose_files

if docker info 2>/dev/null | grep -q 'Runtimes:.*nvidia'; then
  export DOCKER_RUNTIME=nvidia
fi

echo "==> Building full workspace (conservative parallelism, skip rotors_hil_interface)"
docker compose run --rm dev bash -lc '
  set -euo pipefail
  cd ~/uavros_ws
  ./scripts/setup-catkin-full.sh
  catkin build --profile full
'
