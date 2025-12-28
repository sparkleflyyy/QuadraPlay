import 'dart:convert';
import 'package:quadraplay/config.dart';
import 'package:quadraplay/restapi.dart';
import '../models/user_model.dart';

/// Service untuk operasi User
class UserService {
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

  /// Get user by ID
  Future<Map<String, dynamic>> getUserById(String userId) async {
    try {
      if (userId.isEmpty) {
        return {'success': false, 'message': 'User ID tidak boleh kosong'};
      }

      final result = await _dataService.selectWhere(
        token, project, 'users', appid, 'user_id', userId,
      );

      final users = _parseApiResponse(result);
      if (users.isEmpty) {
        return {'success': false, 'message': 'User tidak ditemukan'};
      }

      final user = UserModel.fromJson(users.first);
      return {
        'success': true,
        'message': 'User ditemukan',
        'user': user,
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Get user by email
  Future<Map<String, dynamic>> getUserByEmail(String email) async {
    try {
      if (email.isEmpty) {
        return {'success': false, 'message': 'Email tidak boleh kosong'};
      }

      final result = await _dataService.selectWhere(
        token, project, 'users', appid, 'email', email,
      );

      final users = _parseApiResponse(result);
      if (users.isEmpty) {
        return {'success': false, 'message': 'User tidak ditemukan'};
      }

      final user = UserModel.fromJson(users.first);
      return {
        'success': true,
        'message': 'User ditemukan',
        'user': user,
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Update user data
  Future<Map<String, dynamic>> updateUser({
    required String userId,
    String? name,
    String? email,
  }) async {
    try {
      if (userId.isEmpty) {
        return {'success': false, 'message': 'User ID tidak boleh kosong'};
      }

      // Update name jika disediakan
      if (name != null && name.isNotEmpty) {
        await _dataService.updateWhere(
          'user_id', userId, 'name', name,
          token, project, 'users', appid,
        );
      }

      // Update email jika disediakan
      if (email != null && email.isNotEmpty) {
        // Cek apakah email sudah digunakan user lain
        final existingResult = await _dataService.selectWhere(
          token, project, 'users', appid, 'email', email,
        );
        final List<dynamic> existing = jsonDecode(existingResult);
        if (existing.isNotEmpty && existing.first['user_id'] != userId) {
          return {'success': false, 'message': 'Email sudah digunakan'};
        }

        await _dataService.updateWhere(
          'user_id', userId, 'email', email,
          token, project, 'users', appid,
        );
      }

      // Get updated user
      final result = await getUserById(userId);
      if (result['success']) {
        return {
          'success': true,
          'message': 'User berhasil diupdate',
          'user': result['user'],
        };
      }

      return {'success': true, 'message': 'User berhasil diupdate'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Get all users (admin only)
  Future<Map<String, dynamic>> getAllUsers() async {
    try {
      final result = await _dataService.selectAll(
        token, project, 'users', appid,
      );

      final usersData = _parseApiResponse(result);
      final List<UserModel> users = usersData
          .map((data) => UserModel.fromJson(data))
          .toList();

      return {
        'success': true,
        'message': 'Berhasil mengambil data users',
        'users': users,
      };
    } catch (e) {
      print('Error getAllUsers: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Delete user by ID (admin only)
  Future<Map<String, dynamic>> deleteUser(String id) async {
    try {
      if (id.isEmpty) {
        return {'success': false, 'message': 'ID tidak boleh kosong'};
      }

      final result = await _dataService.removeId(
        token, project, 'users', appid, id,
      );

      if (result == true) {
        return {'success': true, 'message': 'User berhasil dihapus'};
      } else {
        return {'success': false, 'message': 'Gagal menghapus user'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
}
