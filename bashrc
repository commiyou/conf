source ~/conf/rc.d/aliasrc
source ~/conf/rc.d/functionrc

[ $(ps -ef|grep -c com.termux ) -gt 0 ] && sshd
