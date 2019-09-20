#!/usr/bin/env bash
BASEDIR=$(dirname "$0")
source $BASEDIR/sh/utils.sh

cd $BASEDIR
info pip installing ...
pip_install -r python/requirements.txt
PIP_TARGET=$BASEDIR/python pip_install -r python/requirements.txt


cd sh
info git cloning ...
for _repo in $(cat requirements.txt)
do
  [[ $_repo =~ "^#" ]] && continue
  git_clone https://github.com/$_repo
done

cd -

