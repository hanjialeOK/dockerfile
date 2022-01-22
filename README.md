# Docker

download this repo **on your remote server**

```c
git clone git@github.com:hanjialeOK/dockerfile.git docker
cd docker
```

copy your .ssh/

```c
cp ~/.ssh ./
```

download zsh

```c
git clone git@github.com:ohmyzsh/ohmyzsh.git .oh-my-zsh
git clone git@github.com:zsh-users/zsh-autosuggestions.git
git clone git@github.com:zsh-users/zsh-syntax-highlighting.git
cp -r zsh-autosuggestions zsh-syntax-highlighting .oh-my-zsh/custom/plugins/
```

download mujoco

```c
wget https://mujoco.org/download/mujoco210-linux-x86_64.tar.gz
```

build image

```c
docker build -t hanjl/cuda:framework -f tf1.dockerfile .
```

run

```c
docker run -it -v /data2/hanjl:/root/code/ \
    -p 0.0.0.0:2200:22 -p 0.0.0.8000:80 \
    --gpus all --name framework \
    hanjl/cuda:framework
```

work

```c
workon py37
```