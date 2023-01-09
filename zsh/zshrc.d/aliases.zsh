 [ -f $XDG_CONFIG_HOME/rc.d/aliasrc ] && source $XDG_CONFIG_HOME/rc.d/aliasrc


alias zmv='noglob zmv -w'
# paste online
alias -g SPRNG=" | curl -F 'sprunge=<-' http://sprunge.us"

hash -d conf=$XDG_CONFIG_HOME
hash -d vim=$XDG_CONFIG_HOME/vim
hash -d tmux=$XDG_CONFIG_HOME/tmux
hash -d zsh=$XDG_CONFIG_HOME/zsh
hash -d rc=$XDG_CONFIG_HOME/rc.d
hash -d cache=$XDG_CACHE_HOME
hash -d data=$XDG_DATA_HOME
hash -d lvim=$XDG_DATA_HOME/lunarvim/

# vim last modified file in current dir
alias -g NF='*(.om[1])'  # newest file
alias -g ND='*(/om[1])'  # newest directory
alias vn='vim *(.om[1]^D)'

alias -g L=" | less"
alias -g LR="| command less -R"  # less with colors support
alias -g G=" | LC_ALL=C command grep -i --color=auto -a"
alias -g P=" | pprint | less"
alias -g NE="2> /dev/null"
alias -g NUL="> /dev/null 2>&1"
alias -g GBK=" | iconv -f utf8 -t gb18030 -c"
alias -g UTF=" | iconv -f gb18030 -t utf8 -c"
alias -g LU=" | iconv -f utf8 -t gb18030 -c | less"
alias -g LG=" | iconv -f gb18030 -t utf8 -c | less"
alias -g TR1=" | tr '' '\t'"
alias -g TR,=" | tr ',' '\t'"
alias -g CSV=" | tr '\t' ',' "
_column_no() {
  sep="${1:-\t}"
  head -1 | xargs -n1 -d"$sep" | cat -n
}
alias -g CNO=" | _column_no"
alias -g H=" | head"
alias -g H1=" | head -1"
alias -g T=" | tail "
alias -g T1=" | tail -1"

alias -g E="luit -encoding gb18030"  # env gb18030 to utf
if type xdg-open > /dev/null; then
  alias open=xdg-open
fi
