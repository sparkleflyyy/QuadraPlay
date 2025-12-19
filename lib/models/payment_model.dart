/// Model untuk Payment
class PaymentModel {
  final String? id;
  final String paymentId;
  final String reservasiId;
  final String userId;
  final int totalBayar;
  final String metodePembayaran;
  final String buktiPembayaran;
  final String status; // "waiting" | "paid" | "confirmed"
  final DateTime createdAt;

  PaymentModel({
    this.id,
    required this.paymentId,
    required this.reservasiId,
    required this.userId,
    required this.totalBayar,
    required this.metodePembayaran,
    required this.buktiPembayaran,
    required this.status,
    required this.createdAt,
  });

  /// Factory constructor untuk membuat PaymentModel dari JSON
  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['_id'] as String?,
      paymentId: json['payment_id'] as String? ?? '',
      reservasiId: json['reservasi_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      totalBayar: int.tryParse(json['total_bayar']?.toString() ?? '0') ?? 0,
      metodePembayaran: json['metode_pembayaran'] as String? ?? '',
      buktiPembayaran: json['bukti_pembayaran'] as String? ?? '',
      status: json['status'] as String? ?? 'waiting',
      createdAt: json['createdat'] != null 
          ? DateTime.tryParse(json['createdat'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Konversi PaymentModel ke JSON untuk disimpan
  Map<String, dynamic> toJson() {
    return {
      'payment_id': paymentId,
      'reservasi_id': reservasiId,
      'user_id': userId,
      'total_bayar': totalBayar.toString(),
      'metode_pembayaran': metodePembayaran,
      'bukti_pembayaran': buktiPembayaran,
      'status': status,
      'createdat': createdAt.toIso8601String(),
    };
  }

  /// Copy with method untuk update partial
  PaymentModel copyWith({
    String? id,
    String? paymentId,
    String? reservasiId,
    String? userId,
    int? totalBayar,
    String? metodePembayaran,
    String? buktiPembayaran,
    String? status,
    DateTime? createdAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      paymentId: paymentId ?? this.paymentId,
      reservasiId: reservasiId ?? this.reservasiId,
      userId: userId ?? this.userId,
      totalBayar: totalBayar ?? this.totalBayar,
      metodePembayaran: metodePembayaran ?? this.metodePembayaran,
      buktiPembayaran: buktiPembayaran ?? this.buktiPembayaran,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Validasi status
  static bool isValidStatus(String status) {
    return ['waiting', 'paid', 'confirmed'].contains(status);
  }

  @override
  String toString() {
    return 'PaymentModel(paymentId: $paymentId, reservasiId: $reservasiId, status: $status)';
  }
}

/// Status constants untuk payment
class PaymentStatus {
  static const String waiting = 'waiting';
  static const String paid = 'paid';
  static const String confirmed = 'confirmed';
}
