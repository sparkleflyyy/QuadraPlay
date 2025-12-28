/// Model untuk Driver/Kurir
class DriverModel {
  final String? id;
  final String driverId;
  final String namaDriver;
  final String noWa;
  final String fotoProfil;
  final String status; // "available" | "busy"
  final DateTime createdAt;

  DriverModel({
    this.id,
    required this.driverId,
    required this.namaDriver,
    required this.noWa,
    required this.fotoProfil,
    required this.status,
    required this.createdAt,
  });

  /// Factory constructor untuk membuat DriverModel dari JSON
  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['_id'] as String?,
      driverId: json['driver_id'] as String? ?? '',
      namaDriver: json['nama_driver'] as String? ?? '',
      noWa: json['no_wa'] as String? ?? '',
      fotoProfil: json['foto_profil'] as String? ?? '',
      status: json['status'] as String? ?? DriverStatus.available,
      createdAt: _parseDateTime(json['createdat']),
    );
  }

  /// Helper untuk parsing DateTime
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  /// Konversi DriverModel ke JSON
  Map<String, dynamic> toJson() {
    return {
      'driver_id': driverId,
      'nama_driver': namaDriver,
      'no_wa': noWa,
      'foto_profil': fotoProfil,
      'status': status,
      'createdat': createdAt.toIso8601String(),
    };
  }

  /// Copy with method untuk update partial
  DriverModel copyWith({
    String? id,
    String? driverId,
    String? namaDriver,
    String? noWa,
    String? fotoProfil,
    String? status,
    DateTime? createdAt,
  }) {
    return DriverModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      namaDriver: namaDriver ?? this.namaDriver,
      noWa: noWa ?? this.noWa,
      fotoProfil: fotoProfil ?? this.fotoProfil,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Cek apakah driver available
  bool get isAvailable => status == DriverStatus.available;

  @override
  String toString() {
    return 'DriverModel(driverId: $driverId, namaDriver: $namaDriver, status: $status)';
  }
}

/// Status constants untuk driver
class DriverStatus {
  static const String available = 'available';
  static const String busy = 'busy';
}
