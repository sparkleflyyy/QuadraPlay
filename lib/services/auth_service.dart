import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quadraplay/config.dart';
import 'package:quadraplay/restapi.dart';
import '../models/user_model.dart';

/// Service untuk autentikasi user
class AuthService {
  final DataService _dataService = DataService();
  static const String _userKey = 'current_user';
  static const String _userIdKey = 'current_user_id';
  static const String _userRoleKey = 'user_role';

  /// Parse API response - handle both array and object responses
  List<dynamic> _parseApiResponse(String response) {
    if (response.isEmpty || response == '[]') {
      return [];
    }
    
    try {
      final decoded = jsonDecode(response);
      
      // Jika response adalah List langsung
      if (decoded is List) {
        return decoded;
      }
      
      // Jika response adalah Map dengan key 'data' atau 'result'
      if (decoded is Map) {
        if (decoded.containsKey('data') && decoded['data'] is List) {
          return decoded['data'];
        }
        if (decoded.containsKey('result') && decoded['result'] is List) {
          return decoded['result'];
        }
        // Jika Map adalah single object, wrap dalam list
        return [decoded];
      }
      
      return [];
    } catch (e) {
      print('Error parsing API response: $e');
      return [];
    }
  }

  /// Generate unique ID
  String _generateId() {
    return const Uuid().v4();
  }

  /// Register user baru (role selalu 'user', admin tidak bisa registrasi)
  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    // Role selalu 'user' untuk registrasi publik
    const String role = 'user';
    
    try {
      // Validasi input
      if (name.isEmpty) {
        return {'success': false, 'message': 'Nama tidak boleh kosong'};
      }
      if (email.isEmpty || !email.contains('@')) {
        return {'success': false, 'message': 'Email tidak valid'};
      }
      if (password.length < 6) {
        return {'success': false, 'message': 'Password minimal 6 karakter'};
      }

      // Cek apakah email sudah terdaftar
      final existingUser = await _dataService.selectWhere(
        token, project, 'users', appid, 'email', email,
      );
      
      final existingList = _parseApiResponse(existingUser);
      if (existingList.isNotEmpty) {
        return {'success': false, 'message': 'Email sudah terdaftar'};
      }

      // Generate ID (password disimpan plain text untuk kemudahan manual input)
      final userId = _generateId();
      final createdAt = DateTime.now().toIso8601String();

      // Insert ke database (password plain text)
      final result = await _dataService.insertUsers(
        appid, userId, name, email, password, role, createdAt,
      );

      // Cek apakah insert berhasil (response bukan empty atau error)
      if (result != null && result != '[]' && result.toString().isNotEmpty) {
        final user = UserModel(
          userId: userId,
          name: name,
          email: email,
          role: role,
          createdAt: DateTime.now(),
        );
        
        // Simpan ke local storage
        await _saveUserToLocal(user);
        
        return {
          'success': true,
          'message': 'Registrasi berhasil',
          'user': user,
        };
      } else {
        return {'success': false, 'message': 'Gagal mendaftarkan user'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Login user
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      // Validasi input
      if (email.isEmpty) {
        return {'success': false, 'message': 'Email tidak boleh kosong'};
      }
      if (password.isEmpty) {
        return {'success': false, 'message': 'Password tidak boleh kosong'};
      }

      // Cari user berdasarkan email
      final result = await _dataService.selectWhere(
        token, project, 'users', appid, 'email', email,
      );

      final users = _parseApiResponse(result);
      if (users.isEmpty) {
        return {'success': false, 'message': 'Email tidak ditemukan'};
      }

      final userData = users.first;

      // Verifikasi password (plain text comparison)
      if (userData['password'] != password) {
        return {'success': false, 'message': 'Password salah'};
      }

      final user = UserModel.fromJson(userData);
      
      // Simpan ke local storage
      await _saveUserToLocal(user);

      return {
        'success': true,
        'message': 'Login berhasil',
        'user': user,
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Logout user
  Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_userRoleKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get current user dari local storage
  Future<UserModel?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      
      if (userJson != null) {
        final userData = jsonDecode(userJson);
        return UserModel.fromJson(userData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get current user ID
  Future<String?> getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userIdKey);
    } catch (e) {
      return null;
    }
  }

  /// Cek apakah user sudah login
  Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }

  /// Cek apakah user adalah admin
  Future<bool> isAdmin() async {
    final user = await getCurrentUser();
    return user?.role == 'admin';
  }

  /// Simpan user ke local storage
  Future<void> _saveUserToLocal(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJsonSafe()));
    await prefs.setString(_userIdKey, user.userId);
    await prefs.setString(_userRoleKey, user.role);
  }
}
