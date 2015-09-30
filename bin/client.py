#!/usr/bin/python

import os
import sys
import time
import select
import socket
import requests
import resolver

CONSUL = os.environ.get("consul", "127.0.0.1:8500")

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
            
def client (servers):
    for s in servers:
        time.sleep(0.1)
        if (s is None):
            print("FAIL: no servers")
            continue
        try:
            print(ping(s))
        except:
            print("FAIL: can't connect")

resolver.start(CONSUL)
client(resolver.rr())
