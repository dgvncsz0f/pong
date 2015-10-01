#!/bin/sh

daemon=pong

start () {
  daemon -U -N -i -- $daemon +RTS -N -A4m
}

stop () {
  pkill -TERM pong
  while pgrep pong
  do sleep 1; done
}

restart () {
  local old
  rm -f /tmp/pong.socket
  if ! old=$(pgrep pong)
  then start; exit $?; fi
  daemon -E /var/log/pong -U -N -i -- $daemon clone +RTS -N -A4m
  while sleep 1; do test -e /tmp/pong.socket && break; done
  kill -WINCH $old
  while sleep 1; do test -e /tmp/pong.socket || break; done
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
