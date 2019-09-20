umask 0022

[ -z $TERM ] && export TERM=screen-256color
export LC_ALL=en_US.UTF-8
export LANG=$LC_ALL
export HISTFILE=$ZDOTDIR/.zsh_history

# display ansi color
export LESS='-R'
#if (( $+commands[pygmentize] ));
#then
  #export LESSOPEN='|pygmentize -g %s'
#fi
#export PYGMENTIZE_STYLE='monokai'

unset LESSCHARSET
# Highlight section titles in manual pages.
export LESS_TERMCAP_md="${yellow}";

# Don’t clear the screen after quitting a manual page.
# export MANPAGER='less -X';

unset WGETRC
[ -f $ZDOTDIR/../wgetrc ] && wget -h | grep PFS >/dev/null 2>&1 && export WGETRC=$ZDOTDIR/../wgetrc
unset CURL_HOME
[ -f $ZDOTDIR/../curlrc ] && export CURL_HOME=$ZDOTDIR/..

# TODO
export ZSH_CACHE_DIR=$ZDOTDIR/.cache
[ -d $ZSH_CACHE_DIR ] || mkdir -p $ZSH_CACHE_DIR

# ssh TODO
[[ -f ${ZDOTDIR}/ssh/id_rsa ]] && export SSH_KEY_PATH=${ZDOTDIR}/ssh/id_rsa && export GIT_SSH=${ZDOTDIR}/ssh/gitwrap.sh

export EDITOR=vim

unset TMOUT

# pip install cheat
export DEFAULT_CHEAT_DIR=$(cd ${ZDOTDIR}/.. && pwd)/cheat
export CHEATCOLORS=true

# no .pyc file
export PYTHONDONTWRITEBYTECODE=1

export PYTHONIOENCODING='UTF-8'
export PYTHONPATH='.'

# python better exceptions
export BETTER_EXCEPTIONS=1

export MYNAME=$(cd $ZDOTDIR; git config user.name)
export MYEMAIL=$(cd $ZDOTDIR; git config user.email)

export WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'

export GROUP=$USER
export USER_ID=$(id -u $USER)
export GROUP_ID=$(id -g $USER)

export CONF_DIR=$(cd $ZDOTDIR/..;pwd)
export HOME_DIR=$(cd $ZDOTDIR/../..;pwd)
