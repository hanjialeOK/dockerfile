FROM nvidia/cuda:10.0-cudnn7-devel-ubuntu18.04

MAINTAINER hanjiale@mail.ustc.edu.cn

SHELL ["/bin/bash", "-c"]

WORKDIR /root/

ENV DEBIAN_FRONTEND noninteractive
ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8

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
    apt install -y \
        python3.7 \
        python3.7-distutils \
        python3.7-dev \
        # Interactive when configuring tzdata, default time zone: 'Etc/UTC'
        # Fix for using color in matplotlib
        python3.7-tk \
        --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Install virtualenv & virtualenvwrapper`
RUN apt update && \
    apt install -y wget --no-install-recommends && \
    wget https://bootstrap.pypa.io/get-pip.py && \
    python3.7 get-pip.py && \
    pip install virtualenv virtualenvwrapper && \
    sed -i 's/which python/which python3.7/g' `which virtualenvwrapper.sh` && \
    echo -e "\n# virtualenvwrapper" | tee -a /root/.zshrc /root/.bashrc && \
    echo "export WORKON_HOME=/root/.virtualenvs" | tee -a /root/.zshrc /root/.bashrc && \
    echo "export VIRTUALENVWRAPPER_VIRTUALENV=`which virtualenv`" | tee -a /root/.zshrc /root/.bashrc && \
    echo "export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3.7" | tee -a /root/.zshrc /root/.bashrc && \
    echo "source `which virtualenvwrapper.sh`" | tee -a /root/.zshrc /root/.bashrc && \
    source `which virtualenvwrapper.sh` && \
    rm get-pip.py && \
    rm -rf /var/lib/apt/lists/*

# Create py37 and install tensorflow==1.15
RUN source `which virtualenvwrapper.sh` && \
    mkvirtualenv py37 && \
    workon py37 && \
    pip install \
        ipython \
        opencv-python \
        matplotlib \
        seaborn \
        pandas \
        tensorflow-gpu==1.15.5 \
        tensorflow-probability==0.8.0 \
        # Fix load_weights(xx.h5)
        h5py==2.10.0 && \
    deactivate && \
    apt update && \
    # cv2 required
    apt install -y \
        libgl1-mesa-glx \
        libglib2.0-dev \
        --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Install atari
RUN apt update && \
    apt install -y \
        wget \
        unrar \
        unzip \
        --no-install-recommends && \
    wget http://www.atarimania.com/roms/Roms.rar && \
    unrar e Roms.rar && \
    unzip ROMS.zip && \
    source `which virtualenvwrapper.sh` && \
    workon py37 && \
    pip install \
        gym \
        ale-py && \
    ale-import-roms ROMS/ && \
    deactivate && \
    rm *.zip *.rar && \
    rm -rf ROMS/ && \
    rm -rf /var/lib/apt/lists/*

# Install mujoco
COPY mujoco210-linux-x86_64.tar.gz /root/mujoco210-linux-x86_64.tar.gz
RUN apt update && \
    apt install -y wget --no-install-recommends && \
    # wget https://mujoco.org/download/mujoco210-linux-x86_64.tar.gz && \
    tar zxf mujoco210-linux-x86_64.tar.gz && \
    mkdir /root/.mujoco && \
    mv mujoco210/ /root/.mujoco/ && \
    echo -e "\n# mujoco" | tee -a /root/.zshrc /root/.bashrc && \
    # Fix duplicated values when source ~/zshrc.
    echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/root/.mujoco/mujoco210/bin" \
        | tee -a /root/.zshrc /root/.bashrc && \
    source `which virtualenvwrapper.sh` && \
    workon py37 && \
    pip install mujoco-py && \
    apt install -y \
        libosmesa6-dev \
        libgl1-mesa-glx \
        libglfw3 \
        libglew-dev \
        patchelf \
        --no-install-recommends && \
    # ln -s /usr/lib/x86_64-linux-gnu/libGL.so.1 /usr/lib/x86_64-linux-gnu/libGL.so && \
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/root/.mujoco/mujoco210/bin && \
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
        # Fix for `omz update`
        libssl-dev \
        iputils-ping \
        # fuser -v /dev/nvidia0
        psmisc \
        --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Requirements for framework
RUN source `which virtualenvwrapper.sh` && \
    workon py37 && \
    pip install \
        influxdb \
        psutil \
        pyzmq \
        pyarrow \
        scipy && \
    deactivate

# Install horovod
# Make sure that tensorflow has been installed!
RUN echo -e "\n# horovod" | tee -a /root/.zshrc /root/.bashrc && \
    echo "export HOROVOD_GPU_OPERATIONS=NCCL" | tee -a /root/.zshrc /root/.bashrc && \
    echo "export HOROVOD_WITH_TENSORFLOW=1" | tee -a /root/.zshrc /root/.bashrc && \
    export HOROVOD_GPU_OPERATIONS=NCCL && \
    export HOROVOD_WITH_TENSORFLOW=1 && \
    source `which virtualenvwrapper.sh` && \
    workon py37 && \
    pip install horovod && \
    deactivate

# copy init.sh
COPY init.sh /root/init.sh

ENTRYPOINT ["/bin/zsh", "init.sh"]
