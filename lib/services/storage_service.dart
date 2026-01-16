import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

/// Service untuk upload file ke Firebase Storage
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Generate unique filename
  String _generateFilename(String originalName) {
    final ext = path.extension(originalName);
    final uuid = const Uuid().v4();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${uuid}_$timestamp$ext';
  }

  /// Upload file dari bytes (untuk Flutter Web)
  Future<Map<String, dynamic>> _uploadBytes({
    required Uint8List bytes,
    required String filename,
    required String folder,
  }) async {
    try {
      final uniqueFilename = _generateFilename(filename);
      final ref = _storage.ref().child('$folder/$uniqueFilename');

      // Upload bytes
      final uploadTask = ref.putData(bytes);
      
      // Wait for completion
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return {
        'success': true,
        'message': 'File berhasil diupload',
        'url': downloadUrl,
        'filename': uniqueFilename,
        'path': '$folder/$uniqueFilename',
      };
    } on FirebaseException catch (e) {
      return {'success': false, 'message': 'Firebase error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Upload file generik
  Future<Map<String, dynamic>> _uploadFile({
    required File file,
    required String folder,
  }) async {
    try {
      if (!file.existsSync()) {
        return {'success': false, 'message': 'File tidak ditemukan'};
      }

      final filename = _generateFilename(path.basename(file.path));
      final ref = _storage.ref().child('$folder/$filename');

      // Upload file
      final uploadTask = ref.putFile(file);
      
      // Monitor progress (optional)
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      });

      // Wait for completion
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return {
        'success': true,
        'message': 'File berhasil diupload',
        'url': downloadUrl,
        'filename': filename,
        'path': '$folder/$filename',
      };
    } on FirebaseException catch (e) {
      return {'success': false, 'message': 'Firebase error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Upload foto PS
  Future<Map<String, dynamic>> uploadFotoPS(File file) async {
    // Validasi tipe file
    final ext = path.extension(file.path).toLowerCase();
    if (!['.jpg', '.jpeg', '.png', '.webp'].contains(ext)) {
      return {'success': false, 'message': 'Format file tidak valid. Gunakan JPG, PNG, atau WebP'};
    }

    // Validasi ukuran file (max 5MB)
    final fileSize = await file.length();
    if (fileSize > 5 * 1024 * 1024) {
      return {'success': false, 'message': 'Ukuran file maksimal 5MB'};
    }

    return _uploadFile(file: file, folder: 'ps_photos');
  }

  /// Upload foto KTP
  Future<Map<String, dynamic>> uploadKTP(File file) async {
    // Validasi tipe file
    final ext = path.extension(file.path).toLowerCase();
    if (!['.jpg', '.jpeg', '.png'].contains(ext)) {
      return {'success': false, 'message': 'Format file tidak valid. Gunakan JPG atau PNG'};
    }

    // Validasi ukuran file (max 3MB)
    final fileSize = await file.length();
    if (fileSize > 3 * 1024 * 1024) {
      return {'success': false, 'message': 'Ukuran file maksimal 3MB'};
    }

    return _uploadFile(file: file, folder: 'ktp');
  }

  /// Upload foto KTP dari XFile (Flutter Web compatible)
  Future<Map<String, dynamic>> uploadKTPFromXFile(XFile file) async {
    try {
      final ext = path.extension(file.name).toLowerCase();
      if (!['.jpg', '.jpeg', '.png'].contains(ext)) {
        return {'success': false, 'message': 'Format file tidak valid. Gunakan JPG atau PNG'};
      }

      final bytes = await file.readAsBytes();
      
      // Validasi ukuran file (max 3MB)
      if (bytes.length > 3 * 1024 * 1024) {
        return {'success': false, 'message': 'Ukuran file maksimal 3MB'};
      }

      return _uploadBytes(bytes: bytes, filename: file.name, folder: 'ktp');
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Upload bukti pembayaran
  Future<Map<String, dynamic>> uploadBuktiPembayaran(File file) async {
    // Validasi tipe file
    final ext = path.extension(file.path).toLowerCase();
    if (!['.jpg', '.jpeg', '.png', '.pdf'].contains(ext)) {
      return {'success': false, 'message': 'Format file tidak valid. Gunakan JPG, PNG, atau PDF'};
    }

    // Validasi ukuran file (max 5MB)
    final fileSize = await file.length();
    if (fileSize > 5 * 1024 * 1024) {
      return {'success': false, 'message': 'Ukuran file maksimal 5MB'};
    }

    return _uploadFile(file: file, folder: 'bukti_pembayaran');
  }

  /// Upload bukti pembayaran dari XFile (Flutter Web compatible)
  Future<Map<String, dynamic>> uploadBuktiPembayaranFromXFile(XFile file) async {
    try {
      final ext = path.extension(file.name).toLowerCase();
      if (!['.jpg', '.jpeg', '.png', '.pdf'].contains(ext)) {
        return {'success': false, 'message': 'Format file tidak valid. Gunakan JPG, PNG, atau PDF'};
      }

      final bytes = await file.readAsBytes();
      
      // Validasi ukuran file (max 5MB)
      if (bytes.length > 5 * 1024 * 1024) {
        return {'success': false, 'message': 'Ukuran file maksimal 5MB'};
      }

      return _uploadBytes(bytes: bytes, filename: file.name, folder: 'bukti_pembayaran');
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Delete file dari storage
  Future<Map<String, dynamic>> deleteFile(String filePath) async {
    try {
      if (filePath.isEmpty) {
        return {'success': false, 'message': 'Path file tidak boleh kosong'};
      }

      final ref = _storage.ref().child(filePath);
      await ref.delete();

      return {'success': true, 'message': 'File berhasil dihapus'};
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        return {'success': false, 'message': 'File tidak ditemukan'};
      }
      return {'success': false, 'message': 'Firebase error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Delete file by URL
  Future<Map<String, dynamic>> deleteFileByUrl(String url) async {
    try {
      if (url.isEmpty) {
        return {'success': false, 'message': 'URL tidak boleh kosong'};
      }

      final ref = _storage.refFromURL(url);
      await ref.delete();

      return {'success': true, 'message': 'File berhasil dihapus'};
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        return {'success': false, 'message': 'File tidak ditemukan'};
      }
      return {'success': false, 'message': 'Firebase error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Get download URL dari path
  Future<Map<String, dynamic>> getDownloadUrl(String filePath) async {
    try {
      if (filePath.isEmpty) {
        return {'success': false, 'message': 'Path file tidak boleh kosong'};
      }

      final ref = _storage.ref().child(filePath);
      final url = await ref.getDownloadURL();

      return {
        'success': true,
        'message': 'URL berhasil didapatkan',
        'url': url,
      };
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        return {'success': false, 'message': 'File tidak ditemukan'};
      }
      return {'success': false, 'message': 'Firebase error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
}
