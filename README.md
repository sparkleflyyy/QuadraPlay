# QuadraPlay - PlayStation Rental Application

<p align="center">
  <img src="lib/assets/icon/Logo.png" alt="QuadraPlay Logo" width="150"/>
</p>

<p align="center">
  <strong>Aplikasi Rental PlayStation Modern dengan Sistem Delivery</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"/>
  <img src="https://img.shields.io/badge/247Go-Cloud%20Service-4285F4?style=for-the-badge&logo=cloud&logoColor=white" alt="247Go Cloud"/>
</p>

---

## Tentang Aplikasi

**QuadraPlay** adalah aplikasi rental PlayStation berbasis mobile yang memudahkan pengguna untuk menyewa konsol PlayStation dengan sistem delivery langsung ke alamat pelanggan. Aplikasi ini menyediakan fitur manajemen reservasi yang komprehensif untuk administrator serta pengalaman pemesanan yang intuitif bagi pengguna.

## Fitur Utama

### Fitur Pengguna (User)
- **Autentikasi** - Sistem registrasi dan login dengan keamanan terenkripsi
- **Katalog PlayStation** - Menampilkan daftar unit PlayStation yang tersedia (PS3, PS4, PS5)
- **Reservasi Online** - Pemesanan PlayStation dengan pilihan tanggal dan durasi sewa
- **Lokasi Delivery** - Penentuan alamat pengiriman menggunakan GPS dan Google Maps
- **Pembayaran Online** - Integrasi dengan Midtrans Payment Gateway
- **Verifikasi KTP** - Sistem upload identitas untuk keamanan transaksi
- **Riwayat Reservasi** - Pemantauan status reservasi secara real-time
- **Timer Sewa** - Penghitung mundur waktu sewa yang tersisa

### Fitur Administrator
- **Dashboard** - Statistik reservasi dan laporan pendapatan
- **Manajemen PlayStation** - Pengelolaan data unit PlayStation (Create, Read, Update, Delete)
- **Manajemen Reservasi** - Pengelolaan seluruh pesanan pelanggan
- **Manajemen Driver** - Penugasan driver untuk proses delivery dan pickup
- **Manajemen Pengguna** - Pengelolaan akun pengguna terdaftar
- **Peta Lokasi** - Visualisasi lokasi delivery pada peta
- **Fitur Pencarian** - Pencarian reservasi berdasarkan ID

## Alur Reservasi

```
Buat Reservasi → Pembayaran → Dikonfirmasi → Dikirim → 
Terpasang → Masa Sewa Aktif → Dijemput → Selesai
```

## Teknologi yang Digunakan

| Teknologi | Fungsi |
|-----------|--------|
| **Flutter** | Framework pengembangan aplikasi cross-platform |
| **Dart** | Bahasa pemrograman utama |
| **247Go Cloud Service** | Backend data service & penyimpanan file/gambar (console.247go.app) |
| **Midtrans** | Payment gateway untuk transaksi pembayaran |
| **Google Maps** | Integrasi layanan peta dan lokasi |
| **Provider** | State management |
| **PHP + MySQL** | Backend API dan database |

## Panduan Instalasi

### Prasyarat
- Flutter SDK versi 3.10.3 atau lebih tinggi
- Dart SDK
- Android Studio atau Visual Studio Code
- Git

### Langkah Instalasi

1. **Clone Repository**
   ```bash
   git clone https://github.com/yourusername/quadraplay.git
   cd quadraplay
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Konfigurasi Backend**
   - Akses console.247go.app untuk konfigurasi data service
   - Perbarui konfigurasi API endpoint pada file `config.dart`
   - Pastikan file `google-services.json` tersedia di direktori `android/app/` untuk Firebase Storage

4. **Menjalankan Aplikasi**
   ```bash
   flutter run
   ```

## Build APK

```bash
# Build APK untuk release
flutter build apk --release

# Lokasi output file
build/app/outputs/flutter-apk/app-release.apk
```

## Download APK

File APK dapat diunduh melalui halaman [Releases](../../releases/latest).

## Struktur Project

```
quadraplay/
├── lib/
│   ├── assets/          # Asset aplikasi (ikon, gambar)
│   ├── controllers/     # Controller untuk state management
│   ├── models/          # Model data
│   ├── pages/           # Halaman UI
│   ├── services/        # Service untuk komunikasi API
│   ├── config.dart      # Konfigurasi aplikasi
│   ├── main.dart        # Entry point aplikasi
│   └── restapi.dart     # Handler REST API
├── backend/             # Backend PHP
│   ├── config/          # Konfigurasi database
│   ├── midtrans/        # Integrasi Midtrans
│   ├── models/          # Model backend
│   └── services/        # Service backend
├── android/             # Kode native Android
├── ios/                 # Kode native iOS
└── web/                 # Dukungan web
```

## Skema Warna Aplikasi

| Warna | Kode Hex | Penggunaan |
|-------|----------|------------|
| Primary | `#2563EB` | Warna utama aplikasi |
| Secondary | `#7C3AED` | Warna aksen |
| Background | `#F8FAFC` | Warna latar belakang |
| Success | `#10B981` | Indikator status berhasil |
| Error | `#EF4444` | Indikator status error |

## Pengembang

Aplikasi ini dikembangkan menggunakan Flutter Framework.

## Lisensi

Project ini dibuat untuk keperluan pembelajaran dan penggunaan pribadi.

---

<p align="center">
  <strong>Terima kasih telah menggunakan QuadraPlay</strong>
</p>
