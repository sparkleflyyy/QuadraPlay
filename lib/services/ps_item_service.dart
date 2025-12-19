import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:quadraplay/config.dart';
import 'package:quadraplay/restapi.dart';
import '../models/ps_item_model.dart';

/// Service untuk operasi PS Item
class PSItemService {
  final DataService _dataService = DataService();

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

  /// Get all PS items
  Future<Map<String, dynamic>> getAllPSItems() async {
    try {
      final result = await _dataService.selectAll(
        token, project, 'ps_items', appid,
      );

      final itemsData = _parseApiResponse(result);
      final List<PSItemModel> items = itemsData
          .map((data) => PSItemModel.fromJson(data))
          .toList();

      return {
        'success': true,
        'message': 'Berhasil mengambil data PS',
        'items': items,
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Get PS item by ID
  Future<Map<String, dynamic>> getPSItemById(String psId) async {
    try {
      if (psId.isEmpty) {
        return {'success': false, 'message': 'PS ID tidak boleh kosong'};
      }

      final result = await _dataService.selectWhere(
        token, project, 'ps_items', appid, 'ps_id', psId,
      );

      final items = _parseApiResponse(result);
      if (items.isEmpty) {
        return {'success': false, 'message': 'PS tidak ditemukan'};
      }

      final psItem = PSItemModel.fromJson(items.first);
      return {
        'success': true,
        'message': 'PS ditemukan',
        'item': psItem,
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Get PS items by kategori
  Future<Map<String, dynamic>> getPSItemsByKategori(String kategori) async {
    try {
      if (!PSItemModel.isValidKategori(kategori)) {
        return {'success': false, 'message': 'Kategori tidak valid'};
      }

      final result = await _dataService.selectWhere(
        token, project, 'ps_items', appid, 'kategori', kategori,
      );

      final itemsData = _parseApiResponse(result);
      final List<PSItemModel> items = itemsData
          .map((data) => PSItemModel.fromJson(data))
          .toList();

      return {
        'success': true,
        'message': 'Berhasil mengambil data PS',
        'items': items,
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Add new PS item (admin only)
  Future<Map<String, dynamic>> addPSItem({
    required String nama,
    required String kategori,
    required String deskripsi,
    required int hargaPerHari,
    required int stok,
    String fotoUrl = '',
  }) async {
    try {
      // Validasi input
      if (nama.isEmpty) {
        return {'success': false, 'message': 'Nama tidak boleh kosong'};
      }
      if (!PSItemModel.isValidKategori(kategori)) {
        return {'success': false, 'message': 'Kategori tidak valid (PS4, PS5, Nintendo)'};
      }
      if (hargaPerHari <= 0) {
        return {'success': false, 'message': 'Harga per hari harus lebih dari 0'};
      }
      if (stok < 0) {
        return {'success': false, 'message': 'Stok tidak boleh negatif'};
      }

      final psId = _generateId();
      final createdAt = DateTime.now().toIso8601String();

      final result = await _dataService.insertPsItems(
        appid, psId, nama, kategori, deskripsi,
        hargaPerHari.toString(), stok.toString(), fotoUrl, createdAt,
      );

      if (result != '[]') {
        final psItem = PSItemModel(
          psId: psId,
          nama: nama,
          kategori: kategori,
          deskripsi: deskripsi,
          hargaPerHari: hargaPerHari,
          stok: stok,
          fotoUrl: fotoUrl,
          createdAt: DateTime.now(),
        );

        return {
          'success': true,
          'message': 'PS berhasil ditambahkan',
          'item': psItem,
        };
      } else {
        return {'success': false, 'message': 'Gagal menambahkan PS'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Update PS item (admin only)
  Future<Map<String, dynamic>> updatePSItem({
    required String psId,
    String? nama,
    String? kategori,
    String? deskripsi,
    int? hargaPerHari,
    int? stok,
    String? fotoUrl,
  }) async {
    try {
      if (psId.isEmpty) {
        return {'success': false, 'message': 'PS ID tidak boleh kosong'};
      }

      // Cek apakah PS ada
      final existing = await getPSItemById(psId);
      if (!existing['success']) {
        return {'success': false, 'message': 'PS tidak ditemukan'};
      }

      // Update fields yang disediakan
      if (nama != null && nama.isNotEmpty) {
        await _dataService.updateWhere(
          'ps_id', psId, 'nama', nama,
          token, project, 'ps_items', appid,
        );
      }

      if (kategori != null) {
        if (!PSItemModel.isValidKategori(kategori)) {
          return {'success': false, 'message': 'Kategori tidak valid'};
        }
        await _dataService.updateWhere(
          'ps_id', psId, 'kategori', kategori,
          token, project, 'ps_items', appid,
        );
      }

      if (deskripsi != null) {
        await _dataService.updateWhere(
          'ps_id', psId, 'deskripsi', deskripsi,
          token, project, 'ps_items', appid,
        );
      }

      if (hargaPerHari != null && hargaPerHari > 0) {
        await _dataService.updateWhere(
          'ps_id', psId, 'harga_perhari', hargaPerHari.toString(),
          token, project, 'ps_items', appid,
        );
      }

      if (stok != null && stok >= 0) {
        await _dataService.updateWhere(
          'ps_id', psId, 'stok', stok.toString(),
          token, project, 'ps_items', appid,
        );
      }

      if (fotoUrl != null) {
        await _dataService.updateWhere(
          'ps_id', psId, 'foto_url', fotoUrl,
          token, project, 'ps_items', appid,
        );
      }

      // Get updated item
      final result = await getPSItemById(psId);
      if (result['success']) {
        return {
          'success': true,
          'message': 'PS berhasil diupdate',
          'item': result['item'],
        };
      }

      return {'success': true, 'message': 'PS berhasil diupdate'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Delete PS item (admin only)
  Future<Map<String, dynamic>> deletePSItem(String psId) async {
    try {
      if (psId.isEmpty) {
        return {'success': false, 'message': 'PS ID tidak boleh kosong'};
      }

      print('DEBUG: Deleting PS item with psId: $psId');
      
      // Gunakan removeWhere dengan ps_id karena lebih reliable daripada _id
      final result = await _dataService.removeWhere(
        token, project, 'ps_items', appid, 'ps_id', psId,
      );

      print('DEBUG: Delete result: $result');

      if (result == true) {
        return {'success': true, 'message': 'PS berhasil dihapus'};
      } else {
        return {'success': false, 'message': 'Gagal menghapus PS'};
      }
    } catch (e) {
      print('DEBUG: Delete error: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Update stok PS
  Future<Map<String, dynamic>> updateStok(String psId, int newStok) async {
    try {
      if (psId.isEmpty) {
        return {'success': false, 'message': 'PS ID tidak boleh kosong'};
      }
      if (newStok < 0) {
        return {'success': false, 'message': 'Stok tidak boleh negatif'};
      }

      await _dataService.updateWhere(
        'ps_id', psId, 'stok', newStok.toString(),
        token, project, 'ps_items', appid,
      );

      return {'success': true, 'message': 'Stok berhasil diupdate'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
}
