#!/bin/sh
# SlowDNS -> OpenClash backend
# Sisipkan SOCKS5 SlowDNS ke config Clash turunan (config asli tidak diubah).

BASE="/etc/openclash"
UCI="openclash"
MARK="$BASE/.slowdns-backend"
NAME="SLOWDNS-SOCKS"
INJECT="/usr/bin/slowdns-clash-inject.py"

log() { logger -t slowdns-oc -p daemon.info "$1"; }
socks_port() { uci -q get slowdns.settings.socks_port 2>/dev/null || echo 1080; }
src_yaml() { uci -q get "$UCI.config.config_path" 2>/dev/null; }

gen_yaml() {
    SRC="$1"
    OUT="$BASE/config-slowdns.yaml"
    [ -x "$INJECT" ] || { log "injector tidak ada/executable"; return 1; }
    python3 "$INJECT" "$SRC" "$OUT" "$(socks_port)" "$NAME"
}

start_backend() {
    SRC="$(src_yaml)"
    [ -n "$SRC" ] || { log "config_path OpenClash kosong"; return 1; }
    [ -f "$SRC" ] || { log "YAML sumber tidak ada: $SRC"; return 1; }
    case "$SRC" in
        *config-slowdns.yaml) [ -f "$MARK" ] && SRC="$(cat "$MARK")" ;;
    esac

    [ -f "$MARK" ] || printf '%s' "$SRC" > "$MARK"

    gen_yaml "$SRC" || { log "gagal membuat config turunan"; return 1; }

    OUT="$BASE/config-slowdns.yaml"
    if [ -x "$BASE/clash" ] && ! "$BASE/clash" -t -f "$OUT" >/dev/null 2>&1; then
        log "config turunan gagal uji, dibatalkan"
        return 1
    fi

    uci set "$UCI.config.config_path=$OUT"
    uci set "$UCI.config.enable=1"
    uci commit "$UCI"

    log "Menjalankan OpenClash dengan SlowDNS SOCKS5 :$(socks_port)"
    /etc/init.d/openclash enable >/dev/null 2>&1
    /etc/init.d/openclash restart
    sleep 5
}

stop_backend() {
    /etc/init.d/openclash stop 2>/dev/null
    if [ -f "$MARK" ]; then
        ORIG="$(cat "$MARK")"
        uci set "$UCI.config.config_path=$ORIG"
        uci set "$UCI.config.enable=0"
        uci commit "$UCI"
        rm -f "$MARK"
        log "Config OpenClash dikembalikan ke $ORIG"
    fi
}

status_backend() {
    if [ -f "$MARK" ]; then
        echo "OpenClash backend: ACTIVE ($(uci -q get "$UCI.config.config_path"))"
    else
        echo "OpenClash backend: inactive"
    fi
}

case "$1" in
    start) start_backend ;;
    stop) stop_backend ;;
    restart) stop_backend; sleep 1; start_backend ;;
    status) status_backend ;;
    *) echo "Usage: $0 {start|stop|restart|status}"; exit 1 ;;
esac
