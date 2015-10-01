#!/bin/bin/python

#!/usr/bin/python

import os
import sys
import time
import select
import socket
import hashlib
import requests
import tempfile
import threading

stats = set()

def start (consul):
    global stats
    signal = threading.Condition()
    def go ():
        while (True):
            try:
                reply = requests.get("http://%s:8500/v1/health/service/pong?passing" % consul)
                data  = reply.json()
                nodes = set([(item["Node"]["Address"], item["Service"]["Port"]) for item in data ])
                for e in nodes.difference(stats):
                    stats.add(e)
                for e in stats.difference(nodes):
                    stats.remove(e)
                with signal:
                    if (len(stats) > 0):
                        signal.notify()
            except:
                pass
            finally:
                time.sleep(1)
    t = threading.Thread(target=go)
    t.daemon = True
    t.start()
    with signal:
        signal.wait()

def rr ():
    global stats
    while True:
        nodes = sorted(stats)
        if (nodes == []):
            yield None
        for x in nodes:
            if (x not in stats):
                continue
            yield x
