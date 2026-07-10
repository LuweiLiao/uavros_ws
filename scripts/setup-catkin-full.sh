#!/usr/bin/env bash
# Full workspace profile with conservative parallelism (still skips broken HIL).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib/memory-safe.sh
source "${ROOT}/scripts/lib/memory-safe.sh"

PROFILE="${CATKIN_PROFILE:-full}"

cd "${ROOT}"

memory_safe_preflight

if [ ! -d .catkin_tools ]; then
  catkin init
fi

memory_safe_clean_if_profile_mismatch "${PROFILE}" "${ROOT}"

read -r catkin_jobs make_j make_l <<< "$(memory_safe_recommend)"
memory_safe_export_make

BLACKLIST=(
  rotors_hil_interface
  rotors_evaluation
  rqt_rotors
)

catkin config --profile "${PROFILE}"
catkin config --profile "${PROFILE}" --no-buildlist
catkin config --profile "${PROFILE}" --skiplist "${BLACKLIST[@]}"
catkin config --profile "${PROFILE}" -j "${catkin_jobs}" -l "${make_l}"
catkin config --profile "${PROFILE}" --make-args "-j${make_j}" "-l${make_l}"
catkin config --profile "${PROFILE}" --cmake-args -DCMAKE_BUILD_TYPE=Release
catkin profile set "${PROFILE}" 2>/dev/null || true

echo
echo "Catkin profile '${PROFILE}' ready (blacklist: ${BLACKLIST[*]})"
