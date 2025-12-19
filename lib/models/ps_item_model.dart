/// Model untuk PS Item (PlayStation)
class PSItemModel {
  final String? id;
  final String psId;
  final String nama;
  final String kategori; // "PS4" | "PS5" | "Nintendo"
  final String deskripsi;
  final int hargaPerHari;
  final int stok;
  final String fotoUrl;
  final DateTime createdAt;

  PSItemModel({
    this.id,
    required this.psId,
    required this.nama,
    required this.kategori,
    required this.deskripsi,
    required this.hargaPerHari,
    required this.stok,
    required this.fotoUrl,
    required this.createdAt,
  });

  /// Factory constructor untuk membuat PSItemModel dari JSON
  factory PSItemModel.fromJson(Map<String, dynamic> json) {
    return PSItemModel(
      id: json['_id'] as String?,
      psId: json['ps_id'] as String? ?? '',
      nama: json['nama'] as String? ?? '',
      kategori: json['kategori'] as String? ?? 'PS4',
      deskripsi: json['deskripsi'] as String? ?? '',
      hargaPerHari: _parseToInt(json['harga_perhari']),
      stok: _parseToInt(json['stok']),
      fotoUrl: json['foto_url'] as String? ?? '',
      createdAt: json['createdat'] != null 
          ? DateTime.tryParse(json['createdat'].toString()) ?? DateTime.now()
          : DateTime.now(),
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

  /// Konversi PSItemModel ke JSON untuk disimpan
  Map<String, dynamic> toJson() {
    return {
      'ps_id': psId,
      'nama': nama,
      'kategori': kategori,
      'deskripsi': deskripsi,
      'harga_perhari': hargaPerHari.toString(),
      'stok': stok.toString(),
      'foto_url': fotoUrl,
      'createdat': createdAt.toIso8601String(),
    };
  }

  /// Copy with method untuk update partial
  PSItemModel copyWith({
    String? id,
    String? psId,
    String? nama,
    String? kategori,
    String? deskripsi,
    int? hargaPerHari,
    int? stok,
    String? fotoUrl,
    DateTime? createdAt,
  }) {
    return PSItemModel(
      id: id ?? this.id,
      psId: psId ?? this.psId,
      nama: nama ?? this.nama,
      kategori: kategori ?? this.kategori,
      deskripsi: deskripsi ?? this.deskripsi,
      hargaPerHari: hargaPerHari ?? this.hargaPerHari,
      stok: stok ?? this.stok,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Validasi kategori
  static bool isValidKategori(String kategori) {
    return ['PS4', 'PS5', 'Nintendo'].contains(kategori);
  }

  @override
  String toString() {
    return 'PSItemModel(psId: $psId, nama: $nama, kategori: $kategori, hargaPerHari: $hargaPerHari, stok: $stok)';
  }
}
