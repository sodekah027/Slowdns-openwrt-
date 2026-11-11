# SlowDNS (dnstt) Installer for OpenWrt AArch64

**Target Device:** Amlogic HG680P REYRE-STB  
**Architecture:** AArch64 (ARM 64-bit)  
**Kernel:** 5.15.167-ophub  

---

## Deskripsi

Script installer otomatis untuk menjalankan **SlowDNS** menggunakan `dnstt-client` di OpenWrt pada perangkat berbasis Amlogic HG680P. Tunnel DNS ini memungkinkan koneksi SSH melewati port DNS (UDP 53) untuk menembus firewall/blokir ISP.

Tersedia **LuCI GUI** — dapat dikontrol langsung dari panel web OpenWrt di browser (`192.168.1.1`).

---

## Parameter yang Digunakan

| Parameter | Value |
|---|---|
| Mode | NULL |
| Nameserver (NS) | ns-bosku.agenvpn.web.id |
| Public Key | b8fdc42e44c7ab1ebe2258e94cf6 |
| DNS Resolver | 103.253.244.163 |
| SSH Host:Port | bosku.agenvpn.web.id:443 |
| Local Port | 2222 |

---

## Struktur Repository

```
openwrt-slowdns/
├── README.md
├── LICENSE
├── install.sh
└── files/
    └── etc/
    │   ├── init.d/
    │   │   └── slowdns                    # procd service script
    │   ├── config/
    │   │   └── slowdns                    # UCI konfigurasi
    │   └── slowdns/
    │       └── pubkey.pub                 # Public key server
    └── usr/
        ├── lib/lua/luci/
        │   ├── controller/
        │   │   └── slowdns.lua            # LuCI controller
        │   ├── model/cbi/
        │   │   └── slowdns.lua            # LuCI config form
        │   └── view/slowdns/
        │       └── log.htm                # LuCI log viewer
        ├── share/luci/menu.d/
        │   └── 10_slowdns.json            # Menu entry
        └── share/rpcd/acl.d/
            └── luci-app-slowdns.json      # ACL permission
```

---

## Plug and Play

Instalasi satu perintah dari router:

```sh
sh -c 'cd /tmp && rm -rf slowdns-install && mkdir slowdns-install && cd slowdns-install && wget -qO install.sh https://raw.githubusercontent.com/sodekah027/Slowdns-openwrt-/main/install.sh && chmod +x install.sh && ./install.sh'
```

Setelah instalasi, buka **Services → SlowDNS**, isi public key 64 karakter dan akun SSH, lalu klik Save & Apply. Service default **mati** agar tidak bentrok dengan OpenClash. Aktifkan `Enable` hanya jika ingin SlowDNS menjadi jalur mandiri.

Mode mandiri memakai SSH SOCKS5 lokal `127.0.0.1:1080` dan redsocks untuk meneruskan TCP dari LAN. UDP, QUIC, dan aplikasi yang memakai DNS-over-HTTPS tidak otomatis ikut; YouTube/TikTok dapat tetap memakai QUIC sehingga perlu dipaksa TCP jika dibutuhkan.

## Update (One-liner)

Jalankan perintah ini di terminal router untuk update ke versi terbaru tanpa install ulang:

```bash
sh <(curl -s https://raw.githubusercontent.com/sodekah027/Slowdns-openwrt-/main/update.sh)
```

> Konfigurasi (username, password, NS, dll) **tidak akan terhapus** saat update.

---

## Tutorial Install

### Prasyarat

- OpenWrt sudah terinstall di perangkat HG680P
- Koneksi internet aktif di router
- Akses SSH ke router (port 22 atau via LuCI terminal)

---

### Langkah 1 — Login ke Router via SSH

```bash
ssh root@192.168.1.1
```

> Ganti `192.168.1.1` dengan IP router Anda jika berbeda.

---

### Langkah 2 — Install Dependensi

```bash
opkg update
opkg install curl luci-base
```

---

### Langkah 3 — Download Repository

Metode A — menggunakan `git`:
```bash
opkg install git
git clone https://github.com/sodekah027/Slowdns-openwrt-.git /tmp/slowdns-install
cd /tmp/slowdns-install
```

Metode B — download manual (jika git tidak tersedia):
```bash
mkdir -p /tmp/slowdns-install
cd /tmp/slowdns-install
curl -L -o install.sh https://raw.githubusercontent.com/sodekah027/Slowdns-openwrt-/main/install.sh
mkdir -p files/etc/init.d files/etc/config files/etc/slowdns
curl -L -o files/etc/init.d/slowdns https://raw.githubusercontent.com/sodekah027/Slowdns-openwrt-/main/files/etc/init.d/slowdns
curl -L -o files/etc/config/slowdns https://raw.githubusercontent.com/sodekah027/Slowdns-openwrt-/main/files/etc/config/slowdns
curl -L -o files/etc/slowdns/pubkey.pub https://raw.githubusercontent.com/sodekah027/Slowdns-openwrt-/main/files/etc/slowdns/pubkey.pub
```

---

### Langkah 4 — Jalankan Installer

```bash
chmod +x install.sh
sh install.sh
```

Installer akan otomatis:
1. Download binary `dnstt-client` untuk AArch64
2. Menyalin file konfigurasi, service, dan LuCI plugin ke lokasi yang benar
3. Mengaktifkan dan menjalankan service SlowDNS

---

### Langkah 5 — Akses LuCI GUI

1. Buka browser, akses `http://192.168.1.1`
2. Login ke OpenWrt
3. Masuk ke menu **Services → SlowDNS**
4. Atur parameter sesuai kebutuhan
5. Klik **Save & Apply**

Tombol kontrol yang tersedia:
- **Enable/Disable** — aktifkan atau matikan service
- **Start / Stop / Restart** — kontrol service langsung
- **View Log** — lihat log real-time

---

### Langkah 6 — Cek Status Service (CLI)

```bash
/etc/init.d/slowdns status
ps | grep dnstt
```

---

### Langkah 7 — Koneksi SSH Melalui Tunnel

```bash
ssh -p 2222 root@127.0.0.1
```

Untuk SOCKS5 proxy:
```bash
ssh -p 2222 root@127.0.0.1 -N -D 1080
```

---

### Langkah 8 — Konfigurasi Manual via UCI (Opsional)

```bash
uci set slowdns.settings.enabled=1
uci set slowdns.settings.local_port=2222
uci commit slowdns
/etc/init.d/slowdns restart
```

---

## Troubleshooting

**Service tidak mau start:**
```bash
logread | grep slowdns
```

**Binary tidak bisa dieksekusi:**
```bash
file /usr/bin/dnstt-client
chmod +x /usr/bin/dnstt-client
```

**Cek koneksi DNS tunnel:**
```bash
nc -zv 103.253.244.163 53
```

---

## Uninstall

```bash
/etc/init.d/slowdns stop
/etc/init.d/slowdns disable
rm -f /usr/bin/dnstt-client
rm -f /etc/init.d/slowdns
rm -f /etc/config/slowdns
rm -rf /etc/slowdns
rm -f /usr/lib/lua/luci/controller/slowdns.lua
rm -f /usr/lib/lua/luci/model/cbi/slowdns.lua
rm -rf /usr/lib/lua/luci/view/slowdns
rm -f /usr/share/luci/menu.d/10_slowdns.json
rm -f /usr/share/rpcd/acl.d/luci-app-slowdns.json
```

---

## Lisensi

MIT License — lihat file [LICENSE](LICENSE)

---

## Disclaimer

> Script ini dibuat untuk keperluan edukasi dan pengujian jaringan pribadi.  
> Penggunaan sepenuhnya menjadi tanggung jawab pengguna.
