#!/bin/bash
yum -y install ppp pptpd epel-release xl2tpd libreswan lsof

rm -f /etc/ppp/options.pptpd
touch /etc/ppp/options.pptpd
cat >> /etc/ppp/options.pptpd <<EOF
ipcp-accept-local
ipcp-accept-remote
ms-dns  114.114.114.114
ms-dns  223.5.5.5
# ms-dns 8.8.8.8
# ms-dns 8.8.4.4
# ms-wins 192.168.1.2
# ms-wins 192.168.1.4
name xl2tpd
#noccp
auth
#crtscts
idle 1800
mtu 1410
mru 1410
nodefaultroute
debug
#lock
proxyarp
connect-delay 5000
refuse-pap
refuse-mschap
require-mschap-v2
persist
logfile /var/log/xl2tpd.log
EOF

rm -f /etc/ipsec.conf
touch /etc/ipsec.conf
cat >> /etc/ipsec.conf <<EOF
config setup
protostack=netkey
dumpdir=/var/run/pluto/
virtual_private=%v4:10.0.0.0/8,%v4:192.168.0.0/16,%v4:172.16.0.0/12,%v4:25.0.0.0/8,%v4:100.64.0.0/10,%v6:fd00::/8,%v6:fe80::/10

include /etc/ipsec.d/*.conf

EOF


rm -f /etc/ipsec.d/l2tp-ipsec.conf
touch /etc/ipsec.d/l2tp-ipsec.conf
cat >> /etc/ipsec.d/l2tp-ipsec.conf <<EOF
conn L2TP-PSK-NAT
rightsubnet=0.0.0.0/0
dpddelay=10
dpdtimeout=20
dpdaction=clear
forceencaps=yes
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
left=47.52.92.168 
leftprotoport=17/1701 
right=%any
rightprotoport=17/%any
EOF

cat >> /etc/ppp/chap-secrets << EOF
test * password *
EOF

rm -f /etc/ipsec.d/default.secrets
touch /etc/ipsec.d/default.secrets
cat >> /etc/ipsec.d/default.secrets <<EOF
: PSK "password"
EOF

rm -f /etc/sysctl.conf
touch /etc/sysctl.conf
cat >> /etc/sysctl.conf <<EOF

net.ipv4.ip_forward = 1  
net.ipv4.conf.all.accept_redirects = 0 
net.ipv4.conf.all.rp_filter = 0 
net.ipv4.conf.all.send_redirects = 0 
net.ipv4.conf.default.accept_redirects = 0 
net.ipv4.conf.default.rp_filter = 0 
net.ipv4.conf.default.send_redirects = 0 
net.ipv4.conf.eth0.accept_redirects = 0 
net.ipv4.conf.eth0.rp_filter = 0 
net.ipv4.conf.eth0.send_redirects = 0 
net.ipv4.conf.eth1.accept_redirects = 0 
net.ipv4.conf.eth1.rp_filter = 0 
net.ipv4.conf.eth1.send_redirects = 0 
net.ipv4.conf.eth2.accept_redirects = 0 
net.ipv4.conf.eth2.rp_filter = 0 
net.ipv4.conf.eth2.send_redirects = 0 
net.ipv4.conf.ip_vti0.accept_redirects = 0 
net.ipv4.conf.ip_vti0.rp_filter = 0 
net.ipv4.conf.ip_vti0.send_redirects = 0 
net.ipv4.conf.lo.accept_redirects = 0 
net.ipv4.conf.lo.rp_filter = 0 
net.ipv4.conf.lo.send_redirects = 0 
net.ipv4.conf.ppp0.accept_redirects = 0 
net.ipv4.conf.ppp0.rp_filter = 0 
net.ipv4.conf.ppp0.send_redirects = 0 
EOF

sysctl -p

systemctl start firewalld
firewall-cmd --permanent --add-service=ipsec 
firewall-cmd --permanent --add-port=1701/udp 
firewall-cmd --permanent --add-port=4500/udp 
firewall-cmd --permanent --add-masquerade 
firewall-cmd --reload 

systemctl enable ipsec 
systemctl start ipsec 
systemctl enable xl2tpd 
systemctl start xl2tpd

