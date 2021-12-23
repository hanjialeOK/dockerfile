FROM nvidia/cuda:10.0-cudnn7-devel-ubuntu18.04

MAINTAINER Jiale Han

SHELL ["/bin/bash", "-c"]

WORKDIR /root/

ENV LANG C.UTF-8

RUN apt update

# install openssh
COPY .ssh/ /root/.ssh/

RUN apt install -y openssh-server --no-install-recommends && \
    cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys && \
    chmod 600 /root/.ssh/authorized_keys /root/.ssh/id_rsa.pub /root/.ssh/id_rsa && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' \
        /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' \
        /etc/ssh/sshd_config && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/g' \
        /etc/ssh/sshd_config && \
    apt clean

EXPOSE 22
EXPOSE 80

# install zsh
COPY .oh-my-zsh/ /root/.oh-my-zsh/

RUN apt install -y zsh --no-install-recommends && \
    cp /root/.oh-my-zsh/templates/zshrc.zsh-template /root/.zshrc && \
    sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/g' \
        /root/.zshrc && \
    echo -e "\n# locale" >> /root/.zshrc && \
    echo "export LANG=C.UTF-8" >> /root/.zshrc && \
    chsh -s $(which zsh) && \
    apt clean

# install python3.7
RUN apt update && \
    apt install -y software-properties-common --no-install-recommends && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    apt install -y \
        python3.7 \
        python3.7-distutils \
        python3.7-dev \
        --no-install-recommends

# install virtualenv & virtualenvwrapper`
RUN apt update && \
    apt install -y wget --no-install-recommends && \
    wget https://bootstrap.pypa.io/get-pip.py && \
    python3.7 get-pip.py && \
    pip install virtualenv virtualenvwrapper && \
    sed -i 's/which python/which python3.7/g' `which virtualenvwrapper.sh` && \
    # virtualenvwrapper >> zshrc
    echo -e "\n# virtualenvwrapper" >> /root/.zshrc && \
    echo "export WORKON_HOME=/root/.virtualenvs" >> /root/.zshrc && \
    echo "export VIRTUALENVWRAPPER_VIRTUALENV=`which virtualenv`" >> /root/.zshrc && \
    echo "export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3.7" >> /root/.zshrc && \
    echo "source `which virtualenvwrapper.sh`" >> /root/.zshrc && \
    source `which virtualenvwrapper.sh` && \
    mkvirtualenv py37 && \
    deactivate && \
    rm get-pip.py && \
    apt clean

# install atari
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
        opencv-python \
        matplotlib \
        ipython \
        gym \
        ale-py && \
    ale-import-roms ROMS/ && \
    deactivate && \
    # fix for cv2
    apt install -y \
        libgl1-mesa-glx \
        libglib2.0-dev \
        --no-install-recommends && \
    rm *.zip *.rar && \
    rm -rf ROMS/ && \
    apt clean

# install mujoco
RUN apt update && \
    apt install -y wget --no-install-recommends && \
    wget https://mujoco.org/download/mujoco210-linux-x86_64.tar.gz && \
    tar zxf mujoco210-linux-x86_64.tar.gz && \
    mkdir /root/.mujoco && \
    mv mujoco210/ /root/.mujoco/ && \
    echo -e "\n# mujoco" >> /root/.zshrc && \
    echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/root/.mujoco/mujoco210/bin" \
        >> /root/.zshrc && \
    source `which virtualenvwrapper.sh` && \
    workon py37 && \
    pip install mujoco-py && \
    deactivate && \
    apt install -y \
        libosmesa6-dev \
        libgl1-mesa-glx \
        libglfw3 \
        patchelf \
        --no-install-recommends && \
    ln -s /usr/lib/x86_64-linux-gnu/libGL.so.1 /usr/lib/x86_64-linux-gnu/libGL.so && \
    workon py37 && \
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/root/.mujoco/mujoco210/bin && \
    python -c 'import mujoco_py' && \
    deactivate && \
    rm mujoco210-linux-x86_64.tar.gz && \
    apt clean

# install other tools 
RUN apt update && \
    apt install -y \
        vim \
        tmux \
        git \
        net-tools \
        unzip \
        --no-install-recommends && \
    apt clean

# copy init.sh
COPY init.sh /root/init.sh

ENTRYPOINT ["/bin/zsh", "init.sh"]