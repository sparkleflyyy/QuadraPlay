import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/reservasi_model.dart';
import '../services/reservasi_service.dart';

/// Controller untuk Reservasi menggunakan ChangeNotifier (Provider)
class ReservasiController extends ChangeNotifier {
  final ReservasiService _reservasiService = ReservasiService();

  List<ReservasiModel> _reservasiList = [];
  ReservasiModel? _selectedReservasi;
  bool _isLoading = false;
  String? _errorMessage;
  String? _filterStatus;

  String? _lastCreatedReservasiId;
  
  // Getters
  List<ReservasiModel> get reservasiList => _reservasiList;
  List<ReservasiModel> get filteredReservasi {
    if (_filterStatus == null || _filterStatus!.isEmpty) {
      return _reservasiList;
    }
    return _reservasiList.where((r) => r.status == _filterStatus).toList();
  }
  ReservasiModel? get selectedReservasi => _selectedReservasi;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get filterStatus => _filterStatus;
  String? get lastCreatedReservasiId => _lastCreatedReservasiId;

  /// Create reservasi baru
  Future<bool> createReservasi({
    required String userId,
    required String psId,
    required int jumlahHari,
    required int jumlahUnit,
    required DateTime tglMulai,
    required DateTime tglSelesai,
    required String alamat,
    required String noWA,
    required XFile ktpFile,
  }) async {
    _setLoading(true);
    _clearError();
    _lastCreatedReservasiId = null;

    try {
      print('DEBUG: Starting createReservasi...');
      print('DEBUG: userId=$userId, psId=$psId');
      
      // Convert image to base64 data URL untuk disimpan di database
      print('DEBUG: Converting KTP to base64...');
      final bytes = await ktpFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final ext = ktpFile.name.split('.').last.toLowerCase();
      final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
      final ktpUrl = 'data:$mimeType;base64,$base64Image';
      print('DEBUG: KTP converted to base64, length: ${ktpUrl.length}');

      print('DEBUG: Creating reservasi...');
      final result = await _reservasiService.createReservasi(
        userId: userId,
        psId: psId,
        jumlahHari: jumlahHari,
        jumlahUnit: jumlahUnit,
        tglMulai: tglMulai,
        tglSelesai: tglSelesai,
        alamat: alamat,
        noWA: noWA,
        ktpUrl: ktpUrl,
      );
      print('DEBUG: Reservasi result: $result');

      if (result['success']) {
        // Simpan reservasiId yang baru dibuat
        final reservasi = result['reservasi'] as ReservasiModel;
        _lastCreatedReservasiId = reservasi.reservasiId;
        print('DEBUG: Created reservasiId: $_lastCreatedReservasiId');
        
        await loadReservasiByUser(userId); // Refresh list
        return true;
      } else {
        _errorMessage = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('DEBUG: Exception: $e');
      _errorMessage = 'Terjadi kesalahan: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Create reservasi dengan URL KTP yang sudah diupload
  Future<bool> createReservasiWithUrl({
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
    _setLoading(true);
    _clearError();

    try {
      final result = await _reservasiService.createReservasi(
        userId: userId,
        psId: psId,
        jumlahHari: jumlahHari,
        jumlahUnit: jumlahUnit,
        tglMulai: tglMulai,
        tglSelesai: tglSelesai,
        alamat: alamat,
        noWA: noWA,
        ktpUrl: ktpUrl,
      );

      if (result['success']) {
        await loadReservasiByUser(userId); // Refresh list
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

  /// Load reservasi by user ID
  Future<void> loadReservasiByUser(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _reservasiService.getReservasiByUser(userId);

      if (result['success']) {
        _reservasiList = result['reservasi'];
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

  /// Load all reservasi (admin only)
  Future<void> loadAllReservasi() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _reservasiService.getAllReservasi();

      if (result['success']) {
        _reservasiList = result['reservasi'];
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

  /// Get reservasi by ID
  Future<ReservasiModel?> getReservasiById(String reservasiId) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _reservasiService.getReservasiById(reservasiId);

      if (result['success']) {
        _selectedReservasi = result['reservasi'];
        notifyListeners();
        return _selectedReservasi;
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

  /// Approve reservasi (admin only)
  Future<bool> approveReservasi(String reservasiId) async {
    return _updateStatus(reservasiId, 'approve');
  }

  /// Reject reservasi (admin only)
  Future<bool> rejectReservasi(String reservasiId) async {
    return _updateStatus(reservasiId, 'reject');
  }

  /// Start reservasi (admin only)
  Future<bool> startReservasi(String reservasiId) async {
    return _updateStatus(reservasiId, 'start');
  }

  /// Finish reservasi (admin only)
  Future<bool> finishReservasi(String reservasiId) async {
    return _updateStatus(reservasiId, 'finish');
  }

  /// Internal method to update status
  Future<bool> _updateStatus(String reservasiId, String action) async {
    _setLoading(true);
    _clearError();

    try {
      Map<String, dynamic> result;

      switch (action) {
        case 'approve':
          result = await _reservasiService.approveReservasi(reservasiId);
          break;
        case 'reject':
          result = await _reservasiService.rejectReservasi(reservasiId);
          break;
        case 'start':
          result = await _reservasiService.startReservasi(reservasiId);
          break;
        case 'finish':
          result = await _reservasiService.finishReservasi(reservasiId);
          break;
        default:
          return false;
      }

      if (result['success']) {
        await loadAllReservasi(); // Refresh list
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

  /// Clear selected reservasi
  void clearSelectedReservasi() {
    _selectedReservasi = null;
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
}
