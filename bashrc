SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )

[[ -d ~/.local/bin ]] && PATH=~/.local/bin:$PATH
for file in $DIR/rc.d/*rc; do
  source "$file"
done

[[ ! -f ~/.self.sh ]] || source ~/.self.sh

# pkg install termux-services
# sv-enable sshd
#if [ $(ps -ef| grep -v grep | grep -c com.termux ) -gt 0 ]
#then
#    pgrep sshd > /dev/null 2>&1 || sshd 
#    # ln -s ~/conf/bashrc ~/.suroot/.bashrc
#fi
