#!/bin/sh
# SlowDNS -> OpenClash backend
# Membuat config Clash turunan dengan SOCKS5 SlowDNS sebagai outbound utama.

BASE="/etc/openclash"
UCI="openclash"
MARK="$BASE/.slowdns-backend"
RUN="/etc/qtun/run"

log() { logger -t slowdns-oc -p daemon.info "$1"; }

socks_port() {
    uci -q get slowdns.settings.socks_port 2>/dev/null || echo 1080
}

src_yaml() {
    uci -q get "$UCI.config.config_path" 2>/dev/null
}

gen_yaml() {
    SRC="$1"
    OUT="$BASE/config-slowdns.yaml"
    PORT="$(socks_port)"

    python3 - "$SRC" "$OUT" "$PORT" <<'PY'
import sys
src, out, port = sys.argv[1], sys.argv[2], int(sys.argv[3])
text = open(src, encoding='utf-8', errors='replace').read()
lines = text.splitlines()

proxy = f"""  - name: SLOWDNS-SOCKS
    type: socks5
    server: 127.0.0.1
    port: {port}
    udp: true"""

# Remove stale injected block
clean = []
skip = False
for ln in lines:
    if ln.startswith('  - name: SLOWDNS-SOCKS'):
        skip = True
        continue
    if skip:
        if ln.startswith('  - ') or ln and not ln.startswith(' '):
            skip = False
        else:
            continue
    clean.append(ln)
lines = clean

# Insert proxy after proxies: header
try:
    idx = next(i for i, x in enumerate(lines) if x.strip() == 'proxies:')
    lines[idx+1:idx+1] = proxy.splitlines()
except StopIteration:
    lines += ['proxies:', *proxy.splitlines()]

# Prepend SLOWDNS to first select group and make it first proxy
outlines = []
inside_groups = False
injected = False
for i, ln in enumerate(lines):
    if ln.startswith('proxy-groups:'):
        inside_groups = True
        outlines.append(ln)
        continue
    if inside_groups and ln and not ln.startswith(' '):
        inside_groups = False
    if inside_groups and not injected and ln.strip().startswith('- name:'):
        outlines.append(ln)
        continue
    if inside_groups and not injected and ln.strip() == 'type: select':
        outlines.append(ln)
        continue
    if inside_groups and not injected and ln.strip() == 'proxies:':
        outlines.append(ln)
        outlines.append('  - SLOWDNS-SOCKS')
        injected = True
        continue
    outlines.append(ln)

open(out, 'w', encoding='utf-8').write('\n'.join(outlines) + '\n')
PY
    [ -s "$OUT" ]
}

start_backend() {
    SRC="$(src_yaml)"
    [ -n "$SRC" ] || { log "config_path OpenClash kosong"; return 1; }
    [ -f "$SRC" ] || { log "YAML sumber tidak ada: $SRC"; return 1; }
    command -v python3 >/dev/null 2>&1 || { log "python3 tidak tersedia"; return 1; }

    [ -f "$MARK" ] || printf '%s' "$SRC" > "$MARK"

    gen_yaml "$SRC" || { log "gagal membuat config turunan"; return 1; }

    uci set "$UCI.config.config_path=$BASE/config-slowdns.yaml"
    uci set "$UCI.config.enable=1"
    uci commit "$UCI"

    log "Menjalankan OpenClash dengan SlowDNS SOCKS5 :$(socks_port)"
    /etc/init.d/openclash restart
    sleep 5
    /etc/init.d/openclash status | grep -qi running || /etc/init.d/openclash start
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
    /etc/init.d/openclash status 2>/dev/null
}

case "$1" in
    start) start_backend ;;
    stop) stop_backend ;;
    restart) stop_backend; sleep 1; start_backend ;;
    status) status_backend ;;
    *) echo "Usage: $0 {start|stop|restart|status}"; exit 1 ;;
esac
