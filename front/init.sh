#!/bin/zsh
git config --global user.email "hanjiale@mail.ustc.edu.cn"
git config --global user.name "韩佳乐"
service ssh restart
echo "hello!"
exec zsh
