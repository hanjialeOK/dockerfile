# Docker

## Install

Download this repo.

```c
git clone git@github.com:hanjialeOK/dockerfile.git docker
cd docker
```

Copy .ssh/

```c
cp ~/.ssh ./
```

Download zsh

```c
git clone git@github.com:ohmyzsh/ohmyzsh.git .oh-my-zsh
git clone git@github.com:zsh-users/zsh-autosuggestions.git
git clone git@github.com:zsh-users/zsh-syntax-highlighting.git
cp -r zsh-autosuggestions zsh-syntax-highlighting .oh-my-zsh/custom/plugins/
```

Download mujoco

```c
wget https://mujoco.org/download/mujoco210-linux-x86_64.tar.gz
```

Download atari

```c
wget http://www.atarimania.com/roms/Roms.rar
```

Build image

```c
docker build -t hanjl/framework:latest -f tf1.dockerfile .
```

Run

```c
docker run -it --gpus all -v /data/hanjl:/data/hanjl/ -p 0.0.0.0:2200:22 -p 0.0.0.0:1000:1000 -p 0.0.0.0:1001:1001 -p 0.0.0.0:1002:1002 -p 0.0.0.0:1003:1003 --name framework hanjl/framework:latest
```

Virtualenv

```c
workon py37
```

Remote ssh

```c
ssh root@ip -p 2200
```

## Common commands

codebase

```c
CUDA_VISIBLE_DEVICES=0 PYTHONWARNINGS=ignore python run_pg_mujoco.py --alg GeDISC --env Swimmer-v2 --total_steps 1e6
zsh run_pg_mujoco.sh GePPO HumanoidStandup-v2 GePPO_baseline 10e6
zsh run_pg_mujoco_all.sh GePPO GePPO_baseline 3e6
zsh rm_dir.sh /data/hanjl/my_results DISC_baseline
```

plot

```c
python /data/hanjl/rl-exercise/common/plot.py --logdir /data/hanjl/my_results/Ant-v2/DISC_test11_8 --legend 'our disc' --xaxis 'train/timesteps' --value 'train/avgepret' --smooth 16 --count
python /data/hanjl/rl-exercise/common/plot_all.py --logdir my_results --xaxis 'train/timesteps' --value 'train/avgepret' --smooth 16
```

kill nvidia

```c
kill $(fuser -v /dev/nvidia0)
kill $(fuser -v /dev/nvidia1)
```
