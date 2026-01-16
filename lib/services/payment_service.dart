import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:quadraplay/config.dart';
import 'package:quadraplay/restapi.dart';
import '../models/payment_model.dart';
import '../models/reservasi_model.dart';
import 'midtrans_service.dart';

/// Service untuk operasi Payment dengan Midtrans
class PaymentService {
  final DataService _dataService = DataService();
  final MidtransService _midtransService = MidtransService();

  /// Parse API response - handle both array and object responses
  List<dynamic> _parseApiResponse(String response) {
    if (response.isEmpty || response == '[]') {
      return [];
    }

    try {
      final decoded = jsonDecode(response);

      if (decoded is List) {
        return decoded;
      }

      if (decoded is Map) {
        if (decoded.containsKey('data') && decoded['data'] is List) {
          return decoded['data'];
        }
        if (decoded.containsKey('result') && decoded['result'] is List) {
          return decoded['result'];
        }
        return [decoded];
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// Generate unique ID
  String _generateId() {
    return const Uuid().v4();
  }

  /// Generate order ID for Midtrans (max 50 chars)
  String _generateOrderId(String reservasiId) {
    // Ambil 8 karakter pertama dari reservasiId + timestamp 10 digit
    final shortId = reservasiId.substring(0, 8);
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(3); // 10 digit
    return 'QP-$shortId-$timestamp'; // Total: 3+8+1+10 = 22 chars
  }

  /// Create payment dengan Midtrans
  Future<Map<String, dynamic>> createPaymentWithMidtrans({
    required String reservasiId,
    required String userId,
    required int totalPembayaran,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String itemName,
    required int itemQuantity,
  }) async {
    try {
      // Validasi input
      if (reservasiId.isEmpty) {
        return {'success': false, 'message': 'Reservasi ID tidak boleh kosong'};
      }
      if (userId.isEmpty) {
        return {'success': false, 'message': 'User ID tidak boleh kosong'};
      }

      // Cek apakah sudah ada payment untuk reservasi ini
      final existing = await getPaymentByReservasiId(reservasiId);
      if (existing['success']) {
        final existingPayment = existing['payment'] as PaymentModel;
        // Jika sudah ada dan masih pending, return token yang ada
        if (existingPayment.isPending &&
            existingPayment.snapToken != null &&
            !existingPayment.isExpired) {
          return {
            'success': true,
            'message': 'Payment sudah ada',
            'payment': existingPayment,
            'snap_token': existingPayment.snapToken,
          };
        }
        // Jika sudah settlement, return error
        if (existingPayment.isSuccess) {
          return {
            'success': false,
            'message': 'Pembayaran untuk reservasi ini sudah berhasil',
          };
        }
      }

      final paymentId = _generateId();
      final orderId = _generateOrderId(reservasiId);
      final createdAt = DateTime.now();

      // Create transaction di Midtrans
      final midtransResult = await _midtransService.createTransaction(
        orderId: orderId,
        reservasiId: reservasiId,
        userId: userId,
        grossAmount: totalPembayaran,
        customerName: customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        itemName: itemName,
        itemQuantity: itemQuantity,
      );

      if (!midtransResult['success']) {
        return {
          'success': false,
          'message':
              midtransResult['message'] ?? 'Gagal membuat transaksi Midtrans',
        };
      }

      final snapToken = midtransResult['snap_token'] as String;
      final snapRedirectUrl =
          midtransResult['snap_redirect_url'] as String? ?? '';
      final expiryTimeStr = midtransResult['expiry_time'] as String?;
      DateTime? expiryTime;
      if (expiryTimeStr != null && expiryTimeStr.isNotEmpty) {
        expiryTime = DateTime.tryParse(expiryTimeStr);
      }

      // Simpan payment ke database
      final result = await _dataService.insertPaymentMidtrans(
        appid,
        paymentId,
        orderId,
        '', // transaction_id akan diisi dari webhook
        reservasiId,
        userId,
        totalPembayaran.toString(),
        'midtrans',
        '', // payment_type akan diisi dari webhook
        PaymentStatus.pending,
        snapToken,
        snapRedirectUrl,
        '', // va_numbers akan diisi dari webhook
        '', // payment_code akan diisi dari webhook
        '', // settlement_time akan diisi dari webhook
        expiryTime?.toIso8601String() ?? '',
        createdAt.toIso8601String(),
        '',
      );

      if (result != '[]') {
        final payment = PaymentModel(
          paymentId: paymentId,
          orderId: orderId,
          reservasiId: reservasiId,
          userId: userId,
          totalPembayaran: totalPembayaran,
          metodePembayaran: 'midtrans',
          status: PaymentStatus.pending,
          snapToken: snapToken,
          snapRedirectUrl: snapRedirectUrl,
          expiryTime: expiryTime,
          createdAt: createdAt,
        );

        return {
          'success': true,
          'message': 'Payment berhasil dibuat',
          'payment': payment,
          'snap_token': snapToken,
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal menyimpan payment ke database',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Update payment status dari Midtrans callback
  Future<Map<String, dynamic>> updatePaymentFromMidtrans({
    required String orderId,
    required String transactionId,
    required String transactionStatus,
    String? paymentType,
    String? vaNumbers,
    String? paymentCode,
    String? settlementTime,
  }) async {
    try {
      // Get payment by order_id
      final existing = await getPaymentByOrderId(orderId);
      if (!existing['success']) {
        return {'success': false, 'message': 'Payment tidak ditemukan'};
      }

      final payment = existing['payment'] as PaymentModel;
      final now = DateTime.now().toIso8601String();

      // Update transaction_id
      if (transactionId.isNotEmpty) {
        await _dataService.updateWhere(
          'order_id',
          orderId,
          'transaction_id',
          transactionId,
          token,
          project,
          'payments',
          appid,
        );
      }

      // Update transaction_status
      await _dataService.updateWhere(
        'order_id',
        orderId,
        'status',
        transactionStatus,
        token,
        project,
        'payments',
        appid,
      );

      // Update payment_type
      if (paymentType != null && paymentType.isNotEmpty) {
        await _dataService.updateWhere(
          'order_id',
          orderId,
          'payment_type',
          paymentType,
          token,
          project,
          'payments',
          appid,
        );
      }

      // Update va_numbers
      if (vaNumbers != null && vaNumbers.isNotEmpty) {
        await _dataService.updateWhere(
          'order_id',
          orderId,
          'va_numbers',
          vaNumbers,
          token,
          project,
          'payments',
          appid,
        );
      }

      // Update payment_code
      if (paymentCode != null && paymentCode.isNotEmpty) {
        await _dataService.updateWhere(
          'order_id',
          orderId,
          'payment_code',
          paymentCode,
          token,
          project,
          'payments',
          appid,
        );
      }

      // Update settlement_time
      if (settlementTime != null && settlementTime.isNotEmpty) {
        await _dataService.updateWhere(
          'order_id',
          orderId,
          'settlement_time',
          settlementTime,
          token,
          project,
          'payments',
          appid,
        );
      }

      // Update updatedat
      await _dataService.updateWhere(
        'order_id',
        orderId,
        'updatedat',
        now,
        token,
        project,
        'payments',
        appid,
      );

      // Update status reservasi berdasarkan status pembayaran
      String? newReservasiStatus;
      if (transactionStatus == PaymentStatus.settlement ||
          transactionStatus == PaymentStatus.capture) {
        newReservasiStatus =
            ReservasiStatus.paid; // Sudah bayar, menunggu admin approve/reject
      } else if (transactionStatus == PaymentStatus.cancel ||
          transactionStatus == PaymentStatus.expire) {
        newReservasiStatus = ReservasiStatus.cancelled;
      } else if (transactionStatus == PaymentStatus.deny) {
        newReservasiStatus = ReservasiStatus.rejected;
      }

      if (newReservasiStatus != null) {
        await _dataService.updateWhere(
          'reservasi_id',
          payment.reservasiId,
          'status',
          newReservasiStatus,
          token,
          project,
          'reservasi',
          appid,
        );
      }

      return {'success': true, 'message': 'Payment berhasil diupdate'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Get payment by order ID
  Future<Map<String, dynamic>> getPaymentByOrderId(String orderId) async {
    try {
      if (orderId.isEmpty) {
        return {'success': false, 'message': 'Order ID tidak boleh kosong'};
      }

      final result = await _dataService.selectWhere(
        token,
        project,
        'payments',
        appid,
        'order_id',
        orderId,
      );

      final paymentsData = _parseApiResponse(result);
      if (paymentsData.isEmpty) {
        return {'success': false, 'message': 'Payment tidak ditemukan'};
      }

      final payment = PaymentModel.fromJson(paymentsData.first);
      return {
        'success': true,
        'message': 'Payment ditemukan',
        'payment': payment,
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Get payment by reservasi ID
  Future<Map<String, dynamic>> getPaymentByReservasiId(
    String reservasiId,
  ) async {
    try {
      if (reservasiId.isEmpty) {
        return {'success': false, 'message': 'Reservasi ID tidak boleh kosong'};
      }

      final result = await _dataService.selectWhere(
        token,
        project,
        'payments',
        appid,
        'reservasi_id',
        reservasiId,
      );

      final paymentsData = _parseApiResponse(result);
      if (paymentsData.isEmpty) {
        return {'success': false, 'message': 'Payment tidak ditemukan'};
      }

      final payment = PaymentModel.fromJson(paymentsData.first);
      return {
        'success': true,
        'message': 'Payment ditemukan',
        'payment': payment,
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Get payment by ID
  Future<Map<String, dynamic>> getPaymentById(String paymentId) async {
    try {
      if (paymentId.isEmpty) {
        return {'success': false, 'message': 'Payment ID tidak boleh kosong'};
      }

      final result = await _dataService.selectWhere(
        token,
        project,
        'payments',
        appid,
        'payment_id',
        paymentId,
      );

      final paymentsData = _parseApiResponse(result);
      if (paymentsData.isEmpty) {
        return {'success': false, 'message': 'Payment tidak ditemukan'};
      }

      final payment = PaymentModel.fromJson(paymentsData.first);
      return {
        'success': true,
        'message': 'Payment ditemukan',
        'payment': payment,
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Get all payments by user ID
  Future<Map<String, dynamic>> getPaymentsByUserId(String userId) async {
    try {
      if (userId.isEmpty) {
        return {'success': false, 'message': 'User ID tidak boleh kosong'};
      }

      final result = await _dataService.selectWhere(
        token,
        project,
        'payments',
        appid,
        'user_id',
        userId,
      );

      final paymentsData = _parseApiResponse(result);
      final List<PaymentModel> payments = paymentsData
          .map((data) => PaymentModel.fromJson(data))
          .toList();

      return {
        'success': true,
        'message': 'Berhasil mengambil data payments',
        'payments': payments,
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Get all payments (admin only)
  Future<Map<String, dynamic>> getAllPayments() async {
    try {
      final result = await _dataService.selectAll(
        token,
        project,
        'payments',
        appid,
      );

      final paymentsData = _parseApiResponse(result);
      final List<PaymentModel> payments = paymentsData
          .map((data) => PaymentModel.fromJson(data))
          .toList();

      return {
        'success': true,
        'message': 'Berhasil mengambil data payments',
        'payments': payments,
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Check and refresh payment status from Midtrans
  Future<Map<String, dynamic>> refreshPaymentStatus(String orderId) async {
    try {
      final statusResult = await _midtransService.checkTransactionStatus(
        orderId,
      );

      if (!statusResult['success']) {
        return statusResult;
      }

      final data = statusResult['data'] as Map<String, dynamic>;
      final transactionStatus = data['transaction_status'] as String? ?? '';
      final transactionId = data['transaction_id'] as String? ?? '';
      final paymentType = data['payment_type'] as String?;
      final settlementTime = data['settlement_time'] as String?;

      // Extract VA numbers if available
      String? vaNumbers;
      if (data['va_numbers'] != null && data['va_numbers'] is List) {
        final vaList = data['va_numbers'] as List;
        if (vaList.isNotEmpty) {
          vaNumbers = jsonEncode(vaList);
        }
      }

      // Update payment in database
      return await updatePaymentFromMidtrans(
        orderId: orderId,
        transactionId: transactionId,
        transactionStatus: transactionStatus,
        paymentType: paymentType,
        vaNumbers: vaNumbers,
        settlementTime: settlementTime,
      );
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // ============================================================
  // Legacy methods untuk backward compatibility
  // ============================================================

  /// Create payment (legacy - manual upload)
  Future<Map<String, dynamic>> createPayment({
    required String reservasiId,
    required String userId,
    required int totalBayar,
    required String metodePembayaran,
    String? buktiPembayaran,
  }) async {
    try {
      final paymentId = _generateId();
      final createdAt = DateTime.now().toIso8601String();

      final result = await _dataService.insertPayments(
        appid,
        paymentId,
        reservasiId,
        userId,
        totalBayar.toString(),
        metodePembayaran,
        buktiPembayaran ?? '',
        PaymentStatus.pending,
        createdAt,
      );

      if (result != '[]') {
        return {'success': true, 'message': 'Payment berhasil dibuat'};
      } else {
        return {'success': false, 'message': 'Gagal menyimpan payment'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Upload bukti pembayaran (legacy)
  Future<Map<String, dynamic>> uploadBuktiPembayaran({
    required String paymentId,
    required String buktiUrl,
  }) async {
    try {
      await _dataService.updateWhere(
        'payment_id',
        paymentId,
        'bukti_pembayaran',
        buktiUrl,
        token,
        project,
        'payments',
        appid,
      );
      await _dataService.updateWhere(
        'payment_id',
        paymentId,
        'updatedat',
        DateTime.now().toIso8601String(),
        token,
        project,
        'payments',
        appid,
      );
      return {'success': true, 'message': 'Bukti pembayaran berhasil diupload'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Confirm payment (admin only)
  Future<Map<String, dynamic>> confirmPayment(String paymentId) async {
    try {
      await _dataService.updateWhere(
        'payment_id',
        paymentId,
        'status',
        PaymentStatus.settlement,
        token,
        project,
        'payments',
        appid,
      );
      await _dataService.updateWhere(
        'payment_id',
        paymentId,
        'updatedat',
        DateTime.now().toIso8601String(),
        token,
        project,
        'payments',
        appid,
      );
      return {'success': true, 'message': 'Payment berhasil dikonfirmasi'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Update payment status (admin only)
  Future<Map<String, dynamic>> updatePaymentStatus({
    required String paymentId,
    required String newStatus,
  }) async {
    try {
      await _dataService.updateWhere(
        'payment_id',
        paymentId,
        'status',
        newStatus,
        token,
        project,
        'payments',
        appid,
      );
      await _dataService.updateWhere(
        'payment_id',
        paymentId,
        'updatedat',
        DateTime.now().toIso8601String(),
        token,
        project,
        'payments',
        appid,
      );
      return {'success': true, 'message': 'Status payment berhasil diupdate'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Sync payment status dari Midtrans dan update reservasi
  Future<Map<String, dynamic>> syncPaymentStatusFromMidtrans(String orderId) async {
    try {
      // Check status dari Midtrans API
      final statusResult = await _midtransService.checkTransactionStatus(orderId);
      
      if (statusResult['success'] != true) {
        return {
          'success': false,
          'message': statusResult['message'] ?? 'Gagal mengecek status dari Midtrans',
        };
      }

      final transactionStatus = statusResult['transaction_status'] as String;
      final paymentType = statusResult['payment_type'] as String?;
      
      // Convert Midtrans status ke PaymentStatus (gunakan status lama)
      String paymentStatus;
      String reservasiStatus;
      
      if (transactionStatus == 'settlement' || transactionStatus == 'capture') {
        paymentStatus = PaymentStatus.settlement;
        reservasiStatus = 'paid'; // Status lama: paid (sudah bayar, menunggu approval admin)
      } else if (transactionStatus == 'pending') {
        paymentStatus = PaymentStatus.pending;
        reservasiStatus = 'belum_bayar';
      } else if (transactionStatus == 'deny' || transactionStatus == 'cancel' || transactionStatus == 'expire') {
        paymentStatus = PaymentStatus.failure;
        reservasiStatus = 'cancelled';
      } else {
        paymentStatus = PaymentStatus.pending;
        reservasiStatus = 'belum_bayar';
      }

      // Get payment by order_id
      final paymentResult = await getPaymentByOrderId(orderId);
      if (!paymentResult['success']) {
        return {'success': false, 'message': 'Payment tidak ditemukan'};
      }

      final payment = paymentResult['payment'] as PaymentModel;
      
      // Update payment status di database
      await updatePaymentFromMidtrans(
        orderId: orderId,
        transactionId: orderId,
        transactionStatus: transactionStatus,
        paymentType: paymentType,
      );

      // Update status reservasi di database jika sudah bayar
      if (paymentStatus == PaymentStatus.settlement) {
        await _dataService.updateWhere(
          'reservasi_id',
          payment.reservasiId,
          'status',
          reservasiStatus,
          token,
          project,
          'reservasi',
          appid,
        );
      }

      return {
        'success': true,
        'message': 'Status berhasil disinkronkan',
        'payment_status': paymentStatus.toString(),
        'reservasi_status': reservasiStatus,
        'transaction_status': transactionStatus,
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
}

