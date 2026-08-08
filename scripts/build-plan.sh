#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib/memory-safe.sh
source "${ROOT}/scripts/lib/memory-safe.sh"

read -r catkin_jobs make_j make_l <<< "$(memory_safe_recommend)"
total="$(memory_safe_total_mb)"
avail="$(memory_safe_mb MemAvailable)"
tier="$(memory_safe_tier)"

cat <<EOF
uavros_ws build plan
====================
Host RAM: ${total}MB total, ${avail}MB available
Tier: ${tier}

Parallelism (auto):
  catkin packages in parallel : ${catkin_jobs}
  make -j                     : ${make_j}
  make -l                     : ${make_l}

Commands:
  Sim essentials (uav_gazebo + plugins):
    ./scripts/docker-build-ws.sh

  Full workspace (skip broken HIL):
    ./scripts/docker-build-ws-full.sh

<=10GB hosts only: Docker mem_limit=5g (docker-compose.lowmem.yml)
EOF

if [ "$tier" = "medium" ] || [ "$tier" = "high" ]; then
  cat <<EOF

Your machine (${tier} tier): full build is recommended.
EOF
fi

if [ "$tier" = "minimal" ]; then
  cat <<EOF

Your machine (${tier} tier): use sim build; close browsers before compiling.
EOF
fi
