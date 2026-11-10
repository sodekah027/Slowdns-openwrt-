#!/bin/sh
# Installer SlowDNS (dnstt) + LuCI GUI untuk OpenWrt AArch64 (HG680P)

# Binary dnstt-client prebuilt untuk aarch64
# Source: https://github.com/ninja-/dnstt/releases
DNSTT_URL="https://github.com/ninja-/dnstt/releases/download/v0.0.1/dnstt-client-linux-arm64"
INSTALL_BIN="/usr/bin/dnstt-client"
INIT_SCRIPT="/etc/init.d/slowdns"

echo "======================================"
echo "  SlowDNS Installer - OpenWrt AArch64"
echo "======================================"

# 1. Install dependensi
echo "[*] Menginstall dependensi..."
opkg update > /dev/null 2>&1
opkg install curl openssh-client sshpass luci-base > /dev/null 2>&1

# 2. Download dnstt-client binary
echo "[*] Mendownload binary dnstt-client (aarch64)..."
curl -L --retry 3 -o "$INSTALL_BIN" "$DNSTT_URL"

# Validasi binary
FSIZE=$(wc -c < "$INSTALL_BIN" 2>/dev/null || echo 0)
if [ "$FSIZE" -lt 100000 ]; then
    echo "[!] Binary terlalu kecil ($FSIZE bytes), mencoba mirror..."
    # Mirror alternatif: slowdns binary dari paket komunitas
    DNSTT_URL2="https://github.com/CCOSTAN/Home-Automations/raw/refs/heads/master/bin/dnstt-client-linux-arm64"
    curl -L --retry 3 -o "$INSTALL_BIN" "$DNSTT_URL2"
    FSIZE=$(wc -c < "$INSTALL_BIN" 2>/dev/null || echo 0)
fi

if [ "$FSIZE" -lt 100000 ]; then
    echo "[!] GAGAL: Binary tidak valid. Coba download manual:"
    echo "    curl -L -o /usr/bin/dnstt-client <URL_BINARY_AARCH64>"
    echo "    chmod +x /usr/bin/dnstt-client"
else
    chmod +x "$INSTALL_BIN"
    echo "[*] Binary dnstt-client OK ($FSIZE bytes)"
fi

# 3. Salin seluruh file (service, config, LuCI plugin)
if [ -d "./files" ]; then
    cp -r ./files/* /
    echo "[*] File konfigurasi, init service, dan LuCI plugin berhasil disalin."
fi

# 4. Pastikan wrapper script ada dan executable
chmod +x /usr/bin/ssh-tunnel-wrapper.sh 2>/dev/null || true
chmod +x "$INIT_SCRIPT"

# 5. Enable & Start Service
/etc/init.d/slowdns enable
/etc/init.d/slowdns start

# 6. Reload LuCI
rm -rf /tmp/luci-*
luci-reload > /dev/null 2>&1

echo ""
echo "======================================"
echo " Instalasi Selesai!"
echo " Akses LuCI: http://192.168.1.1"
echo " Menu: Services -> SlowDNS"
echo "======================================"
