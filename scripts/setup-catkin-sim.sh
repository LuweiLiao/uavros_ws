#!/usr/bin/env bash
# Configure a minimal, memory-safe catkin profile for uav simulation.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib/memory-safe.sh
source "${ROOT}/scripts/lib/memory-safe.sh"

PROFILE="${CATKIN_PROFILE:-sim}"

cd "${ROOT}"

memory_safe_preflight

if [ ! -d .catkin_tools ]; then
  catkin init
fi

memory_safe_clean_if_profile_mismatch "${PROFILE}" "${ROOT}"

read -r catkin_jobs make_j make_l <<< "$(memory_safe_recommend)"
memory_safe_export_make

# Simulation essentials only — skip entire rotors_simulator (heavy + HIL compile errors).
SIM_PACKAGES=(
  mav_msgs
  mav_planning_msgs
  mav_state_machine_msgs
  mav_system_msgs
  mav_comm
  uav_gazebo
  uav_gazebo_plugin
  uav_control
)

catkin config --profile "${PROFILE}"
catkin config --profile "${PROFILE}" --buildlist "${SIM_PACKAGES[@]}"
catkin config --profile "${PROFILE}" --skiplist rotors_hil_interface
catkin config --profile "${PROFILE}" -j "${catkin_jobs}" -l "${make_l}"
catkin config --profile "${PROFILE}" --make-args "-j${make_j}" "-l${make_l}"
catkin config --profile "${PROFILE}" --cmake-args -DCMAKE_BUILD_TYPE=Release
catkin profile set "${PROFILE}" 2>/dev/null || true

echo
echo "Catkin profile '${PROFILE}' ready:"
catkin config --profile "${PROFILE}"
