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

# Install go
# COPY go1.20.2.linux-amd64.tar.gz /root/go1.20.2.linux-amd64.tar.gz
# COPY v3.21.12 /root/v3.21.12
RUN apt update && \
    apt install -y wget && \
    wget https://dl.google.com/go/go1.20.2.linux-amd64.tar.gz && \
    tar -C /usr/local -zxf go1.20.2.linux-amd64.tar.gz && \
    echo -e "\n# go" | tee -a /root/.zshrc /root/.bashrc && \
    export GOROOT=/usr/local/go && \
    echo "export GOROOT=/usr/local/go" | tee -a /root/.zshrc /root/.bashrc && \
    export GOPATH=/root/go && \
    echo "export GOPATH=/root/go" | tee -a /root/.zshrc /root/.bashrc && \
    export PATH=$PATH:/usr/local/go/bin:/root/go/bin && \
    echo "export PATH=\$PATH:/usr/local/go/bin:/root/go/bin" | tee -a /root/.zshrc /root/.bashrc && \
    export GOPROXY=https://goproxy.cn && \
    echo "export GOPROXY=https://goproxy.cn" | tee -a /root/.zshrc /root/.bashrc && \
    # install protoc
    apt install -y autoconf automake libtool curl cmake make g++ unzip && \
    wget https://codeload.github.com/protocolbuffers/protobuf/tar.gz/refs/tags/v3.21.12 && \
    tar -zxf v3.21.12 && \
    cd protobuf-3.21.12 && \
    mkdir build && cd build && \
    cmake -Dprotobuf_BUILD_TESTS=OFF .. && \
    make -j32 && \
    # make check && \
    make install && \
    ldconfig && \
    protoc --version && \
    go install google.golang.org/protobuf/cmd/protoc-gen-go@latest && \
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest && \
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

# Fix k8s env
RUN sed -i '/^source $ZSH.*$/a export $(cat \/proc\/1\/environ |tr '\''\\0'\'' '\''\\n'\'' | xargs)' ~/.zshrc

# copy init.sh
COPY init.sh /root/init.sh

ENTRYPOINT ["/bin/zsh", "init.sh"]
