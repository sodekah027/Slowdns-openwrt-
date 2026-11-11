#!/bin/sh

. /lib/functions.sh
config_load slowdns
config_get local_port  settings local_port  "5300"
config_get ssh_user    settings ssh_user    "root"
config_get ssh_pass    settings ssh_pass    ""
config_get socks_port  settings socks_port  "1080"

logger -t slowdns -p daemon.info "SSH wrapper: menunggu dnstt-client di port $local_port..."

i=0
while [ $i -lt 30 ]; do
    (echo > /dev/tcp/127.0.0.1/$local_port) 2>/dev/null && break
    sleep 2
    i=$((i+1))
done

ASKPASS="/tmp/slowdns-askpass.sh"
printf '#!/bin/sh\necho "%s"\n' "$ssh_pass" > "$ASKPASS"
chmod 700 "$ASKPASS"
export SSH_ASKPASS="$ASKPASS"
export SSH_ASKPASS_REQUIRE=force
export DISPLAY=":0"

ssh -N \
    -D "127.0.0.1:${socks_port}" \
    -o StrictHostKeyChecking=no \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=3 \
    -o NumberOfPasswordPrompts=1 \
    -p "$local_port" \
    "${ssh_user}@127.0.0.1" &
SSH_PID=$!

i=0
while [ $i -lt 30 ]; do
    (echo > /dev/tcp/127.0.0.1/$socks_port) 2>/dev/null && break
    kill -0 "$SSH_PID" 2>/dev/null || exit 1
    sleep 2
    i=$((i+1))
done

if (echo > /dev/tcp/127.0.0.1/$socks_port) 2>/dev/null; then
    logger -t slowdns -p daemon.info "SOCKS5 siap di 127.0.0.1:$socks_port"
    /usr/bin/slowdns-internet.sh start
else
    logger -t slowdns -p daemon.err "SOCKS5 tidak siap"
    kill "$SSH_PID" 2>/dev/null
    exit 1
fi

wait "$SSH_PID"
