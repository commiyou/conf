# ## http://zsh.sourceforge.net/Doc/Release/Options.html
# Changing Directories
setopt AUTO_CD  
setopt AUTO_PUSHD  
setopt PUSHD_IGNORE_DUPS

# Completion
setopt AUTO_PARAM_SLASH
setopt COMPLETE_IN_WORD
setopt EQUALS # Perform = filename expansion
setopt list_packed # make the completion list smaller
setopt MENU_COMPLETE   # insert the first match immediately.

#  Expansion and Globbing
# setopt GLOB_STAR_SHORT  # the pattern ‘**/*’ can be abbreviated to ‘**’ and the pattern ‘***/*’ can be abbreviated to ***
setopt GLOB_DOTS  # Do not require a leading ‘.’ in a filename to be matched explicitly.
setopt nonomatch  # globbing expressions which don't match anything will be left as-is,
setopt NUMERIC_GLOB_SORT

# History
setopt appendhistory  # Append history, instead of replace, when a terminal session exits
setopt HIST_EXPIRE_DUPS_FIRST    # Expire a duplicate event first when trimming history.
setopt HIST_IGNORE_DUPS          # Do not record an event that was just recorded again.
setopt HIST_FIND_NO_DUPS         # Do not display a previously found event.

setopt hist_ignore_all_dups # Remove the old entry and append the new one
setopt hist_ignore_space # Ignore commands with a space before
setopt noHIST_NO_FUNCTIONS               # save function define
setopt HIST_VERIFY  # perform history expansion and reload the line into the editing buffer
setopt inc_append_history # Add commands as they are typed, don't wait until shell exit
setopt share_history
setopt HIST_NO_STORE             # Don't store history commands


# Input/Output
setopt NO_FLOW_CONTROL                 # Ignore ^S/^Q
setopt interactive_comments

# Job Control
setopt noBG_NICE  # DON't Run all background jobs at a lower priority
setopt LONG_LIST_JOBS 
#setopt notify # Report the status of background jobs immediately, rather than waiting until just before printing a prompt

# compdef _git gco=git-checkout
setopt complete_aliases
setopt EXTENDED_HISTORY          # Write the history file in the ':start:elapsed;command' format.
