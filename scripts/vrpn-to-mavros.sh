#!/usr/bin/env bash
# Bridge VRPN (Motive) -> MAVROS vision_pose/vision_speed -> FCU (UDP preferred).
#
# Usage:
#   ./scripts/vrpn-to-mavros.sh
#   FCU_URL='udp://:14560@192.168.3.109:14550' TRACKER=pend_h1 ./scripts/vrpn-to-mavros.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

# shellcheck source=scripts/lib/memory-safe.sh
source "${ROOT}/scripts/lib/memory-safe.sh"
memory_safe_compose_files

export UID
export GID="$(id -g)"

VRPN_SERVER="${VRPN_SERVER:-192.168.3.37}"
VRPN_PORT="${VRPN_PORT:-3883}"
TRACKER="${TRACKER:-pend_h1}"
# Local bind port @ FCU IP:port (must match WiFi telemetry return path)
FCU_URL="${FCU_URL:-udp://:14560@192.168.3.109:14550}"
USE_MOCAP="${USE_MOCAP:-false}"

if command -v xhost >/dev/null 2>&1; then
  xhost +local:docker >/dev/null 2>&1 || true
fi

if docker info 2>/dev/null | grep -q 'Runtimes:.*nvidia'; then
  export DOCKER_RUNTIME=nvidia
fi

echo "==> VRPN ${VRPN_SERVER}:${VRPN_PORT} tracker=${TRACKER}"
echo "==> FCU  ${FCU_URL}"
echo "==> path: /${TRACKER}/pose -> ENU -> /mavros/vision_pose/pose"

docker compose run --rm --entrypoint bash dev -c "
  set -eo pipefail
  export ROS_MASTER_URI=\${ROS_MASTER_URI:-http://localhost:11311}
  export ROS_HOSTNAME=\${ROS_HOSTNAME:-localhost}
  export HOME=/home/ros
  source /opt/ros/noetic/setup.bash
  if [ -f ~/uavros_ws/devel/setup.bash ]; then
    source ~/uavros_ws/devel/setup.bash
  fi

  if [ ! -f /etc/protocols ] || ! rospack find vrpn_client_ros >/dev/null 2>&1; then
    echo '==> Installing VRPN packages...'
    sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \\
      netbase geographiclib-tools ros-noetic-vrpn ros-noetic-vrpn-client-ros >/dev/null
  fi
  if [ ! -f /usr/share/GeographicLib/geoids/egm96-5.pgm ]; then
    echo '==> Installing GeographicLib datasets (MAVROS)...'
    sudo /opt/ros/noetic/lib/mavros/install_geographiclib_datasets.sh
  fi

  if ! rospack find vrpn_mavros >/dev/null 2>&1; then
    echo '==> Building vrpn_mavros...'
    cd ~/uavros_ws
    catkin build vrpn_mavros --no-status --no-notify
    source devel/setup.bash
  fi

  exec roslaunch vrpn_mavros vrpn_to_mavros.launch \\
    vrpn_server:=${VRPN_SERVER} \\
    vrpn_port:=${VRPN_PORT} \\
    tracker:=${TRACKER} \\
    fcu_url:=${FCU_URL} \\
    use_mocap:=${USE_MOCAP}
"
