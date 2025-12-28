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
  final String
  status; // "pending" | "approved" | "rejected" | "active" | "finished"
  final DateTime createdAt;

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

  /// Helper untuk parsing DateTime
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
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
    );
  }

  /// Validasi status
  static bool isValidStatus(String status) {
    return [
      'belum_bayar',
      'pending',
      'approved',
      'rejected',
      'active',
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
  static const String belumBayar =
      'belum_bayar'; // Reservasi dibuat, belum bayar
  static const String pending =
      'pending'; // Sudah bayar, menunggu approval admin
  static const String approved = 'approved';
  static const String rejected = 'rejected';
  static const String active = 'active';
  static const String finished = 'finished';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
}
