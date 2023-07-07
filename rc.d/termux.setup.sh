[ $(ps -ef| grep -v grep | grep -c com.termux ) -gt 0 ] &&  return

mkdir -p $PREFIX/var/service/sshd/log
ln -sf $PREFIX/share/termux-services/svlogger $PREFIX/var/service/sshd/log/run

mkdir -p $PREFIX/var/service/chatgpt/log
ln -sf $PREFIX/share/termux-services/svlogger $PREFIX/var/service/chatgpt/log/run
ln -sf ~/conf/utils/gptsvr.pyi  $PREFIX/usr/var/service/chatgpt/run
