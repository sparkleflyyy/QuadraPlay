import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/driver_model.dart';
import '../services/driver_service.dart';

/// Controller untuk Driver menggunakan ChangeNotifier (Provider)
class DriverController extends ChangeNotifier {
  final DriverService _driverService = DriverService();

  List<DriverModel> _driversList = [];
  List<DriverModel> _availableDrivers = [];
  DriverModel? _selectedDriver;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<DriverModel> get driversList => _driversList;
  List<DriverModel> get availableDrivers => _availableDrivers;
  DriverModel? get selectedDriver => _selectedDriver;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Load all drivers
  Future<void> loadAllDrivers() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _driverService.getAllDrivers();

      if (result['success']) {
        _driversList = result['drivers'];
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

  /// Load available drivers only
  Future<void> loadAvailableDrivers() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _driverService.getAvailableDrivers();

      if (result['success']) {
        _availableDrivers = result['drivers'];
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

  /// Add new driver
  Future<bool> addDriver({
    required String namaDriver,
    required String noWa,
    XFile? fotoFile,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      String fotoProfil = '';
      if (fotoFile != null) {
        final bytes = await fotoFile.readAsBytes();
        final base64Image = base64Encode(bytes);
        final ext = fotoFile.name.split('.').last.toLowerCase();
        final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
        fotoProfil = 'data:$mimeType;base64,$base64Image';
      }

      final result = await _driverService.createDriver(
        namaDriver: namaDriver,
        noWa: noWa,
        fotoProfil: fotoProfil,
      );

      if (result['success']) {
        await loadAllDrivers();
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

  /// Update driver
  Future<bool> updateDriver({
    required String driverId,
    String? namaDriver,
    String? noWa,
    XFile? fotoFile,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      String? fotoProfil;
      if (fotoFile != null) {
        final bytes = await fotoFile.readAsBytes();
        final base64Image = base64Encode(bytes);
        final ext = fotoFile.name.split('.').last.toLowerCase();
        final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
        fotoProfil = 'data:$mimeType;base64,$base64Image';
      }

      final result = await _driverService.updateDriver(
        driverId: driverId,
        namaDriver: namaDriver,
        noWa: noWa,
        fotoProfil: fotoProfil,
      );

      if (result['success']) {
        await loadAllDrivers();
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

  /// Update driver status
  Future<bool> updateDriverStatus(String driverId, String newStatus) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _driverService.updateDriverStatus(
        driverId: driverId,
        newStatus: newStatus,
      );

      if (result['success']) {
        await loadAllDrivers();
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

  /// Delete driver
  Future<bool> deleteDriver(String driverId) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _driverService.deleteDriver(driverId);

      if (result['success']) {
        await loadAllDrivers();
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

  /// Select driver
  void selectDriver(DriverModel driver) {
    _selectedDriver = driver;
    notifyListeners();
  }

  /// Clear selection
  void clearSelection() {
    _selectedDriver = null;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
