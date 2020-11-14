# vi: set ft=sh

zstyle ':completion:*' sort false
zstyle ':completion:*' file-sort 'modification'
## vim advanced completion (e.g. tex and rc files first)
#zstyle ':completion::*:vim:*:*' file-patterns '*Makefile|*(rc|log)|*.(php|tex|bib|sql|zsh|ini|sh|vim|rb|sh|js|tpl|csv|rdf|txt|phtml|tex|py|n3):vi-files:vim\ likes\ these\ files *~(Makefile|*(rc|log)|*.(log|rc|php|tex|bib|sql|zsh|ini|sh|vim|rb|sh|js|tpl|csv|rdf|txt|phtml|tex|py|n3)):all-files:other\ files'

#zstyle ':completion::*:(sh|bash|zsh):*:*' file-patterns '*Makefile|*(rc|log)|*.(php|tex|bib|sql|zsh|ini|sh|vim|rb|sh|js|tpl|csv|rdf|txt|phtml|tex|py|n3):vi-files:vim\ likes\ these\ files *~(Makefile|*(rc|log)|*.(log|rc|php|tex|bib|sql|zsh|ini|sh|vim|rb|sh|js|tpl|csv|rdf|txt|phtml|tex|py|n3)):all-files:other\ files'
zstyle ':completion:*:*:(vim|vi):*:*files' ignored-patterns '*?.o' "*?.pyc"
#zstyle ':completion::*:(sh|bash|zsh):*:*' file-patterns '*.(sh|zsh)' '%p:all-files'
zstyle ':completion::*:source:*:*' file-patterns '*rc|*.(sh|zsh)' '%p:all-files'
zstyle ':completion::*:(vim|vi):*:*' file-patterns \
      '%p:globbed-files' '*:all-files' '*:local-directories' '*:directories'

#zstyle ':completion:*' file-sort access
zstyle ':completion:*' file-sort 'modification'
#zstyle ':completion:*' sort 'modification'

zstyle ':completion:*:(cd|vi|vim|ls):*' ignore-parents parent pwd

# Ignore what's already in the line
zstyle ':completion:*:(rm|cp|mv||kill|diff|vim|cat|less|more|gzip|gunzip|zcat|tar|fg|bg):*' ignore-line yes
zstyle ':completion:*:*:*:*:processes' command "ps ax -o ppid,pid,user,comm,cmd,time"

# Redirects
zstyle ':completion:*:*:-redirect-,2>,*:*' file-patterns '*.(log|txt)' 'logs/*.log' '%p:all_files'
zstyle ':completion:*:*:-redirect-,2>>,*:*' file-patterns '*.(log|txt)' 'logs/*.log' '%p:all_files'
zstyle ':completion:*:*:-redirect-,>,*:*' file-patterns '*.(log|txt)' 'logs/*.log' '%p:all_files'
zstyle ':completion:*:*:-redirect-,>>,*:*' file-patterns '*.(log|txt)' 'logs/*.log' '%p:all_files'

zstyle ':completion:*' special-dirs true

# disable named-directories autocompletion
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories

# Use caching so that commands like apt and dpkg complete are useable
zstyle ':completion:*' use-cache yes
#zstyle ':completion:*' cache-path $ZSH_CACHE_DIR
