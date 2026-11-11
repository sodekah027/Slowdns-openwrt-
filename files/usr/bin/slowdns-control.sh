#!/bin/sh
# SlowDNS front controller
# Backend: standalone (direct SOCKS) atau openclash

. /lib/functions.sh
config_load slowdns
config_get backend settings backend "standalone"

case "$1" in
    start)
        /etc/init.d/slowdns enable
        /etc/init.d/slowdns restart
        if [ "$backend" = "openclash" ]; then
            sleep 8
            /usr/bin/slowdns-openclash.sh start
        fi
        ;;
    stop)
        /usr/bin/slowdns-openclash.sh stop 2>/dev/null
        /etc/init.d/slowdns stop
        /etc/init.d/slowdns disable
        ;;
    restart)
        "$0" stop
        sleep 1
        "$0" start
        ;;
    status)
        /etc/init.d/slowdns status
        [ -x /usr/bin/slowdns-openclash.sh ] && /usr/bin/slowdns-openclash.sh status
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
