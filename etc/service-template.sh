#!/bin/sh

cat <<EOF
{
    "service": {
        "name": "pong",
        "id": "pong-$(hostname)",
        "tags": [],
        "port": 9000,
        "check": {
            "script": "nc -w5 -zv localhost 9000",
            "interval": "5s"
        }
    }
}
EOF
