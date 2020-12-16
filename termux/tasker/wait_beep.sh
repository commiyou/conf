#!/data/data/com.termux/files/usr/bin/bash
termux-toast start to beep..
sleep 30
am broadcast --user 0 -a net.dinglish.tasker.beep
