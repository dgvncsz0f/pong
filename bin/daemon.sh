#!/bin/sh

daemon=pong

start () {
  daemon -U -N -i $daemon
}

stop () {
  pkill -TERM pong
}

restart () {
  if ! old=$(pgrep pong)
  then exit 1; fi
  daemon -U -N -i -- $daemon clone
  while [ ! -e /tmp/pong.socket ]; do sleep 1; done
  kill -WINCH $old
  while [ -e /tmp/pong.socket ]; do sleep 1; done
  kill -TERM $old
}

case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  restart)
    restart
    ;;
esac      
