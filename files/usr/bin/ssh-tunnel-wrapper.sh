#!/bin/sh
# SSH tunnel wrapper untuk SlowDNS

. /lib/functions.sh
config_load slowdns
config_get local_port  settings local_port  "5300"
config_get ssh_user    settings ssh_user    "root"
config_get ssh_pass    settings ssh_pass    ""
config_get remote_host settings remote_host ""
config_get remote_port settings remote_port "443"

logger -t slowdns -p daemon.info "SSH wrapper: menunggu dnstt-client di port $local_port..."

# Tunggu dnstt-client siap (max 60 detik)
i=0
while [ $i -lt 30 ]; do
    nc -z 127.0.0.1 "$local_port" > /dev/null 2>&1 && break
    sleep 2
    i=$((i+1))
done

if ! nc -z 127.0.0.1 "$local_port" > /dev/null 2>&1; then
    logger -t slowdns -p daemon.err "SSH wrapper: timeout, dnstt-client tidak siap di port $local_port"
    exit 1
fi

logger -t slowdns -p daemon.info "SSH wrapper: konek SSH ${ssh_user}@127.0.0.1:${local_port}"

exec sshpass -p "$ssh_pass" \
    ssh -N \
    -o StrictHostKeyChecking=no \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=3 \
    -o ExitOnForwardFailure=yes \
    -o BatchMode=no \
    -p "$local_port" \
    "${ssh_user}@127.0.0.1"
