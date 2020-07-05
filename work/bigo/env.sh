if [[ -n "$SSH_CONNECTION" && $HOSTNAME != bigoextjump ]]; then
    HOSTNAME=${SSH_CONNECTION#* * }
    HOSTNAME=${HOSTNAME% *}
fi
# set terminal tab title
echo -en "\e]2;$USER@$HOSTNAME\a"
PS1=${PS1//\\h/\$HOSTNAME}
PS1=${PS1//\\u@}
PS1=${PS1//\\w/\\W}

