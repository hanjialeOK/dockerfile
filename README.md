# Dockerfile

clone this repo

```c
git clone git@github.com:hanjialeOK/dockerfile.git dockerbuild
```

copy your .ssh/

```c
cd dockerbuild
mkdir .ssh/
cp ~/.ssh/id_rsa ~/.ssh/id_pub.pub .ssh/
```

clone zsh

```c
cd dockerbuild
git clone git@github.com:ohmyzsh/ohmyzsh.git .oh-my-zsh
git clone git@github.com:zsh-users/zsh-autosuggestions.git
git clone git@github.com:zsh-users/zsh-syntax-highlighting.git
cp -r zsh-autosuggestions zsh-syntax-highlighting .oh-my-zsh/custom/plugins/
```

build

```c
cd dockerbuild
docker build -t hanjl/cuda:10.0-ubu18-rl-zsh -f tf1.dockerfile .
```

run

```c
docker run -it -v /data2/hanjl:/root/code/ \
    -p 0.0.0.0:2200:22 -p 0.0.0.8000:80 \
    --gpus all --name hanjl_test \
    hanjl/cuda:10.0-ubu18-rl-zsh
```

download tensorflow

```c
workon py37
pip install tensorflow-gpu==1.15
```