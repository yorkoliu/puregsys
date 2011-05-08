#!/bin/sh

####################################################
#                                                  
# L2TP VPN & PPTP VPN & SNMP  Installation Script
# Author: Liu tiansi
# Blog: http://blog.liuts.com
# Mail: liutiansi@gmail.com
# Version: 1.1
# Script run  format:
#    VPNinstall.sh "Service Networking Name"
#    Examples: VPNinstall.sh eth0
####################################################

#SHELL define constant
ServiceNetworkName=$1

#x86_64 or i686
MachineHardwareName=`uname -m`

#SNMP source IP
SNMPSource="192.168.0.1"

#SNMP community
SNMPCommunity="KJ345jd7H93et3"

#check VPNinstall.sh par1=null
if [ "$ServiceNetworkName" == "" ]; then
   echo "Parameter Can not empty!"
   echo "Examples: VPNinstall.sh eth0"
   exit
fi

#check Service Networking Name  exist?
GetServiceNetworName=`/sbin/ifconfig|grep 'Link encap'|grep $ServiceNetworkName`
if [ "$GetServiceNetworName" == "" ]; then
   echo "ERROR: $ServiceNetworkName does not exist!"
   exit
fi

echo -n "Presses the Enter key to start install..."
read


echo "==============================start installing==================================="
#ServerIP
ServerIPAddr=`/sbin/ifconfig $ServiceNetworkName | sed -n "2,2p" | awk '{print $2}'|cut -d: -f2|awk '{ print $1}'`

_pwd=$(pwd)
mkdir -p /home/install/VPN
cd /home/install/VPN


echo "------------------------------------L2TP INSTALL------------------------------------"
vpsip=$ServerIPAddr
iprange="10.0.99"
echo "Please input IP-Range:"
read -p "(Default Range: 10.0.99):" iprange
if [ "$iprange" = "" ]; then
	iprange="10.0.99"
fi

mypsk="vpsyou.com"
echo "Please input PSK:"
read -p "(Default PSK: vpsyou.com):" mypsk
if [ "$mypsk" = "" ]; then
	mypsk="vpsyou.com"
fi

clear
get_char()
{
SAVEDSTTY=`stty -g`
stty -echo
stty cbreak
dd if=/dev/tty bs=1 count=1 2> /dev/null
stty -raw
stty echo
stty $SAVEDSTTY
}
echo ""
echo "ServerIP:"
echo "$vpsip"
echo ""
echo "Server Local IP:"
echo "$iprange.1"
echo ""
echo "Client Remote IP Range:"
echo "$iprange.2-$iprange.254"
echo ""
echo "PSK:"
echo "$mypsk"
echo ""
echo "Press any key to start..."
char=`get_char`
clear
mknod /dev/random c 1 9
yum -y update
yum -y upgrade
yum install -y ppp iptables make gcc gmp-devel xmlto bison flex xmlto libpcap-devel lsof vim-enhanced
mkdir /ztmp
mkdir /ztmp/l2tp
cd /ztmp/l2tp
wget http://www.openswan.org/download/openswan-2.6.24.tar.gz
tar zxvf openswan-2.6.24.tar.gz
cd openswan-2.6.24
make programs install
rm -rf /etc/ipsec.conf
touch /etc/ipsec.conf
cat >>/etc/ipsec.conf<<EOF
config setup
    nat_traversal=yes
    virtual_private=%v4:10.0.0.0/8,%v4:192.168.0.0/16,%v4:172.16.0.0/12
    oe=off
    protostack=netkey

conn L2TP-PSK-NAT
    rightsubnet=vhost:%priv
    also=L2TP-PSK-noNAT

conn L2TP-PSK-noNAT
    authby=secret
    pfs=no
    auto=add
    keyingtries=3
    rekey=no
    ikelifetime=8h
    keylife=1h
    type=transport
    left=$vpsip
    leftprotoport=17/1701
    right=%any
    rightprotoport=17/%any
EOF
cat >>/etc/ipsec.secrets<<EOF
$vpsip %any: PSK "$mypsk"
EOF
sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf
sysctl -p
iptables --table nat --append POSTROUTING --jump MASQUERADE
for each in /proc/sys/net/ipv4/conf/*
do
echo 0 > $each/accept_redirects
echo 0 > $each/send_redirects
done
/etc/init.d/ipsec restart
ipsec verify
cd /ztmp/l2tp
wget http://mirror.zeddicus.com/sources/rp-l2tp-0.4.tar.gz
tar zxvf rp-l2tp-0.4.tar.gz
cd rp-l2tp-0.4
./configure
make
cp handlers/l2tp-control /usr/local/sbin/
mkdir /var/run/xl2tpd/
ln -s /usr/local/sbin/l2tp-control /var/run/xl2tpd/l2tp-control
cd /ztmp/l2tp
wget http://mirror.zeddicus.com/sources/xl2tpd-1.2.4.tar.gz
tar zxvf xl2tpd-1.2.4.tar.gz
cd xl2tpd-1.2.4
make install
mkdir /etc/xl2tpd
rm -rf /etc/xl2tpd/xl2tpd.conf
touch /etc/xl2tpd/xl2tpd.conf
cat >>/etc/xl2tpd/xl2tpd.conf<<EOF
[global]
ipsec saref = yes
[lns default]
ip range = $iprange.2-$iprange.254
local ip = $iprange.1
refuse chap = yes
refuse pap = yes
require authentication = yes
ppp debug = yes
pppoptfile = /etc/ppp/options.xl2tpd
length bit = yes
EOF
rm -rf /etc/ppp/options.xl2tpd
touch /etc/ppp/options.xl2tpd
cat >>/etc/ppp/options.xl2tpd<<EOF
require-mschap-v2
ms-dns 8.8.8.8
ms-dns 8.8.4.4
asyncmap 0
auth
crtscts
lock
hide-password
modem
debug
name l2tpd
proxyarp
lcp-echo-interval 30
lcp-echo-failure 4
EOF
cat >>/etc/ppp/chap-secrets<<EOF
test l2tpd test123 *
EOF
touch /usr/bin/zl2tpset
echo "#/bin/bash" >>/usr/bin/zl2tpset
echo "for each in /proc/sys/net/ipv4/conf/*" >>/usr/bin/zl2tpset
echo "do" >>/usr/bin/zl2tpset
echo "echo 0 > \$each/accept_redirects" >>/usr/bin/zl2tpset
echo "echo 0 > \$each/send_redirects" >>/usr/bin/zl2tpset
echo "done" >>/usr/bin/zl2tpset
chmod +x /usr/bin/zl2tpset

#Configuration iptables
/sbin/iptables --table nat --append POSTROUTING --jump MASQUERADE
/sbin/iptables -I FORWARD -i ppp+ -o eth0 -j ACCEPT
/sbin/iptables -I FORWARD -i eth0 -o ppp+ -j ACCEPT

zl2tpset
xl2tpd
cat >>/etc/rc.local<<EOF
/etc/init.d/ipsec restart
/usr/bin/zl2tpset
/usr/local/sbin/xl2tpd
EOF
clear
ipsec verify
printf "
####################################################
#                                                  #
# This is a Shell-Based tool of l2tp installation  #
# Version: 1.2                                     #
# Author: Zed Lau                                  #
# Website: http://zeddicus.com                     #
#                                                  #
####################################################
if there are no [FAILED] above, then you can
connect to your L2TP VPN Server with the default
user/pass below:

ServerIP:$vpsip
username:test
password:test123
PSK:$mypsk
"

echo "------------------------------------PPTP INSTALL------------------------------------"
cd /home/install/VPN
yum install -y ppp iptables

if [ "$MachineHardwareName" == "x86_64" ]; then
	wget http://acelnmp.googlecode.com/files/pptpd-1.3.4-1.rhel5.1.x86_64.rpm
	rpm -ivh pptpd-1.3.4-1.rhel5.1.x86_64.rpm
else
	wget http://acelnmp.googlecode.com/files/pptpd-1.3.4-1.rhel5.1.i386.rpm
	rpm -ivh pptpd-1.3.4-1.rhel5.1.i386.rpm
fi

echo "localip $iprange.1" >> /etc/pptpd.conf
echo "remoteip $iprange.2-$iprange.254" >> /etc/pptpd.conf
echo "ms-dns 8.8.8.8" >> /etc/ppp/options.pptpd
echo "ms-dns 8.8.4.4" >> /etc/ppp/options.pptpd
/etc/init.d/pptpd restart
/sbin/iptables -I INPUT -p tcp --dport 1723 -j ACCEPT
chkconfig pptpd on


echo "------------------------------------SNMP INSTALL------------------------------------"
cd /home/install/VPN
yum -y install net-snmp*
sed -i -e "/^com2sec/{ s/default/$SNMPSource/; }" /etc/snmp/snmpd.conf
sed -i -e "/^com2sec/{ s/public/$SNMPCommunity/; }" /etc/snmp/snmpd.conf
sed -i -e "/^access/{ s/systemview/all/; }" /etc/snmp/snmpd.conf
sed -i -e '/^#view all/{s/#//}' /etc/snmp/snmpd.conf
sed -i -e '/^#       name           incl/a view    all           included   .1' /etc/snmp/snmpd.conf
sed -i -e '/^#view mib2/{s/#//}' /etc/snmp/snmpd.conf
/etc/init.d/snmpd start
chkconfig snmpd on

/sbin/iptables -I INPUT -s $SNMPSource -p udp --dport 161 -j ACCEPT

/etc/rc.d/init.d/iptables save

echo -n "End of the installation,Good luck!"
read
