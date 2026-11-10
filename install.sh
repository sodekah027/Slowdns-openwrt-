#!/bin/sh
# Installer SlowDNS (dnstt) + LuCI GUI untuk OpenWrt AArch64 (HG680P)

DNSTT_URL="https://www.bamsoftware.com/software/dnstt/dnstt-client-linux-arm64"
INSTALL_BIN="/usr/bin/dnstt-client"
INIT_SCRIPT="/etc/init.d/slowdns"

echo "[*] Memasang SlowDNS (dnstt) + LuCI GUI untuk AArch64..."

# 1. Install dependensi
echo "[*] Menginstall dependensi..."
opkg update > /dev/null 2>&1
opkg install curl luci-base > /dev/null 2>&1

# 2. Download dnstt-client binary
echo "[*] Mendownload binary dnstt-client..."
curl -L -o "$INSTALL_BIN" "$DNSTT_URL"
chmod +x "$INSTALL_BIN"

# 3. Salin seluruh file (service, config, LuCI plugin)
if [ -d "./files" ]; then
    cp -r ./files/* /
    echo "[*] File konfigurasi, init service, dan LuCI plugin berhasil disalin."
fi

# 4. Enable & Start Service
chmod +x "$INIT_SCRIPT"
/etc/init.d/slowdns enable
/etc/init.d/slowdns start

# 5. Reload LuCI agar menu SlowDNS muncul
rm -rf /tmp/luci-*
luci-reload > /dev/null 2>&1

echo ""
echo "======================================"
echo " Instalasi Selesai!"
echo " Akses LuCI: http://192.168.1.1"
echo " Menu: Services -> SlowDNS"
echo "======================================"
