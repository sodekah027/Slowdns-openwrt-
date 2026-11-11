#!/bin/sh
# SlowDNS Internet Setup
# Redirect traffic LAN lewat SSH SOCKS5 tunnel menggunakan redsocks + iptables

SOCKS_PORT="1080"
REDIR_PORT="12345"
LAN_IF="br-lan"

start_internet() {
    logger -t slowdns -p daemon.info "Setup internet via tunnel SOCKS5 127.0.0.1:$SOCKS_PORT"

    # Cek apakah redsocks tersedia
    if command -v redsocks > /dev/null 2>&1; then
        # Jalankan redsocks
        redsocks -c /etc/redsocks.conf
        sleep 1

        # iptables rules: redirect semua traffic TCP dari LAN ke redsocks
        iptables -t nat -N REDSOCKS 2>/dev/null
        iptables -t nat -F REDSOCKS

        # Jangan redirect traffic lokal & private
        iptables -t nat -A REDSOCKS -d 0.0.0.0/8 -j RETURN
        iptables -t nat -A REDSOCKS -d 10.0.0.0/8 -j RETURN
        iptables -t nat -A REDSOCKS -d 127.0.0.0/8 -j RETURN
        iptables -t nat -A REDSOCKS -d 169.254.0.0/16 -j RETURN
        iptables -t nat -A REDSOCKS -d 172.16.0.0/12 -j RETURN
        iptables -t nat -A REDSOCKS -d 192.168.0.0/16 -j RETURN
        iptables -t nat -A REDSOCKS -d 224.0.0.0/4 -j RETURN
        iptables -t nat -A REDSOCKS -d 240.0.0.0/4 -j RETURN

        # Redirect sisa TCP ke redsocks
        iptables -t nat -A REDSOCKS -p tcp -j REDIRECT --to-ports $REDIR_PORT

        # Terapkan ke traffic dari LAN
        iptables -t nat -A PREROUTING -i $LAN_IF -p tcp -j REDSOCKS

        logger -t slowdns -p daemon.info "Internet via redsocks aktif"
    else
        logger -t slowdns -p daemon.warn "redsocks tidak ditemukan, coba install: opkg install redsocks"
        setup_tun_fallback
    fi
}

setup_tun_fallback() {
    logger -t slowdns -p daemon.info "Fallback: gunakan ssh -w tun mode"
    # Fallback: pakai ssh tunnel dengan nat sederhana
    # Traffic dari router sendiri bisa lewat SOCKS via proxychains/tsocks
    logger -t slowdns -p daemon.info "SOCKS5 tersedia di 127.0.0.1:$SOCKS_PORT untuk proxy manual"
}

stop_internet() {
    killall redsocks 2>/dev/null
    iptables -t nat -D PREROUTING -i $LAN_IF -p tcp -j REDSOCKS 2>/dev/null
    iptables -t nat -F REDSOCKS 2>/dev/null
    iptables -t nat -X REDSOCKS 2>/dev/null
    logger -t slowdns -p daemon.info "Internet tunnel dibersihkan"
}

case "$1" in
    start) start_internet ;;
    stop)  stop_internet  ;;
    *)     start_internet ;;
esac
