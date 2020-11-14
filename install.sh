#!/bin/bash

if command -v pkg &> /dev/null; then
  pkg install tmux exa zsh  nodejs lua53 subversion
 ln -s /data/data/com.termux/files/usr/bin/lua5.3 /data/data/com.termux/files/usr/bin/lua 
  exit
fi
kernel="$(uname -s | tr '[A-Z]' '[a-z]')"
arch="$(uname -m | tr '[A-Z]' '[a-z]')"
INSTALL_DIR=~/.local

if [[ $(node -v) < 'v10.12' ]]; then
  case "$arch" in
    x86_64) node_arch=x64;;
    aarch64) node_arch=arm64;;
    *) node_arch=$arch;;
  esac
  mkdir -p $INSTALL_DIR && cd $INSTALL_DIR 
  tar_name=$(curl -fsSL https://nodejs.org/dist/latest/ | grep $kernel-$node_arch.tar.gz | head -1 | cut -f2 -d'"')
  if [ -n "$tar_name" ]; then
    wget https://nodejs.org/dist/latest/$tar_name && tar xzf $tar_name -C $INSTALL_DIR --strip-components 1
  else
    echo "can not find $kernel-$node_arch.tar.gz in https://nodejs.org/dist/latest/ " >& 2
  fi
fi

if [[ $(zsh --version | cut -f2 -d ' ') < '5.5' ]]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/romkatv/zsh-bin/master/install)" -- -d $INSTALL_DIR -e no
fi

if ! command -v svn &> /dev/null; then
  if command -v apt-get &> /dev/null; then
    echo sudo apt-get install subversion
  elif command -v yum &> /dev/null; then
    echo sudo yum install subversion
  else
    echo no subversion, should install...
  fi

fi
echo 'export PATH="/data1/youbin/.local/bin/bin:$PATH"' >> ~/.bashrc


