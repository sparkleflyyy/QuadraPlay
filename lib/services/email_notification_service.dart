import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Service untuk mengirim notifikasi email
/// Web: via EmailJS (JavaScript)
/// Mobile: via Backend PHP
class EmailNotificationService {
  // EmailJS Configuration (untuk Web)
  static const String _serviceId = 'service_vawipxo';
  static const String _templateId = 'template_ogfn0dc';
  
  // Backend URL untuk mobile
  static const String _backendUrl = 'https://sfrfrr25.004.az.biz.id/backend/services/send_notification.php';

  /// Kirim email konfirmasi reservasi
  static Future<Map<String, dynamic>> sendReservationConfirmation({
    required String email,
    required String reservasiId,
    required String customerName,
    required String itemName,
    required int jumlahUnit,
    required int jumlahHari,
    required String tglMulai,
    required String tglSelesai,
    required int totalHarga,
    required String alamat,
    required String noWA,
  }) async {
    try {
      debugPrint('========== EMAIL NOTIFICATION DEBUG ==========');
      debugPrint('To: $email');
      debugPrint('Platform: ${kIsWeb ? "Web" : "Mobile"}');
      
      if (kIsWeb) {
        // Web: Gunakan EmailJS via JavaScript interop
        return await _sendViaEmailJS(
          email: email,
          reservasiId: reservasiId,
          customerName: customerName,
          itemName: itemName,
          jumlahUnit: jumlahUnit,
          jumlahHari: jumlahHari,
          tglMulai: tglMulai,
          tglSelesai: tglSelesai,
          totalHarga: totalHarga,
          alamat: alamat,
          noWA: noWA,
        );
      } else {
        // Mobile: Gunakan Backend PHP
        return await _sendViaBackend(
          email: email,
          reservasiId: reservasiId,
          customerName: customerName,
          itemName: itemName,
          jumlahUnit: jumlahUnit,
          jumlahHari: jumlahHari,
          tglMulai: tglMulai,
          tglSelesai: tglSelesai,
          totalHarga: totalHarga,
          alamat: alamat,
          noWA: noWA,
        );
      }
    } catch (e) {
      debugPrint('❌ Exception: $e');
      debugPrint('==============================================');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Kirim email via Backend PHP (untuk Mobile)
  static Future<Map<String, dynamic>> _sendViaBackend({
    required String email,
    required String reservasiId,
    required String customerName,
    required String itemName,
    required int jumlahUnit,
    required int jumlahHari,
    required String tglMulai,
    required String tglSelesai,
    required int totalHarga,
    required String alamat,
    required String noWA,
  }) async {
    try {
      debugPrint('Sending via Backend PHP...');
      
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'to_email': email,
          'to_name': customerName,
          'customer_name': customerName,
          'reservasi_id': reservasiId,
          'item_name': itemName,
          'jumlah_unit': jumlahUnit.toString(),
          'jumlah_hari': jumlahHari.toString(),
          'tgl_mulai': tglMulai,
          'tgl_selesai': tglSelesai,
          'total_harga': _formatCurrency(totalHarga),
          'alamat': alamat,
          'no_wa': noWA,
        }),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        debugPrint('✅ Email sent via backend!');
        return {
          'success': true,
          'message': 'Email sent to $email',
        };
      } else {
        debugPrint('❌ Backend error: ${response.body}');
        return {
          'success': false,
          'message': 'Backend error: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('❌ Backend exception: $e');
      // Jangan gagalkan proses jika email gagal
      return {
        'success': false,
        'message': 'Email service unavailable',
      };
    }
  }

  /// Kirim email via EmailJS (untuk Web) - stub untuk platform non-web
  static Future<Map<String, dynamic>> _sendViaEmailJS({
    required String email,
    required String reservasiId,
    required String customerName,
    required String itemName,
    required int jumlahUnit,
    required int jumlahHari,
    required String tglMulai,
    required String tglSelesai,
    required int totalHarga,
    required String alamat,
    required String noWA,
  }) async {
    // Untuk web, kita perlu menggunakan conditional import
    // Ini akan di-handle oleh file terpisah jika diperlukan
    debugPrint('EmailJS called on web platform');
    debugPrint('Service ID: $_serviceId');
    debugPrint('Template ID: $_templateId');
    
    // Untuk sementara, return success (EmailJS dipanggil via index.html)
    return {
      'success': true,
      'message': 'Email request sent to $email (Web)',
    };
  }

  /// Format angka ke format currency Indonesia
  static String _formatCurrency(int amount) {
    String result = amount.toString();
    String formatted = '';
    int count = 0;

    for (int i = result.length - 1; i >= 0; i--) {
      count++;
      formatted = result[i] + formatted;
      if (count % 3 == 0 && i != 0) {
        formatted = '.$formatted';
      }
    }

    return formatted;
  }
}
