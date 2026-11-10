#!/bin/sh
# Update Script SlowDNS (dnstt) OpenWrt
# Usage: sh <(curl -s https://raw.githubusercontent.com/sodekah027/Slowdns-openwrt-/main/update.sh)

REPO="https://raw.githubusercontent.com/sodekah027/Slowdns-openwrt-/main"
TMP="/tmp/slowdns-update"

echo "======================================"
echo "  SlowDNS Updater - OpenWrt AArch64"
echo "======================================"

# 1. Buat folder tmp
rm -rf "$TMP"
mkdir -p "$TMP/files/etc/init.d" \
         "$TMP/files/etc/config" \
         "$TMP/files/etc/slowdns" \
         "$TMP/files/usr/lib/lua/luci/controller" \
         "$TMP/files/usr/lib/lua/luci/model/cbi" \
         "$TMP/files/usr/lib/lua/luci/view/slowdns" \
         "$TMP/files/usr/share/luci/menu.d" \
         "$TMP/files/usr/share/rpcd/acl.d"

echo "[*] Mendownload file terbaru dari GitHub..."

# 2. Download semua file terbaru
curl -s -o "$TMP/files/etc/init.d/slowdns"                          "$REPO/files/etc/init.d/slowdns"
curl -s -o "$TMP/files/etc/slowdns/pubkey.pub"                       "$REPO/files/etc/slowdns/pubkey.pub"
curl -s -o "$TMP/files/usr/lib/lua/luci/controller/slowdns.lua"      "$REPO/files/usr/lib/lua/luci/controller/slowdns.lua"
curl -s -o "$TMP/files/usr/lib/lua/luci/model/cbi/slowdns.lua"       "$REPO/files/usr/lib/lua/luci/model/cbi/slowdns.lua"
curl -s -o "$TMP/files/usr/lib/lua/luci/view/slowdns/log.htm"        "$REPO/files/usr/lib/lua/luci/view/slowdns/log.htm"
curl -s -o "$TMP/files/usr/share/luci/menu.d/10_slowdns.json"        "$REPO/files/usr/share/luci/menu.d/10_slowdns.json"
curl -s -o "$TMP/files/usr/share/rpcd/acl.d/luci-app-slowdns.json"   "$REPO/files/usr/share/rpcd/acl.d/luci-app-slowdns.json"

# CATATAN: file /etc/config/slowdns TIDAK diupdate agar setting user tidak terhapus

# 3. Terapkan file baru
echo "[*] Menerapkan update..."
/etc/init.d/slowdns stop > /dev/null 2>&1
cp -r "$TMP/files/"* /
chmod +x /etc/init.d/slowdns

# 4. Restart service
/etc/init.d/slowdns enable
/etc/init.d/slowdns start

# 5. Reload LuCI
rm -rf /tmp/luci-*
luci-reload > /dev/null 2>&1

# 6. Bersihkan tmp
rm -rf "$TMP"

echo ""
echo "======================================"
echo "  Update Selesai!"
echo "  Konfigurasi (username/password)"
echo "  tidak berubah."
echo "======================================"
