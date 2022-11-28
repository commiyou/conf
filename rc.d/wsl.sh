if ! command -v wsl.exe &> /dev/null; then
  return
fi

export hostip=$(cat /etc/resolv.conf |grep -oP '(?<=nameserver\ ).*')
alias setss='export all_proxy="http://${hostip}:1080";'
alias unsetss='unset all_proxy'
