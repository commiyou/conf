setopt HIST_SAVE_BY_COPY               # Write to $HISTFILE.new then rename it
setopt HIST_NO_STORE                   # Remove hists access cmds from hist
setopt HIST_NO_FUNCTIONS               # Don't save function define
setopt HIST_REDUCE_BLANKS              # Remove superfluous blanks from each command line being added to the history list

setopt NO_FLOW_CONTROL                 # Ignore ^S/^Q
limit coredumpsize unlimited 2>/dev/null                   # 禁用 core dumps

setopt LONG_LIST_JOBS 

# Remove any right prompt from display when accepting a command line. This may be useful with terminals with other cut/paste methods.
setopt transient_rprompt
# Completion correction : 'sl' instead of 'ls'
setopt correct_all
# Report the status of background jobs immediately, rather than waiting until just before printing a prompt
setopt notify
# Don't kill background jobs on logout
setopt nohup

# DON NOT Allow ‘>’ redirection to truncate existing files, and ‘>>’ to create files. Otherwise ‘>!’ or ‘>|’ must be used to truncate  a file, and ‘>>!’ or ‘>>|’ to create a file.
# setopt no_clobber


# Share history betwen multiple termional sessions
setopt share_history
# Append history, instead of replace, when a terminal session exits
setopt appendhistory
# Add commands as they are typed, don't wait until shell exit
setopt inc_append_history
# Ignore commands with a space before
setopt hist_ignore_space
# Remove the old entry and append the new one
setopt hist_ignore_all_dups
# When searching history don't display results already cycled through twice
setopt hist_find_no_dups
# Remove extra blanks from each command line being added to history
setopt hist_reduce_blanks
# Add timestamps to history
setopt extended_history

setopt autocd

# globbing expressions which don't match anything will be left as-is,
setopt nonomatch
