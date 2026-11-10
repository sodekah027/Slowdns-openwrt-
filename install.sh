#!/bin/sh
# Installer SlowDNS (dnstt) untuk OpenWrt AArch64 (HG680P)

DNSTT_URL="https://www.bamsoftware.com/software/dnstt/dnstt-client-linux-arm64"
INSTALL_BIN="/usr/bin/dnstt-client"
INIT_SCRIPT="/etc/init.d/slowdns"

echo "[*] Memasang SlowDNS (dnstt) untuk AArch64..."

# 1. Download dnstt-client
echo "[*] Mendownload binary dnstt-client..."
curl -L -o "$INSTALL_BIN" "$DNSTT_URL"
chmod +x "$INSTALL_BIN"

# 2. Salin file konfigurasi & init dari direktori files/
if [ -d "./files" ]; then
    cp -r ./files/* /
    echo "[*] File konfigurasi dan init service berhasil disalin."
fi

# 3. Enable & Start Service
chmod +x "$INIT_SCRIPT"
/etc/init.d/slowdns enable
/etc/init.d/slowdns start

echo "[*] Instalasi Selesai!"
