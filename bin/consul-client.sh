#!/bin/sh

set -e

if [ -z "$server_ip" ]
then echo "env:server_ip is not set"; exit 1; fi

self=$(readlink -f "$0")
curdir=$(dirname "$self")

mkdir -p /tmp/consul-lib
mkdir -p /tmp/consul-etc

"${curdir}/../etc/dnsmasq-template.sh" >/etc/dnsmasq.conf
"${curdir}/../etc/resolvconf-dnsmasq-template.sh" >/etc/resolv-dnsmasq.conf
/etc/init.d/dnsmasq restart

"${curdir}/../etc/resolvconf-template.sh" >/etc/resolv.conf
"${curdir}/../etc/service-template.sh" >/tmp/consul-etc/pong.json
daemon -U -N -i -- consul agent -join "$server_ip" -data-dir=/tmp/consul-lib -config-dir=/tmp/consul-etc -config-file="${curdir}/../etc/consul-client.cfg"
