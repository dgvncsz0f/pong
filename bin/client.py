#!/usr/bin/python

import os
import sys
import time
import select
import socket
import requests
import resolver

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

def pingk (s):
    ke = "fail"
    try:
        m = ping(s)
        if (len(m) == 0):
            k = ke
        else:
            k = m.decode("utf8").strip()
    except:
        k = ke
    return(k)

def dump (c, t0):
    t1 = time.time()
    if (t1 - t0 >= 1):
        for k in sorted(c.keys()):
            print("%s [%d]" % (k, c[k]))
        print("--")
        return({}, t1)
    return(c, t0)

def client (servers):
    c  = {}
    t0 = time.time()
    for s in servers:
        if (s is None):
            k = "error"
        else:
            k = pingk(s)
        c[k] = c.get(k, 0) + 1
        c, t0 = dump(c, t0)

def usage (p):
    print("use: %s consul ip|remote" % p)
            
if (len(sys.argv) >= 2):
    if (sys.argv[1] == "consul"):
        resolver.start(sys.argv[2])
        client(resolver.rr())
    else:
        client(sys.argv[1])

else:
    usage(sys.argv[0])
