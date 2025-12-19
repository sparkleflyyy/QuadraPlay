import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../controllers/reservasi_controller.dart';
import '../models/ps_item_model.dart';
import '../models/reservasi_model.dart';
import 'list_ps_page.dart';
import 'upload_pembayaran_page.dart';

class BuatReservasiPage extends StatefulWidget {
  final PSItemModel psItem;
  final String userId;

  const BuatReservasiPage({
    super.key,
    required this.psItem,
    required this.userId,
  });

  @override
  State<BuatReservasiPage> createState() => _BuatReservasiPageState();
}

class _BuatReservasiPageState extends State<BuatReservasiPage> {
  final _formKey = GlobalKey<FormState>();
  final _alamatController = TextEditingController();
  final _noWAController = TextEditingController();

  DateTime? _tglMulai;
  DateTime? _tglSelesai;
  int _jumlahHari = 1;
  int _jumlahUnit = 1;
  XFile? _ktpFile;
  Uint8List? _ktpBytes;
  final ImagePicker _picker = ImagePicker();

  int get _totalHarga => ReservasiModel.calculateTotalHarga(
    widget.psItem.hargaPerHari,
    _jumlahHari,
    _jumlahUnit,
  );

  @override
  void dispose() {
    _alamatController.dispose();
    _noWAController.dispose();
    super.dispose();
  }

  Future<void> _pickKTPImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _ktpFile = image;
        _ktpBytes = bytes;
      });
    }
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_tglMulai ?? now)
          : (_tglSelesai ?? now.add(const Duration(days: 1))),
      firstDate: isStartDate ? now : (_tglMulai ?? now),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF667eea),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _tglMulai = picked;
          if (_tglSelesai != null && _tglSelesai!.isBefore(picked)) {
            _tglSelesai = null;
          }
        } else {
          _tglSelesai = picked;
        }

        if (_tglMulai != null && _tglSelesai != null) {
          _jumlahHari = _tglSelesai!.difference(_tglMulai!).inDays + 1;
          if (_jumlahHari < 1) _jumlahHari = 1;
        }
      });
    }
  }

  Future<void> _submitReservasi() async {
    if (!_formKey.currentState!.validate()) return;

    if (_tglMulai == null || _tglSelesai == null) {
      _showErrorSnackBar('Pilih tanggal mulai dan selesai');
      return;
    }

    if (_ktpFile == null) {
      _showErrorSnackBar('Upload foto KTP');
      return;
    }

    final controller = context.read<ReservasiController>();

    final success = await controller.createReservasi(
      userId: widget.userId,
      psId: widget.psItem.psId,
      jumlahHari: _jumlahHari,
      jumlahUnit: _jumlahUnit,
      tglMulai: _tglMulai!,
      tglSelesai: _tglSelesai!,
      alamat: _alamatController.text.trim(),
      noWA: _noWAController.text.trim(),
      ktpFile: _ktpFile!,
    );

    if (success && mounted) {
      final reservasiId = controller.lastCreatedReservasiId ?? '';
      _showPaymentOptionDialog(reservasiId);
    } else if (mounted) {
      _showErrorSnackBar(controller.errorMessage ?? 'Gagal membuat reservasi');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showPaymentOptionDialog(String reservasiId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 56,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Reservasi Berhasil! 🎉',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Reservasi Anda telah dibuat dengan status "Belum Bayar".',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            const Text(
              'Pilih opsi pembayaran:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Bayar Nanti
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const ListPSPage()),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Reservasi disimpan. Bayar melalui Profile > Histori.',
                      ),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.schedule),
                label: const Text('Bayar Nanti'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFF667eea)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Bayar Sekarang
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UploadPembayaranPage(
                          reservasiId: reservasiId,
                          userId: widget.userId,
                          totalHarga: _totalHarga,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.payment, color: Colors.white),
                  label: const Text(
                    'Bayar Sekarang',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF667eea),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Buat Reservasi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
          ),
        ),
      ),
      body: Consumer<ReservasiController>(
        builder: (context, controller, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info PS Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.gamepad,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.psItem.nama,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rp ${_formatCurrency(widget.psItem.hargaPerHari)}/hari',
                                style: const TextStyle(
                                  color: Color(0xFF11998e),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF667eea).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.psItem.kategori,
                            style: const TextStyle(
                              color: Color(0xFF667eea),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section Title
                  _buildSectionTitle(Icons.calendar_today, 'Pilih Tanggal'),

                  const SizedBox(height: 12),

                  // Date Selection
                  Row(
                    children: [
                      Expanded(
                        child: _buildDatePicker('Mulai', _tglMulai, true),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDatePicker('Selesai', _tglSelesai, false),
                      ),
                    ],
                  ),

                  if (_tglMulai != null && _tglSelesai != null)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF667eea).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.timer,
                            color: Color(0xFF667eea),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Durasi: $_jumlahHari hari',
                            style: const TextStyle(
                              color: Color(0xFF667eea),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Section Title
                  _buildSectionTitle(Icons.add_shopping_cart, 'Jumlah Unit'),

                  const SizedBox(height: 12),

                  // Quantity Selector
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildQuantityButton(
                          Icons.remove,
                          _jumlahUnit > 1,
                          () => setState(() => _jumlahUnit--),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F6FA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$_jumlahUnit',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildQuantityButton(
                          Icons.add,
                          _jumlahUnit < widget.psItem.stok,
                          () => setState(() => _jumlahUnit++),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Center(
                      child: Text(
                        'Stok tersedia: ${widget.psItem.stok} unit',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section Title
                  _buildSectionTitle(Icons.location_on, 'Alamat & Kontak'),

                  const SizedBox(height: 12),

                  // Alamat
                  _buildTextField(
                    controller: _alamatController,
                    label: 'Alamat Pengiriman',
                    hint: 'Masukkan alamat lengkap',
                    icon: Icons.home_outlined,
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Alamat tidak boleh kosong';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Nomor WA
                  _buildTextField(
                    controller: _noWAController,
                    label: 'Nomor WhatsApp',
                    hint: '08xxxxxxxxxx',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nomor WA tidak boleh kosong';
                      }
                      if (value.length < 10) {
                        return 'Nomor WA tidak valid';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Section Title
                  _buildSectionTitle(Icons.badge, 'Upload KTP'),

                  const SizedBox(height: 12),

                  // KTP Upload
                  GestureDetector(
                    onTap: _pickKTPImage,
                    child: Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _ktpBytes != null
                              ? Colors.green
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: _ktpBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.memory(_ktpBytes!, fit: BoxFit.cover),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF667eea,
                                    ).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_outlined,
                                    size: 32,
                                    color: Color(0xFF667eea),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Tap untuk upload foto KTP',
                                  style: TextStyle(
                                    color: Color(0xFF667eea),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Format: JPG, PNG',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Summary Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667eea).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow(
                          'Harga per hari',
                          'Rp ${_formatCurrency(widget.psItem.hargaPerHari)}',
                        ),
                        _buildSummaryRow('Jumlah hari', '$_jumlahHari hari'),
                        _buildSummaryRow('Jumlah unit', '$_jumlahUnit unit'),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: Colors.white30),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Rp ${_formatCurrency(_totalHarga)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Submit Button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF11998e).withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: controller.isLoading ? null : _submitReservasi,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: controller.isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 10),
                                Text(
                                  'Buat Reservasi',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF667eea).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF667eea), size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildDatePicker(String label, DateTime? date, bool isStartDate) {
    return GestureDetector(
      onTap: () => _selectDate(isStartDate),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: date != null ? const Color(0xFF667eea) : Colors.grey[300]!,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: date != null ? const Color(0xFF667eea) : Colors.grey,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date != null
                        ? DateFormat('dd MMM yyyy').format(date)
                        : 'Pilih',
                    style: TextStyle(
                      color: date != null ? Colors.black : Colors.grey,
                      fontWeight: date != null
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                )
              : null,
          color: enabled ? null : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: enabled ? Colors.white : Colors.grey),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF667eea)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8))),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
