import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// Conditional import for Midtrans SDK (only for mobile)
import 'midtrans_mobile.dart' if (dart.library.html) 'midtrans_web.dart';

/// Konfigurasi Midtrans untuk QuadraPlay
class MidtransAppConfig {
  // Sandbox credentials
  static const String clientKey = 'Mid-client-DVAMVogPvIprVqdb';
  static const String merchantId = 'G435251730';
  static const String serverKey = 'Mid-server-3qgT8saiYzGrj5nZu5cdpmhd'; // SANDBOX ONLY!

  // Direct Midtrans API (untuk testing tanpa backend)
  static const String snapApiUrl = 'https://app.sandbox.midtrans.com/snap/v1/transactions';

  // Sandbox Snap URL
  static const String snapUrl = 'https://app.sandbox.midtrans.com/snap/v2/vtweb/';

  // Sandbox mode
  static const bool isProduction = false;
}

/// Service untuk handle Midtrans payment
class MidtransService {
  bool _isInitialized = false;
  final MidtransPlatform _platform = MidtransPlatform();

  /// Singleton pattern
  static final MidtransService _instance = MidtransService._internal();
  factory MidtransService() => _instance;
  MidtransService._internal();

  /// Check if SDK is initialized
  bool get isInitialized => _isInitialized;

  /// Check if running on web
  bool get isWeb => kIsWeb;

  /// Initialize Midtrans SDK
  Future<void> initMidtrans(BuildContext context) async {
    if (_isInitialized) return;

    try {
      if (kIsWeb) {
        // Web: No SDK needed, use redirect
        _isInitialized = true;
        debugPrint('Midtrans Web Mode initialized (using Snap Redirect)');
      } else {
        // Mobile: Initialize SDK
        await _platform.initSDK(context);
        _isInitialized = true;
        debugPrint('Midtrans SDK initialized successfully');
      }
    } catch (e) {
      debugPrint('Error initializing Midtrans: $e');
      // For web, still mark as initialized to allow redirect mode
      if (kIsWeb) {
        _isInitialized = true;
      } else {
        rethrow;
      }
    }
  }

  /// Create transaction and get snap token - DIRECT to Midtrans API (SANDBOX ONLY!)
  /// WARNING: Jangan gunakan di production! Server key harus di backend.
  Future<Map<String, dynamic>> createTransaction({
    required String orderId,
    required String reservasiId,
    required String userId,
    required int grossAmount,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String itemName,
    required int itemQuantity,
  }) async {
    try {
      debugPrint('Calling Midtrans API directly (SANDBOX MODE)');
      
      // Basic auth dengan Server Key
      final authString = base64Encode(utf8.encode('${MidtransAppConfig.serverKey}:'));
      
      // Tambahkan timeout 30 detik untuk mencegah loading infinite
      final response = await http.post(
        Uri.parse(MidtransAppConfig.snapApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Basic $authString',
        },
        body: jsonEncode({
          'transaction_details': {
            'order_id': orderId,
            'gross_amount': grossAmount,
          },
          'customer_details': {
            'first_name': customerName,
            'email': customerEmail,
            'phone': customerPhone,
          },
          'item_details': [
            {
              'id': reservasiId,
              'price': itemQuantity > 0 ? (grossAmount ~/ itemQuantity) : grossAmount, // Harga per unit
              'quantity': itemQuantity,
              'name': itemName,
            },
          ],
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timeout setelah 30 detik');
        },
      );

      debugPrint('Midtrans Response: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Midtrans API langsung mengembalikan token dan redirect_url
        final snapToken = data['token'] as String;
        final redirectUrl = data['redirect_url'] as String;
        return {
          'success': true,
          'snap_token': snapToken,
          'snap_redirect_url': redirectUrl,
          'order_id': orderId,
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['error_messages']?.join(', ') ?? 'Server error: ${response.statusCode}',
        };
      }
    } on http.ClientException catch (e) {
      debugPrint('Network error creating transaction: $e');
      return {'success': false, 'message': 'Koneksi gagal. Periksa internet Anda.'};
    } catch (e) {
      debugPrint('Error creating transaction: $e');
      String errorMessage = 'Terjadi kesalahan';
      if (e.toString().contains('SocketException') || e.toString().contains('Connection')) {
        errorMessage = 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Koneksi timeout. Silakan coba lagi.';
      }
      return {'success': false, 'message': errorMessage};
    }
  }

  /// Start payment - Membuka halaman pembayaran Midtrans di browser
  Future<void> startPayment(String snapToken) async {
    // Gunakan URL redirect untuk semua platform (web & mobile)
    // Ini lebih reliable daripada SDK native
    final url = '${MidtransAppConfig.snapUrl}$snapToken';
    final uri = Uri.parse(url);
    
    debugPrint('Opening payment URL: $url');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri, 
        mode: LaunchMode.externalApplication, // Buka di browser eksternal
      );
    } else {
      throw Exception('Tidak dapat membuka halaman pembayaran');
    }
  }

  /// Check transaction status - DIRECT to Midtrans API (SANDBOX ONLY!)
  Future<Map<String, dynamic>> checkTransactionStatus(String orderId) async {
    try {
      final authString = base64Encode(utf8.encode('${MidtransAppConfig.serverKey}:'));
      final statusUrl = 'https://api.sandbox.midtrans.com/v2/$orderId/status';
      
      final response = await http.get(
        Uri.parse(statusUrl),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Basic $authString',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'transaction_status': data['transaction_status'],
          'order_id': data['order_id'],
          'gross_amount': data['gross_amount'],
          'payment_type': data['payment_type'],
          'data': data,
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Transaction not found',
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Error checking transaction status: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Set callback untuk transaction finished (only for mobile)
  void setTransactionFinishedCallback(Function(dynamic) callback) {
    if (!kIsWeb) {
      _platform.setTransactionFinishedCallback(callback);
    }
  }

  /// Remove callback
  void removeTransactionFinishedCallback() {
    if (!kIsWeb) {
      _platform.removeTransactionFinishedCallback();
    }
  }
}
