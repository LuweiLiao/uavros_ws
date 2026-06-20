# uavros_ws

`uavros_ws` 是用于无人机仿真开发的 ROS Noetic 工作区，主要集成 Gazebo 模型、ArduPilot SITL 联动、模型生成任务和相关第三方 ROS 依赖。

推荐环境：

- Ubuntu 20.04 / WSL2 Ubuntu 20.04
- ROS Noetic
- Gazebo Classic 11
- ArduPilot SITL
- `catkin_tools`
- `task`
- `git-lfs`

## 仓库结构

```text
uavros_ws/
├── Taskfile.yml              # 模型 rsdf -> sdf 生成任务
├── readme.md                 # 当前工作区说明
└── src/
    ├── uav_simulator/        # 核心仿真模型、world、Gazebo 插件
    ├── mav_comm/             # MAV 消息相关依赖
    ├── rotors_simulator/     # RotorS 相关依赖
    ├── catkin_simple/        # catkin 辅助构建包
    └── glog_catkin/          # glog catkin 包
```

其中 `src/uav_simulator` 是核心子模块，包含：

```text
uav_simulator/
├── uav_gazebo/               # Gazebo 模型、world、launch
└── uav_gazebo_plugin/        # Gazebo 与 ArduPilot 通信插件
```

## 克隆仓库

推荐递归克隆，确保子模块一起下载：

```bash
git clone --recursive <repo-url> ~/uavros_ws
```

如果已经普通克隆，可以补拉子模块：

```bash
cd ~/uavros_ws
git submodule update --init --recursive
```

本仓库使用 Git LFS 管理部分较大的 STL 模型文件，首次使用前需要安装并拉取 LFS 对象：

```bash
sudo apt install -y git-lfs
git lfs install
git lfs pull
```

## 安装依赖

安装 ROS Noetic 和常用依赖：

```bash
sudo apt update
sudo apt install -y \
  ros-noetic-desktop-full \
  ros-noetic-joy \
  ros-noetic-octomap-ros \
  python3-catkin-tools \
  python3-wstool \
  protobuf-compiler \
  libgeographic-dev \
  ros-noetic-geographic-msgs \
  libgoogle-glog-dev
```

安装 ArduPilot 依赖请参考 ArduPilot 官方文档，也可以在 ArduPilot 仓库中执行：

```bash
Tools/environment_install/install-prereqs-ubuntu.sh -y
. ~/.profile
```

## 构建工作区

在工作区根目录执行：

```bash
cd ~/uavros_ws
catkin init
catkin build
source devel/setup.bash
```

建议写入 shell 配置：

```bash
echo "source ~/uavros_ws/devel/setup.bash" >> ~/.bashrc
```

如果模型路径没有通过 launch 自动设置，也可以手动添加：

```bash
export GAZEBO_MODEL_PATH=~/uavros_ws/src/uav_simulator/uav_gazebo/models:${GAZEBO_MODEL_PATH}
export GAZEBO_RESOURCE_PATH=~/uavros_ws/src/uav_simulator/uav_gazebo/worlds:${GAZEBO_RESOURCE_PATH}
```

## 模型生成任务

模型通常维护 `.rsdf` 模板，Gazebo 实际加载 `.sdf`。修改模型后需要重新生成。

常用命令：

```bash
cd ~/uavros_ws
task erb-pendulum_quadcopter:pendulum_quadcopter
task erb-usl_bicopter:usl_bicopter_multi
task erb-tilt_tricopter:tilt_tricopter
```

任务定义在 `Taskfile.yml`。新增模型时应同步补充对应生成任务。

## 启动 Gazebo

通用启动方式：

```bash
roslaunch uav_gazebo spawn.launch world_name:=<world_name>
```

示例：

```bash
roslaunch uav_gazebo spawn.launch world_name:=pendulum_quadcopter
roslaunch uav_gazebo spawn.launch world_name:=tilt_tricopter
roslaunch uav_gazebo spawn.launch world_name:=usl_bicopter
```

`world_name` 对应：

```text
src/uav_simulator/uav_gazebo/worlds/<world_name>.world
```

## 启动 ArduPilot SITL

以 Copter 为例：

```bash
cd <ardupilot>/ArduCopter
../Tools/autotest/sim_vehicle.py -v ArduCopter -f gazebo-iris --console --map
```

如果使用倒立摆四旋翼并需要圆杆 ODOMETRY 输入，可让 ArduPilot SERIAL2 作为 TCP server：

```bash
../Tools/autotest/sim_vehicle.py \
  -v ArduCopter \
  -f gazebo-iris \
  --console \
  --add-param=mav.parm \
  --add-param=pendulum.parm \
  -A "--serial2=tcp:14557"
```

Gazebo 侧 `PoleMavlinkPosePlugin` 会连接 `127.0.0.1:14557` 并发送圆杆 `ODOMETRY`。

## 倒立摆四旋翼

相关模型位于：

```text
src/uav_simulator/uav_gazebo/models/pendulum_quadcopter/
```

关键组成：

- `pendulum_quadcopter`：四旋翼总装模型
- `pendulum_quadcopter_base`：机体、机臂、顶部圆槽
- `pendulum_quadcopter_prop`：桨叶模型
- `pendulum_pole`：独立圆杆模型

相关插件：

- `PoleHoldReleasePlugin`：锁住、释放、重置圆杆
- `PoleMavlinkPosePlugin`：发送圆杆 MAVLink ODOMETRY

常用命令：

```bash
# 设置圆杆位置，NED 坐标，z 为负表示上方
rostopic pub /pendulum_pole/set_position_ned geometry_msgs/PointStamped "header:
  frame_id: 'local_ned'
point:
  x: 0.0
  y: 0.0
  z: -5.0" -1

# 释放圆杆
rostopic pub /pendulum_pole/unlock std_msgs/Bool "data: true" -1

# 重新锁住圆杆
rostopic pub /pendulum_pole/unlock std_msgs/Bool "data: false" -1
```

## 双旋翼模型

相关模型位于：

```text
src/uav_simulator/uav_gazebo/models/usl_bicopter/
```

启动示例：

```bash
roslaunch uav_gazebo spawn.launch world_name:=usl_bicopter
roslaunch uav_gazebo spawn.launch world_name:=usl_bicopter_multi
```

对应 Gazebo 插件为：

```text
ArduRotorBicopter
```

## 常见问题

### Gazebo 找不到模型

检查：

- 是否 `source ~/uavros_ws/devel/setup.bash`
- `GAZEBO_MODEL_PATH` 是否包含对应模型目录
- `spawn.launch` 是否已经把新增模型目录加入搜索路径
- `.rsdf` 是否已经重新生成 `.sdf`

### 修改模型后 Gazebo 没变化

Gazebo 不会自动重新加载已加载的模型和插件。修改模型或插件后通常需要：

```bash
task <对应模型生成任务>
catkin build uav_gazebo_plugin
```

然后重启 Gazebo 或重新 spawn 模型。

### 推送 GitHub 时提示超过 100MB

本仓库部分 STL 文件较大，必须使用 Git LFS。确认：

```bash
git lfs install
git lfs ls-files
```

如果历史中已有超过 100MB 的普通 Git 对象，需要通过 `git lfs migrate import` 迁移后再推送。

## 维护约定

- 修改模型优先改 `.rsdf`，再生成 `.sdf`。
- 新增模型后同步更新 `Taskfile.yml`。
- 新增模型目录后同步检查 `spawn.launch` 的模型搜索路径。
- 新增 Gazebo 插件后同步更新 `uav_gazebo_plugin/CMakeLists.txt`。
- 修改插件后运行：

```bash
catkin build uav_gazebo_plugin
```

- 子模块更新后，需要在主仓库提交新的子模块指针。
