#!/bin/sh
# SSH tunnel wrapper untuk SlowDNS
# Dibaca dari UCI config

. /lib/functions.sh
config_load slowdns
config_get local_port settings local_port "2222"
config_get ssh_user  settings ssh_user  "root"
config_get ssh_pass  settings ssh_pass  ""
config_get remote_host settings remote_host ""

# Tunggu dnstt-client siap
sleep 5
i=0
while [ $i -lt 10 ]; do
    nc -z 127.0.0.1 "$local_port" > /dev/null 2>&1 && break
    sleep 2
    i=$((i+1))
done

exec sshpass -p "$ssh_pass" \
    ssh -N \
    -o StrictHostKeyChecking=no \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=3 \
    -o ExitOnForwardFailure=yes \
    -p "$local_port" \
    "${ssh_user}@127.0.0.1"
