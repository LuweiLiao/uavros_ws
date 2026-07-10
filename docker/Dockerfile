FROM osrf/ros:noetic-desktop-full

ARG USER_ID=1000
ARG GROUP_ID=1000
ARG USERNAME=ros

ENV DEBIAN_FRONTEND=noninteractive \
    ROS_DISTRO=noetic \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# ROS Noetic + Gazebo Classic + uavros_ws build/runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    git \
    git-lfs \
    libeigen3-dev \
    libgeographic-dev \
    libgoogle-glog-dev \
    libprotobuf-dev \
    libyaml-cpp-dev \
    # Required by VRPN (getprotobyname); missing in some slim images
    netbase \
    protobuf-compiler \
    python3-catkin-tools \
    python3-pip \
    python3-rosdep \
    python3-vcstool \
    python3-wstool \
    ruby \
    sudo \
    wget \
    && apt-get install -y --no-install-recommends \
    ros-noetic-cv-bridge \
    ros-noetic-gazebo-ros-pkgs \
    ros-noetic-geographic-msgs \
    ros-noetic-joy \
    ros-noetic-mavros \
    ros-noetic-mavros-extras \
    ros-noetic-mavlink \
    ros-noetic-octomap-ros \
    ros-noetic-octomap-msgs \
    ros-noetic-xacro \
    ros-noetic-tf \
    ros-noetic-tf2-ros \
    ros-noetic-dynamic-reconfigure \
    ros-noetic-image-transport \
    ros-noetic-robot-state-publisher \
    ros-noetic-vrpn \
    ros-noetic-vrpn-client-ros \
    geographiclib-tools \
    && rm -rf /var/lib/apt/lists/*

# MAVROS requires GeographicLib geoid model (egm96-5.pgm)
RUN /opt/ros/noetic/lib/mavros/install_geographiclib_datasets.sh

# Task runner for rsdf -> sdf generation (Taskfile.yml)
RUN sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin

RUN git lfs install --system

# Match host UID/GID so bind-mounted workspace keeps correct ownership
RUN groupadd -g ${GROUP_ID} ${USERNAME} \
    && useradd -m -u ${USER_ID} -g ${GROUP_ID} -s /bin/bash ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

COPY docker/ros_entrypoint.sh /ros_entrypoint.sh
RUN chmod +x /ros_entrypoint.sh

USER ${USERNAME}
WORKDIR /home/${USERNAME}/uavros_ws

ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["bash"]
