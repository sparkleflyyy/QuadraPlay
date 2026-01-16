import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:quadraplay/config.dart';
import 'package:quadraplay/restapi.dart';
import '../models/reservasi_model.dart';
import '../models/driver_model.dart';
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
    String? kordinat,
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
        psItem.hargaPerHari,
        jumlahHari,
        jumlahUnit,
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
        kordinat: kordinat ?? '',
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
          kordinat: kordinat,
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
        token,
        project,
        'reservasi',
        appid,
        'user_id',
        userId,
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
        token,
        project,
        'reservasi',
        appid,
        'reservasi_id',
        reservasiId,
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
        token,
        project,
        'reservasi',
        appid,
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
        'reservasi_id',
        reservasiId,
        'status',
        newStatus,
        token,
        project,
        'reservasi',
        appid,
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

  /// Assign driver to reservasi and update status to shipping
  Future<Map<String, dynamic>> assignDriver({
    required String reservasiId,
    required DriverModel driver,
  }) async {
    try {
      if (reservasiId.isEmpty) {
        return {'success': false, 'message': 'Reservasi ID tidak boleh kosong'};
      }

      // Update status ke shipping
      await _dataService.updateWhere(
        'reservasi_id',
        reservasiId,
        'status',
        ReservasiStatus.shipping,
        token,
        project,
        'reservasi',
        appid,
      );

      // Update driver info
      await _dataService.updateReservasiField(
        reservasiId,
        'driver_id',
        driver.driverId,
        token,
        project,
        appid,
      );
      await _dataService.updateReservasiField(
        reservasiId,
        'driver_name',
        driver.namaDriver,
        token,
        project,
        appid,
      );
      await _dataService.updateReservasiField(
        reservasiId,
        'driver_phone',
        driver.noWa,
        token,
        project,
        appid,
      );
      await _dataService.updateReservasiField(
        reservasiId,
        'driver_photo',
        driver.fotoProfil,
        token,
        project,
        appid,
      );

      // Update driver status menjadi busy (tidak tersedia)
      await _dataService.updateWhere(
        'driver_id',
        driver.driverId,
        'status',
        'busy',
        token,
        project,
        'drivers',
        appid,
      );

      return {
        'success': true,
        'message': 'Driver berhasil di-assign, status: Sedang Dikirim',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Mark PS as installed with proof photo
  Future<Map<String, dynamic>> markAsInstalled({
    required String reservasiId,
    required String fotoBuktiPasang,
  }) async {
    try {
      if (reservasiId.isEmpty) {
        return {'success': false, 'message': 'Reservasi ID tidak boleh kosong'};
      }
      if (fotoBuktiPasang.isEmpty) {
        return {
          'success': false,
          'message': 'Foto bukti pasang wajib diupload',
        };
      }

      // Update status ke installed
      await _dataService.updateWhere(
        'reservasi_id',
        reservasiId,
        'status',
        ReservasiStatus.installed,
        token,
        project,
        'reservasi',
        appid,
      );

      // Update foto bukti pasang
      await _dataService.updateReservasiField(
        reservasiId,
        'foto_bukti_pasang',
        fotoBuktiPasang,
        token,
        project,
        appid,
      );

      return {
        'success': true,
        'message': 'PS terpasang, menunggu aktivasi sewa',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Upload bukti terpasang oleh user dan update status + driver availability
  Future<Map<String, dynamic>> uploadBuktiTerpasang({
    required String reservasiId,
    required String buktiTerpasang,
    required String driverId,
  }) async {
    try {
      if (reservasiId.isEmpty) {
        return {'success': false, 'message': 'Reservasi ID tidak boleh kosong'};
      }
      if (buktiTerpasang.isEmpty) {
        return {
          'success': false,
          'message': 'Foto bukti terpasang wajib diupload',
        };
      }

      // Update status ke installed
      await _dataService.updateWhere(
        'reservasi_id',
        reservasiId,
        'status',
        ReservasiStatus.installed,
        token,
        project,
        'reservasi',
        appid,
      );

      // Update foto bukti terpasang
      await _dataService.updateReservasiField(
        reservasiId,
        'bukti_terpasang',
        buktiTerpasang,
        token,
        project,
        appid,
      );

      // Update driver status menjadi available lagi
      if (driverId.isNotEmpty) {
        await _dataService.updateWhere(
          'driver_id',
          driverId,
          'status',
          'available',
          token,
          project,
          'drivers',
          appid,
        );
      }

      return {
        'success': true,
        'message': 'Bukti terpasang berhasil diupload, menunggu aktivasi sewa',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Start rental with timer (waktu_sewa_mulai)
  Future<Map<String, dynamic>> startRentalWithTimer(String reservasiId) async {
    try {
      if (reservasiId.isEmpty) {
        return {'success': false, 'message': 'Reservasi ID tidak boleh kosong'};
      }

      // Get reservasi untuk mendapatkan jumlah_hari
      final existing = await getReservasiById(reservasiId);
      if (!existing['success']) {
        return {'success': false, 'message': 'Reservasi tidak ditemukan'};
      }

      final reservasi = existing['reservasi'] as ReservasiModel;
      final now = DateTime.now();
      final endTime = now.add(Duration(days: reservasi.jumlahHari));

      // Update status ke active
      await _dataService.updateWhere(
        'reservasi_id',
        reservasiId,
        'status',
        ReservasiStatus.active,
        token,
        project,
        'reservasi',
        appid,
      );

      // Update waktu sewa mulai
      await _dataService.updateReservasiField(
        reservasiId,
        'waktu_sewa_mulai',
        now.toIso8601String(),
        token,
        project,
        appid,
      );

      // Update waktu sewa berakhir
      await _dataService.updateReservasiField(
        reservasiId,
        'waktu_sewa_berakhir',
        endTime.toIso8601String(),
        token,
        project,
        appid,
      );

      return {
        'success': true,
        'message': 'Sewa dimulai! Timer berjalan.',
        'waktu_mulai': now,
        'waktu_berakhir': endTime,
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Update foto user penerima
  Future<Map<String, dynamic>> updateFotoUserPenerima({
    required String reservasiId,
    required String fotoUserPenerima,
  }) async {
    try {
      if (reservasiId.isEmpty) {
        return {'success': false, 'message': 'Reservasi ID tidak boleh kosong'};
      }

      await _dataService.updateReservasiField(
        reservasiId,
        'foto_user_penerima',
        fotoUserPenerima,
        token,
        project,
        appid,
      );

      return {'success': true, 'message': 'Foto penerima berhasil diupdate'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Update lokasi koordinat
  Future<Map<String, dynamic>> updateLocation({
    required String reservasiId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      if (reservasiId.isEmpty) {
        return {'success': false, 'message': 'Reservasi ID tidak boleh kosong'};
      }

      await _dataService.updateReservasiField(
        reservasiId,
        'latitude',
        latitude.toString(),
        token,
        project,
        appid,
      );
      await _dataService.updateReservasiField(
        reservasiId,
        'longitude',
        longitude.toString(),
        token,
        project,
        appid,
      );

      return {'success': true, 'message': 'Lokasi berhasil diupdate'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Get statistics for active rentals
  Future<Map<String, dynamic>> getActiveRentalStats() async {
    try {
      final result = await _dataService.selectWhere(
        token,
        project,
        'reservasi',
        appid,
        'status',
        ReservasiStatus.active,
      );

      final reservasiData = _parseApiResponse(result);
      final List<ReservasiModel> activeRentals = reservasiData
          .map((data) => ReservasiModel.fromJson(data))
          .toList();

      // Group by PS type
      Map<String, int> psByType = {};
      for (var r in activeRentals) {
        psByType[r.psId] = (psByType[r.psId] ?? 0) + r.jumlahUnit;
      }

      return {
        'success': true,
        'total_active': activeRentals.length,
        'total_units': activeRentals.fold<int>(
          0,
          (sum, r) => sum + r.jumlahUnit,
        ),
        'rentals': activeRentals,
        'by_type': psByType,
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Get reservasi by status
  Future<Map<String, dynamic>> getReservasiByStatus(String status) async {
    try {
      if (!ReservasiModel.isValidStatus(status)) {
        return {'success': false, 'message': 'Status tidak valid'};
      }

      final result = await _dataService.selectWhere(
        token,
        project,
        'reservasi',
        appid,
        'status',
        status,
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

  // ==================== PICKUP METHODS ====================

  /// Check dan update reservasi yang sudah expired (waktu sewa habis)
  /// Dipanggil oleh scheduler/cron job
  Future<Map<String, dynamic>> checkAndUpdateExpiredReservasi() async {
    try {
      // Get semua reservasi dengan status active
      final result = await _dataService.selectWhere(
        token,
        project,
        'reservasi',
        appid,
        'status',
        ReservasiStatus.active,
      );

      final reservasiData = _parseApiResponse(result);
      final List<ReservasiModel> activeRentals = reservasiData
          .map((data) => ReservasiModel.fromJson(data))
          .toList();

      int expiredCount = 0;
      List<String> expiredIds = [];

      for (var reservasi in activeRentals) {
        // Cek apakah waktu sewa sudah berakhir
        if (reservasi.isSewaExpired) {
          // Update status ke expired
          await _dataService.updateWhere(
            'reservasi_id',
            reservasi.reservasiId,
            'status',
            ReservasiStatus.expired,
            token,
            project,
            'reservasi',
            appid,
          );
          expiredCount++;
          expiredIds.add(reservasi.reservasiId);
        }
      }

      return {
        'success': true,
        'message': '$expiredCount reservasi telah di-update ke status expired',
        'expired_count': expiredCount,
        'expired_ids': expiredIds,
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Schedule pickup - Admin mengatur jadwal penjemputan dan assign driver
  /// Status: expired -> scheduling_pickup
  Future<Map<String, dynamic>> schedulePickup({
    required String reservasiId,
    required String
    pickupTime, // Format: "HH:mm" (jam saja, tanggal = hari ini)
    required DriverModel driver,
  }) async {
    try {
      if (reservasiId.isEmpty) {
        return {'success': false, 'message': 'Reservasi ID tidak boleh kosong'};
      }
      if (pickupTime.isEmpty) {
        return {'success': false, 'message': 'Waktu penjemputan wajib diisi'};
      }

      // Cek apakah reservasi ada dan statusnya expired
      final existing = await getReservasiById(reservasiId);
      if (!existing['success']) {
        return {'success': false, 'message': 'Reservasi tidak ditemukan'};
      }

      final reservasi = existing['reservasi'] as ReservasiModel;
      if (reservasi.status != ReservasiStatus.expired) {
        return {
          'success': false,
          'message':
              'Hanya reservasi dengan status "expired" yang dapat dijadwalkan penjemputan',
        };
      }

      // Format pickup_time dengan tanggal hari ini
      final now = DateTime.now();
      final fullPickupTime =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} $pickupTime:00';

      // Update status ke scheduling_pickup
      await _dataService.updateWhere(
        'reservasi_id',
        reservasiId,
        'status',
        ReservasiStatus.schedulingPickup,
        token,
        project,
        'reservasi',
        appid,
      );

      // Update pickup_driver_id
      await _dataService.updateReservasiField(
        reservasiId,
        'pickup_driver_id',
        driver.driverId,
        token,
        project,
        appid,
      );

      // Update pickup_time
      await _dataService.updateReservasiField(
        reservasiId,
        'pickup_time',
        fullPickupTime,
        token,
        project,
        appid,
      );

      // Update driver status menjadi busy
      await _dataService.updateWhere(
        'driver_id',
        driver.driverId,
        'status',
        DriverStatus.busy,
        token,
        project,
        'drivers',
        appid,
      );

      return {
        'success': true,
        'message': 'Jadwal penjemputan berhasil diatur',
        'pickup_time': fullPickupTime,
        'driver': driver.namaDriver,
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Start picking up - Admin mengubah status saat driver mulai berangkat
  /// Status: scheduling_pickup -> picking_up
  Future<Map<String, dynamic>> startPickingUp(String reservasiId) async {
    try {
      if (reservasiId.isEmpty) {
        return {'success': false, 'message': 'Reservasi ID tidak boleh kosong'};
      }

      // Cek apakah reservasi ada dan statusnya scheduling_pickup
      final existing = await getReservasiById(reservasiId);
      if (!existing['success']) {
        return {'success': false, 'message': 'Reservasi tidak ditemukan'};
      }

      final reservasi = existing['reservasi'] as ReservasiModel;
      if (reservasi.status != ReservasiStatus.schedulingPickup) {
        return {
          'success': false,
          'message':
              'Hanya reservasi dengan status "scheduling_pickup" yang dapat dimulai penjemputan',
        };
      }

      // Update status ke picking_up
      await _dataService.updateWhere(
        'reservasi_id',
        reservasiId,
        'status',
        ReservasiStatus.pickingUp,
        token,
        project,
        'reservasi',
        appid,
      );

      return {
        'success': true,
        'message': 'Driver sedang dalam perjalanan menjemput PS',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Upload bukti jemput oleh user - Status: picking_up -> picked_up
  Future<Map<String, dynamic>> uploadBuktiJemput({
    required String reservasiId,
    required String fotoBuktiJemput,
  }) async {
    try {
      if (reservasiId.isEmpty) {
        return {'success': false, 'message': 'Reservasi ID tidak boleh kosong'};
      }
      if (fotoBuktiJemput.isEmpty) {
        return {
          'success': false,
          'message': 'Foto bukti jemput wajib diupload',
        };
      }

      // Cek apakah reservasi ada dan statusnya picking_up
      final existing = await getReservasiById(reservasiId);
      if (!existing['success']) {
        return {'success': false, 'message': 'Reservasi tidak ditemukan'};
      }

      final reservasi = existing['reservasi'] as ReservasiModel;
      if (reservasi.status != ReservasiStatus.pickingUp) {
        return {
          'success': false,
          'message':
              'Hanya reservasi dengan status "picking_up" yang dapat upload bukti jemput',
        };
      }

      // Update status ke picked_up
      await _dataService.updateWhere(
        'reservasi_id',
        reservasiId,
        'status',
        ReservasiStatus.pickedUp,
        token,
        project,
        'reservasi',
        appid,
      );

      // Update foto bukti jemput
      await _dataService.updateReservasiField(
        reservasiId,
        'foto_bukti_jemput',
        fotoBuktiJemput,
        token,
        project,
        appid,
      );

      return {
        'success': true,
        'message': 'Bukti jemput berhasil diupload, menunggu konfirmasi admin',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Confirm completed - Admin konfirmasi PS sudah di gudang
  /// Status: picked_up -> completed
  /// Stok PS +1, Driver status -> available
  Future<Map<String, dynamic>> confirmCompleted(String reservasiId) async {
    try {
      if (reservasiId.isEmpty) {
        return {'success': false, 'message': 'Reservasi ID tidak boleh kosong'};
      }

      // Cek apakah reservasi ada dan statusnya picked_up
      final existing = await getReservasiById(reservasiId);
      if (!existing['success']) {
        return {'success': false, 'message': 'Reservasi tidak ditemukan'};
      }

      final reservasi = existing['reservasi'] as ReservasiModel;
      if (reservasi.status != ReservasiStatus.pickedUp) {
        return {
          'success': false,
          'message':
              'Hanya reservasi dengan status "picked_up" yang dapat dikonfirmasi selesai',
        };
      }

      // Update status ke completed
      await _dataService.updateWhere(
        'reservasi_id',
        reservasiId,
        'status',
        ReservasiStatus.completed,
        token,
        project,
        'reservasi',
        appid,
      );

      // Kembalikan stok PS (+jumlahUnit)
      final psResult = await _psItemService.getPSItemById(reservasi.psId);
      if (psResult['success']) {
        final psItem = psResult['item'];
        final newStok = psItem.stok + reservasi.jumlahUnit;
        await _psItemService.updateStok(reservasi.psId, newStok);
      }

      // Update pickup driver status menjadi available
      if (reservasi.pickupDriverId != null &&
          reservasi.pickupDriverId!.isNotEmpty) {
        await _dataService.updateWhere(
          'driver_id',
          reservasi.pickupDriverId!,
          'status',
          DriverStatus.available,
          token,
          project,
          'drivers',
          appid,
        );
      }

      return {
        'success': true,
        'message': 'Reservasi selesai! Stok PS telah dikembalikan.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Get reservasi yang perlu dijadwalkan penjemputan (status: expired)
  Future<Map<String, dynamic>> getExpiredReservasi() async {
    try {
      final result = await _dataService.selectWhere(
        token,
        project,
        'reservasi',
        appid,
        'status',
        ReservasiStatus.expired,
      );

      final reservasiData = _parseApiResponse(result);
      final List<ReservasiModel> expiredList = reservasiData
          .map((data) => ReservasiModel.fromJson(data))
          .toList();

      return {
        'success': true,
        'message': 'Berhasil mengambil data reservasi expired',
        'reservasi': expiredList,
        'count': expiredList.length,
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Get reservasi yang sedang proses penjemputan (scheduling_pickup, picking_up, picked_up)
  Future<Map<String, dynamic>> getPickupInProgressReservasi() async {
    try {
      final allResult = await getAllReservasi();
      if (!allResult['success']) {
        return allResult;
      }

      final allReservasi = allResult['reservasi'] as List<ReservasiModel>;
      final pickupStatuses = [
        ReservasiStatus.schedulingPickup,
        ReservasiStatus.pickingUp,
        ReservasiStatus.pickedUp,
      ];

      final pickupInProgress = allReservasi
          .where((r) => pickupStatuses.contains(r.status))
          .toList();

      return {
        'success': true,
        'message': 'Berhasil mengambil data penjemputan dalam proses',
        'reservasi': pickupInProgress,
        'count': pickupInProgress.length,
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
}
