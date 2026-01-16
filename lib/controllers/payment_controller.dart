import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';

/// Controller untuk Payment menggunakan ChangeNotifier (Provider)
class PaymentController extends ChangeNotifier {
  final PaymentService _paymentService = PaymentService();

  List<PaymentModel> _payments = [];
  PaymentModel? _selectedPayment;
  bool _isLoading = false;
  String? _errorMessage;
  String? _filterStatus;

  // Getters
  List<PaymentModel> get payments => _payments;
  List<PaymentModel> get filteredPayments {
    if (_filterStatus == null || _filterStatus!.isEmpty) {
      return _payments;
    }
    return _payments.where((p) => p.status == _filterStatus).toList();
  }

  PaymentModel? get selectedPayment => _selectedPayment;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get filterStatus => _filterStatus;

  /// Create payment dengan Midtrans
  Future<Map<String, dynamic>?> createPaymentWithMidtrans({
    required String reservasiId,
    required String userId,
    required int totalPembayaran,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String itemName,
    int itemQuantity = 1,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _paymentService.createPaymentWithMidtrans(
        reservasiId: reservasiId,
        userId: userId,
        totalPembayaran: totalPembayaran,
        customerName: customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        itemName: itemName,
        itemQuantity: itemQuantity,
      );

      if (result['success'] == true) {
        await loadAllPayments(); // Refresh list
        return result;
      } else {
        _errorMessage = result['message'] ?? 'Gagal membuat pembayaran';
        notifyListeners();
        return result;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      notifyListeners();
      return {'success': false, 'message': _errorMessage};
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh payment status dari Midtrans
  Future<bool> refreshPaymentStatus(String orderId) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _paymentService.refreshPaymentStatus(orderId);

      if (result['success'] == true) {
        await loadAllPayments(); // Refresh list
        return true;
      } else {
        _errorMessage = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get payment by Order ID
  Future<PaymentModel?> getPaymentByOrderId(String orderId) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _paymentService.getPaymentByOrderId(orderId);

      if (result['success'] == true) {
        _selectedPayment = result['payment'];
        notifyListeners();
        return _selectedPayment;
      } else {
        _errorMessage = result['message'];
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Create payment baru (legacy - manual upload)
  Future<bool> createPayment({
    required String reservasiId,
    required String userId,
    required int totalBayar,
    required String metodePembayaran,
    XFile? buktiFile,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      String buktiUrl = '';

      // Convert bukti pembayaran to base64 jika ada
      if (buktiFile != null) {
        print('DEBUG: Converting bukti pembayaran to base64...');
        final bytes = await buktiFile.readAsBytes();
        final base64Image = base64Encode(bytes);
        final ext = buktiFile.name.split('.').last.toLowerCase();
        final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
        buktiUrl = 'data:$mimeType;base64,$base64Image';
        print('DEBUG: Bukti converted to base64, length: ${buktiUrl.length}');
      }

      final result = await _paymentService.createPayment(
        reservasiId: reservasiId,
        userId: userId,
        totalBayar: totalBayar,
        metodePembayaran: metodePembayaran,
        buktiPembayaran: buktiUrl,
      );

      if (result['success']) {
        await loadAllPayments(); // Refresh list
        return true;
      } else {
        _errorMessage = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Upload bukti pembayaran
  Future<bool> uploadBuktiPembayaran({
    required String paymentId,
    required XFile buktiFile,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Convert bukti pembayaran to base64
      print('DEBUG: Converting bukti pembayaran to base64...');
      final bytes = await buktiFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final ext = buktiFile.name.split('.').last.toLowerCase();
      final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
      final buktiUrl = 'data:$mimeType;base64,$base64Image';
      print('DEBUG: Bukti converted to base64, length: ${buktiUrl.length}');

      final result = await _paymentService.uploadBuktiPembayaran(
        paymentId: paymentId,
        buktiUrl: buktiUrl,
      );

      if (result['success']) {
        await loadAllPayments(); // Refresh list
        return true;
      } else {
        _errorMessage = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get payment by reservasi ID
  Future<PaymentModel?> getPaymentByReservasiId(String reservasiId) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _paymentService.getPaymentByReservasiId(reservasiId);

      if (result['success']) {
        _selectedPayment = result['payment'];
        notifyListeners();
        return _selectedPayment;
      } else {
        _errorMessage = result['message'];
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Load payments by user ID
  Future<void> loadPaymentsByUser(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _paymentService.getPaymentsByUserId(userId);

      if (result['success']) {
        _payments = result['payments'];
        notifyListeners();
      } else {
        _errorMessage = result['message'];
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Load all payments (admin only)
  Future<void> loadAllPayments() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _paymentService.getAllPayments();

      if (result['success']) {
        _payments = result['payments'];
        notifyListeners();
      } else {
        _errorMessage = result['message'];
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Confirm payment (admin only)
  Future<bool> confirmPayment(String paymentId) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _paymentService.confirmPayment(paymentId);

      if (result['success']) {
        await loadAllPayments(); // Refresh list
        return true;
      } else {
        _errorMessage = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update payment status (admin only)
  Future<bool> updatePaymentStatus({
    required String paymentId,
    required String newStatus,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _paymentService.updatePaymentStatus(
        paymentId: paymentId,
        newStatus: newStatus,
      );

      if (result['success']) {
        await loadAllPayments(); // Refresh list
        return true;
      } else {
        _errorMessage = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Set filter status
  void setFilterStatus(String? status) {
    _filterStatus = status;
    notifyListeners();
  }

  /// Clear selected payment
  void clearSelectedPayment() {
    _selectedPayment = null;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Clear error (public)
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Sync payment status dari Midtrans
  Future<Map<String, dynamic>> syncPaymentStatus(String orderId) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _paymentService.syncPaymentStatusFromMidtrans(orderId);
      
      if (result['success'] == true) {
        // Refresh payment list
        await loadPaymentsByUser(_selectedPayment?.userId ?? '');
      }

      return result;
    } catch (e) {
      _errorMessage = e.toString();
      return {'success': false, 'message': e.toString()};
    } finally {
      _setLoading(false);
    }
  }
}
