#!/bin/bash

install_github_latest() {
  repo=${1:?no repo, like "BurntSushi/ripgrep"}
  repo_url="https://api.github.com/repos/$repo/releases/latest"
  shift
  STDOUT=$(set -o pipefail; curl -s "$repo_url" | grep browser_download_url |  cut -d '"' -f 4)
  [ $? != 0 ] && echo "curl '$repo_url' error" >&2 && exit 1
  for pattern in "$@"
  do
    STDOUT=$(echo "$STDOUT" | grep "$pattern")
  done
  latest_release_url="$STDOUT"
  [[ "$latest_release_url" =~ ^https ]] || { echo pattern not match >&2; exit 1; }
  filename=${latest_release_url##*/}
  wget -q --no-check-certificate "$latest_release_url" -O $filename
  unp $filename
}

install_github_latest "$@"
