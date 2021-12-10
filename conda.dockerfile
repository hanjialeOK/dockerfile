FROM nvidia/cuda:10.0-cudnn7-devel-ubuntu18.04

MAINTAINER Jiale Han

SHELL ["/bin/bash","-c"]

WORKDIR /root

RUN apt update \
    && apt install -y vim cmake tmux wget git g++ \
    && wget https://repo.anaconda.com/miniconda/Miniconda3-py37_4.10.3-Linux-x86_64.sh \
    && echo -e "\nexport export HOROVOD_GPU_OPERATIONS=NCCL" >> .bashrc \
    && apt install -y libgl1-mesa-glx libglib2.0-dev\
    && apt clean \