import 'dart:io';
import 'package:flutter/material.dart';
import '../models/ps_item_model.dart';
import '../services/ps_item_service.dart';
import '../services/storage_service.dart';

/// Controller untuk PS Item menggunakan ChangeNotifier (Provider)
class PSItemController extends ChangeNotifier {
  final PSItemService _psItemService = PSItemService();
  final StorageService _storageService = StorageService();

  List<PSItemModel> _psItems = [];
  PSItemModel? _selectedItem;
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedKategori;

  // Getters
  List<PSItemModel> get psItems => _psItems;
  List<PSItemModel> get filteredItems {
    if (_selectedKategori == null || _selectedKategori!.isEmpty) {
      return _psItems;
    }
    return _psItems
        .where((item) => item.kategori == _selectedKategori)
        .toList();
  }

  PSItemModel? get selectedItem => _selectedItem;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedKategori => _selectedKategori;

  /// Get all PS items
  Future<void> loadAllPSItems() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _psItemService.getAllPSItems();

      if (result['success']) {
        _psItems = result['items'];
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

  /// Get PS item by ID
  Future<PSItemModel?> getPSItemById(String psId) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _psItemService.getPSItemById(psId);

      if (result['success']) {
        _selectedItem = result['item'];
        notifyListeners();
        return _selectedItem;
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

  /// Add new PS item (admin only)
  Future<bool> addPSItem({
    required String nama,
    required String kategori,
    required String deskripsi,
    required int hargaPerHari,
    required int stok,
    File? fotoFile,
    String? fotoUrl,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      String finalFotoUrl = fotoUrl ?? '';

      // Upload foto jika ada
      if (fotoFile != null && finalFotoUrl.isEmpty) {
        final uploadResult = await _storageService.uploadFotoPS(fotoFile);
        if (uploadResult['success']) {
          finalFotoUrl = uploadResult['url'];
        } else {
          _errorMessage = uploadResult['message'];
          notifyListeners();
          return false;
        }
      }

      final result = await _psItemService.addPSItem(
        nama: nama,
        kategori: kategori,
        deskripsi: deskripsi,
        hargaPerHari: hargaPerHari,
        stok: stok,
        fotoUrl: finalFotoUrl,
      );

      if (result['success']) {
        await loadAllPSItems(); // Refresh list
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

  /// Update PS item (admin only)
  Future<bool> updatePSItem({
    required String psId,
    String? nama,
    String? kategori,
    String? deskripsi,
    int? hargaPerHari,
    int? stok,
    File? fotoFile,
    String? fotoUrl,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      String? finalFotoUrl = fotoUrl;

      // Upload foto baru jika ada file
      if (fotoFile != null && (finalFotoUrl == null || finalFotoUrl.isEmpty)) {
        final uploadResult = await _storageService.uploadFotoPS(fotoFile);
        if (uploadResult['success']) {
          finalFotoUrl = uploadResult['url'];
        } else {
          _errorMessage = uploadResult['message'];
          notifyListeners();
          return false;
        }
      }

      final result = await _psItemService.updatePSItem(
        psId: psId,
        nama: nama,
        kategori: kategori,
        deskripsi: deskripsi,
        hargaPerHari: hargaPerHari,
        stok: stok,
        fotoUrl: finalFotoUrl,
      );

      if (result['success']) {
        await loadAllPSItems(); // Refresh list
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

  /// Delete PS item (admin only)
  Future<bool> deletePSItem(String id) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _psItemService.deletePSItem(id);

      if (result['success']) {
        await loadAllPSItems(); // Refresh list
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

  /// Set filter kategori
  void setKategori(String? kategori) {
    _selectedKategori = kategori;
    notifyListeners();
  }

  /// Clear selected item
  void clearSelectedItem() {
    _selectedItem = null;
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
