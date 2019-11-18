umask 0022

current_shell() {
  sh -c 'ps -p $$ -o ppid=' | xargs ps -o comm= -p
}

[ -z $TERM ] && export TERM=screen-256color
export TERM=screen-256color
export LC_ALL=en_US.UTF-8
export LANG=$LC_ALL
[ -e "$ZDOTDIR" ] && export HISTFILE="$ZDOTDIR"/.zsh_history

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

# [ -f "$ZDOTDIR"/../wgetrc ] && wget -h | grep PFS >/dev/null 2>&1 && export WGETRC="$ZDOTDIR"/../wgetrc
# [ -f "$ZDOTDIR"/../curlrc ] && export CURL_HOME="$ZDOTDIR"/..

# TODO
[ -e "$ZDOTDIR" ] && export ZSH_CACHE_DIR="$ZDOTDIR"/.cache && mkdir -p $ZSH_CACHE_DIR

# ssh TODO
[ -e "$ZDOTDIR" ] && [[ -f ${ZDOTDIR}/ssh/id_rsa ]] && export SSH_KEY_PATH=${ZDOTDIR}/ssh/id_rsa && export GIT_SSH=${ZDOTDIR}/ssh/gitwrap.sh

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

# export MYNAME=$(cd "$ZDOTDIR"; git config user.name)
# export MYEMAIL=$(cd "$ZDOTDIR"; git config user.email)

export WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'

export GROUP=$USER
export USER_ID=$(id -u $USER)
export GROUP_ID=$(id -g $USER)

[ -e "$ZDOTDIR" ] && export CONF_DIR=$(cd "$ZDOTDIR"/..;pwd)
[ -e "$ZDOTDIR" ] && export HOME_DIR=$(cd "$ZDOTDIR"/../..;pwd)

[ -z "$SSHHOME" ] && export SSHHOME=$CONF_DIR/sshrc
export PYTHONSTARTUP=""$ZDOTDIR"/.pythonrc"
