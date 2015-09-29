#!/bin/sh

cat <<EOF
user=root
interface=lo
interface=eth0
no-dhcp-interface=lo
no-dhcp-interface=eth0
all-servers
log-queries
resolv-file=/etc/resolv-dnsmasq.conf
server=/consul.hattomo.com/${server_ip}
EOF
