import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:quadraplay/config.dart';
import 'package:quadraplay/restapi.dart';
import '../models/reservasi_model.dart';
import 'ps_item_service.dart';

/// Service untuk operasi Reservasi
class ReservasiService {
  final DataService _dataService = DataService();
  final PSItemService _psItemService = PSItemService();

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

  /// Create reservasi baru
  Future<Map<String, dynamic>> createReservasi({
    required String userId,
    required String psId,
    required int jumlahHari,
    required int jumlahUnit,
    required DateTime tglMulai,
    required DateTime tglSelesai,
    required String alamat,
    required String noWA,
    required String ktpUrl,
  }) async {
    try {
      // Validasi input
      if (userId.isEmpty) {
        return {'success': false, 'message': 'User ID tidak boleh kosong'};
      }
      if (psId.isEmpty) {
        return {'success': false, 'message': 'PS ID tidak boleh kosong'};
      }
      if (jumlahHari <= 0) {
        return {'success': false, 'message': 'Jumlah hari harus lebih dari 0'};
      }
      if (jumlahUnit <= 0) {
        return {'success': false, 'message': 'Jumlah unit harus lebih dari 0'};
      }
      if (alamat.isEmpty) {
        return {'success': false, 'message': 'Alamat tidak boleh kosong'};
      }
      if (noWA.isEmpty) {
        return {'success': false, 'message': 'Nomor WA tidak boleh kosong'};
      }
      if (ktpUrl.isEmpty) {
        return {'success': false, 'message': 'Foto KTP wajib diupload'};
      }

      // Get PS item untuk mendapatkan harga
      final psResult = await _psItemService.getPSItemById(psId);
      if (!psResult['success']) {
        return {'success': false, 'message': 'PS tidak ditemukan'};
      }

      final psItem = psResult['item'];
      
      // Cek stok
      if (psItem.stok < jumlahUnit) {
        return {'success': false, 'message': 'Stok tidak mencukupi'};
      }

      // Hitung total harga: jumlahHari × hargaPerHari × jumlahUnit
      final totalHarga = ReservasiModel.calculateTotalHarga(
        psItem.hargaPerHari, jumlahHari, jumlahUnit,
      );

      final reservasiId = _generateId();
      final createdAt = DateTime.now().toIso8601String();

      final result = await _dataService.insertReservasi(
        appid,
        reservasiId,
        userId,
        psId,
        jumlahHari.toString(),
        jumlahUnit.toString(),
        tglMulai.toIso8601String(),
        tglSelesai.toIso8601String(),
        alamat,
        noWA,
        ktpUrl,
        totalHarga.toString(),
        ReservasiStatus.belumBayar, // Status awal: belum bayar
        createdAt,
      );

      if (result != '[]') {
        final reservasi = ReservasiModel(
          reservasiId: reservasiId,
          userId: userId,
          psId: psId,
          jumlahHari: jumlahHari,
          jumlahUnit: jumlahUnit,
          tglMulai: tglMulai,
          tglSelesai: tglSelesai,
          alamat: alamat,
          noWA: noWA,
          ktpUrl: ktpUrl,
          totalHarga: totalHarga,
          status: ReservasiStatus.belumBayar,
          createdAt: DateTime.now(),
        );

        return {
          'success': true,
          'message': 'Reservasi berhasil dibuat',
          'reservasi': reservasi,
        };
      } else {
        return {'success': false, 'message': 'Gagal membuat reservasi'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Get reservasi by user ID
  Future<Map<String, dynamic>> getReservasiByUser(String userId) async {
    try {
      if (userId.isEmpty) {
        return {'success': false, 'message': 'User ID tidak boleh kosong'};
      }

      final result = await _dataService.selectWhere(
        token, project, 'reservasi', appid, 'user_id', userId,
      );

      final reservasiData = _parseApiResponse(result);
      final List<ReservasiModel> reservasiList = reservasiData
          .map((data) => ReservasiModel.fromJson(data))
          .toList();

      return {
        'success': true,
        'message': 'Berhasil mengambil data reservasi',
        'reservasi': reservasiList,
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Get reservasi by ID
  Future<Map<String, dynamic>> getReservasiById(String reservasiId) async {
    try {
      if (reservasiId.isEmpty) {
        return {'success': false, 'message': 'Reservasi ID tidak boleh kosong'};
      }

      final result = await _dataService.selectWhere(
        token, project, 'reservasi', appid, 'reservasi_id', reservasiId,
      );

      final reservasiData = _parseApiResponse(result);
      if (reservasiData.isEmpty) {
        return {'success': false, 'message': 'Reservasi tidak ditemukan'};
      }

      final reservasi = ReservasiModel.fromJson(reservasiData.first);
      return {
        'success': true,
        'message': 'Reservasi ditemukan',
        'reservasi': reservasi,
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Get all reservasi (admin only)
  Future<Map<String, dynamic>> getAllReservasi() async {
    try {
      final result = await _dataService.selectAll(
        token, project, 'reservasi', appid,
      );

      final reservasiData = _parseApiResponse(result);
      final List<ReservasiModel> reservasiList = reservasiData
          .map((data) => ReservasiModel.fromJson(data))
          .toList();

      return {
        'success': true,
        'message': 'Berhasil mengambil data reservasi',
        'reservasi': reservasiList,
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Update status reservasi (admin only)
  Future<Map<String, dynamic>> updateStatusReservasi({
    required String reservasiId,
    required String newStatus,
  }) async {
    try {
      if (reservasiId.isEmpty) {
        return {'success': false, 'message': 'Reservasi ID tidak boleh kosong'};
      }
      if (!ReservasiModel.isValidStatus(newStatus)) {
        return {'success': false, 'message': 'Status tidak valid: $newStatus'};
      }

      // Cek apakah reservasi ada
      final existing = await getReservasiById(reservasiId);
      if (!existing['success']) {
        return {'success': false, 'message': 'Reservasi tidak ditemukan'};
      }

      print('DEBUG: Updating reservasi $reservasiId to status $newStatus');
      
      final updateResult = await _dataService.updateWhere(
        'reservasi_id', reservasiId, 'status', newStatus,
        token, project, 'reservasi', appid,
      );
      
      print('DEBUG: Update result: $updateResult');
      
      if (updateResult != true) {
        return {'success': false, 'message': 'Gagal update status di database'};
      }

      // Jika status approved, kurangi stok
      if (newStatus == ReservasiStatus.approved) {
        final reservasi = existing['reservasi'] as ReservasiModel;
        final psResult = await _psItemService.getPSItemById(reservasi.psId);
        if (psResult['success']) {
          final psItem = psResult['item'];
          final newStok = psItem.stok - reservasi.jumlahUnit;
          if (newStok >= 0) {
            await _psItemService.updateStok(reservasi.psId, newStok);
          }
        }
      }

      // Jika status finished, kembalikan stok
      if (newStatus == ReservasiStatus.finished) {
        final reservasi = existing['reservasi'] as ReservasiModel;
        final psResult = await _psItemService.getPSItemById(reservasi.psId);
        if (psResult['success']) {
          final psItem = psResult['item'];
          final newStok = psItem.stok + reservasi.jumlahUnit;
          await _psItemService.updateStok(reservasi.psId, newStok);
        }
      }

      return {
        'success': true,
        'message': 'Status reservasi berhasil diupdate ke $newStatus',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Approve reservasi
  Future<Map<String, dynamic>> approveReservasi(String reservasiId) async {
    return updateStatusReservasi(
      reservasiId: reservasiId,
      newStatus: ReservasiStatus.approved,
    );
  }

  /// Reject reservasi
  Future<Map<String, dynamic>> rejectReservasi(String reservasiId) async {
    return updateStatusReservasi(
      reservasiId: reservasiId,
      newStatus: ReservasiStatus.rejected,
    );
  }

  /// Start reservasi (active)
  Future<Map<String, dynamic>> startReservasi(String reservasiId) async {
    return updateStatusReservasi(
      reservasiId: reservasiId,
      newStatus: ReservasiStatus.active,
    );
  }

  /// Finish reservasi
  Future<Map<String, dynamic>> finishReservasi(String reservasiId) async {
    return updateStatusReservasi(
      reservasiId: reservasiId,
      newStatus: ReservasiStatus.finished,
    );
  }

  /// Get reservasi by status
  Future<Map<String, dynamic>> getReservasiByStatus(String status) async {
    try {
      if (!ReservasiModel.isValidStatus(status)) {
        return {'success': false, 'message': 'Status tidak valid'};
      }

      final result = await _dataService.selectWhere(
        token, project, 'reservasi', appid, 'status', status,
      );

      final List<dynamic> reservasiData = jsonDecode(result);
      final List<ReservasiModel> reservasiList = reservasiData
          .map((data) => ReservasiModel.fromJson(data))
          .toList();

      return {
        'success': true,
        'message': 'Berhasil mengambil data reservasi',
        'reservasi': reservasiList,
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
}
