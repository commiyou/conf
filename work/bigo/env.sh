if [[ -n "$SSH_CONNECTION" && $HOSTNAME != bigoextjump ]]; then
    HOSTNAME=${SSH_CONNECTION#* * }
    HOSTNAME=${HOSTNAME% *}
fi
# set terminal tab title
echo -en "\e]2;$HOSTNAME\a"


