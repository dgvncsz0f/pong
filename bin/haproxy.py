#!/usr/bin/python

import os
import sys
import time
import select
import socket
import hashlib
import requests
import resolver
import tempfile

CONSUL      = os.environ.get("consul", "127.0.0.1")
HAPROXY_CFG = "/tmp/haproxy.cfg"
HAPROXY_PID = "/tmp/haproxy.pid"

def haproxy_cfg ():
    cfg = """
global
  user haproxy
  group haproxy
  pidfile %s
  daemon

defaults
  mode tcp
  retries 3
  timeout connect 500ms
  timeout client 500ms
  timeout server 500ms

frontend pong
  bind *:4500
  default_backend pong

backend pong
  balance roundrobin
  option tcp-check expect rstring .*pong\n
%s
"""
    nodes = []
    for node in resolver.stats:
        args = {"host": node[0],
                "port": node[1],
                "name": node[0].replace(".", "_")
               }
        nodes.append("  server %(name)s %(host)s:%(port)s maxconn 64 check inter 1000" % args)
    return(cfg % (HAPROXY_PID, "\n".join(sorted(nodes))))

def haproxy_requires_reload (cfg):
    try:
        with open(HAPROXY_CFG, "r") as fh:
            o_md5 = hashlib.md5(fh.read()).digest()
            n_md5 = hashlib.md5(cfg).digest()
            return(o_md5 != n_md5)
    except:
        return(True)

def haproxy_reload ():
    try:
        with open(HAPROXY_PID, "r") as fh:
            pid = fh.read()
    except:
        pid = ""
    if (len(pid) > 0):
        print("reloading haproxy")
        os.system("haproxy -f %s -st %s" % (HAPROXY_CFG, pid))
    else:
        print("starting haproxy")
        os.system("haproxy -f %s" % (HAPROXY_CFG,))
    
def haproxy ():
    cfg = haproxy_cfg()
    if (haproxy_requires_reload(cfg)):
        with open(HAPROXY_CFG, "w") as fh:
            fh.write(cfg)
        haproxy_reload()

resolver.start(CONSUL)
while True:
    try:
        haproxy()
    except: pass
    time.sleep(5)
