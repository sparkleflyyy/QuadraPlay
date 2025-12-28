/// Model untuk Payment dengan Midtrans Integration
class PaymentModel {
  final String? id;
  final String paymentId;
  final String orderId;
  final String? transactionId;
  final String reservasiId;
  final String userId;
  final int totalPembayaran;
  final String metodePembayaran;
  final String? paymentType;
  final String status;
  final String? snapToken;
  final String? snapRedirectUrl;
  final String? vaNumbers;
  final String? paymentCode;
  final DateTime? settlementTime;
  final DateTime? expiryTime;
  final DateTime createdAt;
  final DateTime? updatedAt;
  // Legacy field for backward compatibility
  final String? buktiPembayaran;

  PaymentModel({
    this.id,
    required this.paymentId,
    required this.orderId,
    this.transactionId,
    required this.reservasiId,
    required this.userId,
    required this.totalPembayaran,
    required this.metodePembayaran,
    this.paymentType,
    required this.status,
    this.snapToken,
    this.snapRedirectUrl,
    this.vaNumbers,
    this.paymentCode,
    this.settlementTime,
    this.expiryTime,
    required this.createdAt,
    this.updatedAt,
    this.buktiPembayaran,
  });

  /// Factory constructor untuk membuat PaymentModel dari JSON
  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['_id'] as String?,
      paymentId: json['payment_id'] as String? ?? '',
      orderId: json['order_id'] as String? ?? '',
      transactionId: json['transaction_id'] as String?,
      reservasiId: json['reservasi_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      totalPembayaran:
          int.tryParse(
            json['total_pembayaran']?.toString() ??
                json['total_bayar']?.toString() ??
                '0',
          ) ??
          0,
      metodePembayaran: json['metode_pembayaran'] as String? ?? 'midtrans',
      paymentType: json['payment_type'] as String?,
      status: json['status'] as String? ?? PaymentStatus.pending,
      snapToken: json['snap_token'] as String?,
      snapRedirectUrl: json['snap_redirect_url'] as String?,
      vaNumbers: json['va_numbers'] as String?,
      paymentCode: json['payment_code'] as String?,
      settlementTime:
          json['settlement_time'] != null &&
              json['settlement_time'].toString().isNotEmpty
          ? DateTime.tryParse(json['settlement_time'].toString())
          : null,
      expiryTime:
          json['expiry_time'] != null &&
              json['expiry_time'].toString().isNotEmpty
          ? DateTime.tryParse(json['expiry_time'].toString())
          : null,
      createdAt: json['createdat'] != null
          ? DateTime.tryParse(json['createdat'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt:
          json['updatedat'] != null && json['updatedat'].toString().isNotEmpty
          ? DateTime.tryParse(json['updatedat'].toString())
          : null,
      buktiPembayaran: json['bukti_pembayaran'] as String?,
    );
  }

  /// Konversi PaymentModel ke JSON untuk disimpan
  Map<String, dynamic> toJson() {
    return {
      'payment_id': paymentId,
      'order_id': orderId,
      'transaction_id': transactionId ?? '',
      'reservasi_id': reservasiId,
      'user_id': userId,
      'total_pembayaran': totalPembayaran.toString(),
      'metode_pembayaran': metodePembayaran,
      'payment_type': paymentType ?? '',
      'status': status,
      'snap_token': snapToken ?? '',
      'snap_redirect_url': snapRedirectUrl ?? '',
      'va_numbers': vaNumbers ?? '',
      'payment_code': paymentCode ?? '',
      'settlement_time': settlementTime?.toIso8601String() ?? '',
      'expiry_time': expiryTime?.toIso8601String() ?? '',
      'createdat': createdAt.toIso8601String(),
      'updatedat': updatedAt?.toIso8601String() ?? '',
    };
  }

  /// Copy with method untuk update partial
  PaymentModel copyWith({
    String? id,
    String? paymentId,
    String? orderId,
    String? transactionId,
    String? reservasiId,
    String? userId,
    int? totalPembayaran,
    String? metodePembayaran,
    String? paymentType,
    String? status,
    String? snapToken,
    String? snapRedirectUrl,
    String? vaNumbers,
    String? paymentCode,
    DateTime? settlementTime,
    DateTime? expiryTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      paymentId: paymentId ?? this.paymentId,
      orderId: orderId ?? this.orderId,
      transactionId: transactionId ?? this.transactionId,
      reservasiId: reservasiId ?? this.reservasiId,
      userId: userId ?? this.userId,
      totalPembayaran: totalPembayaran ?? this.totalPembayaran,
      metodePembayaran: metodePembayaran ?? this.metodePembayaran,
      paymentType: paymentType ?? this.paymentType,
      status: status ?? this.status,
      snapToken: snapToken ?? this.snapToken,
      snapRedirectUrl: snapRedirectUrl ?? this.snapRedirectUrl,
      vaNumbers: vaNumbers ?? this.vaNumbers,
      paymentCode: paymentCode ?? this.paymentCode,
      settlementTime: settlementTime ?? this.settlementTime,
      expiryTime: expiryTime ?? this.expiryTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if payment is expired
  bool get isExpired {
    if (expiryTime == null) return false;
    return DateTime.now().isAfter(expiryTime!);
  }

  /// Check if payment is successful
  bool get isSuccess {
    return status == PaymentStatus.settlement ||
        status == PaymentStatus.capture;
  }

  /// Check if payment is pending
  bool get isPending {
    return status == PaymentStatus.pending;
  }

  /// Get remaining time until expiry
  Duration? get remainingTime {
    if (expiryTime == null) return null;
    final remaining = expiryTime!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Format remaining time as string
  String get remainingTimeFormatted {
    final remaining = remainingTime;
    if (remaining == null) return '-';
    if (remaining == Duration.zero) return 'Kadaluarsa';

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    if (hours > 0) {
      return '${hours}j ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}d';
    } else {
      return '${seconds}d';
    }
  }

  @override
  String toString() {
    return 'PaymentModel(paymentId: $paymentId, orderId: $orderId, status: $status)';
  }
}

/// Status constants untuk payment (Midtrans status)
class PaymentStatus {
  static const String pending = 'pending';
  static const String settlement = 'settlement';
  static const String capture = 'capture';
  static const String cancel = 'cancel';
  static const String deny = 'deny';
  static const String expire = 'expire';
  static const String failure = 'failure';
  // Legacy status for backward compatibility
  static const String paid = 'settlement'; // Alias for settlement
  static const String confirmed = 'settlement';

  /// Get display text for status
  static String getDisplayText(String status) {
    switch (status) {
      case pending:
        return 'Menunggu Pembayaran';
      case settlement:
      case capture:
        return 'Pembayaran Berhasil';
      case cancel:
        return 'Dibatalkan';
      case deny:
        return 'Ditolak';
      case expire:
        return 'Kadaluarsa';
      case failure:
        return 'Gagal';
      default:
        return status;
    }
  }

  /// Get color for status
  static int getStatusColor(String status) {
    switch (status) {
      case pending:
        return 0xFFFFA726; // Orange
      case settlement:
      case capture:
        return 0xFF4CAF50; // Green
      case cancel:
      case expire:
        return 0xFF9E9E9E; // Grey
      case deny:
      case failure:
        return 0xFFF44336; // Red
      default:
        return 0xFF9E9E9E;
    }
  }
}
