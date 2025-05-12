# 配置步骤      

**注意注意：这里推荐在`WSL2`中使用Ubuntu20.04，WSL2配置可参考CSDN** 
   
1. 下载源码     
   [注意]: 首先`fork` src文件夹下面的uav_simulator.  
   然后 `git clone https://github.com/Luviewer/uavros_ws.git --recursive` 注意，需要递归克隆子模块，如果克隆不下来，可能是网络的问题
2. 安装`ROS` [这里请安装ros-noetic]  
   1) 参考官方安装环境：http://wiki.ros.org/      
   2) 使用“鱼香ROS”一键安装环境（推荐） [鱼香ROS](https://blog.csdn.net/qq_27865227/article/details/120191557?ops_request_misc=%257B%2522request%255Fid%2522%253A%252214476310f536396c2a7afbc2bce00965%2522%252C%2522scm%2522%253A%252220140713.130102334.pc%255Fblog.%2522%257D&request_id=14476310f536396c2a7afbc2bce00965&biz_id=0&utm_medium=distribute.pc_search_result.none-task-blog-2~blog~first_rank_ecpm_v1~rank_v31_ecpm-2-120191557-null-null.nonecase&utm_term=ros%E5%AE%89%E8%A3%85&spm=1018.2226.3001.4450)

3. 安装`uavros_ws`环境    
    步骤如下:  
    >`sudo apt-get install ros-noetic-desktop-full ros-noetic-joy ros-noetic-octomap-ros python3-wstool python3-catkin-tools protobuf-compiler`      

    >`sudo apt-get install libgeographic-dev ros-noetic-geographic-msgs  # Required for mavros.`     

    >`sudo apt-get install libgoogle-glog-dev`  

    >`cd ~/uavros_ws/src`

    >`catkin_init_workspace`    

    >`wstool init`

    >`cd ~/uavros_ws`

    >`catkin init  # If you haven't done this before. `
    
    >`catkin build`

    最后配置环境变量：

    >`echo "source ~/uavros_ws/devel/setup.bash" >> ~/.bashrc`    

    >`echo "export GAZEBO_MODEL_PATH=~/uavros_ws/src/uav_simulator/uav_gazebo/models:${GAZEBO_MODEL_PATH}" >> ~/.bashrc`  

    >`echo "export GAZEBO_RESOURCE_PATH=~/uavros_ws/src/uav_simulator/uav_gazebo/worlds:${GAZEBO_RESOURCE_PATH}" >> ~/.bashrc`    

    >`source ~/.bashrc`

4. 安装ardupilot            
    参考: https://ardupilot.org/dev/index.html      
    1. 在任意位置下载源码:        
    `git clone https://github.com/Luviewer/ardupilot.git --recursive`     
    2. 安装ardupilot环境        
    `cd ardupilot`      
    `Tools/environment_install/install-prereqs-ubuntu.sh -y`        
    `. ~/.profile`

5. 安装VSCODE
   
6. 运行仿真   
   `roslaunch uav_gazebo spawn.launch world_name:=tsduav_quad`  其中，world_name:= 后面需要具体的机型参数，可选的机型在`src/uav_simulator/uav_gazebo/worlds`路径下面  
   `~/xx/ardupilot/ArduCopter/../Tools/autotest/sim_vehicle.py -f gazebo-iris --console` xx为`ardupilot`路径

#
`uav_simulator` 是gazeb模型核心仓库，更深入学习可参考`https://gitee.com/Luviewer/uav_simulator.git`    
飞控代码建议fork仓库：`https://gitee.com/Luviewer/ardupilot`