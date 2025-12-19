import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/auth_controller.dart';
import '../controllers/ps_item_controller.dart';
import '../controllers/reservasi_controller.dart';
import '../controllers/payment_controller.dart';
import '../models/reservasi_model.dart';
import '../models/payment_model.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'login_page.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserService _userService = UserService();
  List<UserModel> _users = [];
  bool _loadingUsers = false;
  Map<String, PaymentModel> _paymentMap = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshAll());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);
    try {
      final result = await _userService.getAllUsers();
      if (result['success']) {
        setState(() => _users = result['users']);
      }
    } catch (e) {
      print('Error loading users: $e');
    }
    setState(() => _loadingUsers = false);
  }

  void _buildPaymentMap(List<PaymentModel> payments) {
    _paymentMap = {};
    for (var payment in payments) {
      _paymentMap[payment.reservasiId] = payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 160,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF667eea),
              leading: const SizedBox.shrink(),
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
                  onPressed: _refreshAll,
                ),
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.more_vert,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onSelected: (value) {
                    if (value == 'logout') _logout();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.logout,
                              color: Colors.red,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('Logout'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.admin_panel_settings,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Admin Panel',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Kelola PlayStation & Reservasi',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFF667eea),
                    indicatorWeight: 3,
                    labelColor: const Color(0xFF667eea),
                    unselectedLabelColor: Colors.grey,
                    indicatorPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    tabs: const [
                      Tab(icon: Icon(Icons.gamepad_outlined), text: 'PS Items'),
                      Tab(
                        icon: Icon(Icons.receipt_long_outlined),
                        text: 'Reservasi',
                      ),
                      Tab(icon: Icon(Icons.people_outline), text: 'Users'),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPSItemsTab(),
            _buildReservasiTab(),
            _buildUsersTab(),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667eea).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: _showAddPSDialog,
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            )
          : null,
    );
  }

  // ==================== PS Items Tab ====================
  Widget _buildPSItemsTab() {
    return Consumer<PSItemController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF667eea)),
          );
        }

        if (controller.psItems.isEmpty) {
          return _buildEmptyState(
            Icons.gamepad_outlined,
            'Tidak ada PS Items',
            'Tambahkan PlayStation untuk disewakan',
            onAction: _showAddPSDialog,
            actionLabel: 'Tambah PS',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.psItems.length,
          itemBuilder: (context, index) {
            final item = controller.psItems[index];
            return _buildPSItemCard(item);
          },
        );
      },
    );
  }

  Widget _buildPSItemCard(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[200],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: item.fotoUrl.isNotEmpty
                ? (item.fotoUrl.startsWith('data:image')
                      ? Image.memory(
                          base64Decode(item.fotoUrl.split(',').last),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
                        )
                      : Image.network(
                          item.fotoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
                        ))
                : _buildPlaceholderIcon(),
          ),
        ),
        title: Text(
          item.nama,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.kategori,
                    style: const TextStyle(
                      color: Color(0xFF667eea),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: item.stok > 0
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Stok: ${item.stok}',
                    style: TextStyle(
                      color: item.stok > 0 ? Colors.green : Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Rp ${_formatCurrency(item.hargaPerHari)}/hari',
              style: const TextStyle(
                color: Color(0xFF11998e),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.more_vert, size: 18),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) {
            if (value == 'edit')
              _showEditPSDialog(item);
            else if (value == 'delete')
              _confirmDeletePS(item.psId);
          },
          itemBuilder: (context) => [
            _buildPopupMenuItem(Icons.edit, 'Edit', 'edit', Colors.blue),
            _buildPopupMenuItem(Icons.delete, 'Hapus', 'delete', Colors.red),
          ],
        ),
      ),
    );
  }

  // ==================== Reservasi Tab ====================
  Widget _buildReservasiTab() {
    return Consumer2<ReservasiController, PaymentController>(
      builder: (context, reservasiController, paymentController, child) {
        if (reservasiController.isLoading || paymentController.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF667eea)),
          );
        }

        _buildPaymentMap(paymentController.payments);

        if (reservasiController.reservasiList.isEmpty) {
          return _buildEmptyState(
            Icons.receipt_long_outlined,
            'Tidak ada reservasi',
            'Belum ada reservasi masuk',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reservasiController.reservasiList.length,
          itemBuilder: (context, index) {
            final reservasi = reservasiController.reservasiList[index];
            final payment = _paymentMap[reservasi.reservasiId];
            return _buildReservasiCard(reservasi, payment);
          },
        );
      },
    );
  }

  Widget _buildReservasiCard(ReservasiModel reservasi, PaymentModel? payment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getStatusColor(reservasi.status).withOpacity(0.1),
                  Colors.white,
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF667eea).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.confirmation_number,
                        color: Color(0xFF667eea),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reservasi',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        Text(
                          '#${_truncateId(reservasi.reservasiId)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                _buildStatusBadge(reservasi.status),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow(
                  Icons.person_outline,
                  'User ID',
                  _truncateId(reservasi.userId),
                ),
                _buildDetailRow(
                  Icons.gamepad_outlined,
                  'PS ID',
                  _truncateId(reservasi.psId),
                ),
                _buildDetailRow(
                  Icons.shopping_cart_outlined,
                  'Jumlah',
                  '${reservasi.jumlahUnit} unit × ${reservasi.jumlahHari} hari',
                ),
                _buildDetailRow(
                  Icons.date_range_outlined,
                  'Tanggal',
                  '${DateFormat('dd/MM/yy').format(reservasi.tglMulai)} - ${DateFormat('dd/MM/yy').format(reservasi.tglSelesai)}',
                ),
                _buildDetailRow(
                  Icons.location_on_outlined,
                  'Alamat',
                  reservasi.alamat,
                ),
                _buildDetailRow(Icons.phone_outlined, 'No. WA', reservasi.noWA),

                const SizedBox(height: 12),

                // KTP Button
                if (reservasi.ktpUrl.isNotEmpty)
                  _buildImageButton(
                    'Lihat Foto KTP',
                    Icons.badge,
                    reservasi.ktpUrl,
                  ),

                const SizedBox(height: 12),

                // Payment Section
                _buildPaymentSection(payment),

                const SizedBox(height: 16),

                // Total
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(color: Colors.white),
                      ),
                      Text(
                        'Rp ${_formatCurrency(reservasi.totalHarga)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Actions
                _buildReservasiActions(reservasi),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(PaymentModel? payment) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: Colors.grey[600], size: 18),
              const SizedBox(width: 8),
              const Text(
                'Pembayaran',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (payment != null) ...[
            Text(
              'Metode: ${payment.metodePembayaran}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 8),
            if (payment.buktiPembayaran.isNotEmpty)
              _buildImageButton(
                'Lihat Bukti Bayar',
                Icons.receipt,
                payment.buktiPembayaran,
              ),
            if (payment.status == PaymentStatus.paid)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmPayment(payment.paymentId),
                    icon: const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Konfirmasi Pembayaran',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
          ] else
            Text(
              'Belum ada pembayaran',
              style: TextStyle(
                color: Colors.grey[400],
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReservasiActions(ReservasiModel reservasi) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (reservasi.status == ReservasiStatus.belumBayar)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.hourglass_empty,
                  color: Colors.orange[700],
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Menunggu pembayaran',
                  style: TextStyle(color: Colors.orange[700], fontSize: 12),
                ),
              ],
            ),
          ),
        if (reservasi.status == ReservasiStatus.pending) ...[
          _buildActionButton(
            'Approve',
            Icons.check,
            Colors.green,
            () => _updateReservasiStatus(reservasi.reservasiId, 'approve'),
          ),
          _buildActionButton(
            'Reject',
            Icons.close,
            Colors.red,
            () => _updateReservasiStatus(reservasi.reservasiId, 'reject'),
          ),
        ],
        if (reservasi.status == ReservasiStatus.approved)
          _buildActionButton(
            'Start',
            Icons.play_arrow,
            Colors.blue,
            () => _updateReservasiStatus(reservasi.reservasiId, 'start'),
          ),
        if (reservasi.status == ReservasiStatus.active)
          _buildActionButton(
            'Finish',
            Icons.done_all,
            Colors.purple,
            () => _updateReservasiStatus(reservasi.reservasiId, 'finish'),
          ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    );
  }

  // ==================== Users Tab ====================
  Widget _buildUsersTab() {
    if (_loadingUsers) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF667eea)),
      );
    }

    if (_users.isEmpty) {
      return _buildEmptyState(
        Icons.people_outline,
        'Tidak ada user',
        'Belum ada user terdaftar',
        onAction: _loadUsers,
        actionLabel: 'Refresh',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      color: const Color(0xFF667eea),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    final isAdmin = user.role == 'admin';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isAdmin
                  ? [Colors.orange, Colors.deepOrange]
                  : [const Color(0xFF667eea), const Color(0xFF764ba2)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              user.email,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isAdmin
                        ? Colors.orange.withOpacity(0.1)
                        : const Color(0xFF667eea).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAdmin ? Icons.admin_panel_settings : Icons.person,
                        size: 12,
                        color: isAdmin
                            ? Colors.orange
                            : const Color(0xFF667eea),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user.role.toUpperCase(),
                        style: TextStyle(
                          color: isAdmin
                              ? Colors.orange
                              : const Color(0xFF667eea),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd MMM yyyy').format(user.createdAt),
                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Helper Widgets ====================
  Widget _buildEmptyState(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onAction,
    String? actionLabel,
  }) {
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
            child: Icon(icon, size: 56, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.grey[500])),
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                actionLabel,
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.gamepad, color: Colors.grey),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[400]),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageButton(String label, IconData icon, String url) {
    return OutlinedButton.icon(
      onPressed: () => _showImageDialog(label, url),
      icon: Icon(icon, size: 16, color: const Color(0xFF667eea)),
      label: Text(label, style: const TextStyle(color: Color(0xFF667eea))),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFF667eea)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    final displayText = _getStatusText(status);
    final icon = _getStatusIcon(status);

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
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            displayText,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
    );
  }

  // ==================== Helper Methods ====================
  Color _getStatusColor(String status) {
    switch (status) {
      case 'belum_bayar':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'active':
        return Colors.blue;
      case 'finished':
      case 'completed':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'belum_bayar':
        return 'BELUM BAYAR';
      case 'pending':
        return 'MENUNGGU';
      case 'approved':
        return 'DISETUJUI';
      case 'rejected':
        return 'DITOLAK';
      case 'active':
        return 'AKTIF';
      case 'finished':
      case 'completed':
        return 'SELESAI';
      default:
        return status.toUpperCase();
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'belum_bayar':
        return Icons.pending_actions;
      case 'pending':
        return Icons.hourglass_empty;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'active':
        return Icons.play_circle;
      case 'finished':
      case 'completed':
        return Icons.verified;
      default:
        return Icons.info;
    }
  }

  String _truncateId(String id) => id.length > 8 ? id.substring(0, 8) : id;

  String _formatCurrency(int amount) =>
      NumberFormat('#,###', 'id_ID').format(amount);

  // ==================== Actions ====================
  void _refreshAll() {
    context.read<PSItemController>().loadAllPSItems();
    context.read<ReservasiController>().loadAllReservasi();
    context.read<PaymentController>().loadAllPayments();
    _loadUsers();
  }

  void _showImageDialog(String title, String url) {
    final isBase64 = url.startsWith('data:image');
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxHeight: 400),
              child: isBase64
                  ? Image.memory(
                      base64Decode(url.split(',').last),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _buildImageError(),
                    )
                  : Image.network(
                      url,
                      fit: BoxFit.contain,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : const Center(child: CircularProgressIndicator()),
                      errorBuilder: (_, __, ___) => _buildImageError(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageError() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 50, color: Colors.grey),
          SizedBox(height: 8),
          Text('Gagal memuat gambar'),
        ],
      ),
    );
  }

  Future<void> _updateReservasiStatus(String reservasiId, String action) async {
    final controller = context.read<ReservasiController>();
    bool success = false;

    switch (action) {
      case 'approve':
        success = await controller.approveReservasi(reservasiId);
        break;
      case 'reject':
        success = await controller.rejectReservasi(reservasiId);
        break;
      case 'start':
        success = await controller.startReservasi(reservasiId);
        break;
      case 'finish':
        success = await controller.finishReservasi(reservasiId);
        break;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Status berhasil diupdate'
                : (controller.errorMessage ?? 'Gagal update'),
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _confirmPayment(String paymentId) async {
    final success = await context.read<PaymentController>().confirmPayment(
      paymentId,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Payment dikonfirmasi' : 'Gagal konfirmasi'),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showAddPSDialog() {
    final namaController = TextEditingController();
    final deskripsiController = TextEditingController();
    final hargaController = TextEditingController();
    final stokController = TextEditingController();
    String kategori = 'PS4';
    XFile? selectedImage;
    Uint8List? imageBytes;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add, color: Color(0xFF667eea)),
              ),
              const SizedBox(width: 12),
              const Text('Tambah PS Item'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildImagePicker(imageBytes, () async {
                  final picker = ImagePicker();
                  final image = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 800,
                    maxHeight: 800,
                    imageQuality: 80,
                  );
                  if (image != null) {
                    final bytes = await image.readAsBytes();
                    setDialogState(() {
                      selectedImage = image;
                      imageBytes = bytes;
                    });
                  }
                }),
                const SizedBox(height: 16),
                _buildDialogTextField(
                  namaController,
                  'Nama',
                  Icons.gamepad_outlined,
                ),
                const SizedBox(height: 12),
                _buildKategoriDropdown(
                  kategori,
                  (v) => setDialogState(() => kategori = v ?? 'PS4'),
                ),
                const SizedBox(height: 12),
                _buildDialogTextField(
                  deskripsiController,
                  'Deskripsi',
                  Icons.description_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                _buildDialogTextField(
                  hargaController,
                  'Harga/Hari',
                  Icons.attach_money,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _buildDialogTextField(
                  stokController,
                  'Stok',
                  Icons.inventory_2_outlined,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                String fotoUrl = '';
                if (selectedImage != null && imageBytes != null) {
                  final ext = selectedImage!.name.split('.').last.toLowerCase();
                  final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
                  fotoUrl =
                      'data:$mimeType;base64,${base64Encode(imageBytes!)}';
                }
                final success = await context
                    .read<PSItemController>()
                    .addPSItem(
                      nama: namaController.text,
                      kategori: kategori,
                      deskripsi: deskripsiController.text,
                      hargaPerHari: int.tryParse(hargaController.text) ?? 0,
                      stok: int.tryParse(stokController.text) ?? 0,
                      fotoUrl: fotoUrl,
                    );
                if (context.mounted) {
                  Navigator.pop(context);
                  _showResultSnackBar(
                    success,
                    'PS Item ditambahkan',
                    'Gagal menambahkan',
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Simpan',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPSDialog(dynamic item) {
    final namaController = TextEditingController(text: item.nama);
    final deskripsiController = TextEditingController(text: item.deskripsi);
    final hargaController = TextEditingController(
      text: item.hargaPerHari.toString(),
    );
    final stokController = TextEditingController(text: item.stok.toString());
    String kategori = item.kategori;
    XFile? selectedImage;
    Uint8List? imageBytes;
    String currentFotoUrl = item.fotoUrl;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              const Text('Edit PS Item'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildImagePickerWithPreview(
                  imageBytes,
                  currentFotoUrl,
                  () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 800,
                      maxHeight: 800,
                      imageQuality: 80,
                    );
                    if (image != null) {
                      final bytes = await image.readAsBytes();
                      setDialogState(() {
                        selectedImage = image;
                        imageBytes = bytes;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildDialogTextField(
                  namaController,
                  'Nama',
                  Icons.gamepad_outlined,
                ),
                const SizedBox(height: 12),
                _buildKategoriDropdown(
                  kategori,
                  (v) => setDialogState(() => kategori = v ?? 'PS4'),
                ),
                const SizedBox(height: 12),
                _buildDialogTextField(
                  deskripsiController,
                  'Deskripsi',
                  Icons.description_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                _buildDialogTextField(
                  hargaController,
                  'Harga/Hari',
                  Icons.attach_money,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _buildDialogTextField(
                  stokController,
                  'Stok',
                  Icons.inventory_2_outlined,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                String? fotoUrl;
                if (selectedImage != null && imageBytes != null) {
                  final ext = selectedImage!.name.split('.').last.toLowerCase();
                  final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
                  fotoUrl =
                      'data:$mimeType;base64,${base64Encode(imageBytes!)}';
                }
                final success = await context
                    .read<PSItemController>()
                    .updatePSItem(
                      psId: item.psId,
                      nama: namaController.text,
                      kategori: kategori,
                      deskripsi: deskripsiController.text,
                      hargaPerHari: int.tryParse(hargaController.text) ?? 0,
                      stok: int.tryParse(stokController.text) ?? 0,
                      fotoUrl: fotoUrl,
                    );
                if (context.mounted) {
                  Navigator.pop(context);
                  _showResultSnackBar(
                    success,
                    'PS Item diupdate',
                    'Gagal update',
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Simpan',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(Uint8List? imageBytes, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(
            color: imageBytes != null
                ? const Color(0xFF667eea)
                : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
        ),
        child: imageBytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(imageBytes, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 40,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap untuk upload foto',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildImagePickerWithPreview(
    Uint8List? imageBytes,
    String currentUrl,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF667eea)),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: imageBytes != null
              ? Image.memory(imageBytes, fit: BoxFit.cover)
              : currentUrl.isNotEmpty
              ? (currentUrl.startsWith('data:image')
                    ? Image.memory(
                        base64Decode(currentUrl.split(',').last),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildAddPhotoPlaceholder(),
                      )
                    : Image.network(
                        currentUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildAddPhotoPlaceholder(),
                      ))
              : _buildAddPhotoPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildAddPhotoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey[400]),
        const SizedBox(height: 4),
        Text(
          'Tap untuk upload foto',
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDialogTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF667eea)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
        ),
      ),
    );
  }

  Widget _buildKategoriDropdown(String value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: 'Kategori',
        prefixIcon: const Icon(
          Icons.category_outlined,
          color: Color(0xFF667eea),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: [
        'PS4',
        'PS5',
        'Nintendo',
      ].map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
      onChanged: onChanged,
    );
  }

  void _showResultSnackBar(bool success, String successMsg, String errorMsg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? successMsg : errorMsg),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _confirmDeletePS(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text('Hapus PS Item'),
          ],
        ),
        content: const Text('Yakin ingin menghapus PS Item ini?'),
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
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await context.read<PSItemController>().deletePSItem(id);
      if (mounted)
        _showResultSnackBar(success, 'PS Item dihapus', 'Gagal menghapus');
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text('Logout'),
          ],
        ),
        content: const Text('Yakin ingin keluar?'),
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
      if (mounted)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
    }
  }
}
