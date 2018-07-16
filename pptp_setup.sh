#!/bin/bash
yum -y install ppp pptpd

cat >> /etc/ppp/options.pptpd <<EOF
ms-dns 8.8.8.8
ms-dns 8.8.4.4
EOF

cat >> /etc/ppp/chap-secrets << EOF
test pptpd password *
EOF

cat >> /etc/pptpd.conf << EOF
localip 192.168.0.1
remoteip 192.168.0.234-238
EOF

cat >> /etc/sysctl.conf << EOF
net.ipv4.ip_forward=1
EOF

sysctl -p
systemctl start firewalld
firewall-cmd --zone=public --add-port=1723/tcp --permanent
firewall-cmd --permanent --zone=public --add-masquerade
firewall-cmd --permanent --zone=public --add-rich-rule='rule family=ipv4 source address=192.168.0.0/24 masquerade'
firewall-cmd --permanent --direct --add-rule ipv4 filter INPUT 0 -i eth0 -p gre -j ACCEPT
firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -p tcp -i ppp+ -j TCPMSS --syn --set-mss 1356
firewall-cmd --reload
systemctl enable firewalld
systemctl enable pptpd
systemctl start pptpd
