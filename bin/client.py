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

def connect (s, addr):
    try:
        s.connect(addr)
    except BlockingIOError as e:
        p = select.select([], [s], [], 1)
        if (p[1] == []):
            raise

def ping (addr):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM | socket.SOCK_NONBLOCK, 0)
    try:
        connect(s, addr)
        s.send(b"ping")
        p = select.select([s], [], [], 1)
        if (p[0] == []):
            return(b"fail")
        else:
            return(s.recv(512, socket.MSG_DONTWAIT))
    finally:
        s.close()

def repeat (s):
    while True:
        yield (s, 4500)
            
def client (servers):
    t0    = time.time()
    count = 1
    for s in servers:
        t1 = time.time()
        time.sleep(WAIT)
        if (s is None):
            print("fail: no servers")
            continue
        try:
            if (t1 - t0 > 0.1):
                print("%s [%d]" % (ping(s).decode("utf8").strip(), count))
                t0    = t1
                count = 1
            else:
                count += 1
                ping(s)
        except:
            print("fail: can't connect")

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
