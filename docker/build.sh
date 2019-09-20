#!/usr/bin/env bash
BASEDIR=$(dirname "$0")

set -e

#########################################
#==========>     yums
#########################################
# { // yum

# https://unix.stackexchange.com/questions/182500/no-manual-entry-for-man
sed -i 's/^tsflags=nodocs/#&/' /etc/yum.conf

mv -f /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
curl -s -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo

yum localinstall -y --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-7.noarch.rpm

mv -f /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo.backup
mv -f /etc/yum.repos.d/epel-testing.repo /etc/yum.repos.d/epel-testing.repo.backup
curl -s -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo

yum makecache

yum install -y \
  autoconf \
  automake \
  curl-devel \
  expat-devel \
  gcc \
  gettext-devel \
  libevent-devel \
  make \
  man \
  ncdu \
  ncurses-devel \
  openssl-devel \
  perl-ExtUtils-CBuilder \
  perl-ExtUtils-Embed \
  perl-ExtUtils-ParseXS  \
  perl-ExtUtils-XSpp     \
  python-devel \
  python-pip \
  python36-devel \
  python36-pip \
  sudo \
  tree \
  unzip \
  wget \
  which  \
  zlib-devel

git config --system http.sslVerify false 
echo 'Defaults env_keep = "http_proxy https_proxy ftp_proxy DISPLAY XAUTHORITY"' >> /etc/sudoers
echo "check_certificate = off" >> /etc/wgetrc 
# }  // end yum


#########################################
#==========>     pip
#########################################
# { // pip

python_pkgs="bs4 delegator.py toolz tablib bidict"
echo -e "[global]\nindex-url = https://mirrors.aliyun.com/pypi/simple/\n\n[install]\ntrusted-host=mirrors.aliyun.com\n" > /etc/pip.conf 
pip install $python_pkgs unp click 
pip3 install $python_pkgs thefuck numpy pandas scipy scikit-learn matplotlib jupyter
# } // end pip

# zsh
#&&  wget https://github.com/zsh-users/zsh/archive/zsh-5.7.1.zip \
# && unp zsh-5.7.1.zip && cd zsh-zsh-5.7.1/ \
GIT_SSL_NO_VERIFY=true git clone --single-branch --depth 1 https://github.com/zsh-users/zsh.git \
 && cd zsh \
 && ./Util/preconfig \
 && ./configure --with-tcsetpgrp \
 && make \
 && make install && cd $BASEDIR 


# tmux
GIT_SSL_NO_VERIFY=true git clone --branch 2.6 --depth 1 https://github.com/tmux/tmux.git && \
  cd tmux && \
  sh autogen.sh && \
  ./configure && \
  make && make install && cd $BASEDIR 

GIT_SSL_NO_VERIFY=true git clone https://github.com/vim/vim.git \
 && cd vim \
 && CFLAGS="-I/usr/lib64/perl5/CORE/ -O2 -g" ./configure \
    --disable-gui \
    --with-features=huge \
    --enable-multibyte \
    --enable-pythoninterp=yes \
    --with-python-config-dir=$(python -c 'import sysconfig;print(sysconfig.get_config_var("LIBPL"))') \
    --enable-python3interp=yes \
    --with-python3-config-dir=$(python3 -c 'import sysconfig;print(sysconfig.get_config_var("LIBPL"))') \
    --enable-perlinterp=yes \
    --enable-luainterp=yes \
    --enable-rubyinterp=yes \
    --enable-cscope  && \
  cd src && \
  make && make install && cd $BASEDIR 

curl -o /usr/local/bin/tldr https://raw.githubusercontent.com/raylee/tldr/master/tldr \
	&& chmod +x /usr/local/bin/tldr 

sh -x ${BASEDIR}/install_github_latest.sh BurntSushi/ripgrep x86 linux musl \
  && mv ripgrep*/rg /usr/local/bin \
  && mv ripgrep*/doc/rg.1 /usr/local/share/man/man1  

sh -x ${BASEDIR}/install_github_latest.sh sharkdp/fd x86 linux musl \
  && mv fd*/fd /usr/local/bin \
  && mv fd*/fd.1 /usr/local/share/man/man1  

sh -x ${BASEDIR}/install_github_latest.sh junegunn/fzf-bin linux_386 \
  && mv fzf /usr/local/bin/ \
  && GIT_SSL_NO_VERIFY=true git clone --depth 1 https://github.com/junegunn/fzf.git \
  && mv fzf/bin/fzf-tmux /usr/local/bin/ \
  && mv fzf/man/man1/* /usr/local/share/man/man1  

# git
GIT_SSL_NO_VERIFY=true git clone -b 'v2.17.1' --single-branch  https://github.com/git/git.git 
yum remove -y git
cd git && make prefix=/usr install && cd $BASEDIR 
git config --system http.sslVerify false 

yum remove -y ncurses-devel curl-devel expat-devel gettext-devel libevent-devel ncurses-devel openssl-devel python-devel python36-devel
yum install -y ncurses curl expat gettext libevent ncurses openssl python python36
yum clean all
rm -rf /tmp/* 
rm -rf /var/cache 
find /usr -name "__pycache__" | xargs rm -rf 
find /usr -name "*.pyc" -delete 
