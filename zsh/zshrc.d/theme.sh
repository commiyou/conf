local user_color='green'; [ $UID -eq 0 ] && user_color='red'
RPROMPT='%{$fg_bold[red]%}%(?..%?)%{$reset_color%}$(git_prompt_info)$(git_prompt_status)%{$reset_color%}'
