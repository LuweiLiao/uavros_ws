#!/usr/bin/env bash
# Adaptive catkin/make parallelism based on host RAM.

memory_safe_mb() {
  local key="${1:-MemAvailable}"
  awk -v key="$key" '$1 == key ":" { printf "%d", $2 / 1024 }' /proc/meminfo
}

memory_safe_total_mb() {
  memory_safe_mb MemTotal
}

memory_safe_tier() {
  local total
  total="$(memory_safe_total_mb)"
  if [ "$total" -ge 32000 ]; then
    echo "high"
  elif [ "$total" -ge 20000 ]; then
    echo "medium"
  elif [ "$total" -ge 12000 ]; then
    echo "low"
  else
    echo "minimal"
  fi
}

# Returns "CATKIN_JOBS MAKE_J MAKE_LOAD" based on total/available RAM.
memory_safe_recommend() {
  local total avail
  total="$(memory_safe_total_mb)"
  avail="$(memory_safe_mb MemAvailable)"

  local catkin_jobs=1 make_j=2 make_l=2
  if [ "$total" -ge 32000 ]; then
    catkin_jobs=4
    make_j=8
    make_l=8
  elif [ "$total" -ge 20000 ]; then
    catkin_jobs=3
    make_j=6
    make_l=6
  elif [ "$total" -ge 16000 ]; then
    catkin_jobs=2
    make_j=4
    make_l=4
  elif [ "$total" -ge 12000 ]; then
    catkin_jobs=2
    make_j=3
    make_l=3
  elif [ "$total" -ge 10000 ]; then
    catkin_jobs=1
    make_j=2
    make_l=2
  else
    catkin_jobs=1
    make_j=1
    make_l=2
  fi

  if [ "$avail" -lt 2500 ]; then
    catkin_jobs=1
    make_j=1
    make_l=1
  elif [ "$avail" -lt 4000 ]; then
    catkin_jobs=1
    make_j=2
    make_l=2
  fi

  echo "$catkin_jobs $make_j $make_l"
}

memory_safe_preflight() {
  local total avail tier
  total="$(memory_safe_total_mb)"
  avail="$(memory_safe_mb MemAvailable)"
  tier="$(memory_safe_tier)"
  read -r catkin_jobs make_j make_l <<< "$(memory_safe_recommend)"

  echo "==> Memory: ${total}MB total, ${avail}MB available (tier: ${tier})"
  echo "==> Build limits: catkin_jobs=${catkin_jobs}, make -j${make_j} -l${make_l}"

  if [ "$avail" -lt 1500 ]; then
    echo "ERROR: Available memory below 1.5GB. Close browsers/IDE and retry." >&2
    return 1
  fi

  if [ "$tier" = "minimal" ] && [ "$avail" -lt 3000 ]; then
    echo "WARNING: Low memory. Close heavy apps before building." >&2
  fi
}

memory_safe_export_make() {
  read -r _ make_j make_l <<< "$(memory_safe_recommend)"
  export MAKEFLAGS="-j${make_j} -l${make_l}"
  export CATKIN_PARALLEL_JOBS="${_}"
}

memory_safe_compose_files() {
  local total
  total="$(memory_safe_total_mb)"
  if [ "$total" -le 10240 ]; then
    export COMPOSE_FILE="docker-compose.yml:docker-compose.lowmem.yml"
    echo "==> Low-RAM host (<=10GB): Docker mem_limit=5g"
  else
    unset COMPOSE_FILE
  fi
}

# Drop stale build/devel when switching catkin profiles (avoids profile mismatch errors).
memory_safe_clean_if_profile_mismatch() {
  local profile="$1"
  local root="${2:-.}"
  local profiles_yaml="${root}/.catkin_tools/profiles/profiles.yaml"

  if [ ! -d "${root}/build" ] || [ ! -f "${profiles_yaml}" ]; then
    return 0
  fi

  local active
  active="$(awk -F': ' '/^active:/ {print $2; exit}' "${profiles_yaml}" | tr -d '[:space:]')"
  if [ -n "${active}" ] && [ "${active}" != "${profile}" ]; then
    echo "==> Profile switch (${active} -> ${profile}): cleaning build/devel/logs"
    (cd "${root}" && catkin clean -y -b -d --profile "${active}" 2>/dev/null) || rm -rf "${root}/build" "${root}/devel" "${root}/logs"
  fi
}
