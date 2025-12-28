import 'package:flutter/material.dart';
import 'package:midtrans_sdk/midtrans_sdk.dart';
import 'midtrans_service.dart';

/// Mobile implementation using Midtrans SDK
class MidtransPlatform {
  MidtransSDK? _midtrans;
  bool _isInitialized = false;

  Future<void> initSDK(BuildContext context) async {
    if (_isInitialized && _midtrans != null) {
      debugPrint('Midtrans SDK already initialized');
      return;
    }

    try {
      debugPrint('Initializing Midtrans SDK for mobile...');
      _midtrans = await MidtransSDK.init(
        config: MidtransConfig(
          clientKey: MidtransAppConfig.clientKey,
          merchantBaseUrl: '', // Tidak diperlukan karena menggunakan direct API
          enableLog: true,
          colorTheme: ColorTheme(
            colorPrimary: const Color(0xFF667eea),
            colorPrimaryDark: const Color(0xFF764ba2),
            colorSecondary: const Color(0xFF667eea),
          ),
        ),
      );
      _isInitialized = true;
      debugPrint('Midtrans SDK initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Midtrans SDK: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  Future<void> startPayment(String snapToken) async {
    if (_midtrans == null || !_isInitialized) {
      debugPrint('Midtrans SDK not initialized, attempting to initialize...');
      throw Exception(
        'Midtrans SDK belum diinisialisasi. Silakan restart aplikasi.',
      );
    }

    try {
      debugPrint(
        'Starting payment with token: ${snapToken.substring(0, 10)}...',
      );
      await _midtrans!.startPaymentUiFlow(token: snapToken);
    } catch (e) {
      debugPrint('Error starting payment: $e');
      rethrow;
    }
  }

  void setTransactionFinishedCallback(Function(dynamic) callback) {
    if (_midtrans != null) {
      _midtrans!.setTransactionFinishedCallback((result) {
        debugPrint('Transaction finished with result');
        callback(result);
      });
    } else {
      debugPrint('Warning: Cannot set callback, Midtrans SDK not initialized');
    }
  }

  void removeTransactionFinishedCallback() {
    _midtrans?.removeTransactionFinishedCallback();
  }
}
