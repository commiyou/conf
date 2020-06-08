# vi: set ft=sh

## vim advanced completion (e.g. tex and rc files first)
zstyle ':completion::*:vim:*:*' file-patterns '*Makefile|*(rc|log)|*.(php|tex|bib|sql|zsh|ini|sh|vim|rb|sh|js|tpl|csv|rdf|txt|phtml|tex|py|n3):vi-files:vim\ likes\ these\ files *~(Makefile|*(rc|log)|*.(log|rc|php|tex|bib|sql|zsh|ini|sh|vim|rb|sh|js|tpl|csv|rdf|txt|phtml|tex|py|n3)):all-files:other\ files'

zstyle ':completion:*:*:vim:*:*files' ignored-patterns '*?.o' "*?.pyc"
zstyle ':completion:*:*:vi:*:*files' ignored-patterns '*?.o' "*?.pyc"

#zstyle ':completion:*' file-sort access
zstyle ':completion:*' file-sort 'modification'

# Ignore what's already in the line
zstyle ':completion:*:(rm|cp|mv||kill|diff|vim|cat|less|more|gzip|gunzip|zcat|tar|fg|bg):*' ignore-line yes
