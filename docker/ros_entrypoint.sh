#!/bin/bash
set -e

source /opt/ros/noetic/setup.bash

WS="/home/ros/uavros_ws"
if [ -f "${WS}/devel/setup.bash" ]; then
  source "${WS}/devel/setup.bash"
fi

export GAZEBO_MODEL_PATH="${WS}/src/uav_simulator/uav_gazebo/models:${GAZEBO_MODEL_PATH:-}"
export GAZEBO_RESOURCE_PATH="${WS}/src/uav_simulator/uav_gazebo/worlds:${GAZEBO_RESOURCE_PATH:-}"

exec "$@"
