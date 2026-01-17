---
# QuadraPlay

QuadraPlay adalah aplikasi mobile untuk layanan rental PlayStation dengan fitur reservasi, manajemen pengiriman (delivery), dan integrasi pembayaran. Dokumen ini menjelaskan ringkasan proyek, teknologi inti, konfigurasi yang diperlukan untuk pengujian, serta akun uji yang dapat digunakan oleh penguji.

## Daftar Isi

- Tentang
- Fitur Utama
- Teknologi
- Konfigurasi (ringkasan dan contoh `config.dart`)
- Akun Pengujian
- Panduan Singkat Menjalankan Aplikasi
- Catatan Keamanan
- Kontak

## Tentang

QuadraPlay menyediakan mekanisme pemesanan PlayStation dengan layanan pengantaran ke alamat pengguna. Aplikasi menyertakan antarmuka pengguna untuk pelanggan dan panel administrasi untuk manajemen unit, reservasi, dan pengiriman.

## Fitur Utama

- Autentikasi pengguna (registrasi, login)
- Katalog unit PlayStation (PS3 / PS4 / PS5)
- Proses reservasi dengan pilihan tanggal dan durasi
- Upload dokumen identitas (KTP)
- Integrasi pembayaran melalui Midtrans (token / redirect)
- Manajemen reservasi dan driver pada panel admin
- Penyimpanan file/gambar menggunakan 247Go Cloud Service

## Teknologi

| Komponen | Keterangan |
|----------|------------|
| Flutter (Dart) | Framework frontend aplikasi mobile |
| 247Go Cloud Service | Backend data service dan penyimpanan file (`console.247go.app`) |
| Midtrans | Gateway pembayaran (sandbox/production sesuai konfigurasi) |

## Konfigurasi

Semua pengaturan koneksi ke layanan eksternal disimpan pada `lib/config.dart`. Di bawah ini contoh minimal yang dapat digunakan sebagai template saat pengujian:

```dart
// lib/config.dart
const String baseUrl = 'https://api.247go.app/v5/';
const String token = '690de4f3fcee2015d33ec864'; 
const String project = 'sewa_ps';
const String appid = '693accaf23173f13b93c1fed';
const String midtransServerKey = 'MIDTRANS_SERVER_KEY_IF_APPLICABLE';

```

## Akun Pengujian

Gunakan akun berikut untuk keperluan penilaian dan pengujian:

- Admin
  - Email: muhammadiqbal18303@gmail.com
  - Password: iqbal123
- User
  - Email: aksa@gmail.com
  - Password: aksa123
- Konfirmasi bayar untuk midtrans
  - https://simulator.sandbox.midtrans.com/
  

## Panduan Singkat Menjalankan Aplikasi

Prasyarat: Flutter SDK, Android SDK/Emulator, Git.

Langkah cepat:

```bash
git clone <repository-url>
cd quadraplay
flutter pub get
# Perbarui lib/config.dart sesuai nilai environment
flutter run -d chrome --web-browser-flag="--disable-web-security"
```

Build release APK:

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

## Kontak

- Muhammad Iqbal — muhammadiqbal18303@gmail.com

---
