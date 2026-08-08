#!/usr/bin/env bash
# Build simulation essentials (uav_gazebo + plugins). Parallelism scales with RAM.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

# shellcheck source=scripts/lib/memory-safe.sh
source "${ROOT}/scripts/lib/memory-safe.sh"

export UID
export GID="$(id -g)"

memory_safe_preflight

memory_safe_compose_files

if docker info 2>/dev/null | grep -q 'Runtimes:.*nvidia'; then
  export DOCKER_RUNTIME=nvidia
fi

echo "==> Building simulation workspace (profile: sim)"
docker compose run --rm dev bash -lc '
  set -euo pipefail
  cd ~/uavros_ws
  ./scripts/setup-catkin-sim.sh
  echo "==> catkin build --profile sim"
  catkin build --profile sim
  echo
  echo "Build finished. Enter container and source:"
  echo "  ./scripts/docker-shell.sh"
  echo "  source ~/uavros_ws/devel/setup.bash"
'
