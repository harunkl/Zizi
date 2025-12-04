ZIVPN UDP Manager + Telegram Backup

ZIVPN adalah manager akun UDP VPN berbasis VPS dengan fitur:

- Auto install UDP ZIVPN
- Auto install dependency (jq, curl, vnstat)
- Manajemen akun via menu
- Auto expired akun
- Backup & restore akun
- Notifikasi akun ke Telegram
- Monitoring bandwidth
- Shortcut perintah: "zivpn"

---

✅ 1 Perintah Install (Auto Semua)

Jalankan perintah ini di VPS kamu (Ubuntu/Debian):

```bash
wget https://raw.githubusercontent.com/harunkl/Zizi/main/install.sh -O install.sh && chmod +x install.sh && bash install.sh

Proses yang terjadi otomatis:

1. Install UDP ZIVPN
2. Install jq, curl, vnstat (jika belum ada)
3. Install ZIVPN Manager
4. Shortcut dibuat: "zivpn"
5. Manager langsung terbuka otomatis

---

✅ Cara Menjalankan Manager

Jika ingin membuka kembali manager:

zivpn

---

✅ Menu yang Tersedia

- 1 → Lihat akun UDP
- 2 → Tambah akun baru
- 3 → Hapus akun
- 4 → Restart layanan
- 5 → Status VPS
- 6 → Backup akun + kirim ke Telegram
- 7 → Restore akun
- 0 → Keluar

---

✅ Backup & Restore

File backup akan tersimpan di:

/etc/zivpn/

Nama file:

- "backup_config.json"
- "backup_meta.json"

Backup juga otomatis dikirim ke Telegram.

---

✅ Syarat VPS

- OS: Ubuntu 20.04 / 22.04 atau Debian 10 / 11
- Akses: Root
- Port UDP terbuka

---

⚠️ Catatan Penting

- Pastikan service "zivpn.service" aktif
- Pastikan port UDP tidak diblokir firewall
- Token Bot Telegram dan Chat ID harus valid

---

👤 Author

Harun
Dengan bantuan GPT

---

✅ Lisensi

Free to use
