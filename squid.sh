#!/bin/bash
clear
tput bold ; printf '%35s%s%-20s\n' "SQUID PROXY" ; tput sgr0
IP=$(wget -qO- ipv4.icanhazip.com)
read -p "Per continuare confermare l'IP di questo server: " -e -i $IP ipdovps
if [ -z "$ipdovps" ]
then
	tput bold ; echo "" ; echo "" ; echo " Non hai inserito l'IP di questo server. Riprova. " ; echo "" ; echo "" ; tput sgr0
	exit 1
fi
echo ""
apt-get update -y
apt-get upgrade -y
apt-get install squid3 nano unzip git wget -y
killall apache2
apt-get purge apache2 -y
if [ -f "/usr/sbin/ufw" ] ; then
	ufw allow 80/tcp ; ufw allow 3128/tcp ; ufw allow 8080/tcp
fi
if [ -d "/etc/squid/" ]
then
	wget https://raw.githubusercontent.com/switchy89/personal/master/squid1.txt -O /tmp/sqd1
	echo "acl url3 dstdomain -i $ipdovps" > /tmp/sqd2
	wget https://raw.githubusercontent.com/89870must73/z/main/squid.txt -O /tmp/sqd3
	cat /tmp/sqd1 /tmp/sqd2 /tmp/sqd3 > /etc/squid/squid.conf
	wget https://raw.githubusercontent.com/89870must73/z/main/payload.txt -O /etc/squid/payload.txt
	echo " " >> /etc/squid/payload.txt
	grep -v "^PasswordAuthentication yes" /etc/ssh/sshd_config > /tmp/passlogin && mv /tmp/passlogin /etc/ssh/sshd_config
	echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
	if [ ! -f "/etc/init.d/squid" ]
	then
		service squid reload > /dev/null
	else
		/etc/init.d/squid reload > /dev/null
	fi
	if [ ! -f "/etc/init.d/ssh" ]
	then
		service ssh reload > /dev/null
	else
		/etc/init.d/ssh reload > /dev/null
	fi
fi
echo ""
tput bold ; echo "Squid Proxy Installato e funzionante sulle porte: 80, 3128, 8080." ; tput sgr0
echo ""
exit 1
