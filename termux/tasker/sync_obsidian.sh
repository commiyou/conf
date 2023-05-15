#!/bin/bash
root=/sdcard/Documents/obsidian
[ -d $root ] || mkdir -p $root
cd $root
#[ -d $root ] || mkdir -p $root
git config --global --add safe.directory /sdcard/Documents/obsidian/notes
git config --global --add safe.directory /storage/emulated/0/Documents/obsidian/notes
cd notes || exit 1
git pull --rebase --autostash
git add  .
git commit -m "android update"
git push

