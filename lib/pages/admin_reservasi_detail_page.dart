import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/reservasi_controller.dart';
import '../controllers/payment_controller.dart';
import '../controllers/driver_controller.dart';
import '../controllers/ps_item_controller.dart';
import '../models/reservasi_model.dart';
import '../models/payment_model.dart';
import '../models/driver_model.dart';
import '../services/user_service.dart';
import '../services/email_notification_service.dart';

class AdminReservasiDetailPage extends StatefulWidget {
  final ReservasiModel reservasi;
  final PaymentModel? payment;

  const AdminReservasiDetailPage({
    super.key,
    required this.reservasi,
    this.payment,
  });

  @override
  State<AdminReservasiDetailPage> createState() =>
      _AdminReservasiDetailPageState();
}

class _AdminReservasiDetailPageState extends State<AdminReservasiDetailPage> {
  // Konstanta warna tema
  static const Color _primaryColor = Color(0xFF2563EB);
  static const Color _bgColor = Color(0xFFF8FAFC);

  late ReservasiModel _reservasi;
  PaymentModel? _payment;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _reservasi = widget.reservasi;
    _payment = widget.payment;
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      final reservasiController = context.read<ReservasiController>();
      final paymentController = context.read<PaymentController>();

      await reservasiController.loadAllReservasi();
      await paymentController.loadAllPayments();

      // Find updated reservasi
      final updated = reservasiController.reservasiList.firstWhere(
        (r) => r.reservasiId == _reservasi.reservasiId,
        orElse: () => _reservasi,
      );

      // Find payment
      PaymentModel? updatedPayment;
      try {
        updatedPayment = paymentController.payments.firstWhere(
          (p) => p.reservasiId == _reservasi.reservasiId,
        );
      } catch (_) {}

      if (mounted) {
        setState(() {
          _reservasi = updated;
          _payment = updatedPayment;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          'Detail Reservasi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(onPressed: _refreshData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Header Card dengan Status
                    _buildHeaderCard(),
                    const SizedBox(height: 16),

                    // Info Dasar
                    _buildSectionCard(
                      title: 'Informasi Reservasi',
                      icon: Icons.info_outline,
                      child: Column(
                        children: [
                          _buildInfoRow(
                            'ID Reservasi',
                            '#${_reservasi.reservasiId}',
                          ),
                          _buildInfoRow('Tipe PS', _getPsName(_reservasi.psId)),
                          _buildInfoRow(
                            'Jumlah Unit',
                            '${_reservasi.jumlahUnit} unit',
                          ),
                          _buildInfoRow(
                            'Durasi',
                            '${_reservasi.jumlahHari} hari',
                          ),
                          _buildInfoRow(
                            'Periode',
                            '${DateFormat('dd MMM yyyy').format(_reservasi.tglMulai)} - ${DateFormat('dd MMM yyyy').format(_reservasi.tglSelesai)}',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info Penyewa
                    _buildSectionCard(
                      title: 'Informasi Penyewa',
                      icon: Icons.person_outline,
                      child: Column(
                        children: [
                          _buildInfoRow('User ID', _reservasi.userId),
                          _buildInfoRow(
                            'No. WhatsApp',
                            _reservasi.noWA,
                            onTap: () => _openWhatsApp(_reservasi.noWA),
                          ),
                          _buildInfoRow('Alamat', _reservasi.alamat),
                          if (_reservasi.kordinat != null &&
                              _reservasi.kordinat!.isNotEmpty)
                            _buildInfoRow(
                              'Koordinat',
                              _reservasi.kordinat!,
                              onTap: () {
                                final coords = _reservasi.kordinat!.split(',');
                                if (coords.length == 2) {
                                  _openMaps(
                                    double.tryParse(coords[0]) ?? 0,
                                    double.tryParse(coords[1]) ?? 0,
                                  );
                                }
                              },
                            ),
                          // KTP
                          if (_reservasi.ktpUrl.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildImageSection(
                              'Foto KTP',
                              _reservasi.ktpUrl,
                              Icons.badge_outlined,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info Pembayaran
                    _buildSectionCard(
                      title: 'Informasi Pembayaran',
                      icon: Icons.payment_outlined,
                      child: Column(
                        children: [
                          _buildInfoRow(
                            'Total',
                            'Rp ${_formatCurrency(_reservasi.totalHarga)}',
                            valueStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: _primaryColor,
                            ),
                          ),
                          if (_payment != null) ...[
                            _buildInfoRow('Metode', _payment!.metodePembayaran),
                            _buildInfoRow(
                              'Status',
                              _payment!.status == PaymentStatus.settlement
                                  ? '✓ Lunas'
                                  : _payment!.status == PaymentStatus.pending
                                  ? 'Menunggu Bayar'
                                  : 'Gagal',
                              valueStyle: TextStyle(
                                color:
                                    _payment!.status == PaymentStatus.settlement
                                    ? Colors.green
                                    : _payment!.status == PaymentStatus.pending
                                    ? Colors.orange
                                    : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            // Bukti pembayaran
                            if (_payment!.buktiPembayaran != null &&
                                _payment!.buktiPembayaran!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildImageSection(
                                'Bukti Pembayaran',
                                _payment!.buktiPembayaran!,
                                Icons.receipt_outlined,
                              ),
                            ],
                          ] else
                            _buildInfoRow('Status', 'Belum ada pembayaran'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info Pengantaran
                    if (_reservasi.driverName != null ||
                        _reservasi.fotoBuktiPasang != null ||
                        _reservasi.buktiTerpasang != null)
                      _buildSectionCard(
                        title: 'Informasi Pengantaran',
                        icon: Icons.local_shipping_outlined,
                        child: Column(
                          children: [
                            if (_reservasi.driverName != null) ...[
                              _buildInfoRow('Driver', _reservasi.driverName!),
                              if (_reservasi.driverPhone != null)
                                _buildInfoRow(
                                  'No. WA Driver',
                                  _reservasi.driverPhone!,
                                  onTap: () =>
                                      _openWhatsApp(_reservasi.driverPhone!),
                                ),
                            ],
                            // Foto penerima
                            if (_reservasi.fotoUserPenerima != null &&
                                _reservasi.fotoUserPenerima!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildImageSection(
                                'Foto Penerima PS',
                                _reservasi.fotoUserPenerima!,
                                Icons.person_pin_outlined,
                              ),
                            ],
                            // Bukti terpasang dari driver
                            if (_reservasi.fotoBuktiPasang != null &&
                                _reservasi.fotoBuktiPasang!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildImageSection(
                                'Bukti Pasang (Driver)',
                                _reservasi.fotoBuktiPasang!,
                                Icons.home_outlined,
                              ),
                            ],
                            // Bukti terpasang dari user
                            if (_reservasi.buktiTerpasang != null &&
                                _reservasi.buktiTerpasang!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildImageSection(
                                'Bukti Terpasang (User)',
                                _reservasi.buktiTerpasang!,
                                Icons.verified_user_outlined,
                              ),
                            ],
                          ],
                        ),
                      ),

                    // Info Penjemputan
                    if (_reservasi.pickupDriverId != null ||
                        _reservasi.pickupTime != null ||
                        _reservasi.fotoBuktiJemput != null) ...[
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        title: 'Informasi Penjemputan',
                        icon: Icons.assignment_return_outlined,
                        child: Column(
                          children: [
                            if (_reservasi.pickupTime != null)
                              _buildInfoRow(
                                'Jadwal Pickup',
                                _reservasi.pickupTime!,
                              ),
                            if (_reservasi.pickupDriverId != null)
                              _buildPickupDriverInfo(),
                            if (_reservasi.fotoBuktiJemput != null &&
                                _reservasi.fotoBuktiJemput!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildImageSection(
                                'Bukti Penjemputan',
                                _reservasi.fotoBuktiJemput!,
                                Icons.photo_camera_outlined,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    // Timer Section (jika active)
                    if (_reservasi.status == ReservasiStatus.active) ...[
                      const SizedBox(height: 16),
                      _buildTimerCard(),
                    ],

                    const SizedBox(height: 24),

                    // Action Buttons
                    _buildActionSection(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor(_reservasi.status),
            _getStatusColor(_reservasi.status).withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor(_reservasi.status).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            _getStatusIcon(_reservasi.status),
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            _getStatusLabel(_reservasi.status),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '#${_truncateId(_reservasi.reservasiId)}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCard() {
    final sisaWaktu = _reservasi.getSisaWaktuFormatted();
    final isExpired = _reservasi.isSewaExpired;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isExpired
              ? [Colors.red.shade400, Colors.red.shade600]
              : [Colors.indigo.shade400, Colors.purple.shade400],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isExpired ? Icons.timer_off : Icons.timer,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sisa Waktu Sewa',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                sisaWaktu,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: _primaryColor, size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    VoidCallback? onTap,
    TextStyle? valueStyle,
  }) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
                  valueStyle ??
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
          if (onTap != null)
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(onTap: onTap, child: content);
    }
    return content;
  }

  Widget _buildImageSection(String title, String imageUrl, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showFullImage(context, imageUrl),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildImage(imageUrl, height: 150),
          ),
        ),
      ],
    );
  }

  Widget _buildImage(String imageUrl, {double? height}) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64Data = imageUrl.split(',').last;
        return Image.memory(
          base64Decode(base64Data),
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
        );
      } catch (e) {
        return _buildImagePlaceholder();
      }
    } else {
      return Image.network(
        imageUrl,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
      );
    }
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 150,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
      ),
    );
  }

  Widget _buildPickupDriverInfo() {
    return Consumer<DriverController>(
      builder: (context, driverController, _) {
        try {
          final driver = driverController.driversList.firstWhere(
            (d) => d.driverId == _reservasi.pickupDriverId,
          );
          return Column(
            children: [
              _buildInfoRow('Driver Pickup', driver.namaDriver),
              _buildInfoRow(
                'No. WA',
                driver.noWa,
                onTap: () => _openWhatsApp(driver.noWa),
              ),
            ],
          );
        } catch (_) {
          return _buildInfoRow(
            'Driver Pickup ID',
            _reservasi.pickupDriverId ?? '-',
          );
        }
      },
    );
  }

  Widget _buildActionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Aksi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 12, children: _buildActionButtons()),
      ],
    );
  }

  List<Widget> _buildActionButtons() {
    List<Widget> buttons = [];

    switch (_reservasi.status) {
      case ReservasiStatus.belumBayar:
        buttons.add(
          _buildStatusInfo(
            'Menunggu pembayaran',
            Icons.hourglass_empty,
            Colors.orange,
          ),
        );
        break;

      case ReservasiStatus.paid:
        buttons.add(
          _buildActionButton(
            'Approve',
            Icons.check,
            Colors.green,
            () => _updateStatus('approve'),
          ),
        );
        buttons.add(
          _buildActionButton(
            'Reject',
            Icons.close,
            Colors.red,
            () => _updateStatus('reject'),
          ),
        );
        break;

      case ReservasiStatus.approved:
        buttons.add(
          _buildActionButton(
            'Kirim Unit',
            Icons.local_shipping,
            Colors.blue,
            () => _showAssignDriverDialog(),
          ),
        );
        break;

      case ReservasiStatus.shipping:
        buttons.add(
          _buildStatusInfo(
            'Menunggu user upload bukti',
            Icons.hourglass_empty,
            Colors.blue,
          ),
        );
        break;

      case ReservasiStatus.installed:
        if (_reservasi.buktiTerpasang != null &&
            _reservasi.buktiTerpasang!.isNotEmpty) {
          buttons.add(
            _buildActionButton(
              'Start Sewa',
              Icons.play_arrow,
              Colors.indigo,
              () => _startRental(),
            ),
          );
        } else {
          buttons.add(
            _buildStatusInfo(
              'User belum upload bukti terpasang',
              Icons.warning,
              Colors.orange,
            ),
          );
        }
        break;

      case ReservasiStatus.active:
        buttons.add(
          _buildActionButton(
            'Waktu Habis',
            Icons.timer_off,
            Colors.orange,
            () => _updateStatus('expire'),
          ),
        );
        break;

      case ReservasiStatus.expired:
        buttons.add(
          _buildActionButton(
            'Jadwalkan Penjemputan',
            Icons.schedule,
            Colors.deepOrange,
            () => _showSchedulePickupDialog(),
          ),
        );
        break;

      case ReservasiStatus.schedulingPickup:
        buttons.add(
          _buildActionButton(
            'Mulai Jemput',
            Icons.directions_car,
            Colors.blue,
            () => _startPickingUp(),
          ),
        );
        break;

      case ReservasiStatus.pickingUp:
        buttons.add(
          _buildStatusInfo(
            'Menunggu user upload bukti jemput',
            Icons.hourglass_empty,
            Colors.blue,
          ),
        );
        break;

      case ReservasiStatus.pickedUp:
        buttons.add(
          _buildActionButton(
            'Konfirmasi Selesai',
            Icons.check_circle,
            Colors.green,
            () => _confirmCompleted(),
          ),
        );
        break;

      case ReservasiStatus.completed:
        buttons.add(
          _buildStatusInfo(
            'Reservasi selesai',
            Icons.check_circle,
            Colors.green,
          ),
        );
        break;

      default:
        buttons.add(
          _buildStatusInfo(
            'Status: ${_reservasi.status}',
            Icons.info,
            Colors.grey,
          ),
        );
    }

    return buttons;
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
      ),
    );
  }

  Widget _buildStatusInfo(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ========== Action Methods ==========

  Future<void> _updateStatus(String action) async {
    final controller = context.read<ReservasiController>();
    bool success = false;

    switch (action) {
      case 'approve':
        success = await controller.approveReservasi(_reservasi.reservasiId);
        if (success) {
          await _sendConfirmationEmail();
        }
        break;
      case 'reject':
        success = await controller.rejectReservasi(_reservasi.reservasiId);
        break;
      case 'expire':
        success = await controller.expireReservasi(_reservasi.reservasiId);
        break;
    }

    _showResultSnackBar(
      success,
      'Status berhasil diupdate',
      controller.errorMessage ?? 'Gagal update status',
    );

    if (success) await _refreshData();
  }

  Future<void> _sendConfirmationEmail() async {
    try {
      final userService = UserService();
      final userResult = await userService.getUserById(_reservasi.userId);

      if (!userResult['success']) return;

      final user = userResult['user'];

      await EmailNotificationService.sendReservationConfirmation(
        email: user.email,
        reservasiId: _reservasi.reservasiId,
        customerName: user.namaLengkap,
        itemName: _getPsName(_reservasi.psId),
        jumlahUnit: _reservasi.jumlahUnit,
        jumlahHari: _reservasi.jumlahHari,
        tglMulai: DateFormat('dd MMM yyyy').format(_reservasi.tglMulai),
        tglSelesai: DateFormat('dd MMM yyyy').format(_reservasi.tglSelesai),
        totalHarga: _reservasi.totalHarga,
        alamat: _reservasi.alamat,
        noWA: _reservasi.noWA,
      );
    } catch (e) {
      debugPrint('Email error: $e');
    }
  }

  void _showAssignDriverDialog() {
    final driverController = context.read<DriverController>();
    final availableDrivers = driverController.driversList
        .where((d) => d.status == DriverStatus.available)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Driver',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (availableDrivers.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text('Tidak ada driver tersedia')),
              )
            else
              ...availableDrivers.map(
                (driver) => ListTile(
                  leading: CircleAvatar(
                    backgroundImage: driver.fotoProfil.isNotEmpty
                        ? (driver.fotoProfil.startsWith('data:image')
                              ? MemoryImage(
                                  base64Decode(
                                    driver.fotoProfil.split(',').last,
                                  ),
                                )
                              : NetworkImage(driver.fotoProfil)
                                    as ImageProvider)
                        : null,
                    child: driver.fotoProfil.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(driver.namaDriver),
                  subtitle: Text(driver.noWa),
                  onTap: () async {
                    Navigator.pop(context);
                    final success = await context
                        .read<ReservasiController>()
                        .assignDriver(_reservasi.reservasiId, driver);
                    if (success) {
                      await context.read<DriverController>().updateDriverStatus(
                        driver.driverId,
                        DriverStatus.busy,
                      );
                      await context.read<DriverController>().loadAllDrivers();
                    }
                    _showResultSnackBar(
                      success,
                      'Driver ${driver.namaDriver} ditugaskan',
                      'Gagal menugaskan driver',
                    );
                    if (success) await _refreshData();
                  },
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _startRental() async {
    final controller = context.read<ReservasiController>();
    final success = await controller.startRentalWithTimer(
      _reservasi.reservasiId,
    );

    _showResultSnackBar(
      success,
      'Sewa dimulai',
      controller.errorMessage ?? 'Gagal memulai sewa',
    );

    if (success) await _refreshData();
  }

  void _showSchedulePickupDialog() {
    final driverController = context.read<DriverController>();
    final availableDrivers = driverController.driversList
        .where((d) => d.status == DriverStatus.available)
        .toList();

    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    DriverModel? selectedDriver;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Jadwalkan Penjemputan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // Date picker
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Tanggal'),
                subtitle: Text(DateFormat('dd MMM yyyy').format(selectedDate)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (date != null) {
                    setModalState(() => selectedDate = date);
                  }
                },
              ),
              // Time picker
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Waktu'),
                subtitle: Text(selectedTime.format(context)),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (time != null) {
                    setModalState(() => selectedTime = time);
                  }
                },
              ),
              const SizedBox(height: 12),
              // Driver dropdown
              const Text('Pilih Driver:'),
              const SizedBox(height: 8),
              DropdownButtonFormField<DriverModel>(
                value: selectedDriver,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                hint: const Text('Pilih driver'),
                items: availableDrivers
                    .map(
                      (d) =>
                          DropdownMenuItem(value: d, child: Text(d.namaDriver)),
                    )
                    .toList(),
                onChanged: (v) => setModalState(() => selectedDriver = v),
              ),
              const SizedBox(height: 20),
              // Confirm button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedDriver == null
                      ? null
                      : () async {
                          Navigator.pop(context);
                          final pickupTime = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );
                          final formattedTime = DateFormat(
                            'dd MMM yyyy HH:mm',
                          ).format(pickupTime);

                          final success = await context
                              .read<ReservasiController>()
                              .schedulePickup(
                                reservasiId: _reservasi.reservasiId,
                                pickupTime: formattedTime,
                                driver: selectedDriver!,
                              );

                          if (success) {
                            await context
                                .read<DriverController>()
                                .updateDriverStatus(
                                  selectedDriver!.driverId,
                                  DriverStatus.busy,
                                );
                            await context
                                .read<DriverController>()
                                .loadAllDrivers();
                          }

                          _showResultSnackBar(
                            success,
                            'Penjemputan dijadwalkan',
                            'Gagal menjadwalkan',
                          );
                          if (success) await _refreshData();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Jadwalkan',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startPickingUp() async {
    final controller = context.read<ReservasiController>();
    final success = await controller.startPickingUp(_reservasi.reservasiId);

    _showResultSnackBar(
      success,
      'Penjemputan dimulai',
      controller.errorMessage ?? 'Gagal memulai penjemputan',
    );

    if (success) await _refreshData();
  }

  Future<void> _confirmCompleted() async {
    final controller = context.read<ReservasiController>();
    final success = await controller.confirmCompleted(_reservasi.reservasiId);

    if (success) {
      // Return driver status to available
      if (_reservasi.pickupDriverId != null) {
        await context.read<DriverController>().updateDriverStatus(
          _reservasi.pickupDriverId!,
          DriverStatus.available,
        );
        await context.read<DriverController>().loadAllDrivers();
      }
    }

    _showResultSnackBar(
      success,
      'Reservasi selesai',
      controller.errorMessage ?? 'Gagal menyelesaikan',
    );

    if (success) await _refreshData();
  }

  // ========== Helper Methods ==========

  void _showResultSnackBar(bool success, String successMsg, String errorMsg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? successMsg : errorMsg),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildImage(imageUrl, height: null),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPsName(String psId) {
    final psController = context.read<PSItemController>();
    try {
      final psItem = psController.psItems.firstWhere(
        (item) => item.psId == psId,
      );
      return psItem.nama;
    } catch (e) {
      return psId;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case ReservasiStatus.belumBayar:
        return Colors.orange;
      case ReservasiStatus.paid:
        return Colors.blue;
      case ReservasiStatus.approved:
        return Colors.teal;
      case ReservasiStatus.shipping:
        return Colors.indigo;
      case ReservasiStatus.installed:
        return Colors.cyan;
      case ReservasiStatus.active:
        return Colors.green;
      case ReservasiStatus.expired:
        return Colors.deepOrange;
      case ReservasiStatus.schedulingPickup:
        return Colors.amber.shade700;
      case ReservasiStatus.pickingUp:
        return Colors.blue.shade700;
      case ReservasiStatus.pickedUp:
        return Colors.purple;
      case ReservasiStatus.completed:
        return Colors.green.shade700;
      case ReservasiStatus.rejected:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case ReservasiStatus.belumBayar:
        return Icons.payment;
      case ReservasiStatus.paid:
        return Icons.paid;
      case ReservasiStatus.approved:
        return Icons.check_circle;
      case ReservasiStatus.shipping:
        return Icons.local_shipping;
      case ReservasiStatus.installed:
        return Icons.home;
      case ReservasiStatus.active:
        return Icons.play_circle;
      case ReservasiStatus.expired:
        return Icons.timer_off;
      case ReservasiStatus.schedulingPickup:
        return Icons.schedule;
      case ReservasiStatus.pickingUp:
        return Icons.directions_car;
      case ReservasiStatus.pickedUp:
        return Icons.inventory;
      case ReservasiStatus.completed:
        return Icons.verified;
      case ReservasiStatus.rejected:
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case ReservasiStatus.belumBayar:
        return 'Menunggu Pembayaran';
      case ReservasiStatus.paid:
        return 'Sudah Bayar';
      case ReservasiStatus.approved:
        return 'Disetujui';
      case ReservasiStatus.shipping:
        return 'Dalam Pengiriman';
      case ReservasiStatus.installed:
        return 'PS Terpasang';
      case ReservasiStatus.active:
        return 'Sedang Disewa';
      case ReservasiStatus.expired:
        return 'Masa Sewa Habis';
      case ReservasiStatus.schedulingPickup:
        return 'Dijadwalkan Pickup';
      case ReservasiStatus.pickingUp:
        return 'Sedang Dijemput';
      case ReservasiStatus.pickedUp:
        return 'Sudah Dijemput';
      case ReservasiStatus.completed:
        return 'Selesai';
      case ReservasiStatus.rejected:
        return 'Ditolak';
      default:
        return status;
    }
  }

  String _truncateId(String id) => id.length > 8 ? id.substring(0, 8) : id;

  String _formatCurrency(int amount) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(amount);
  }

  Future<void> _openWhatsApp(String phone) async {
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '62${cleanPhone.substring(1)}';
    }
    final url = 'https://wa.me/$cleanPhone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}
