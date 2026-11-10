# SlowDNS (dnstt) Installer for OpenWrt AArch64

**Target Device:** Amlogic HG680P REYRE-STB  
**Architecture:** AArch64 (ARM 64-bit)  
**Kernel:** 5.15.167-ophub  

---

## Deskripsi

Script installer otomatis untuk menjalankan **SlowDNS** menggunakan `dnstt-client` di OpenWrt pada perangkat berbasis Amlogic HG680P. Tunnel DNS ini memungkinkan koneksi SSH melewati port DNS (UDP 53) untuk menembus firewall/blokir ISP.

---

## Parameter yang Digunakan

| Parameter | Value |
|---|---|
| Mode | NULL |
| Nameserver (NS) | ns-bosku.agenvpn.web.id |
| Public Key | b8fdc42e44c7ab1ebe2258e94cf6 |
| DNS Resolver | 103.253.244.163 |
| SSH Host:Port | bosku.agenvpn.web.id:443 |

---

## Struktur Repository

```
openwrt-slowdns/
├── README.md
├── install.sh
└── files/
    └── etc/
        ├── init.d/
        │   └── slowdns          # procd service script
        ├── config/
        │   └── slowdns          # UCI konfigurasi
        └── slowdns/
            └── pubkey.pub       # Public key server
```

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
opkg install curl
```

---

### Langkah 3 — Download Repository

Metode A — menggunakan `git`:
```bash
opkg install git
git clone https://github.com/sodekah027/Slowdns-openwrt-.git /tmp/slowdns-install
cd /tmp/slowdns-install
```

Metode B — download manual satu per satu (jika git tidak tersedia):
```bash
mkdir -p /tmp/slowdns-install
cd /tmp/slowdns-install

# Download install.sh
curl -L -o install.sh https://raw.githubusercontent.com/sodekah027/Slowdns-openwrt-/main/install.sh

# Download init service
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
2. Menyalin file konfigurasi dan service ke lokasi yang benar
3. Mengaktifkan dan menjalankan service SlowDNS

---

### Langkah 5 — Cek Status Service

```bash
/etc/init.d/slowdns status
```

Atau cek proses berjalan:
```bash
ps | grep dnstt
```

---

### Langkah 6 — Koneksi SSH Melalui Tunnel

Setelah `dnstt-client` berjalan di port lokal `2222`, hubungkan SSH melalui tunnel:

```bash
ssh -p 2222 root@127.0.0.1
```

Untuk SOCKS5 proxy (browsing lewat tunnel):
```bash
ssh -p 2222 root@127.0.0.1 -N -D 1080
```

---

### Langkah 7 — Konfigurasi Manual (Opsional)

Edit konfigurasi UCI jika diperlukan:

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
```

---

## Lisensi

MIT License — lihat file [LICENSE](LICENSE)

---

## Disclaimer

> Script ini dibuat untuk keperluan edukasi dan pengujian jaringan pribadi.  
> Penggunaan sepenuhnya menjadi tanggung jawab pengguna.
