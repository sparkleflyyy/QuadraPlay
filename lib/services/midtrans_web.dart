import 'package:flutter/material.dart';

/// Web implementation - no SDK, uses redirect only
class MidtransPlatform {
  Future<void> initSDK(BuildContext context) async {
    // Web doesn't need SDK initialization
  }

  Future<void> startPayment(String snapToken) async {
    // Web uses URL redirect, handled in midtrans_service.dart
    throw Exception('Use URL redirect for web');
  }

  void setTransactionFinishedCallback(Function(dynamic) callback) {
    // Not supported on web
  }

  void removeTransactionFinishedCallback() {
    // Not supported on web
  }
}
