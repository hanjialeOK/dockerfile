#!/bin/zsh
source `which virtualenvwrapper.sh`
git config --global user.email "hanjiale@mail.ustc.edu.cn"
git config --global user.name "hanjiale"
service ssh restart
echo "hello!"
exec zsh
