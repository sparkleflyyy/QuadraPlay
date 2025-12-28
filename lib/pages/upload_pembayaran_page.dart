import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/payment_controller.dart';
import 'list_ps_page.dart';

class UploadPembayaranPage extends StatefulWidget {
  final String reservasiId;
  final String userId;
  final int totalHarga;

  const UploadPembayaranPage({
    super.key,
    required this.reservasiId,
    required this.userId,
    required this.totalHarga,
  });

  @override
  State<UploadPembayaranPage> createState() => _UploadPembayaranPageState();
}

class _UploadPembayaranPageState extends State<UploadPembayaranPage> {
  final _formKey = GlobalKey<FormState>();
  String _metodePembayaran = 'Dana';
  XFile? _buktiFile;
  Uint8List? _buktiBytes;
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _paymentMethods = [
    {'name': 'Dana', 'icon': '💳', 'color': Color(0xFF118EEA)},
    {'name': 'GoPay', 'icon': '💚', 'color': Color(0xFF00AA13)},
    {'name': 'Transfer Bank BCA', 'icon': '🏦', 'color': Color(0xFF0060AF)},
    {'name': 'Transfer Bank Mandiri', 'icon': '🏦', 'color': Color(0xFF003A70)},
    {'name': 'Transfer Bank BRI', 'icon': '🏦', 'color': Color(0xFF00529C)},
  ];

  Future<void> _pickBuktiImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _buktiFile = image;
        _buktiBytes = bytes;
      });
    }
  }

  Future<void> _submitPayment() async {
    if (_buktiFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Upload bukti pembayaran'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    final controller = context.read<PaymentController>();

    final success = await controller.createPayment(
      reservasiId: widget.reservasiId,
      userId: widget.userId,
      totalBayar: widget.totalHarga,
      metodePembayaran: _metodePembayaran,
      buktiFile: _buktiFile,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Pembayaran berhasil diupload! 🎉'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ListPSPage()),
        (route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'Gagal upload pembayaran'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label disalin: $text'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
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
          'Pembayaran',
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
      body: Consumer<PaymentController>(
        builder: (context, controller, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total Payment Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667eea).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.receipt_long,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Total Pembayaran',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rp ${_formatCurrency(widget.totalHarga)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Section Title
                  _buildSectionTitle(Icons.payment, 'Metode Pembayaran'),

                  const SizedBox(height: 12),

                  // Payment Method Selection
                  Container(
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
                    child: Column(
                      children: _paymentMethods.map((method) {
                        final isSelected = _metodePembayaran == method['name'];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _metodePembayaran = method['name'];
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF667eea).withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: (method['color'] as Color)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      method['icon'],
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    method['name'],
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? const Color(0xFF667eea)
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF667eea)
                                          : Colors.grey[300]!,
                                      width: 2,
                                    ),
                                    color: isSelected
                                        ? const Color(0xFF667eea)
                                        : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 14,
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section Title
                  _buildSectionTitle(Icons.account_balance, 'Transfer ke'),

                  const SizedBox(height: 12),

                  // Payment Info Card
                  _buildPaymentInfoCard(),

                  const SizedBox(height: 24),

                  // Section Title
                  _buildSectionTitle(Icons.receipt, 'Bukti Pembayaran'),

                  const SizedBox(height: 12),

                  // Upload Bukti
                  GestureDetector(
                    onTap: _pickBuktiImage,
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _buktiBytes != null
                              ? Colors.green
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: _buktiBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.memory(_buktiBytes!, fit: BoxFit.cover),
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.green.withOpacity(
                                              0.3,
                                            ),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 10,
                                    left: 10,
                                    right: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Tap untuk ganti gambar',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
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
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF667eea,
                                    ).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.cloud_upload_outlined,
                                    size: 40,
                                    color: Color(0xFF667eea),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Upload Bukti Transfer',
                                  style: TextStyle(
                                    color: Color(0xFF667eea),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Format: JPG, PNG (Max 5MB)',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 32),

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
                      onPressed: controller.isLoading ? null : _submitPayment,
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
                                  'Konfirmasi Pembayaran',
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

  Widget _buildPaymentInfoCard() {
    String accountNumber;
    String accountName = 'Homer Telson';
    Color accentColor;

    if (_metodePembayaran == 'Dana') {
      accountNumber = '085156607253';
      accentColor = const Color(0xFF118EEA);
    } else if (_metodePembayaran == 'GoPay') {
      accountNumber = '085156607253';
      accentColor = const Color(0xFF00AA13);
    } else if (_metodePembayaran.contains('BCA')) {
      accountNumber = '1234567890';
      accentColor = const Color(0xFF0060AF);
    } else if (_metodePembayaran.contains('Mandiri')) {
      accountNumber = '0987654321';
      accentColor = const Color(0xFF003A70);
    } else {
      accountNumber = '5678901234';
      accentColor = const Color(0xFF00529C);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor, accentColor.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _metodePembayaran.contains('Dana')
                        ? 'DANA'
                        : _metodePembayaran.contains('GoPay')
                        ? 'GPay'
                        : _metodePembayaran.split(' ').last.substring(0, 3),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _metodePembayaran,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'a.n. $accountName',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nomor Rekening/HP',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      accountNumber,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => _copyToClipboard(accountNumber, 'Nomor'),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.copy,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
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
