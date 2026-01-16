import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:quadraplay/config.dart';
import 'package:quadraplay/restapi.dart';
import '../models/driver_model.dart';

/// Service untuk operasi Driver
class DriverService {
  final DataService _dataService = DataService();

  /// Parse API response
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

  /// Create driver baru
  Future<Map<String, dynamic>> createDriver({
    required String namaDriver,
    required String noWa,
    required String fotoProfil,
  }) async {
    try {
      if (namaDriver.isEmpty) {
        return {'success': false, 'message': 'Nama driver tidak boleh kosong'};
      }
      if (noWa.isEmpty) {
        return {'success': false, 'message': 'No WA tidak boleh kosong'};
      }

      final driverId = _generateId();
      final createdAt = DateTime.now().toIso8601String();

      final result = await _dataService.insertDriver(
        appid,
        driverId,
        namaDriver,
        noWa,
        fotoProfil,
        DriverStatus.available,
        createdAt,
      );

      if (result != '[]') {
        final driver = DriverModel(
          driverId: driverId,
          namaDriver: namaDriver,
          noWa: noWa,
          fotoProfil: fotoProfil,
          status: DriverStatus.available,
          createdAt: DateTime.now(),
        );

        return {
          'success': true,
          'message': 'Driver berhasil ditambahkan',
          'driver': driver,
        };
      } else {
        return {'success': false, 'message': 'Gagal menambahkan driver'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Get all drivers
  Future<Map<String, dynamic>> getAllDrivers() async {
    try {
      final result = await _dataService.selectAll(
        token, project, 'drivers', appid,
      );

      final driversData = _parseApiResponse(result);
      final List<DriverModel> driversList = driversData
          .map((data) => DriverModel.fromJson(data))
          .toList();

      return {
        'success': true,
        'message': 'Berhasil mengambil data drivers',
        'drivers': driversList,
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Get available drivers only
  Future<Map<String, dynamic>> getAvailableDrivers() async {
    try {
      final result = await _dataService.selectWhere(
        token, project, 'drivers', appid, 'status', DriverStatus.available,
      );

      final driversData = _parseApiResponse(result);
      final List<DriverModel> driversList = driversData
          .map((data) => DriverModel.fromJson(data))
          .toList();

      return {
        'success': true,
        'message': 'Berhasil mengambil data drivers',
        'drivers': driversList,
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Get driver by ID
  Future<Map<String, dynamic>> getDriverById(String driverId) async {
    try {
      if (driverId.isEmpty) {
        return {'success': false, 'message': 'Driver ID tidak boleh kosong'};
      }

      final result = await _dataService.selectWhere(
        token, project, 'drivers', appid, 'driver_id', driverId,
      );

      final driversData = _parseApiResponse(result);
      if (driversData.isEmpty) {
        return {'success': false, 'message': 'Driver tidak ditemukan'};
      }

      final driver = DriverModel.fromJson(driversData.first);
      return {
        'success': true,
        'message': 'Driver ditemukan',
        'driver': driver,
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Update driver status
  Future<Map<String, dynamic>> updateDriverStatus({
    required String driverId,
    required String newStatus,
  }) async {
    try {
      if (driverId.isEmpty) {
        return {'success': false, 'message': 'Driver ID tidak boleh kosong'};
      }

      final updateResult = await _dataService.updateWhere(
        'driver_id', driverId, 'status', newStatus,
        token, project, 'drivers', appid,
      );
      
      if (updateResult != true) {
        return {'success': false, 'message': 'Gagal update status driver'};
      }

      return {
        'success': true,
        'message': 'Status driver berhasil diupdate',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Update driver info
  Future<Map<String, dynamic>> updateDriver({
    required String driverId,
    String? namaDriver,
    String? noWa,
    String? fotoProfil,
  }) async {
    try {
      if (driverId.isEmpty) {
        return {'success': false, 'message': 'Driver ID tidak boleh kosong'};
      }

      if (namaDriver != null) {
        await _dataService.updateWhere(
          'driver_id', driverId, 'nama_driver', namaDriver,
          token, project, 'drivers', appid,
        );
      }

      if (noWa != null) {
        await _dataService.updateWhere(
          'driver_id', driverId, 'no_wa', noWa,
          token, project, 'drivers', appid,
        );
      }

      if (fotoProfil != null) {
        await _dataService.updateWhere(
          'driver_id', driverId, 'foto_profil', fotoProfil,
          token, project, 'drivers', appid,
        );
      }

      return {
        'success': true,
        'message': 'Driver berhasil diupdate',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Delete driver
  Future<Map<String, dynamic>> deleteDriver(String driverId) async {
    try {
      if (driverId.isEmpty) {
        return {'success': false, 'message': 'Driver ID tidak boleh kosong'};
      }

      final result = await _dataService.removeWhere(
        token, project, 'drivers', appid, 'driver_id', driverId,
      );

      if (result == true) {
        return {
          'success': true,
          'message': 'Driver berhasil dihapus',
        };
      } else {
        return {'success': false, 'message': 'Gagal menghapus driver'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
}
