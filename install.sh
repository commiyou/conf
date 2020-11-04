#!/bin/bash

kernel="$(uname -s | tr '[A-Z]' '[a-z]')"
arch="$(uname -m | tr '[A-Z]' '[a-z]')"
INSTALL_DIR=~/.local/tmp

if [[ $(node -v) < 'v10.12' ]]; then
  case "$arch" in
    x86_64) node_arch=x64;;
    aarch64) node_arch=arm64;;
    *) node_arch=$arch;;
  esac
  mkdir -p $INSTALL_DIR && cd $INSTALL_DIR 
  wget https://nodejs.org/dist/latest/node-v*-$kernel-$node_arch.tar.gz && tar xzf node-v*-$kernel-$node_arch.tar.gz -C $INSTALL_DIR --strip-components 1
  #ln -s $INSTALL_DIR/node-v*-$kernel-$node_arch/bin/nodejs
fi

if [[ $(zsh --version | cut -f2 -d ' ') < '5.4' ]]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/romkatv/zsh-bin/master/install)" -- -d $INSTALL_DIR -e no
fi
