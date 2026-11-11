#!/bin/sh
# SSH tunnel wrapper untuk SlowDNS - tanpa sshpass

. /lib/functions.sh
config_load slowdns
config_get local_port  settings local_port  "5300"
config_get ssh_user    settings ssh_user    "root"
config_get ssh_pass    settings ssh_pass    ""

logger -t slowdns -p daemon.info "SSH wrapper: menunggu dnstt-client di port $local_port..."

# Tunggu dnstt-client siap (max 60 detik)
i=0
while [ $i -lt 30 ]; do
    # Test port pakai bash /dev/tcp
    (echo > /dev/tcp/127.0.0.1/$local_port) 2>/dev/null && break
    sleep 2
    i=$((i+1))
done

logger -t slowdns -p daemon.info "SSH wrapper: konek SSH ${ssh_user}@127.0.0.1:${local_port}"

# Buat askpass script sementara
ASKPASS="/tmp/slowdns-askpass.sh"
printf '#!/bin/sh\necho "%s"\n' "$ssh_pass" > "$ASKPASS"
chmod +x "$ASKPASS"

export SSH_ASKPASS="$ASKPASS"
export DISPLAY=":0"

exec ssh -N \
    -o StrictHostKeyChecking=no \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=3 \
    -o NumberOfPasswordPrompts=1 \
    -p "$local_port" \
    "${ssh_user}@127.0.0.1"
