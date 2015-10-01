#!/bin/sh

set -e

self=$(readlink -f "$0")
curdir=$(dirname "$self")

mkdir -p /tmp/consul-lib
mkdir -p /tmp/consul-etc

"${curdir}/../etc/resolvconf-dnsmasq-template.sh" >/etc/resolv-dnsmasq.conf
env consul='127.0.0.1#8600' "${curdir}/../etc/dnsmasq-template.sh" >/etc/dnsmasq.conf
/etc/init.d/dnsmasq restart

"${curdir}/../etc/resolvconf-template.sh" >/etc/resolv.conf
daemon -O/var/log/consul -U -N -i -- consul agent -data-dir=/tmp/consul-lib -config-file="${curdir}/../etc/consul-server.cfg" -client 0.0.0.0
