/// Model untuk Reservasi
class ReservasiModel {
  final String? id;
  final String reservasiId;
  final String userId;
  final String psId;
  final int jumlahHari;
  final int jumlahUnit;
  final DateTime tglMulai;
  final DateTime tglSelesai;
  final String alamat;
  final String noWA;
  final String ktpUrl;
  final int totalHarga;
  final String status; // "pending" | "paid" | "approved" | "shipping" | "installed" | "active" | "completed"
  final DateTime createdAt;
  
  // New fields for enhanced features
  final String? driverId;           // ID driver yang mengantar
  final String? driverName;         // Nama driver
  final String? driverPhone;        // No WA driver
  final String? driverPhoto;        // Foto profil driver
  final String? fotoBuktiPasang;    // Foto bukti PS sudah terpasang (upload oleh user)
  final String? fotoUserPenerima;   // Foto user penerima PS
  final DateTime? waktuSewaMulai;   // Waktu sewa dimulai (saat admin klik Start)
  final DateTime? waktuSewaBerakhir;// Waktu sewa berakhir (waktuSewaMulai + jumlahHari)
  final double? latitude;           // Latitude lokasi pengiriman
  final double? longitude;          // Longitude lokasi pengiriman
  final String? kordinat;           // Koordinat dalam format "lat,lng"
  final String? buktiTerpasang;     // Foto bukti unit sudah terpasang (upload oleh user)

  ReservasiModel({
    this.id,
    required this.reservasiId,
    required this.userId,
    required this.psId,
    required this.jumlahHari,
    required this.jumlahUnit,
    required this.tglMulai,
    required this.tglSelesai,
    required this.alamat,
    required this.noWA,
    required this.ktpUrl,
    required this.totalHarga,
    required this.status,
    required this.createdAt,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.driverPhoto,
    this.fotoBuktiPasang,
    this.fotoUserPenerima,
    this.waktuSewaMulai,
    this.waktuSewaBerakhir,
    this.latitude,
    this.longitude,
    this.kordinat,
    this.buktiTerpasang,
  });

  /// Factory constructor untuk membuat ReservasiModel dari JSON
  factory ReservasiModel.fromJson(Map<String, dynamic> json) {
    return ReservasiModel(
      id: json['_id'] as String?,
      reservasiId: json['reservasi_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      psId: json['ps_id'] as String? ?? '',
      jumlahHari: _parseToInt(json['jumlah_hari']),
      jumlahUnit: _parseToInt(json['jumlah_unit']),
      tglMulai: _parseDateTime(json['tgl_mulai']),
      tglSelesai: _parseDateTime(json['tgl_selesai']),
      alamat: json['alamat'] as String? ?? '',
      noWA: json['no_wa'] as String? ?? '',
      ktpUrl: json['foto_ktp'] as String? ?? '',
      totalHarga: _parseToInt(json['total_harga']),
      status: json['status'] as String? ?? 'pending',
      createdAt: _parseDateTime(json['createdat']),
      // New fields
      driverId: json['driver_id'] as String?,
      driverName: json['driver_name'] as String?,
      driverPhone: json['driver_phone'] as String?,
      driverPhoto: json['driver_photo'] as String?,
      fotoBuktiPasang: json['foto_bukti_pasang'] as String?,
      fotoUserPenerima: json['foto_user_penerima'] as String?,
      waktuSewaMulai: _parseNullableDateTime(json['waktu_sewa_mulai']),
      waktuSewaBerakhir: _parseNullableDateTime(json['waktu_sewa_berakhir']),
      latitude: _parseToDouble(json['latitude']),
      longitude: _parseToDouble(json['longitude']),
      kordinat: json['kordinat'] as String?,
      buktiTerpasang: json['bukti_terpasang'] as String?,
    );
  }

  /// Helper untuk parsing ke int
  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Helper untuk parsing ke double
  static double? _parseToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Helper untuk parsing DateTime
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  /// Helper untuk parsing nullable DateTime
  static DateTime? _parseNullableDateTime(dynamic value) {
    if (value == null || value == '') return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Konversi ReservasiModel ke JSON untuk disimpan
  Map<String, dynamic> toJson() {
    return {
      'reservasi_id': reservasiId,
      'user_id': userId,
      'ps_id': psId,
      'jumlah_hari': jumlahHari.toString(),
      'jumlah_unit': jumlahUnit.toString(),
      'tgl_mulai': tglMulai.toIso8601String(),
      'tgl_selesai': tglSelesai.toIso8601String(),
      'alamat': alamat,
      'no_wa': noWA,
      'foto_ktp': ktpUrl,
      'total_harga': totalHarga.toString(),
      'status': status,
      'createdat': createdAt.toIso8601String(),
      'driver_id': driverId ?? '',
      'driver_name': driverName ?? '',
      'driver_phone': driverPhone ?? '',
      'driver_photo': driverPhoto ?? '',
      'foto_bukti_pasang': fotoBuktiPasang ?? '',
      'foto_user_penerima': fotoUserPenerima ?? '',
      'waktu_sewa_mulai': waktuSewaMulai?.toIso8601String() ?? '',
      'waktu_sewa_berakhir': waktuSewaBerakhir?.toIso8601String() ?? '',
      'latitude': latitude?.toString() ?? '',
      'longitude': longitude?.toString() ?? '',
      'kordinat': kordinat ?? '',
      'bukti_terpasang': buktiTerpasang ?? '',
    };
  }

  /// Copy with method untuk update partial
  ReservasiModel copyWith({
    String? id,
    String? reservasiId,
    String? userId,
    String? psId,
    int? jumlahHari,
    int? jumlahUnit,
    DateTime? tglMulai,
    DateTime? tglSelesai,
    String? alamat,
    String? noWA,
    String? ktpUrl,
    int? totalHarga,
    String? status,
    DateTime? createdAt,
    String? driverId,
    String? driverName,
    String? driverPhone,
    String? driverPhoto,
    String? fotoBuktiPasang,
    String? fotoUserPenerima,
    DateTime? waktuSewaMulai,
    DateTime? waktuSewaBerakhir,
    double? latitude,
    double? longitude,
    String? kordinat,
    String? buktiTerpasang,
  }) {
    return ReservasiModel(
      id: id ?? this.id,
      reservasiId: reservasiId ?? this.reservasiId,
      userId: userId ?? this.userId,
      psId: psId ?? this.psId,
      jumlahHari: jumlahHari ?? this.jumlahHari,
      jumlahUnit: jumlahUnit ?? this.jumlahUnit,
      tglMulai: tglMulai ?? this.tglMulai,
      tglSelesai: tglSelesai ?? this.tglSelesai,
      alamat: alamat ?? this.alamat,
      noWA: noWA ?? this.noWA,
      ktpUrl: ktpUrl ?? this.ktpUrl,
      totalHarga: totalHarga ?? this.totalHarga,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverPhoto: driverPhoto ?? this.driverPhoto,
      fotoBuktiPasang: fotoBuktiPasang ?? this.fotoBuktiPasang,
      fotoUserPenerima: fotoUserPenerima ?? this.fotoUserPenerima,
      waktuSewaMulai: waktuSewaMulai ?? this.waktuSewaMulai,
      waktuSewaBerakhir: waktuSewaBerakhir ?? this.waktuSewaBerakhir,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      kordinat: kordinat ?? this.kordinat,
      buktiTerpasang: buktiTerpasang ?? this.buktiTerpasang,
    );
  }

  /// Hitung sisa waktu sewa dalam Duration
  Duration? getSisaWaktu() {
    if (waktuSewaBerakhir == null) return null;
    final now = DateTime.now();
    if (now.isAfter(waktuSewaBerakhir!)) return Duration.zero;
    return waktuSewaBerakhir!.difference(now);
  }

  /// Cek apakah sewa sudah berakhir
  bool get isSewaExpired {
    if (waktuSewaBerakhir == null) return false;
    return DateTime.now().isAfter(waktuSewaBerakhir!);
  }

  /// Format sisa waktu ke string
  String getSisaWaktuFormatted() {
    final sisa = getSisaWaktu();
    if (sisa == null) return '-';
    if (sisa == Duration.zero) return 'Waktu habis';
    
    final days = sisa.inDays;
    final hours = sisa.inHours % 24;
    final minutes = sisa.inMinutes % 60;
    
    if (days > 0) {
      return '$days hari $hours jam';
    } else if (hours > 0) {
      return '$hours jam $minutes menit';
    } else {
      return '$minutes menit';
    }
  }

  /// Validasi status
  static bool isValidStatus(String status) {
    return [
      'belum_bayar',
      'pending',
      'paid',
      'approved',
      'shipping',
      'installed',
      'active',
      'rejected',
      'finished',
      'completed',
      'cancelled',
    ].contains(status);
  }

  /// Hitung total harga
  static int calculateTotalHarga(
    int hargaPerHari,
    int jumlahHari,
    int jumlahUnit,
  ) {
    return hargaPerHari * jumlahHari * jumlahUnit;
  }

  @override
  String toString() {
    return 'ReservasiModel(reservasiId: $reservasiId, userId: $userId, psId: $psId, status: $status, totalHarga: $totalHarga)';
  }
}

/// Status constants untuk reservasi
class ReservasiStatus {
  static const String belumBayar = 'belum_bayar'; // Reservasi dibuat, belum bayar
  static const String pending = 'pending'; // Sudah bayar, menunggu approval admin
  static const String paid = 'paid'; // Sudah bayar, menunggu konfirmasi admin
  static const String approved = 'approved'; // Admin setuju, menyiapkan barang
  static const String shipping = 'shipping'; // Barang dibawa kurir
  static const String installed = 'installed'; // Barang sampai & dipasang
  static const String active = 'active'; // Waktu sewa berjalan/Timer on
  static const String rejected = 'rejected';
  static const String finished = 'finished';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';

  /// Get display text for status
  static String getDisplayText(String status) {
    switch (status) {
      case belumBayar:
        return 'Belum Bayar';
      case pending:
        return 'Menunggu Konfirmasi';
      case paid:
        return 'Sudah Bayar';
      case approved:
        return 'Disetujui';
      case shipping:
        return 'Sedang Dikirim';
      case installed:
        return 'Terpasang';
      case active:
        return 'Aktif';
      case rejected:
        return 'Ditolak';
      case finished:
      case completed:
        return 'Selesai';
      case cancelled:
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  /// Get user-friendly description
  static String getDescription(String status) {
    switch (status) {
      case belumBayar:
        return 'Silakan lakukan pembayaran untuk melanjutkan';
      case pending:
        return 'Menunggu konfirmasi pembayaran dari admin';
      case paid:
        return 'Pembayaran diterima, menunggu persetujuan admin';
      case approved:
        return 'Reservasi disetujui, unit sedang disiapkan';
      case shipping:
        return 'Unit sedang dalam perjalanan ke lokasi Anda';
      case installed:
        return 'Unit sudah terpasang, menunggu aktivasi sewa';
      case active:
        return 'Waktu sewa sedang berjalan';
      case rejected:
        return 'Reservasi ditolak';
      case finished:
      case completed:
        return 'Sewa telah selesai';
      case cancelled:
        return 'Reservasi dibatalkan';
      default:
        return '';
    }
  }
}
