FROM nvidia/cuda:10.0-cudnn7-devel-ubuntu18.04

MAINTAINER Jiale Han

SHELL ["/bin/bash", "-c"]

WORKDIR /root/

ENV LANG C.UTF-8

RUN apt update

# openssh conf
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

# zsh conf
COPY .oh-my-zsh/ /root/.oh-my-zsh/

RUN apt install -y zsh --no-install-recommends && \
    cp /root/.oh-my-zsh/templates/zshrc.zsh-template /root/.zshrc && \
    sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/g' \
        /root/.zshrc && \
    echo -e "\n# locale" >> /root/.zshrc && \
    echo "export LANG=C.UTF-8" >> /root/.zshrc && \
    chsh -s $(which zsh) && \
    apt clean

# python conf
RUN apt install -y \
        software-properties-common \
        wget \
        --no-install-recommends && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    apt install -y \
        python3.7 \
        python3.7-distutils \
        python3.7-dev \
        --no-install-recommends && \
    # install virtualenv & virtualenvwrapper
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
    rm get-pip.py && \
    apt clean

# gym conf
COPY ROMS/ /root/ROMS/

RUN source `which virtualenvwrapper.sh` && \
    mkvirtualenv py37 && \
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
    rm -rf ROMS/ && \
    apt clean

# necessary 
RUN apt install -y \
        vim \
        tmux \
        git \
        net-tools \
        --no-install-recommends && \
    apt clean

# copy init.sh
COPY init.sh /root/init.sh

ENTRYPOINT ["/bin/zsh", "init.sh"]