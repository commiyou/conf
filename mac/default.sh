#!/bin/sh

# https://github.com/herrbischoff/awesome-macos-command-line

# Enable Dock Autohide
defaults write com.apple.dock autohide -bool true && \
killall Dock

xcode-select --install

brew install macvim --HEAD --with-cscope --with-lua --with-override-system-vim --with-luajit --with-python


# Ask User for Password
function gui_password {
    if [[ -z $1 ]]; then
        gui_prompt="Password:"
    else
        gui_prompt="$1"
    fi
    PW=$(osascript <<EOF
    tell application "System Events"
        activate
        text returned of (display dialog "${gui_prompt}" default answer "" with hidden answer)
    end tell
EOF
    )

    echo -n "${PW}"
}


# Enable Tab in modal dialogs.
# All controls
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# lock screen
# /System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend

# bash
brew install bash && \
echo $(brew --prefix)/bin/bash | sudo tee -a /etc/shells && \
chsh -s $(brew --prefix)/bin/bash
# zsh
brew install zsh && \
sudo sh -c 'echo $(brew --prefix)/bin/zsh >> /etc/shells' && \
chsh -s $(brew --prefix)/bin/zsh


echo ""
echo "Enabling the Develop menu and the Web Inspector in Safari"
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" -bool true
echo ""
echo "Disabling the annoying backswipe in Chrome"
defaults write com.google.Chrome AppleEnableSwipeNavigateWithScrolls -bool false
defaults write com.google.Chrome.canary AppleEnableSwipeNavigateWithScrolls -bool false
killall Safari >/dev/null 2>&1

brew install ctags

