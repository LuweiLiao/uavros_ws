#!/usr/bin/env bash
# End-to-end smoke test: VRPN tiltquad -> MAVROS -> FCU.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

# shellcheck source=scripts/lib/memory-safe.sh
source "${ROOT}/scripts/lib/memory-safe.sh"
memory_safe_compose_files

export UID
export GID="$(id -g)"

VRPN_SERVER="${VRPN_SERVER:-192.168.43.5}"
TRACKER="${TRACKER:-tiltquad}"
FCU_URL="${FCU_URL:-udp://:14551@192.168.43.9:14550}"

if docker info 2>/dev/null | grep -q 'Runtimes:.*nvidia'; then
  export DOCKER_RUNTIME=nvidia
fi

echo "==> Smoke test VRPN=${VRPN_SERVER} tracker=${TRACKER} FCU=${FCU_URL}"

docker compose run --rm --entrypoint bash dev -c "
set -eo pipefail
export ROS_MASTER_URI=http://localhost:11311
export ROS_HOSTNAME=localhost
source /opt/ros/noetic/setup.bash

sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \\
  netbase geographiclib-tools ros-noetic-vrpn ros-noetic-vrpn-client-ros >/dev/null
if [ ! -f /usr/share/GeographicLib/geoids/egm96-5.pgm ]; then
  echo '==> Installing GeographicLib datasets...'
  sudo /opt/ros/noetic/lib/mavros/install_geographiclib_datasets.sh
fi

timeout 3 bash -c 'echo >/dev/tcp/${VRPN_SERVER}/3883' || { echo 'FAIL: VRPN port closed'; exit 1; }
echo \"OK: VRPN ${VRPN_SERVER}:3883 reachable\"

roslaunch ~/uavros_ws/docker/launch/vrpn_to_mavros.launch \\
  vrpn_server:=${VRPN_SERVER} tracker:=${TRACKER} fcu_url:=${FCU_URL} \\
  >/tmp/bridge.log 2>&1 &
LPID=\$!
cleanup() { kill \$LPID 2>/dev/null || true; pkill -f 'roslaunch|roscore|mavros|vrpn' || true; }
trap cleanup EXIT

ok_pose=0
ok_mav=0
for i in \$(seq 1 50); do
  if timeout 1 rostopic echo -n 1 /${TRACKER}/pose >/tmp/pose.txt 2>/dev/null; then
    ok_pose=1
  fi
  if timeout 1 rostopic echo -n 1 /mavros/state 2>/dev/null | grep -q 'connected: True'; then
    ok_mav=1
  fi
  if [ \$ok_pose -eq 1 ] && [ \$ok_mav -eq 1 ]; then
    break
  fi
  # Fail fast if mavros already crashed
  if ! kill -0 \$LPID 2>/dev/null; then
    echo 'FAIL: bridge process exited early'
    tail -50 /tmp/bridge.log
    exit 1
  fi
  sleep 1
done

echo \"=== /${TRACKER}/pose sample ===\"
head -25 /tmp/pose.txt || true
echo '=== /mavros/state ==='
timeout 3 rostopic echo -n 1 /mavros/state | tee /tmp/mavstate.txt || true
echo '=== /mavros/vision_pose/pose ==='
timeout 4 rostopic echo -n 1 /mavros/vision_pose/pose 2>&1 | tee /tmp/vision.txt | head -25 || true
echo '=== vision_pose hz ==='
timeout 4 rostopic hz /mavros/vision_pose/pose 2>&1 | head -6 || true

fail=0
if ! grep -q 'position:' /tmp/pose.txt 2>/dev/null; then
  echo \"FAIL: no /${TRACKER}/pose\"
  fail=1
fi
if ! grep -q 'connected: True' /tmp/mavstate.txt 2>/dev/null; then
  echo 'FAIL: mavros not connected to FCU'
  fail=1
fi
if ! grep -q 'position:' /tmp/vision.txt 2>/dev/null; then
  echo 'FAIL: no /mavros/vision_pose/pose (relay broken)'
  fail=1
fi
if [ \"\$fail\" -ne 0 ]; then
  tail -50 /tmp/bridge.log || true
  exit 1
fi

echo 'PASS: VRPN pose + MAVROS connected + vision_pose flowing'
"
