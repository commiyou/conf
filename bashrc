# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi 
# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions

export ZDOTDIR=~/conf/zsh
# export https_proxy=
# export http_proxy=$https_proxy
# TERM=screen-256color

export PATH=$ZDOTDIR/bin:$PATH
source $ZDOTDIR/zsh.before/exports.zsh
source $SSHHOME/.sshrc
