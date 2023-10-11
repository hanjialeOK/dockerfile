FROM ubuntu:20.04

MAINTAINER hanjiale@mail.ustc.edu.cn

SHELL ["/bin/bash", "-c"]

WORKDIR /root/

ENV DEBIAN_FRONTEND noninteractive
ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8

# Use USTC source
RUN cp /etc/apt/sources.list /etc/apt/sources.list.hide && \
    sed -i "s@http://.*archive.ubuntu.com@http://mirrors.ustc.edu.cn@g" /etc/apt/sources.list && \
    sed -i "s@http://.*security.ubuntu.com@http://mirrors.ustc.edu.cn@g" /etc/apt/sources.list

# Install openssh
RUN apt update && \
    apt install -y openssh-server --no-install-recommends && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' \
        /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/g' \
        /etc/ssh/sshd_config && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' \
        /etc/ssh/sshd_config && \
    echo "root:K8s1958" | chpasswd && \
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

# Install nodejs
# https://github.com/nodesource/distributions
RUN apt update && \
    apt install -y ca-certificates curl gnupg && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    export NODE_MAJOR=18 && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    apt update && \
    apt install nodejs -y && \
    rm -rf /var/lib/apt/lists/*

# Install necessary tools
RUN apt update && \
    apt install -y \
        vim \
        tmux \
        git \
        wget \
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

# NPM 反向代理使用
# https://mirrors.ustc.edu.cn/help/npm.html
RUN echo "registry=https://npmreg.proxy.ustclug.org/" > ~/.npmrc

# Fix time zone
RUN apt update && \
    apt install -y tzdata && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo 'Asia/Shanghai' > /etc/timezone && \
    rm -rf /var/lib/apt/lists/*

# Copy init.sh
COPY init.sh /root/init.sh

ENTRYPOINT ["/bin/zsh", "init.sh"]
