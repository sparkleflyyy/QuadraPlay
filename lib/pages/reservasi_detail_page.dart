import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/auth_controller.dart';
import '../controllers/reservasi_controller.dart';
import '../controllers/payment_controller.dart';
import '../controllers/ps_item_controller.dart';
import '../models/reservasi_model.dart';
import 'payment_page.dart';

// Helper function to clean base64 string
String _cleanBase64(String base64String) {
  if (base64String.contains(',')) {
    return base64String.split(',').last;
  }
  return base64String;
}

class ReservasiDetailPage extends StatefulWidget {
  final ReservasiModel reservasi;

  const ReservasiDetailPage({super.key, required this.reservasi});

  @override
  State<ReservasiDetailPage> createState() => _ReservasiDetailPageState();
}

class _ReservasiDetailPageState extends State<ReservasiDetailPage> {
  // Konstanta warna tema
  static const Color _primaryColor = Color(0xFF2563EB);
  static const Color _bgColor = Color(0xFFF8FAFC);
  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = Color(0xFF1E293B);
  static const Color _textSecondary = Color(0xFF64748B);

  late ReservasiModel _reservasi;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _reservasi = widget.reservasi;
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      final controller = context.read<ReservasiController>();
      await controller.loadReservasiByUser(_reservasi.userId);

      // Find updated reservasi
      final updated = controller.reservasiList.firstWhere(
        (r) => r.reservasiId == _reservasi.reservasiId,
        orElse: () => _reservasi,
      );

      if (mounted) {
        setState(() => _reservasi = updated);
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
        title: Text(
          'Detail Reservasi',
          style: const TextStyle(fontWeight: FontWeight.bold),
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
                          _buildInfoRow('No. WhatsApp', _reservasi.noWA),
                          _buildInfoRow('Alamat', _reservasi.alamat),
                          if (_reservasi.latitude != null &&
                              _reservasi.longitude != null)
                            _buildLocationButton(),
                          const SizedBox(height: 12),
                          // Foto KTP
                          _buildImageSection(
                            'Foto KTP',
                            _reservasi.ktpUrl,
                            Icons.badge_outlined,
                          ),
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
                          _buildInfoRow(
                            'Status Bayar',
                            _reservasi.status == ReservasiStatus.belumBayar
                                ? 'Belum Bayar'
                                : 'Sudah Bayar',
                          ),
                          // Tombol bayar jika belum bayar
                          if (_reservasi.status ==
                              ReservasiStatus.belumBayar) ...[
                            const SizedBox(height: 12),
                            _buildPayButton(),
                          ],
                          // Bukti pembayaran - tampilkan dari payment jika ada
                          const SizedBox(height: 12),
                          _buildPaymentProofSection(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info Pengantaran
                    if (_reservasi.driverName != null ||
                        _reservasi.fotoBuktiPasang != null ||
                        _reservasi.buktiTerpasang != null) ...[
                      _buildSectionCard(
                        title: 'Informasi Pengantaran',
                        icon: Icons.local_shipping_outlined,
                        child: Column(
                          children: [
                            if (_reservasi.driverName != null) ...[
                              _buildInfoRow('Driver', _reservasi.driverName!),
                              if (_reservasi.driverPhone != null)
                                _buildDriverContact(),
                            ],
                            if (_reservasi.waktuSewaMulai != null)
                              _buildInfoRow(
                                'Waktu Mulai Sewa',
                                DateFormat(
                                  'dd MMM yyyy, HH:mm',
                                ).format(_reservasi.waktuSewaMulai!),
                              ),
                            if (_reservasi.waktuSewaBerakhir != null)
                              _buildInfoRow(
                                'Waktu Berakhir Sewa',
                                DateFormat(
                                  'dd MMM yyyy, HH:mm',
                                ).format(_reservasi.waktuSewaBerakhir!),
                              ),
                            // Foto bukti pasang dari driver
                            if (_reservasi.fotoBuktiPasang != null &&
                                _reservasi.fotoBuktiPasang!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildImageSection(
                                'Bukti PS Terpasang (Driver)',
                                _reservasi.fotoBuktiPasang!,
                                Icons.camera_alt_outlined,
                              ),
                            ],
                            // Bukti terpasang dari user
                            if (_reservasi.buktiTerpasang != null &&
                                _reservasi.buktiTerpasang!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildImageSection(
                                'Bukti PS Terpasang (User)',
                                _reservasi.buktiTerpasang!,
                                Icons.verified_user_outlined,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Upload Bukti Terpasang (jika status shipping)
                    if (_reservasi.status == ReservasiStatus.shipping) ...[
                      _buildUploadBuktiTerpasangSection(),
                      const SizedBox(height: 16),
                    ],

                    // Info Penjemputan
                    if (_reservasi.pickupDriverId != null ||
                        _reservasi.pickupTime != null ||
                        _reservasi.fotoBuktiJemput != null ||
                        _reservasi.status == ReservasiStatus.schedulingPickup ||
                        _reservasi.status == ReservasiStatus.pickingUp ||
                        _reservasi.status == ReservasiStatus.pickedUp) ...[
                      _buildSectionCard(
                        title: 'Informasi Penjemputan',
                        icon: Icons.assignment_return_outlined,
                        child: Column(
                          children: [
                            if (_reservasi.pickupTime != null)
                              _buildInfoRow(
                                'Jadwal Jemput',
                                _reservasi.pickupTime!,
                              ),
                            // Foto bukti jemput
                            if (_reservasi.fotoBuktiJemput != null &&
                                _reservasi.fotoBuktiJemput!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildImageSection(
                                'Bukti PS Dijemput',
                                _reservasi.fotoBuktiJemput!,
                                Icons.check_circle_outline,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Upload Bukti Jemput (jika status picking_up)
                    if (_reservasi.status == ReservasiStatus.pickingUp) ...[
                      _buildUploadBuktiJemputSection(),
                      const SizedBox(height: 16),
                    ],

                    // Timer Section (jika status active)
                    if (_reservasi.status == ReservasiStatus.active &&
                        _reservasi.waktuSewaMulai != null &&
                        _reservasi.waktuSewaBerakhir != null) ...[
                      _buildTimerSection(),
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 20),
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
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            _getStatusIcon(_reservasi.status),
            color: Colors.white,
            size: 50,
          ),
          const SizedBox(height: 12),
          Text(
            _getStatusDisplayText(_reservasi.status),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ReservasiStatus.getDescription(_reservasi.status),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
            ),
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
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          // Content
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => _openMaps(_reservasi.latitude!, _reservasi.longitude!),
        icon: const Icon(Icons.map, size: 16),
        label: const Text('Lihat di Maps'),
        style: TextButton.styleFrom(
          foregroundColor: _primaryColor,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildDriverContact() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              'Kontak Driver',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _openWhatsApp(_reservasi.driverPhone!),
              child: Row(
                children: [
                  Text(
                    _reservasi.driverPhone!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chat, size: 14, color: _primaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(String label, String imageData, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showImageDialog(label, imageData),
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildImage(imageData),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage(String imageData) {
    // Check if it's a URL or base64
    if (imageData.startsWith('http://') || imageData.startsWith('https://')) {
      return Image.network(
        imageData,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildImageError(),
      );
    } else {
      try {
        return Image.memory(
          base64Decode(_cleanBase64(imageData)),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildImageError(),
        );
      } catch (e) {
        return _buildImageError();
      }
    }
  }

  Widget _buildImageError() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(Icons.broken_image, color: Colors.grey[400], size: 50),
      ),
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFFf7971e), Color(0xFFffd200)],
          ),
        ),
        child: ElevatedButton.icon(
          onPressed: () {
            final user = context.read<AuthController>().currentUser;
            if (user == null) return;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentPage(
                  reservasiId: _reservasi.reservasiId,
                  userId: user.userId,
                  totalHarga: _reservasi.totalHarga,
                  itemName: 'Rental PlayStation',
                  itemQuantity: _reservasi.jumlahUnit,
                ),
              ),
            ).then((_) => _refreshData());
          },
          icon: const Icon(Icons.payment, color: Colors.white),
          label: const Text(
            'Bayar Sekarang',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentProofSection() {
    return Consumer<PaymentController>(
      builder: (context, paymentController, _) {
        // Find payment for this reservasi - wrap in try-catch
        try {
          final paymentData = paymentController.payments.firstWhere(
            (p) => p.reservasiId == _reservasi.reservasiId,
          );

          if (paymentData.buktiPembayaran != null &&
              paymentData.buktiPembayaran!.isNotEmpty) {
            return _buildImageSection(
              'Bukti Pembayaran',
              paymentData.buktiPembayaran!,
              Icons.receipt_outlined,
            );
          }
        } catch (e) {
          // No payment found
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildUploadBuktiTerpasangSection() {
    return _buildSectionCard(
      title: 'Upload Bukti Terpasang',
      icon: Icons.add_photo_alternate_outlined,
      child: Column(
        children: [
          Text(
            'PS sudah tiba? Upload foto sebagai bukti PS sudah terpasang di tempat Anda.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _pickAndUploadBuktiTerpasang,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Ambil Foto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadBuktiJemputSection() {
    return _buildSectionCard(
      title: 'Upload Bukti Penjemputan',
      icon: Icons.add_photo_alternate_outlined,
      child: Column(
        children: [
          Text(
            'Driver sudah tiba untuk menjemput PS? Upload foto sebagai bukti PS sudah dijemput.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _pickAndUploadBuktiJemput,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Ambil Foto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerSection() {
    final now = DateTime.now();
    final endTime = _reservasi.waktuSewaBerakhir!;
    final remaining = endTime.difference(now);
    final isExpired = remaining.isNegative;

    return _buildSectionCard(
      title: 'Waktu Sewa',
      icon: Icons.timer_outlined,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimerBox(isExpired ? 0 : remaining.inDays, 'Hari'),
              const SizedBox(width: 8),
              _buildTimerBox(isExpired ? 0 : remaining.inHours % 24, 'Jam'),
              const SizedBox(width: 8),
              _buildTimerBox(isExpired ? 0 : remaining.inMinutes % 60, 'Menit'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isExpired ? 'Waktu sewa telah berakhir' : 'Sisa waktu sewa Anda',
            style: TextStyle(
              color: isExpired ? Colors.red : Colors.grey[600],
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBox(int value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadBuktiTerpasang() async {
    final picker = ImagePicker();
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (pickedFile == null) return;

    setState(() => _isLoading = true);

    try {
      final success = await context
          .read<ReservasiController>()
          .uploadBuktiTerpasang(
            _reservasi.reservasiId,
            pickedFile,
            _reservasi.driverId ?? '',
          );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bukti terpasang berhasil diupload'),
            backgroundColor: Colors.green,
          ),
        );
        await _refreshData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengupload bukti'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadBuktiJemput() async {
    final picker = ImagePicker();
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (pickedFile == null) return;

    setState(() => _isLoading = true);

    try {
      final success = await context
          .read<ReservasiController>()
          .uploadBuktiJemput(_reservasi.reservasiId, pickedFile);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bukti jemput berhasil diupload'),
            backgroundColor: Colors.green,
          ),
        );
        await _refreshData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengupload bukti'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Pilih Sumber Foto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.camera_alt, color: _primaryColor),
              ),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.photo_library, color: _primaryColor),
              ),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageDialog(String title, String imageData) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(title),
              centerTitle: true,
              automaticallyImplyLeading: false,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              actions: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
              child: _buildImage(imageData),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'belum_bayar':
        return Colors.red;
      case ReservasiStatus.pending:
        return Colors.orange;
      case ReservasiStatus.paid:
        return Colors.teal;
      case ReservasiStatus.approved:
        return Colors.blue;
      case ReservasiStatus.shipping:
        return Colors.indigo;
      case ReservasiStatus.installed:
        return Colors.cyan;
      case ReservasiStatus.rejected:
        return Colors.red;
      case ReservasiStatus.active:
        return Colors.green;
      case ReservasiStatus.expired:
        return Colors.deepOrange;
      case ReservasiStatus.schedulingPickup:
        return Colors.orange;
      case ReservasiStatus.pickingUp:
        return Colors.blue;
      case ReservasiStatus.pickedUp:
        return Colors.teal;
      case ReservasiStatus.finished:
      case ReservasiStatus.completed:
        return Colors.purple;
      case ReservasiStatus.cancelled:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'belum_bayar':
        return Icons.pending_actions;
      case ReservasiStatus.pending:
        return Icons.hourglass_empty;
      case ReservasiStatus.paid:
        return Icons.payment;
      case ReservasiStatus.approved:
        return Icons.check_circle;
      case ReservasiStatus.shipping:
        return Icons.local_shipping;
      case ReservasiStatus.installed:
        return Icons.build_circle;
      case ReservasiStatus.rejected:
        return Icons.cancel;
      case ReservasiStatus.active:
        return Icons.play_circle;
      case ReservasiStatus.expired:
        return Icons.timer_off;
      case ReservasiStatus.schedulingPickup:
        return Icons.schedule;
      case ReservasiStatus.pickingUp:
        return Icons.directions_car;
      case ReservasiStatus.pickedUp:
        return Icons.check_box;
      case ReservasiStatus.finished:
      case ReservasiStatus.completed:
        return Icons.verified;
      case ReservasiStatus.cancelled:
        return Icons.block;
      default:
        return Icons.info;
    }
  }

  String _getStatusDisplayText(String status) {
    switch (status) {
      case 'belum_bayar':
        return 'Belum Bayar';
      case ReservasiStatus.pending:
        return 'Menunggu';
      case ReservasiStatus.paid:
        return 'Sudah Bayar';
      case ReservasiStatus.approved:
        return 'Disetujui';
      case ReservasiStatus.shipping:
        return 'Sedang Dikirim';
      case ReservasiStatus.installed:
        return 'Terpasang';
      case ReservasiStatus.rejected:
        return 'Ditolak';
      case ReservasiStatus.active:
        return 'Aktif';
      case ReservasiStatus.expired:
        return 'Waktu Habis';
      case ReservasiStatus.schedulingPickup:
        return 'Dijadwalkan Jemput';
      case ReservasiStatus.pickingUp:
        return 'Sedang Dijemput';
      case ReservasiStatus.pickedUp:
        return 'Sudah Dijemput';
      case ReservasiStatus.finished:
      case ReservasiStatus.completed:
        return 'Selesai';
      case ReservasiStatus.cancelled:
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  String _formatCurrency(int amount) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(amount);
  }

  /// Helper untuk mendapatkan nama PS dari psId
  String _getPsName(String psId) {
    final psController = context.read<PSItemController>();
    final psItem = psController.psItems.firstWhere(
      (item) => item.psId == psId,
      orElse: () => psController.psItems.isNotEmpty
          ? psController.psItems.first
          : throw Exception('PS not found'),
    );
    try {
      return psItem.nama;
    } catch (e) {
      return psId; // Fallback ke psId jika tidak ditemukan
    }
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
