#!/bin/sh

cat <<EOF
{
    "service": {
        "name": "haproxy",
        "id": "haproxy-$(hostname)",
        "tags": ["pong"],
        "port": 8000,
        "check": {
            "script": "nc-check -w5 -zv localhost 8000",
            "interval": "5s"
        }
    }
}
EOF
