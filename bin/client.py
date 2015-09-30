#!/usr/bin/python

import os
import sys
import time
import select
import socket
import requests
import resolver

WAIT    = float(os.environ.get("wait", "0.1"))
CONSUL  = os.environ.get("consul", "127.0.0.1")
HAPROXY = os.environ.get("haproxy", "127.0.0.1")

def ping (addr):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM, 0)
    try:
        s.connect(addr)
        s.send(b"ping")
        p = select.select([s], [], [], 1)
        if (p[0] == []):
            return(b"fail")
        else:
            return(s.recv(512))
    finally:
        s.close()

def repeat (s):
    while True:
        yield (s, 4500)
            
def client (servers):
    for s in servers:
        time.sleep(WAIT)
        if (s is None):
            print("FAIL: no servers")
            continue
        try:
            print(ping(s))
        except:
            print("FAIL: can't connect")

def usage (p):
    print("use: %s local|remote" % p)
            
resolver.start(CONSUL)
if (len(sys.argv) >= 2):
    if (sys.argv[1] == "local"):
        client(resolver.rr())
    elif (sys.argv[1] == "remote"):
        client(repeat(HAPROXY))
    else:
        usage(sys.argv[0])
else:
    usage(sys.argv[0])
