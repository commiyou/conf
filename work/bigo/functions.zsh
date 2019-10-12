#!/usr/bin/env bash
BASEDIR=$(dirname "$0")

down_repo() {
  for repo in ${@}
  do
    git clone ssh://youbin@gerrit.sysop.520hello.com:29418/$repo && scp -p -P 29418 youbin@gerrit.sysop.520hello.com:hooks/commit-msg $repo/.git/hooks/
  done
}

