#!/bin/bash
#

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
INSTALL_DIR=${1:-$(cd $SCRIPT_DIR/.. && pwd)/.local}
BIN_DIR="$INSTALL_DIR/bin"



echo_green() {
  local RED='\033[0;31m'
  local GREEN='\033[0;32m'
  local NC='\033[0m' # No Color
  printf "${GREEN}${*}${NC}\n"
}

echo_red() {
  local RED='\033[0;31m'
  local GREEN='\033[0;32m'
  local NC='\033[0m' # No Color
  printf "${RED}${@}${NC}\n"
}
check_yes_no() {
  echo_green "$@"
  while true
  do
    read yes_or_no
    [[ "$yes_or_no" =~ [nN].* ]] && exit
    [[ "$yes_or_no" =~ [yY].* ]] && break
  done
}



pkg_install() {
  if command -v pkg &> /dev/null; then
    echo_green termux-change-repo
    pkg up
    pkg install openssl openssh git tmux exa zsh  nodejs lua53 subversion fzf fd wget python
    ln -sf /data/data/com.termux/files/usr/bin/lua5.3 /data/data/com.termux/files/usr/bin/lua 
    termux-setup-storage
    mv ~/.termux termux
    ln -s ~/conf/termux .termux
    exit
  fi
}

install_node() {
  if [[ $(node -v) < 'v10.12' ]]; then
    echo_green "installing node"
    kernel="$(uname -s | tr '[A-Z]' '[a-z]')"
    arch="$(uname -m | tr '[A-Z]' '[a-z]')"
    case "$arch" in
      x86_64) node_arch=x64;;
      aarch64) node_arch=arm64;;
      *) node_arch=$arch;;
    esac
    tar_name=$(curl -fsSL https://nodejs.org/dist/latest/ | grep $kernel-$node_arch.tar.gz | head -1 | cut -f2 -d'"')
    if [ -n "$tar_name" ]; then
      wget https://nodejs.org/dist/latest/$tar_name && tar xzf $tar_name -C $INSTALL_DIR --strip-components 1
    else
      echo_red "can not find $kernel-$node_arch.tar.gz in https://nodejs.org/dist/latest/ " >& 2
    fi
  fi
}

install_zsh() {
  if [[ $(zsh --version | cut -f2 -d ' ') < '5.5' ]]; then
    echo_green "installing zsh"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/romkatv/zsh-bin/master/install)" -- -d $INSTALL_DIR -e no
  fi
}

install_vim8() {
  cmd="sudo apt install software-properties-common; sudo add-apt-repository ppa:jonathonf/vim; sudo apt update; sudo apt install -y vim"
  echo_green "$cmd"
  eval $cmd
}
apt_install() {
  pkg=${1}
  cmd=${2:-$pkg}
  ppa=${3}
  if [[ -n "$ppa" ]] && command -v $cmd &> /dev/null; then
    echo_green "$cmd installed"
    return 0
  fi
  echo_green "installing $cmd"
  [[ -n "$ppa" ]] && sudo add-apt-repository $ppa && sudo apt update
  sudo apt install -y $pkg || echo_red "apt $pkg install failed"
}

install_ubuntu_pkgs() {
  #install_vim8
  cmd="sudo apt install software-properties-common"
  echo_green "$cmd"
  $cmd
  apt_install vim vim ppa:jonathonf/vim
  apt_install lua5.3 && sudo ln -sf /usr/bin/lua5.3 $BIN_DIR/lua 
  apt_install unzip
  apt_install subversion svn
  apt_install git git ppa:git-core/ppa
  # cmd="sudo add-apt-repository ppa:git-core/ppa; sudo apt update; sudo apt install -y lua5.3 git subversion unzip; sudo ln -s /usr/bin/lua5.3 /usr/bin/lua"
  # echo_green "$cmd"
  # eval $cmd
}

install_nvim() {
  if command -v nvim &> /dev/null; then
    echo_green "nvim installed"
    return
  fi
  curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
  mv nvim.appimage $INSTALL_DIR/bin/nvim
  chmod u+x  $INSTALL_DIR/bin/nvim
}

install_lvim() {
  if command -v lvim &> /dev/null; then
    echo_green "lvim installed"
    return
  fi
  echo_green install luavim ..
  cmd="bash <(curl -s https://raw.githubusercontent.com/lunarvim/lunarvim/master/utils/installer/install.sh)"
  echo_green "$cmd"
  eval $cmd || exit 1

  mv $SCRIPT_DIR/lvim $SCRIPT_DIR/lvim.tpl
  mv $SCRIPT_DIR/lvim.bak $SCRIPT_DIR/lvim

  cmd="ln -s $BIN_DIR/lvim $BIN_DIR/vim"
  echo_green "$cmd"
  eval $cmd
}

install_miscs() {
  cmd="pip3 install thefuck"
  echo_green $cmd
  $cmd
}

install_go() {
  if command -v go &> /dev/null; then
    echo_green "go installed"
    return
  fi
  wget https://go.dev/dl/go1.19.4.linux-amd64.tar.gz
  rm -rf $INSTALL_DIR/go && tar -C $INSTALL_DIR -xzf go1.19.4.linux-amd64.tar.gz
  echo $INSTALL_DIR/go/bin >> ~/.path
}

update() {
  check_yes_no "install into $INSTALL_DIR ?"
  mkdir -p $INSTALL_DIR 
  mkdir -p $BIN_DIR

  echo $PATH | xargs -n1 -d':' | grep -q $BIN_DIR || echo 'export PATH="'$BIN_DIR':$PATH"' >> ~/.bashrc
  #[ -e ~/.zshenv ] && mv ~/.zshenv  ~/.zshenv.$(date +%s)
  cmd="source $SCRIPT_DIR/profile"
  cat ~/.zshenv | grep -q "$cmd" || echo "$cmd" >> ~/.zshenv
}

install_wsl() {
  if ! command -v wsl.exe &> /dev/null; then
    return
  fi
  echo_red 'wsl version , wsl -l -v; wsl --set-version Ubuntu-18.04 2'
  echo_red 'wsl, changeuser  ubuntu1804.exe config --default-user root'
}


 #update
 #install_ubuntu_pkgs
 #install_wsl
 #install_zsh
 #install_node
 #install_nvim
 #install_lvim
 install_go
 #install_miscs
