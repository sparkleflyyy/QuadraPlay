import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:quadraplay/config.dart';
import 'package:quadraplay/restapi.dart';
import '../models/payment_model.dart';
import '../models/reservasi_model.dart';

/// Service untuk operasi Payment
class PaymentService {
  final DataService _dataService = DataService();

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

  /// Create payment baru
  Future<Map<String, dynamic>> createPayment({
    required String reservasiId,
    required String userId,
    required int totalBayar,
    required String metodePembayaran,
    String buktiPembayaran = '',
  }) async {
    try {
      // Validasi input
      if (reservasiId.isEmpty) {
        return {'success': false, 'message': 'Reservasi ID tidak boleh kosong'};
      }
      if (userId.isEmpty) {
        return {'success': false, 'message': 'User ID tidak boleh kosong'};
      }
      if (metodePembayaran.isEmpty) {
        return {
          'success': false,
          'message': 'Metode pembayaran tidak boleh kosong',
        };
      }

      // Cek apakah sudah ada payment untuk reservasi ini
      final existing = await getPaymentByReservasiId(reservasiId);
      if (existing['success']) {
        return {
          'success': false,
          'message': 'Payment untuk reservasi ini sudah ada',
        };
      }

      final paymentId = _generateId();
      final createdAt = DateTime.now().toIso8601String();

      final result = await _dataService.insertPayments(
        appid,
        paymentId,
        reservasiId,
        userId,
        totalBayar.toString(),
        metodePembayaran,
        buktiPembayaran,
        PaymentStatus.waiting,
        createdAt,
      );

      if (result != '[]') {
        // Update status reservasi menjadi pending (menunggu approval)
        print('DEBUG: Updating reservasi status to pending...');
        final updateResult = await _dataService.updateWhere(
          'reservasi_id', // where_field
          reservasiId, // where_value
          'status', // update_field
          ReservasiStatus.pending, // update_value
          token,
          project,
          'reservasi',
          appid,
        );
        print('DEBUG: Reservasi status update result: $updateResult');

        final payment = PaymentModel(
          paymentId: paymentId,
          reservasiId: reservasiId,
          userId: userId,
          totalBayar: totalBayar,
          metodePembayaran: metodePembayaran,
          buktiPembayaran: buktiPembayaran,
          status: PaymentStatus.waiting,
          createdAt: DateTime.now(),
        );

        return {
          'success': true,
          'message': 'Payment berhasil dibuat',
          'payment': payment,
        };
      } else {
        return {'success': false, 'message': 'Gagal membuat payment'};
      }
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

  /// Upload bukti pembayaran
  Future<Map<String, dynamic>> uploadBuktiPembayaran({
    required String paymentId,
    required String buktiUrl,
  }) async {
    try {
      if (paymentId.isEmpty) {
        return {'success': false, 'message': 'Payment ID tidak boleh kosong'};
      }
      if (buktiUrl.isEmpty) {
        return {
          'success': false,
          'message': 'URL bukti pembayaran tidak boleh kosong',
        };
      }

      // Cek apakah payment ada
      final existing = await getPaymentById(paymentId);
      if (!existing['success']) {
        return {'success': false, 'message': 'Payment tidak ditemukan'};
      }

      // Update bukti pembayaran
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

      // Update status ke 'paid'
      await _dataService.updateWhere(
        'payment_id',
        paymentId,
        'status',
        PaymentStatus.paid,
        token,
        project,
        'payments',
        appid,
      );

      // Update status reservasi ke 'pending' (menunggu approval admin)
      final payment = existing['payment'] as PaymentModel;
      await _dataService.updateWhere(
        'reservasi_id',
        payment.reservasiId,
        'status',
        ReservasiStatus.pending,
        token,
        project,
        'reservasi',
        appid,
      );

      return {'success': true, 'message': 'Bukti pembayaran berhasil diupload'};
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
      if (paymentId.isEmpty) {
        return {'success': false, 'message': 'Payment ID tidak boleh kosong'};
      }
      if (!PaymentModel.isValidStatus(newStatus)) {
        return {'success': false, 'message': 'Status tidak valid'};
      }

      // Cek apakah payment ada
      final existing = await getPaymentById(paymentId);
      if (!existing['success']) {
        return {'success': false, 'message': 'Payment tidak ditemukan'};
      }

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

      return {
        'success': true,
        'message': 'Status payment berhasil diupdate ke $newStatus',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Confirm payment (admin only)
  Future<Map<String, dynamic>> confirmPayment(String paymentId) async {
    return updatePaymentStatus(
      paymentId: paymentId,
      newStatus: PaymentStatus.confirmed,
    );
  }

  /// Get payments by status
  Future<Map<String, dynamic>> getPaymentsByStatus(String status) async {
    try {
      if (!PaymentModel.isValidStatus(status)) {
        return {'success': false, 'message': 'Status tidak valid'};
      }

      final result = await _dataService.selectWhere(
        token,
        project,
        'payments',
        appid,
        'status',
        status,
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
}
