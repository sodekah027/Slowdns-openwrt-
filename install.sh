#!/bin/sh
# Installer SlowDNS (dnstt) + LuCI GUI untuk OpenWrt AArch64 (HG680P)

INSTALL_BIN="/usr/bin/dnstt-client"
INIT_SCRIPT="/etc/init.d/slowdns"

echo "======================================"
echo "  SlowDNS Installer - OpenWrt AArch64"
echo "======================================"

# 1. Install dependensi
echo "[*] Menginstall dependensi..."
opkg update > /dev/null 2>&1
opkg install curl openssh-client luci-base redsocks > /dev/null 2>&1

# 2. Download dnstt-client binary (coba beberapa sumber)
echo "[*] Mendownload binary dnstt-client (aarch64)..."

try_download() {
    local url="$1"
    echo "    Mencoba: $url"
    curl -fsSL --retry 2 --connect-timeout 10 -o "$INSTALL_BIN" "$url" 2>/dev/null
    local size
    size=$(wc -c < "$INSTALL_BIN" 2>/dev/null || echo 0)
    if [ "$size" -gt 100000 ]; then
        echo "    OK ($size bytes)"
        return 0
    fi
    echo "    Gagal ($size bytes)"
    return 1
}

# Daftar sumber binary aarch64 (prebuilt)
try_download "https://github.com/sodekah027/Slowdns-openwrt-/raw/main/bin/dnstt-client-aarch64" || {
    echo ""
    echo "[!] Semua sumber gagal. Download manual:"
    echo ""
    echo "    1. Build dari source di PC Linux/x86:"
    echo "       git clone https://www.bamsoftware.com/git/dnstt.git"
    echo "       cd dnstt/dnstt-client"
    echo "       GOARCH=arm64 GOOS=linux go build -o dnstt-client-aarch64"
    echo ""
    echo "    2. Upload ke router:"
    echo "       scp dnstt-client-aarch64 root@192.168.1.1:/usr/bin/dnstt-client"
    echo "       ssh root@192.168.1.1 chmod +x /usr/bin/dnstt-client"
    echo ""
    echo "    3. Lanjutkan install:"
    echo "       sh /tmp/slowdns-install/install.sh --skip-binary"
    echo ""
}

# Cek hasil download
FSIZE=$(wc -c < "$INSTALL_BIN" 2>/dev/null || echo 0)
if [ "$FSIZE" -gt 100000 ]; then
    chmod +x "$INSTALL_BIN"
    echo "[*] Binary dnstt-client siap ($FSIZE bytes)"
else
    echo "[!] Binary belum tersedia. Service tidak akan berjalan sampai binary valid dipasang."
fi

# 3. Salin seluruh file (service, config, LuCI plugin)
if [ -d "./files" ]; then
    cp -r ./files/* /
    chmod +x /usr/bin/ssh-tunnel-wrapper.sh 2>/dev/null
    chmod +x "$INIT_SCRIPT"
    echo "[*] File konfigurasi dan plugin berhasil disalin."
fi

# 4. Enable service (hanya start kalau binary valid)
/etc/init.d/slowdns enable
if [ "$FSIZE" -gt 100000 ]; then
    /etc/init.d/slowdns start
    echo "[*] Service SlowDNS dijalankan."
else
    echo "[!] Service diaktifkan tapi tidak dijalankan (binary belum valid)."
fi

# 5. Reload LuCI
rm -rf /tmp/luci-*
luci-reload > /dev/null 2>&1

echo ""
echo "======================================"
echo " Instalasi Selesai!"
echo " Akses LuCI: http://192.168.1.1"
echo " Menu: Services -> SlowDNS"
echo "======================================"
