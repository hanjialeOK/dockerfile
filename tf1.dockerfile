FROM nvidia/cuda:10.0-cudnn7-devel-ubuntu18.04

MAINTAINER hanjiale@mail.ustc.edu.cn

SHELL ["/bin/bash", "-c"]

WORKDIR /root/

ENV DEBIAN_FRONTEND noninteractive
ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8

# Update key for nvidia repo
RUN rm /etc/apt/sources.list.d/cuda.list && \
    rm /etc/apt/sources.list.d/nvidia-ml.list && \
    apt-key del 7fa2af80 && \
    apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/3bf863cc.pub && \
    apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64/7fa2af80.pub && \
    # Use USTC source
    cp /etc/apt/sources.list /etc/apt/sources.list.hide && \
    sed -i "s@http://.*archive.ubuntu.com@http://mirrors.ustc.edu.cn@g" /etc/apt/sources.list && \
    sed -i "s@http://.*security.ubuntu.com@http://mirrors.ustc.edu.cn@g" /etc/apt/sources.list

# Install openssh
COPY .ssh/ /root/.ssh/
RUN apt update && \
    apt install -y openssh-server --no-install-recommends && \
    cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys && \
    chmod 600 /root/.ssh/authorized_keys /root/.ssh/id_rsa.pub /root/.ssh/id_rsa && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' \
        /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' \
        /etc/ssh/sshd_config && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/g' \
        /etc/ssh/sshd_config && \
    rm -rf /var/lib/apt/lists/*
EXPOSE 22
EXPOSE 80

# Install zsh
COPY .oh-my-zsh/ /root/.oh-my-zsh/
RUN apt update && \
    apt install -y zsh --no-install-recommends && \
    cp /root/.oh-my-zsh/templates/zshrc.zsh-template /root/.zshrc && \
    sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/g' \
        /root/.zshrc && \
    echo -e "\n# locale" | tee -a /root/.zshrc /root/.bashrc && \
    echo "export LC_ALL=C.UTF-8" | tee -a /root/.zshrc /root/.bashrc && \
    echo "export LANG=C.UTF-8" | tee -a /root/.zshrc /root/.bashrc && \
    chsh -s $(which zsh) && \
    rm -rf /var/lib/apt/lists/*

# Install python3.7
RUN apt update && \
    apt install -y software-properties-common --no-install-recommends && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    sed -i 's/ppa.launchpad.net/launchpad.proxy.ustclug.org/g' /etc/apt/sources.list.d/*.list && \
    apt update && \
    apt install -y \
        python3.7 \
        python3.7-distutils \
        python3.7-dev \
        # Interactive when configuring tzdata, default time zone: 'Etc/UTC'
        # Fix for using color in matplotlib
        python3.7-tk \
        --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Install virtualenv & virtualenvwrapper
ENV WORKON_HOME /root/.virtualenvs
ENV VIRTUALENVWRAPPER_VIRTUALENV /usr/local/bin/virtualenv
ENV VIRTUALENVWRAPPER_PYTHON /usr/bin/python3.7
RUN apt update && \
    apt install -y wget --no-install-recommends && \
    wget https://bootstrap.pypa.io/get-pip.py && \
    python3.7 get-pip.py && \
    pip config set global.index-url https://mirror.baidu.com/pypi/simple && \
    pip install \
        # importlib-metadata releases v5.0.0 which it remove deprecated endpoint.
        importlib-metadata==4.13.0 \
        virtualenv \
        virtualenvwrapper && \
    echo -e "\n# virtualenvwrapper" | tee -a /root/.zshrc /root/.bashrc && \
    echo "export WORKON_HOME=/root/.virtualenvs" | tee -a /root/.zshrc /root/.bashrc && \
    echo "export VIRTUALENVWRAPPER_VIRTUALENV=`which virtualenv`" | tee -a /root/.zshrc /root/.bashrc && \
    echo "export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3.7" | tee -a /root/.zshrc /root/.bashrc && \
    echo "source `which virtualenvwrapper.sh`" | tee -a /root/.zshrc /root/.bashrc && \
    rm get-pip.py && \
    source `which virtualenvwrapper.sh` && \
    mkvirtualenv py37 && \
    pip install \
        # The latest protobuf is not compatible with tensorflow and horovod
        protobuf==3.20.1 \
        # Fix gym.
        # importlib-metadata releases v5.0.0 which it remove deprecated endpoint.
        importlib-metadata==4.13.0 && \
    deactivate && \
    rm -rf /var/lib/apt/lists/*

# Install tensorflow==1.15
RUN apt update && \
    apt install -y \
        # CV2 required
        libgl1-mesa-glx \
        libglib2.0-dev \
        # Mpi4py required
        libopenmpi-dev \
        openmpi-bin \
        --no-install-recommends && \
    source `which virtualenvwrapper.sh` && \
    workon py37 && \
    pip install \
        ipython \
        opencv-python \
        matplotlib \
        pandas \
        mpi4py \
        tensorflow-gpu==1.15.5 \
        # Fix sns.tsplot
        seaborn==0.8.1 \
        # Fix load_weights(xx.h5)
        h5py==2.10.0 && \
    deactivate && \
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
    source `which virtualenvwrapper.sh` && \
    workon py37 && \
    pip install \
        # gym<=0.19.0: gym[atari]=atari-py, python -m atari_py.import_roms ROMS/
        # gym==0.20.0: gym[atari]=ale-py, module 'ale_py.gym' has no attribute 'ALGymEnv'
        # gym==0.21.0: gym[atari]=ale-py, perfect!
        # gym>=0.22.0: gym[atari]=ale-py, warnings...
        # https://github.com/mgbellemare/Arcade-Learning-Environment#openai-gym
        # https://github.com/openai/gym
        gym==0.21.0 \
        # ale-py \
        'gym[box2d]' \
        'gym[atari]' && \
    ale-import-roms ROMS/ && \
    deactivate && \
    rm Roms.rar && \
    rm -rf ROMS/ 'HC ROMS' && \
    rm -rf /var/lib/apt/lists/*

# Install mujoco
# ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/root/.mujoco/mujoco210/bin
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
    source `which virtualenvwrapper.sh` && \
    workon py37 && \
    export LD_LIBRARY_PATH=/root/.mujoco/mujoco210/bin && \
    # gym<=0.16.0: float32 warning...
    # gym<=0.21,>0.16: perfect!
    # gym<0.24,>=0.22: v3 warning...
    # gym>=0.24: pip install 'gym[mujoco]', https://github.com/openai/gym
    # https://github.com/openai/mujoco-py#install-and-use-mujoco-py
    pip install 'mujoco-py<2.2,>=2.1' && \
    python -c 'import mujoco_py' && \
    deactivate && \
    rm mujoco210-linux-x86_64.tar.gz && \
    rm -rf /var/lib/apt/lists/*

# Install necessary tools
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
        # Fix for wlt.sh
        curl \
        # Fix for `omz update`
        libssl-dev \
        iputils-ping \
        # fuser -v /dev/nvidia0
        psmisc \
        --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# # # Requirements for framework
# # RUN source `which virtualenvwrapper.sh` && \
# #     workon py37 && \
# #     pip install \
# #         influxdb \
# #         psutil \
# #         pyzmq \
# #         pyarrow \
# #         scipy && \
# #     deactivate

# # # Install horovod
# # # Make sure that tensorflow has been installed!
# # ENV HOROVOD_GPU_OPERATIONS NCCL
# # ENV HOROVOD_WITH_TENSORFLOW 1
# # RUN echo -e "\n# horovod" | tee -a /root/.zshrc /root/.bashrc && \
# #     echo "export HOROVOD_GPU_OPERATIONS=NCCL" | tee -a /root/.zshrc /root/.bashrc && \
# #     echo "export HOROVOD_WITH_TENSORFLOW=1" | tee -a /root/.zshrc /root/.bashrc && \
# #     source `which virtualenvwrapper.sh` && \
# #     workon py37 && \
# #     pip install horovod && \
# #     deactivate

# copy init.sh
COPY init.sh /root/init.sh

ENTRYPOINT ["/bin/zsh", "init.sh"]
