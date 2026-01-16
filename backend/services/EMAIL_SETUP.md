# Konfigurasi Email Notifikasi - QuadraPlay

## Cara Setup Email Notification dengan Gmail SMTP

### Langkah 1: Siapkan Akun Gmail

1. Gunakan Gmail yang akan dipakai untuk mengirim notifikasi (contoh: `noreply.quadraplay@gmail.com`)
2. Pastikan sudah mengaktifkan **2-Step Verification**

### Langkah 2: Buat App Password

1. Buka [Google Account Security](https://myaccount.google.com/security)
2. Scroll ke bagian **"Signing in to Google"**
3. Klik **"2-Step Verification"** (harus sudah aktif)
4. Scroll ke bawah dan klik **"App passwords"**
5. Pilih app: **Mail**
6. Pilih device: **Other** (beri nama "QuadraPlay Backend")
7. Klik **Generate**
8. **Copy password yang muncul** (16 karakter tanpa spasi)

### Langkah 3: Update Konfigurasi

Edit file `backend/config/email_config.php`:

```php
// Ganti dengan email Gmail Anda
define('SMTP_USERNAME', 'your-email@gmail.com');

// Ganti dengan App Password yang sudah di-generate
define('SMTP_PASSWORD', 'xxxx xxxx xxxx xxxx');

// Sama dengan SMTP_USERNAME
define('MAIL_FROM_EMAIL', 'your-email@gmail.com');

// Nama yang akan muncul sebagai pengirim
define('MAIL_FROM_NAME', 'QuadraPlay');

// Info perusahaan untuk template email
define('COMPANY_NAME', 'QuadraPlay');
define('COMPANY_ADDRESS', 'Alamat Anda');
define('COMPANY_PHONE', '08123456789');
```

### Langkah 4: Upload ke Server

Upload folder `backend/` ke server Anda:
- `backend/config/email_config.php`
- `backend/services/EmailService.php`
- `backend/services/send_notification.php`
- `backend/services/logs/` (folder untuk log)

### Langkah 5: Update URL di Flutter

Edit file `lib/services/email_notification_service.dart`:

```dart
// Sesuaikan dengan URL backend Anda
static const String _baseUrl = 'https://your-domain.com/api/quadraplay/services';
```

---

## Cara Kerja

1. Admin klik **"Konfirmasi Pembayaran"** di Admin Panel
2. Sistem update status payment ke `settlement`
3. Sistem kirim request ke `send_notification.php`
4. Backend kirim email via Gmail SMTP ke user
5. User terima email konfirmasi dengan detail reservasi

---

## Template Email

Email yang dikirim berisi:
- ✅ Badge konfirmasi
- 📋 Detail reservasi (ID, item, jumlah, tanggal, alamat)
- 💰 Total pembayaran
- 📦 Langkah selanjutnya
- 📞 Info kontak

---

## Troubleshooting

### Email tidak terkirim?

1. Cek log di `backend/services/logs/notification_YYYY-MM-DD.log`
2. Pastikan App Password benar (bukan password Gmail biasa)
3. Pastikan 2-Step Verification aktif
4. Coba test koneksi SMTP manual

### Error "Authentication failed"?

- App Password salah atau expired
- Generate App Password baru

### Error "Connection refused"?

- Port 465 mungkin diblokir hosting
- Coba hubungi hosting provider

---

## Batasan Gmail SMTP

- **500 email/hari** untuk akun Gmail gratis
- **2000 email/hari** untuk Google Workspace
- Cocok untuk bisnis skala kecil-menengah

---

## Alternatif (Opsional)

Jika volume email tinggi, pertimbangkan:
- **SendGrid** - 100 email/hari gratis
- **Mailgun** - 5000 email/bulan gratis
- **AWS SES** - $0.10 per 1000 email
