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
import 'login_page.dart';
import 'payment_page.dart';
import 'list_ps_page.dart';
import 'reservasi_detail_page.dart';

// Helper function to clean base64 string
String _cleanBase64(String base64String) {
  // Remove data URI prefix if present
  if (base64String.contains(',')) {
    return base64String.split(',').last;
  }
  return base64String;
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  // Konstanta warna tema
  static const Color _primaryColor = Color(0xFF2563EB);
  static const Color _secondaryColor = Color(0xFF7C3AED);
  static const Color _bgColor = Color(0xFFF8FAFC);
  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = Color(0xFF1E293B);
  static const Color _textSecondary = Color(0xFF64748B);

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authController = context.read<AuthController>();
    final user = authController.currentUser;
    if (user != null) {
      // Load PS items untuk mapping nama
      await context.read<PSItemController>().loadAllPSItems();

      // Load reservasi
      await context.read<ReservasiController>().loadReservasiByUser(
        user.userId,
      );

      // Check dan sync payment status untuk reservasi yang belum bayar
      final paymentController = context.read<PaymentController>();
      await paymentController.loadPaymentsByUser(user.userId);

      // Sync status untuk pending payments
      for (var payment in paymentController.payments) {
        if (payment.status == 'pending' && payment.orderId.isNotEmpty) {
          await paymentController.syncPaymentStatus(payment.orderId);
        }
      }

      // Refresh reservasi setelah sync payment
      await context.read<ReservasiController>().loadReservasiByUser(
        user.userId,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 400,
              floating: false,
              pinned: true,
              backgroundColor: _primaryColor,
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
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    // Fallback: jika tidak ada route untuk di-pop, kembali ke ListPSPage
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const ListPSPage()),
                    );
                  }
                },
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  onPressed: _loadData,
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_primaryColor, _secondaryColor],
                    ),
                  ),
                  child: SafeArea(
                    child: Consumer<AuthController>(
                      builder: (context, controller, _) {
                        final user = controller.currentUser;
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            // Avatar
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 3,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white.withOpacity(0.3),
                                child: Text(
                                  user != null && user.name.isNotEmpty
                                      ? user.name[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Nama
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Text(
                                user?.name ?? 'User',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Role badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    user?.role == 'admin'
                                        ? Icons.admin_panel_settings
                                        : Icons.person,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    (user?.role ?? 'user').toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  decoration: const BoxDecoration(
                    color: _bgColor,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: _primaryColor,
                    indicatorWeight: 3,
                    labelColor: _primaryColor,
                    unselectedLabelColor: _textSecondary,
                    indicatorPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    tabs: const [
                      Tab(icon: Icon(Icons.person_outline), text: 'Biodata'),
                      Tab(icon: Icon(Icons.receipt_long), text: 'Reservasi'),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [_buildBiodataTab(), _buildHistoriTab()],
        ),
      ),
    );
  }

  Widget _buildBiodataTab() {
    return Consumer<AuthController>(
      builder: (context, controller, child) {
        final user = controller.currentUser;

        if (user == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_off,
                    size: 48,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Anda belum login'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Biodata Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                  children: [
                    _buildBiodataRow(
                      Icons.email_outlined,
                      'Email',
                      user.email,
                      _primaryColor,
                    ),
                    const Divider(height: 30),
                    _buildBiodataRow(
                      Icons.fingerprint,
                      'User ID',
                      user.userId,
                      Colors.orange,
                    ),
                    const Divider(height: 30),
                    _buildBiodataRow(
                      Icons.calendar_today_outlined,
                      'Bergabung',
                      DateFormat('dd MMMM yyyy').format(user.createdAt),
                      Colors.green,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Logout Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFff6b6b), Color(0xFFee5a5a)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBiodataRow(
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoriTab() {
    return Consumer<ReservasiController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: _primaryColor),
          );
        }

        if (controller.reservasiList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    size: 56,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Belum ada reservasi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Reservasi Anda akan muncul di sini',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF667eea),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.reservasiList.length,
            itemBuilder: (context, index) {
              final reservasi = controller.reservasiList[index];
              return _buildReservasiCard(reservasi);
            },
          ),
        );
      },
    );
  }

  Widget _buildReservasiCard(ReservasiModel reservasi) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReservasiDetailPage(reservasi: reservasi),
          ),
        ).then((_) => _loadData());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon PS
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getStatusColor(reservasi.status).withOpacity(0.2),
                      _getStatusColor(reservasi.status).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.gamepad,
                  color: _getStatusColor(reservasi.status),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ID & Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '#${_truncateId(reservasi.reservasiId)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF667eea),
                          ),
                        ),
                        _buildCompactStatusBadge(reservasi.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Nama PS
                    Text(
                      _getPsName(reservasi.psId),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Periode & Jumlah
                    Row(
                      children: [
                        Icon(
                          Icons.date_range,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${DateFormat('dd MMM').format(reservasi.tglMulai)} - ${DateFormat('dd MMM yyyy').format(reservasi.tglSelesai)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${reservasi.jumlahUnit} unit',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Arrow
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStatusBadge(String status) {
    Color color = _getStatusColor(status);
    String displayText;

    switch (status) {
      case 'belum_bayar':
        displayText = 'Belum Bayar';
        break;
      case ReservasiStatus.pending:
        displayText = 'Menunggu';
        break;
      case ReservasiStatus.paid:
        displayText = 'Sudah Bayar';
        break;
      case ReservasiStatus.approved:
        displayText = 'Disetujui';
        break;
      case ReservasiStatus.shipping:
        displayText = 'Dikirim';
        break;
      case ReservasiStatus.installed:
        displayText = 'Terpasang';
        break;
      case ReservasiStatus.rejected:
        displayText = 'Ditolak';
        break;
      case ReservasiStatus.active:
        displayText = 'Aktif';
        break;
      case ReservasiStatus.expired:
        displayText = 'Expired';
        break;
      case ReservasiStatus.schedulingPickup:
        displayText = 'Dijadwalkan';
        break;
      case ReservasiStatus.pickingUp:
        displayText = 'Menjemput';
        break;
      case ReservasiStatus.pickedUp:
        displayText = 'Dijemput';
        break;
      case ReservasiStatus.finished:
      case ReservasiStatus.completed:
        displayText = 'Selesai';
        break;
      case ReservasiStatus.cancelled:
        displayText = 'Dibatalkan';
        break;
      default:
        displayText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[400]),
        const SizedBox(width: 10),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDescriptionSection(ReservasiModel reservasi) {
    final description = ReservasiStatus.getDescription(reservasi.status);
    if (description.isEmpty) return const SizedBox.shrink();

    Color bgColor;
    Color textColor;
    IconData icon;

    switch (reservasi.status) {
      case ReservasiStatus.pending:
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange[800]!;
        icon = Icons.info_outline;
        break;
      case ReservasiStatus.paid:
        bgColor = Colors.teal.withOpacity(0.1);
        textColor = Colors.teal[800]!;
        icon = Icons.check_circle_outline;
        break;
      case ReservasiStatus.approved:
        bgColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue[800]!;
        icon = Icons.thumb_up_outlined;
        break;
      case ReservasiStatus.shipping:
        bgColor = Colors.indigo.withOpacity(0.1);
        textColor = Colors.indigo[800]!;
        icon = Icons.local_shipping_outlined;
        break;
      case ReservasiStatus.installed:
        bgColor = Colors.cyan.withOpacity(0.1);
        textColor = Colors.cyan[800]!;
        icon = Icons.build_outlined;
        break;
      case ReservasiStatus.active:
        bgColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green[800]!;
        icon = Icons.play_circle_outline;
        break;
      case ReservasiStatus.expired:
        bgColor = Colors.deepOrange.withOpacity(0.1);
        textColor = Colors.deepOrange[800]!;
        icon = Icons.timer_off_outlined;
        break;
      case ReservasiStatus.schedulingPickup:
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange[800]!;
        icon = Icons.schedule;
        break;
      case ReservasiStatus.pickingUp:
        bgColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue[800]!;
        icon = Icons.directions_car;
        break;
      case ReservasiStatus.pickedUp:
        bgColor = Colors.teal.withOpacity(0.1);
        textColor = Colors.teal[800]!;
        icon = Icons.check_box;
        break;
      case ReservasiStatus.completed:
        bgColor = Colors.purple.withOpacity(0.1);
        textColor = Colors.purple[800]!;
        icon = Icons.verified_outlined;
        break;
      case ReservasiStatus.rejected:
        bgColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red[800]!;
        icon = Icons.cancel_outlined;
        break;
      default:
        bgColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey[800]!;
        icon = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerSection(ReservasiModel reservasi) {
    final sisaWaktu = reservasi.getSisaWaktuFormatted();
    final isExpired = reservasi.isSewaExpired;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isExpired
              ? [Colors.red.withOpacity(0.1), Colors.orange.withOpacity(0.1)]
              : [Colors.green.withOpacity(0.1), Colors.teal.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpired
              ? Colors.red.withOpacity(0.3)
              : Colors.green.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isExpired ? Icons.timer_off : Icons.timer,
                color: isExpired ? Colors.red : Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isExpired ? 'Waktu Sewa Habis' : 'Sisa Waktu Sewa',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isExpired ? Colors.red[800] : Colors.green[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time,
                  color: isExpired ? Colors.red : const Color(0xFF667eea),
                ),
                const SizedBox(width: 10),
                Text(
                  sisaWaktu,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isExpired ? Colors.red : const Color(0xFF667eea),
                  ),
                ),
              ],
            ),
          ),
          if (reservasi.waktuSewaMulai != null &&
              reservasi.waktuSewaBerakhir != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mulai',
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                    Text(
                      DateFormat(
                        'dd/MM/yyyy HH:mm',
                      ).format(reservasi.waktuSewaMulai!),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.arrow_forward, color: Colors.grey[400], size: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Berakhir',
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                    Text(
                      DateFormat(
                        'dd/MM/yyyy HH:mm',
                      ).format(reservasi.waktuSewaBerakhir!),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDriverInfoSection(ReservasiModel reservasi) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.delivery_dining, color: Colors.indigo[700], size: 18),
              const SizedBox(width: 8),
              Text(
                'Info Pengantar',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo[700],
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Driver Photo
              if (reservasi.driverPhoto != null &&
                  reservasi.driverPhoto!.isNotEmpty)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.indigo.withOpacity(0.3)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.memory(
                      base64Decode(_cleanBase64(reservasi.driverPhoto!)),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.person, color: Colors.grey[400]),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.person, color: Colors.indigo[400]),
                ),
              const SizedBox(width: 12),
              // Driver Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reservasi.driverName ?? '-',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (reservasi.driverPhone != null &&
                        reservasi.driverPhone!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            reservasi.driverPhone!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // WhatsApp Button
              if (reservasi.driverPhone != null &&
                  reservasi.driverPhone!.isNotEmpty)
                IconButton(
                  onPressed: () => _openWhatsApp(reservasi.driverPhone!),
                  icon: const Icon(Icons.chat, color: Colors.green),
                  tooltip: 'Hubungi via WhatsApp',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green.withOpacity(0.1),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFotoBuktiPasangSection(ReservasiModel reservasi) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.cyan.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyan.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_camera, color: Colors.cyan[700], size: 18),
              const SizedBox(width: 8),
              Text(
                'Foto Bukti Pemasangan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan[700],
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              base64Decode(_cleanBase64(reservasi.fotoBuktiPasang!)),
              width: double.infinity,
              height: 150,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 100,
                color: Colors.grey[200],
                child: Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.grey[400],
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Upload Bukti Terpasang Section
  Widget _buildUploadBuktiTerpasangSection(ReservasiModel reservasi) {
    // Jika sudah upload, jangan tampilkan tombol upload lagi
    if (reservasi.buktiTerpasang != null &&
        reservasi.buktiTerpasang!.isNotEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.withOpacity(0.1), Colors.green.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: Colors.teal[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unit Sudah Terpasang?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[800],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Upload foto bukti unit sudah terpasang',
                      style: TextStyle(color: Colors.teal[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showUploadBuktiTerpasangDialog(reservasi),
              icon: const Icon(Icons.upload_file, color: Colors.white),
              label: const Text(
                'Upload Bukti Terpasang',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 14),
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

  // Tampilkan bukti terpasang yang sudah diupload
  Widget _buildBuktiTerpasangSection(ReservasiModel reservasi) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified, color: Colors.green[700], size: 18),
              const SizedBox(width: 8),
              Text(
                'Bukti Unit Terpasang',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Terverifikasi',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: GestureDetector(
              onTap: () => _showImageDialog(
                'Bukti Unit Terpasang',
                reservasi.buktiTerpasang!,
              ),
              child: Image.memory(
                base64Decode(_cleanBase64(reservasi.buktiTerpasang!)),
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 100,
                  color: Colors.grey[200],
                  child: Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.grey[400],
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadBuktiTerpasangDialog(ReservasiModel reservasi) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt, color: Colors.teal, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Upload Bukti Terpasang',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Foto bukti bahwa unit PS sudah terpasang di lokasi Anda',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _pickAndUploadBuktiTerpasang(
                        reservasi,
                        ImageSource.gallery,
                      );
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galeri'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _pickAndUploadBuktiTerpasang(
                        reservasi,
                        ImageSource.camera,
                      );
                    },
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: const Text(
                      'Kamera',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  Future<void> _pickAndUploadBuktiTerpasang(
    ReservasiModel reservasi,
    ImageSource source,
  ) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (image == null) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF667eea)),
            SizedBox(height: 16),
            Text('Mengupload bukti terpasang...'),
          ],
        ),
      ),
    );

    try {
      final controller = context.read<ReservasiController>();
      final success = await controller.uploadBuktiTerpasang(
        reservasi.reservasiId,
        image,
        reservasi.driverId ?? '',
      );

      // Close loading dialog
      Navigator.pop(context);

      if (success) {
        // Refresh data
        await _loadData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Bukti terpasang berhasil diupload!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              controller.errorMessage ?? 'Gagal upload bukti terpasang',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // ==================== PICKUP SECTIONS ====================

  /// Info jadwal penjemputan (untuk status scheduling_pickup)
  Widget _buildPickupScheduledSection(ReservasiModel reservasi) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepOrange.shade50, Colors.orange.shade50],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.deepOrange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.schedule,
                  color: Colors.deepOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Penjemputan Dijadwalkan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Colors.deepOrange),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Jadwal Jemput',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      reservasi.pickupTime ?? 'Belum ditentukan',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Driver akan segera berangkat untuk menjemput PlayStation. Harap siapkan unit yang akan dikembalikan.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Upload bukti jemput section (untuk status picking_up)
  Widget _buildUploadBuktiJemputSection(ReservasiModel reservasi) {
    // Jika sudah upload, tidak perlu tampilkan lagi
    if (reservasi.fotoBuktiJemput != null &&
        reservasi.fotoBuktiJemput!.isNotEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.indigo.shade50],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.directions_car,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Driver Sedang Menuju',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Upload foto setelah PS diserahkan',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showUploadBuktiJemputDialog(reservasi),
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              label: const Text(
                'Upload Bukti Jemput',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 14),
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

  /// Tampilkan bukti jemput yang sudah diupload
  Widget _buildBuktiJemputSection(ReservasiModel reservasi) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Bukti Penjemputan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Terkirim',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: GestureDetector(
              onTap: () => _showImageDialog(
                'Bukti Penjemputan',
                reservasi.fotoBuktiJemput!,
              ),
              child: Image.memory(
                base64Decode(_cleanBase64(reservasi.fotoBuktiJemput!)),
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 100,
                  color: Colors.grey[200],
                  child: Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.grey[400],
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadBuktiJemputDialog(ReservasiModel reservasi) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.photo_camera,
                color: Colors.blue,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Upload Bukti Penjemputan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Foto sebagai bukti PlayStation sudah diserahkan ke driver',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _pickAndUploadBuktiJemput(reservasi, ImageSource.gallery);
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galeri'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _pickAndUploadBuktiJemput(reservasi, ImageSource.camera);
                    },
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: const Text(
                      'Kamera',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  Future<void> _pickAndUploadBuktiJemput(
    ReservasiModel reservasi,
    ImageSource source,
  ) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (image == null) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF667eea)),
            SizedBox(height: 16),
            Text('Mengupload bukti penjemputan...'),
          ],
        ),
      ),
    );

    try {
      final controller = context.read<ReservasiController>();
      final success = await controller.uploadBuktiJemput(
        reservasi.reservasiId,
        image,
      );

      // Close loading dialog
      Navigator.pop(context);

      if (success) {
        // Refresh data
        await _loadData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Bukti penjemputan berhasil diupload!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              controller.errorMessage ?? 'Gagal upload bukti penjemputan',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
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
              child: Image.memory(
                base64Decode(_cleanBase64(imageData)),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.grey[400],
                      size: 50,
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

  Widget _buildStatusBadge(String status) {
    Color color = _getStatusColor(status);
    String displayText;
    IconData icon;

    switch (status) {
      case 'belum_bayar':
        displayText = 'Belum Bayar';
        icon = Icons.pending_actions;
        break;
      case ReservasiStatus.pending:
        displayText = 'Menunggu';
        icon = Icons.hourglass_empty;
        break;
      case ReservasiStatus.paid:
        displayText = 'Sudah Bayar';
        icon = Icons.payment;
        break;
      case ReservasiStatus.approved:
        displayText = 'Disetujui';
        icon = Icons.check_circle;
        break;
      case ReservasiStatus.shipping:
        displayText = 'Dikirim';
        icon = Icons.local_shipping;
        break;
      case ReservasiStatus.installed:
        displayText = 'Terpasang';
        icon = Icons.build_circle;
        break;
      case ReservasiStatus.rejected:
        displayText = 'Ditolak';
        icon = Icons.cancel;
        break;
      case ReservasiStatus.active:
        displayText = 'Aktif';
        icon = Icons.play_circle;
        break;
      case ReservasiStatus.expired:
        displayText = 'Waktu Habis';
        icon = Icons.timer_off;
        break;
      case ReservasiStatus.schedulingPickup:
        displayText = 'Dijadwalkan';
        icon = Icons.schedule;
        break;
      case ReservasiStatus.pickingUp:
        displayText = 'Menjemput';
        icon = Icons.directions_car;
        break;
      case ReservasiStatus.pickedUp:
        displayText = 'Dijemput';
        icon = Icons.check_box;
        break;
      case ReservasiStatus.finished:
      case ReservasiStatus.completed:
        displayText = 'Selesai';
        icon = Icons.verified;
        break;
      case ReservasiStatus.cancelled:
        displayText = 'Dibatalkan';
        icon = Icons.block;
        break;
      default:
        displayText = status;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            displayText,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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

  String _formatCurrency(int amount) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(amount);
  }

  String _truncateId(String id) {
    if (id.length > 8) {
      return id.substring(0, 8);
    }
    return id;
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

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.logout, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text('Logout'),
          ],
        ),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<AuthController>().logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }
}
