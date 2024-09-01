# 这是 cuda11.8 镜像，主要用于 tensorflow2.x
# 大小约 16 GB
# Q: 为什么需要 rm -rf /var/lib/apt/lists/* ？
# A: 减少镜像体积，参考 dockerfile 官方文档 https://docs.docker.com/develop/develop-images/instructions/#apt-get。
# 这条语句要放在每个 RUN 的最后，而不能偷懒只放在最后面的 RUN，因为镜像是按层构建的，只在最后做没有意义。
# 不过这个文件夹相对较小，apt update 后，/var/lib/apt/lists/ 大概 47M。
# Q: 为什么 pip 需要 --no-cache-dir ？
# A: 减少镜像体积，和删除 apt 缓存同理，尤其是针对 tensorflow 和 pytorch 这种比较大的包，很有用。

FROM nvcr.io/nvidia/cuda:12.1.1-cudnn8-devel-ubuntu22.04

MAINTAINER hanjiale@mail.ustc.edu.cn

SHELL ["/bin/bash", "-c"]

WORKDIR /root/

ENV DEBIAN_FRONTEND noninteractive
ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8

RUN rm /etc/apt/sources.list.d/cuda*.list && \
    # Use USTC source
    cp /etc/apt/sources.list /etc/apt/sources.list.hide && \
    sed -i "s@http://.*archive.ubuntu.com@http://mirrors.ustc.edu.cn@g" /etc/apt/sources.list && \
    sed -i "s@http://.*security.ubuntu.com@http://mirrors.ustc.edu.cn@g" /etc/apt/sources.list && \
    apt update && \
    apt upgrade -y && \
    rm -rf /var/lib/apt/lists/*

# Fix time zone
RUN apt update && \
    apt install -y tzdata --no-install-recommends && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo 'Asia/Shanghai' > /etc/timezone && \
    rm -rf /var/lib/apt/lists/*

# Install openssh
COPY .ssh/ /root/.ssh/
RUN apt update && \
    apt install -y openssh-server --no-install-recommends && \
    cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys && \
    chmod 600 /root/.ssh/authorized_keys /root/.ssh/id_rsa.pub /root/.ssh/id_rsa && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' \
        /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/g' \
        /etc/ssh/sshd_config && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/g' \
        /etc/ssh/sshd_config && \
    echo "root:Ustc1958" | chpasswd && \
    rm -rf /var/lib/apt/lists/*
EXPOSE 22

# Install zsh
ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8
COPY .oh-my-zsh/ /root/.oh-my-zsh/
RUN apt update && \
    apt install -y \
        zsh \
        git \
        --no-install-recommends && \
    cp /root/.oh-my-zsh/templates/zshrc.zsh-template /root/.zshrc && \
    sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/g' \
        /root/.zshrc && \
    echo -e "\n# locale" | tee -a /root/.zshrc /root/.bashrc && \
    echo "export LC_ALL=C.UTF-8" | tee -a /root/.zshrc /root/.bashrc && \
    echo "export LANG=C.UTF-8" | tee -a /root/.zshrc /root/.bashrc && \
    chsh -s $(which zsh) && \
    rm -rf /var/lib/apt/lists/*

# Install python3.11
RUN apt update && \
    apt install -y software-properties-common --no-install-recommends && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    sed -i 's/ppa.launchpad.net/launchpad.proxy.ustclug.org/g' /etc/apt/sources.list.d/*.list && \
    apt update && \
    apt install -y \
        python3.11 \
        python3.11-distutils \
        python3.11-dev \
        # Interactive when configuring tzdata, default time zone: 'Etc/UTC'
        # Fix for using color in matplotlib
        python3.11-tk \
        --no-install-recommends && \
    ln -fs python3.11 /usr/bin/python3 && \
    ln -fs python3.11 /usr/bin/python && \
    rm -rf /var/lib/apt/lists/*

# Install pip
RUN apt update && \
    apt install -y wget --no-install-recommends && \
    wget https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py && \
    # 清华源必备，速度很快
    pip config set global.index-url https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple && \
    rm get-pip.py && \
    rm -rf /var/lib/apt/lists/*

# Install atari
COPY Roms.rar /root/Roms.rar
RUN apt update && \
    apt install -y \
        wget \
        unrar \
        unzip \
        --no-install-recommends && \
    # wget http://www.atarimania.com/roms/Roms.rar && \
    unrar x Roms.rar && \
    pip install \
        # gym 已不再维护，迁移至 gymnasium
        gymnasium==0.29.1 \
        'gymnasium[atari]' \
        --no-cache-dir && \
    ale-import-roms ROMS/ && \
    rm Roms.rar && \
    rm -rf ROMS/ 'HC ROMS' && \
    rm -rf /var/lib/apt/lists/*

# Install mujoco
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/root/.mujoco/mujoco210/bin
COPY mujoco210-linux-x86_64.tar.gz /root/mujoco210-linux-x86_64.tar.gz
RUN apt update && \
    apt install -y wget --no-install-recommends && \
    # wget https://mujoco.org/download/mujoco210-linux-x86_64.tar.gz && \
    tar zxf mujoco210-linux-x86_64.tar.gz && \
    mkdir /root/.mujoco && \
    mv mujoco210/ /root/.mujoco/ && \
    echo -e "\n# mujoco" | tee -a /root/.zshrc /root/.bashrc && \
    echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/root/.mujoco/mujoco210/bin" \
        | tee -a /root/.zshrc /root/.bashrc && \
    apt install -y \
        libosmesa6-dev \
        libgl1-mesa-glx \
        libglfw3 \
        libglew-dev \
        patchelf \
        --no-install-recommends && \
    # ln -s /usr/lib/x86_64-linux-gnu/libGL.so.1 /usr/lib/x86_64-linux-gnu/libGL.so && \
    pip install \
        # gym 已不再维护，迁移至 gymnasium
        gymnasium==0.29.1 \
        # gymnasium[mujoco] 支持 v4
        'gymnasium[mujoco]' \
        --no-cache-dir && \
    pip install \
        # mujoco-py 支持 v3，已不再维护
        'mujoco-py<2.2,>=2.1' \
        # 为了编译 mujoco_py，需要降级 cython
        "cython<3" \
        --no-cache-dir && \
    # mujoco-py 第一次需要编译
    python -c 'import mujoco_py' && \
    rm mujoco210-linux-x86_64.tar.gz && \
    rm -rf /var/lib/apt/lists/*

# Install PIP tools
RUN apt update && \
    apt install -y \
        # CV2 required
        libgl1-mesa-glx \
        libglib2.0-dev \
        # Mpi4py required
        libopenmpi-dev \
        openmpi-bin \
        --no-install-recommends && \
    pip install \
        ipython \
        opencv-python \
        matplotlib \
        pandas \
        mpi4py \
        # 张量操作
        einops \
        # Fix sns.tsplot
        seaborn==0.8.1 \
        --no-cache-dir && \
    rm -rf /var/lib/apt/lists/*

# Install APT tools
RUN apt update && \
    apt install -y \
        vim \
        tmux \
        git \
        net-tools \
        unzip \
        cmake \
        gcc \
        g++ \
        htop \
        # Fix for wlt.sh
        curl \
        # Fix for `omz update`
        libssl-dev \
        iputils-ping \
        # fuser -v /dev/nvidia0
        psmisc \
        # 录制 GIF 等需要
        ffmpeg \
        --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Install jax
# torch 和 jax 对 nvidia_cudnn_cu12 这个 pip 依赖可能会冲突
RUN pip install \
        jax[cuda12]==0.4.28 \
        jaxlib \
        optax==0.2.1 \
        chex==0.1.84 \
        -f https://storage.googleapis.com/jax-releases/jax_cuda_releases.html \
        --no-cache-dir

# Install torch
# torch 和 jax 对 nvidia_cudnn_cu12 这个 pip 依赖可能会冲突
RUN pip install \
        torch==2.3.0 \
        torchvision==0.18.0 \
        --index-url https://download.pytorch.org/whl/cu121 \
        --no-cache-dir

# Install tensorflow
RUN pip install \
        tensorflow==2.16.2 \
        tensorboard==2.16.2 \
        tensorflow_probability \
        --no-cache-dir

# Install dreamerv3 environments
RUN pip install \
        crafter \
        dm_control \
        memory_maze \
        --no-cache-dir

# Install dreamerv3 dependencies
RUN pip install \
        cloudpickle \
        colored \
        gputil \
        msgpack \
        numpy \
        psutil \
        ruamel.yaml \
        zmq \
        --no-cache-dir

# Copy init.sh
COPY init.sh /root/init.sh
ENTRYPOINT ["/bin/zsh", "init.sh"]
