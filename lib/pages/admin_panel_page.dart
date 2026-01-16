import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/auth_controller.dart';
import '../controllers/ps_item_controller.dart';
import '../controllers/reservasi_controller.dart';
import '../controllers/payment_controller.dart';
import '../controllers/driver_controller.dart';
import '../models/reservasi_model.dart';
import '../models/payment_model.dart';
import '../models/user_model.dart';
import '../models/driver_model.dart';
import '../services/user_service.dart';
import '../services/ps_item_service.dart';
import '../services/email_notification_service.dart';
import 'login_page.dart';
import 'admin_dashboard_page.dart';
import 'admin_reservasi_detail_page.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage>
    with SingleTickerProviderStateMixin {
  // Konstanta warna tema
  static const Color _primaryColor = Color(0xFF2563EB);
  static const Color _secondaryColor = Color(0xFF7C3AED);
  static const Color _bgColor = Color(0xFFF8FAFC);
  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = Color(0xFF1E293B);
  static const Color _textSecondary = Color(0xFF64748B);

  late TabController _tabController;
  final UserService _userService = UserService();
  List<UserModel> _users = [];
  bool _loadingUsers = false;
  Map<String, PaymentModel> _paymentMap = {};
  String? _selectedStatusFilter; // Filter status reservasi
  String _searchQuery = ''; // Search query untuk ID reservasi
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
    ); // Changed to 5 tabs (added Dashboard)
    _tabController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshAll());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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

  // Helper untuk header icon button
  Widget _buildHeaderIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: _buildHeaderIcon(icon),
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Icon(icon, color: _textSecondary, size: 20),
    );
  }

  // Helper untuk nav item
  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () => setState(() => _tabController.animateTo(index)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? _primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? _primaryColor : _textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? _primaryColor : _textSecondary,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
      backgroundColor: _bgColor,
      body: Column(
        children: [
          // Modern Header dengan Glassmorphism effect
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 16,
              20,
              20,
            ),
            decoration: BoxDecoration(
              color: _cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_primaryColor, _secondaryColor],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.space_dashboard_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'QuadraPlay',
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Admin Panel',
                            style: TextStyle(
                              color: _primaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildHeaderIconButton(
                      icon: Icons.refresh_rounded,
                      onPressed: _refreshAll,
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: _buildHeaderIcon(Icons.more_horiz_rounded),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
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
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.logout_rounded,
                                  color: Colors.red,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Logout',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Body Content
          Expanded(
            child: IndexedStack(
              index: _tabController.index,
              children: [
                AdminDashboardPage(
                  onNavigateToReservasi: (statusFilter) {
                    setState(() {
                      _selectedStatusFilter = statusFilter;
                      _tabController.animateTo(2); // Index 2 = Reservasi tab
                    });
                  },
                ),
                _buildPSItemsTab(),
                _buildReservasiTab(),
                _buildDriversTab(),
                _buildUsersTab(),
              ],
            ),
          ),
        ],
      ),

      // Modern Bottom Navigation Bar
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: _cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
          ],
          borderRadius: BorderRadius.circular(24),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  0,
                  Icons.dashboard_outlined,
                  Icons.dashboard_rounded,
                  'Dashboard',
                ),
                _buildNavItem(
                  1,
                  Icons.sports_esports_outlined,
                  Icons.sports_esports_rounded,
                  'PS Items',
                ),
                _buildNavItem(
                  2,
                  Icons.receipt_long_outlined,
                  Icons.receipt_long_rounded,
                  'Reservasi',
                ),
                _buildNavItem(
                  3,
                  Icons.local_shipping_outlined,
                  Icons.local_shipping_rounded,
                  'Drivers',
                ),
                _buildNavItem(
                  4,
                  Icons.people_outline_rounded,
                  Icons.people_rounded,
                  'Users',
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _tabController.index == 1
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [_primaryColor, _secondaryColor],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: _showAddPSDialog,
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            )
          : _tabController.index == 3
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF34D399)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: _showAddDriverDialog,
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 28,
                ),
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
          return Center(child: CircularProgressIndicator(color: _primaryColor));
        }

        if (controller.psItems.isEmpty) {
          return _buildEmptyState(
            Icons.sports_esports_outlined,
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
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: _bgColor,
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
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: _textPrimary,
            fontSize: 15,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.kategori,
                    style: const TextStyle(
                      color: _primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: item.stok > 0
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Stok: ${item.stok}',
                    style: TextStyle(
                      color: item.stok > 0
                          ? const Color(0xFF10B981)
                          : Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Rp ${_formatCurrency(item.hargaPerHari)}/hari',
              style: const TextStyle(
                color: Color(0xFF10B981),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.more_horiz_rounded,
              size: 18,
              color: _textSecondary,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 8,
          onSelected: (value) {
            if (value == 'edit')
              _showEditPSDialog(item);
            else if (value == 'delete')
              _confirmDeletePS(item.psId);
          },
          itemBuilder: (context) => [
            _buildPopupMenuItem(
              Icons.edit_rounded,
              'Edit',
              'edit',
              _primaryColor,
            ),
            _buildPopupMenuItem(
              Icons.delete_rounded,
              'Hapus',
              'delete',
              Colors.red,
            ),
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
          return Center(child: CircularProgressIndicator(color: _primaryColor));
        }

        _buildPaymentMap(paymentController.payments);

        // Filter reservasi berdasarkan status dan search
        List<ReservasiModel> filteredList = reservasiController.reservasiList;

        // Filter by status
        if (_selectedStatusFilter != null) {
          filteredList = filteredList
              .where((r) => r.status == _selectedStatusFilter)
              .toList();
        }

        // Filter by search query (ID reservasi)
        if (_searchQuery.isNotEmpty) {
          filteredList = filteredList
              .where(
                (r) => r.reservasiId.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList();
        }

        return Column(
          children: [
            // Filter & Search Row
            _buildFilterAndSearchRow(reservasiController.reservasiList),

            // Reservasi List
            Expanded(
              child: filteredList.isEmpty
                  ? _buildEmptyState(
                      Icons.receipt_long_outlined,
                      _searchQuery.isNotEmpty
                          ? 'Tidak ditemukan'
                          : _selectedStatusFilter != null
                          ? 'Tidak ada reservasi dengan status ini'
                          : 'Tidak ada reservasi',
                      _searchQuery.isNotEmpty
                          ? 'ID "$_searchQuery" tidak ditemukan'
                          : _selectedStatusFilter != null
                          ? 'Coba pilih filter lain'
                          : 'Belum ada reservasi masuk',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final reservasi = filteredList[index];
                        final payment = _paymentMap[reservasi.reservasiId];
                        return _buildReservasiCard(reservasi, payment);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  /// Filter dan Search Bar dalam satu Row
  Widget _buildFilterAndSearchRow(List<ReservasiModel> allReservasi) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Filter Dropdown (kiri)
          Expanded(flex: 3, child: _buildStatusFilterDropdown(allReservasi)),
          const SizedBox(width: 12),
          // Search Field (kanan)
          Expanded(flex: 2, child: _buildSearchField()),
        ],
      ),
    );
  }

  /// Search field untuk mencari ID reservasi
  Widget _buildSearchField() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Cari ID...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 18),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[400], size: 18),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilterDropdown(List<ReservasiModel> allReservasi) {
    // Daftar semua status
    final statusList = [
      {'value': null, 'label': 'Semua Status', 'icon': Icons.list_alt},
      {
        'value': ReservasiStatus.belumBayar,
        'label': 'Belum Bayar',
        'icon': Icons.payment,
      },
      {
        'value': ReservasiStatus.pending,
        'label': 'Menunggu Konfirmasi',
        'icon': Icons.pending_actions,
      },
      {
        'value': ReservasiStatus.paid,
        'label': 'Sudah Bayar',
        'icon': Icons.check_circle_outline,
      },
      {
        'value': ReservasiStatus.approved,
        'label': 'Disetujui',
        'icon': Icons.thumb_up_outlined,
      },
      {
        'value': ReservasiStatus.shipping,
        'label': 'Dikirim',
        'icon': Icons.local_shipping_outlined,
      },
      {
        'value': ReservasiStatus.installed,
        'label': 'Terpasang',
        'icon': Icons.build_outlined,
      },
      {
        'value': ReservasiStatus.active,
        'label': 'Aktif',
        'icon': Icons.play_circle_outline,
      },
      {
        'value': ReservasiStatus.finished,
        'label': 'Selesai',
        'icon': Icons.check_circle,
      },
      {
        'value': ReservasiStatus.rejected,
        'label': 'Ditolak',
        'icon': Icons.cancel_outlined,
      },
      {
        'value': ReservasiStatus.cancelled,
        'label': 'Dibatalkan',
        'icon': Icons.block,
      },
    ];

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedStatusFilter,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: _primaryColor),
          hint: Row(
            children: [
              Icon(Icons.filter_list_rounded, color: _textSecondary, size: 20),
              const SizedBox(width: 10),
              Text('Filter Status', style: TextStyle(color: _textSecondary)),
            ],
          ),
          items: statusList.map((status) {
            final value = status['value'] as String?;
            final label = status['label'] as String;
            final icon = status['icon'] as IconData;

            // Hitung jumlah reservasi per status
            final count = value == null
                ? allReservasi.length
                : allReservasi.where((r) => r.status == value).length;

            return DropdownMenuItem<String?>(
              value: value,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _getStatusColorByValue(value).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: _getStatusColorByValue(value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(label, style: const TextStyle(fontSize: 14)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColorByValue(value).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColorByValue(value),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedStatusFilter = value;
            });
          },
          selectedItemBuilder: (context) {
            return statusList.map((status) {
              final value = status['value'] as String?;
              final label = status['label'] as String;
              final icon = status['icon'] as IconData;

              return Row(
                children: [
                  Icon(icon, size: 20, color: _getStatusColorByValue(value)),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      color: _getStatusColorByValue(value),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Color _getStatusColorByValue(String? status) {
    if (status == null) return Colors.grey;
    switch (status) {
      case ReservasiStatus.belumBayar:
        return Colors.orange;
      case ReservasiStatus.pending:
        return Colors.amber;
      case ReservasiStatus.paid:
        return Colors.blue;
      case ReservasiStatus.approved:
        return Colors.teal;
      case ReservasiStatus.shipping:
        return Colors.indigo;
      case ReservasiStatus.installed:
        return Colors.purple;
      case ReservasiStatus.active:
        return Colors.green;
      case ReservasiStatus.finished:
      case ReservasiStatus.completed:
        return Colors.grey;
      case ReservasiStatus.rejected:
      case ReservasiStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Card ringkas untuk reservasi - tap untuk detail
  Widget _buildReservasiCard(ReservasiModel reservasi, PaymentModel? payment) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminReservasiDetailPage(
              reservasi: reservasi,
              payment: payment,
            ),
          ),
        ).then((_) => _refreshAll());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon PS
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _getStatusColor(reservasi.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.sports_esports_rounded,
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
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _primaryColor,
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
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Periode & Jumlah
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: _textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${DateFormat('dd MMM').format(reservasi.tglMulai)} - ${DateFormat('dd MMM yyyy').format(reservasi.tglSelesai)}',
                          style: TextStyle(fontSize: 12, color: _textSecondary),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 14,
                          color: _textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${reservasi.jumlahUnit} unit',
                          style: TextStyle(fontSize: 12, color: _textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Arrow
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: _textSecondary,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Badge status compact untuk card ringkas
  Widget _buildCompactStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _getCompactStatusLabel(status),
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Label status singkat
  String _getCompactStatusLabel(String status) {
    switch (status) {
      case ReservasiStatus.belumBayar:
        return 'BELUM BAYAR';
      case ReservasiStatus.paid:
        return 'PAID';
      case ReservasiStatus.approved:
        return 'APPROVED';
      case ReservasiStatus.shipping:
        return 'SHIPPING';
      case ReservasiStatus.installed:
        return 'INSTALLED';
      case ReservasiStatus.active:
        return 'ACTIVE';
      case ReservasiStatus.expired:
        return 'EXPIRED';
      case ReservasiStatus.schedulingPickup:
        return 'SCHEDULED';
      case ReservasiStatus.pickingUp:
        return 'PICKING UP';
      case ReservasiStatus.pickedUp:
        return 'PICKED UP';
      case ReservasiStatus.completed:
        return 'COMPLETED';
      case ReservasiStatus.rejected:
        return 'REJECTED';
      default:
        return status.toUpperCase();
    }
  }

  /// Helper untuk mendapatkan nama PS dari psId
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

  Widget _buildPaymentSection(
    PaymentModel? payment,
    ReservasiModel? reservasi,
  ) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              // Tombol refresh status dari Midtrans
              if (payment != null && payment.status == PaymentStatus.pending)
                InkWell(
                  onTap: () => _refreshPaymentStatus(payment.orderId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh, color: Colors.blue[700], size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Cek Status',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
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
            Row(
              children: [
                if (payment.buktiPembayaran != null &&
                    payment.buktiPembayaran!.isNotEmpty) ...[
                  _buildImageButton(
                    'Lihat Bukti Bayar',
                    Icons.receipt,
                    payment.buktiPembayaran!,
                  ),
                  const SizedBox(width: 8),
                ],
                // Status pembayaran badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: payment.status == PaymentStatus.settlement
                        ? Colors.green.withOpacity(0.1)
                        : payment.status == PaymentStatus.pending
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    payment.status == PaymentStatus.settlement
                        ? '✓ Lunas'
                        : payment.status == PaymentStatus.pending
                        ? 'Menunggu Bayar'
                        : 'Gagal',
                    style: TextStyle(
                      color: payment.status == PaymentStatus.settlement
                          ? Colors.green[700]
                          : payment.status == PaymentStatus.pending
                          ? Colors.orange[700]
                          : Colors.red[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
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
        // Status: paid - Approve or Reject (setelah pembayaran berhasil)
        if (reservasi.status == ReservasiStatus.paid) ...[
          _buildActionButton(
            'Approve',
            Icons.check,
            Colors.green,
            () => _updateReservasiStatus(
              reservasi.reservasiId,
              'approve',
              reservasi: reservasi,
            ),
          ),
          _buildActionButton(
            'Reject',
            Icons.close,
            Colors.red,
            () => _updateReservasiStatus(reservasi.reservasiId, 'reject'),
          ),
        ],
        // Status: approved - Assign driver and ship
        if (reservasi.status == ReservasiStatus.approved)
          _buildActionButton(
            'Kirim Unit',
            Icons.local_shipping,
            Colors.blue,
            () => _showAssignDriverDialog(reservasi),
          ),
        // Status: shipping - Menunggu user upload bukti terpasang
        if (reservasi.status == ReservasiStatus.shipping) ...[
          _buildDriverInfoSection(reservasi),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.hourglass_empty, color: Colors.blue[700], size: 16),
                const SizedBox(width: 6),
                Text(
                  'Menunggu user upload bukti',
                  style: TextStyle(color: Colors.blue[700], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
        // Status: installed - Start timer (hanya jika user sudah upload bukti terpasang)
        if (reservasi.status == ReservasiStatus.installed) ...[
          // Tampilkan bukti terpasang dari user
          if (reservasi.buktiTerpasang != null &&
              reservasi.buktiTerpasang!.isNotEmpty) ...[
            _buildImageButton(
              'Bukti Terpasang (User)',
              Icons.verified_user,
              reservasi.buktiTerpasang!,
            ),
            const SizedBox(width: 8),
            _buildActionButton(
              'Start Sewa',
              Icons.play_arrow,
              Colors.indigo,
              () => _startRentalWithTimer(reservasi.reservasiId),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning, color: Colors.orange[700], size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'User belum upload bukti terpasang',
                    style: TextStyle(color: Colors.orange[700], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
        // Status: active - Show timer and finish button
        if (reservasi.status == ReservasiStatus.active) ...[
          _buildTimerSection(reservasi),
          const SizedBox(width: 8),
          _buildActionButton(
            'Waktu Habis',
            Icons.timer_off,
            Colors.orange,
            () => _updateReservasiStatus(reservasi.reservasiId, 'expire'),
          ),
        ],
        // Status: expired - Jadwalkan penjemputan
        if (reservasi.status == ReservasiStatus.expired) ...[
          _buildActionButton(
            'Jadwalkan Penjemputan',
            Icons.schedule,
            Colors.deepOrange,
            () => _showSchedulePickupDialog(reservasi),
          ),
        ],
        // Status: scheduling_pickup - Menunggu driver berangkat
        if (reservasi.status == ReservasiStatus.schedulingPickup) ...[
          _buildPickupScheduleInfo(reservasi),
          const SizedBox(width: 8),
          _buildActionButton(
            'Mulai Jemput',
            Icons.directions_car,
            Colors.blue,
            () => _startPickingUp(reservasi.reservasiId),
          ),
        ],
        // Status: picking_up - Menunggu user upload bukti jemput
        if (reservasi.status == ReservasiStatus.pickingUp) ...[
          _buildPickupDriverInfo(reservasi),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hourglass_empty, color: Colors.blue, size: 16),
                const SizedBox(width: 6),
                const Text(
                  'Menunggu user upload bukti jemput',
                  style: TextStyle(color: Colors.blue, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
        // Status: picked_up - Konfirmasi selesai
        if (reservasi.status == ReservasiStatus.pickedUp) ...[
          if (reservasi.fotoBuktiJemput != null &&
              reservasi.fotoBuktiJemput!.isNotEmpty) ...[
            _buildImageButton(
              'Bukti Jemput',
              Icons.photo_camera,
              reservasi.fotoBuktiJemput!,
            ),
            const SizedBox(width: 8),
          ],
          _buildActionButton(
            'Konfirmasi Selesai',
            Icons.check_circle,
            Colors.green,
            () => _confirmCompleted(reservasi.reservasiId),
          ),
        ],
      ],
    );
  }

  Widget _buildDriverInfoSection(ReservasiModel reservasi) {
    if (reservasi.driverName == null || reservasi.driverName!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (reservasi.driverPhoto != null &&
              reservasi.driverPhoto!.isNotEmpty)
            CircleAvatar(
              radius: 20,
              backgroundImage: reservasi.driverPhoto!.startsWith('data:image')
                  ? MemoryImage(
                      base64Decode(reservasi.driverPhoto!.split(',').last),
                    )
                  : NetworkImage(reservasi.driverPhoto!) as ImageProvider,
            )
          else
            const CircleAvatar(radius: 20, child: Icon(Icons.person)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reservasi.driverName ?? 'Driver',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              GestureDetector(
                onTap: () => _openWhatsApp(reservasi.driverPhone ?? ''),
                child: Row(
                  children: [
                    const Icon(Icons.phone, size: 12, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      reservasi.driverPhone ?? '',
                      style: const TextStyle(color: Colors.green, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimerSection(ReservasiModel reservasi) {
    final sisaWaktu = reservasi.getSisaWaktuFormatted();
    final isExpired = reservasi.isSewaExpired;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isExpired
              ? [Colors.red.shade400, Colors.red.shade600]
              : [Colors.indigo.shade400, Colors.purple.shade400],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isExpired ? Icons.timer_off : Icons.timer,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sisa Waktu',
                style: TextStyle(color: Colors.white70, fontSize: 10),
              ),
              Text(
                sisaWaktu,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
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
        child: CircularProgressIndicator(color: _primaryColor),
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
      color: _primaryColor,
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
                        : _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAdmin ? Icons.admin_panel_settings : Icons.person,
                        size: 12,
                        color: isAdmin ? Colors.orange : _primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user.role.toUpperCase(),
                        style: TextStyle(
                          color: isAdmin ? Colors.orange : _primaryColor,
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
        trailing: !isAdmin
            ? IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                onPressed: () => _showDeleteUserDialog(user),
              )
            : null,
      ),
    );
  }

  void _showDeleteUserDialog(UserModel user) {
    showDialog(
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
              child: const Icon(Icons.warning_amber_rounded, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text('Hapus User'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah Anda yakin ingin menghapus user ini?',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_primaryColor, _secondaryColor],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          user.email,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tindakan ini tidak dapat dibatalkan!',
                      style: TextStyle(color: Colors.red[700], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteUser(user);
            },
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
  }

  Future<void> _deleteUser(UserModel user) async {
    try {
      // Check if user has valid userId
      if (user.userId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('User ID tidak valid'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: _primaryColor),
        ),
      );

      final result = await _userService.deleteUser(user.userId);

      // Close loading
      if (mounted) Navigator.pop(context);

      if (result['success']) {
        // Remove from local list
        setState(() {
          _users.removeWhere((u) => u.userId == user.userId);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('User ${user.name} berhasil dihapus')),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(result['message'] ?? 'Gagal menghapus user'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading if still showing
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
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
                backgroundColor: _primaryColor,
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

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 16,
              color: onTap != null ? Colors.blue : Colors.grey[400],
            ),
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
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: onTap != null ? Colors.blue : null,
                  decoration: onTap != null ? TextDecoration.underline : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressRow(ReservasiModel reservasi) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => _openMaps(
          reservasi.alamat,
          lat: reservasi.latitude,
          lng: reservasi.longitude,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 16,
              color: Colors.blue,
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              child: Text(
                'Alamat',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      reservasi.alamat,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map, size: 10, color: Colors.blue),
                        SizedBox(width: 2),
                        Text(
                          'Maps',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageButton(String label, IconData icon, String url) {
    return OutlinedButton.icon(
      onPressed: () => _showImageDialog(label, url),
      icon: Icon(icon, size: 16, color: _primaryColor),
      label: Text(label, style: const TextStyle(color: _primaryColor)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: _primaryColor),
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
      case 'paid':
        return Colors.amber;
      case 'approved':
        return Colors.green;
      case 'shipping':
        return Colors.blue;
      case 'installed':
        return Colors.teal;
      case 'active':
        return Colors.indigo;
      case 'rejected':
        return Colors.red;
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
      case 'paid':
        return 'SUDAH BAYAR';
      case 'approved':
        return 'DISETUJUI';
      case 'shipping':
        return 'DIKIRIM';
      case 'installed':
        return 'TERPASANG';
      case 'active':
        return 'AKTIF';
      case 'rejected':
        return 'DITOLAK';
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
      case 'paid':
        return Icons.payment;
      case 'approved':
        return Icons.check_circle;
      case 'shipping':
        return Icons.local_shipping;
      case 'installed':
        return Icons.build;
      case 'active':
        return Icons.play_circle;
      case 'rejected':
        return Icons.cancel;
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
    context.read<ReservasiController>().loadActiveRentalStats();
    context.read<PaymentController>().loadAllPayments();
    context.read<DriverController>().loadAllDrivers();
    _loadUsers();
  }

  /// Open WhatsApp
  Future<void> _openWhatsApp(String phone) async {
    if (phone.isEmpty) return;
    String formattedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '62${formattedPhone.substring(1)}';
    }
    final url = Uri.parse('https://wa.me/$formattedPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  /// Open Maps with address
  Future<void> _openMaps(String address, {double? lat, double? lng}) async {
    Uri url;
    if (lat != null && lng != null) {
      url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );
    } else {
      final encodedAddress = Uri.encodeComponent(address);
      url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$encodedAddress',
      );
    }
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
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
                  colors: [_primaryColor, _secondaryColor],
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

  /// Refresh status pembayaran dari Midtrans
  Future<void> _refreshPaymentStatus(String orderId) async {
    if (orderId.isEmpty) return;

    final paymentController = context.read<PaymentController>();
    final reservasiController = context.read<ReservasiController>();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Mengecek status pembayaran...'),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    final success = await paymentController.refreshPaymentStatus(orderId);

    if (success) {
      // Refresh reservasi list juga
      await reservasiController.loadAllReservasi();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Status berhasil diperbarui ✓'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(paymentController.errorMessage ?? 'Gagal cek status'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _updateReservasiStatus(
    String reservasiId,
    String action, {
    ReservasiModel? reservasi,
  }) async {
    final controller = context.read<ReservasiController>();
    bool success = false;

    switch (action) {
      case 'approve':
        success = await controller.approveReservasi(reservasiId);
        // Kirim email saat approve
        if (success && reservasi != null) {
          final emailSent = await _sendConfirmationEmail(null, reservasi);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  emailSent
                      ? 'Reservasi diapprove & email terkirim ✓'
                      : 'Reservasi diapprove (email gagal)',
                ),
                backgroundColor: emailSent ? Colors.green : Colors.orange,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
          return; // Skip snackbar di bawah
        }
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
      case 'expire':
        success = await controller.expireReservasi(reservasiId);
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

  /// Kirim email konfirmasi ke user
  Future<bool> _sendConfirmationEmail(
    PaymentModel? payment,
    ReservasiModel? reservasi,
  ) async {
    if (reservasi == null) {
      debugPrint('❌ Email: reservasi null');
      return false;
    }

    try {
      debugPrint('📧 Memulai proses kirim email...');

      // Get user data untuk email
      final userService = UserService();
      final userResult = await userService.getUserById(reservasi.userId);

      if (!userResult['success']) {
        debugPrint('❌ Email: Gagal get user data - ${userResult['message']}');
        return false;
      }

      final user = userResult['user'] as UserModel;
      debugPrint('✓ User ditemukan: ${user.email}');

      // Get PS item name
      final psItemService = PSItemService();
      final psResult = await psItemService.getPSItemById(reservasi.psId);
      String itemName = 'PlayStation';
      if (psResult['success']) {
        itemName = psResult['item'].nama ?? 'PlayStation';
      }
      debugPrint('✓ Item: $itemName');

      // Format tanggal
      final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');
      final tglMulai = dateFormat.format(reservasi.tglMulai);
      final tglSelesai = dateFormat.format(reservasi.tglSelesai);

      debugPrint('📧 Mengirim email ke: ${user.email}');

      // Kirim email
      final emailResult =
          await EmailNotificationService.sendReservationConfirmation(
            email: user.email,
            reservasiId: reservasi.reservasiId.substring(0, 8),
            customerName: user.name,
            itemName: itemName,
            jumlahUnit: reservasi.jumlahUnit,
            jumlahHari: reservasi.jumlahHari,
            tglMulai: tglMulai,
            tglSelesai: tglSelesai,
            totalHarga: reservasi.totalHarga,
            alamat: reservasi.alamat,
            noWA: reservasi.noWA,
          );

      if (emailResult['success'] == true) {
        debugPrint('✅ Email berhasil dikirim ke ${user.email}');
        return true;
      } else {
        debugPrint('❌ Gagal kirim email: ${emailResult['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending email: $e');
      return false;
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
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add, color: _primaryColor),
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
                backgroundColor: _primaryColor,
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
            color: imageBytes != null ? _primaryColor : Colors.grey[300]!,
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
          border: Border.all(color: _primaryColor),
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

  // ==================== Driver Management ====================
  void _showAssignDriverDialog(ReservasiModel reservasi) {
    showDialog(
      context: context,
      builder: (context) => Consumer<DriverController>(
        builder: (context, driverController, child) {
          if (driverController.isLoading) {
            return const AlertDialog(
              content: Center(child: CircularProgressIndicator()),
            );
          }

          final availableDrivers = driverController.driversList
              .where((d) => d.status == DriverStatus.available)
              .toList();

          return AlertDialog(
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
                  child: const Icon(Icons.local_shipping, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                const Text('Pilih Kurir'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: availableDrivers.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Tidak ada kurir tersedia',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: availableDrivers.length,
                      itemBuilder: (context, index) {
                        final driver = availableDrivers[index];
                        return ListTile(
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
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () async {
                            Navigator.pop(context);
                            final success = await context
                                .read<ReservasiController>()
                                .assignDriver(reservasi.reservasiId, driver);
                            // Update driver status to busy dan refresh list
                            if (success) {
                              await context
                                  .read<DriverController>()
                                  .updateDriverStatus(
                                    driver.driverId,
                                    DriverStatus.busy,
                                  );
                              // Refresh driver list agar status terupdate
                              await context
                                  .read<DriverController>()
                                  .loadAllDrivers();
                            }
                            _showResultSnackBar(
                              success,
                              'Kurir ${driver.namaDriver} ditugaskan',
                              'Gagal menugaskan kurir',
                            );
                          },
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _startRentalWithTimer(String reservasiId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.play_arrow, color: Colors.indigo),
            ),
            const SizedBox(width: 12),
            const Text('Mulai Sewa?'),
          ],
        ),
        content: const Text(
          'Timer akan mulai berjalan sekarang. Pastikan PS sudah terpasang dengan benar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Mulai', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await context
          .read<ReservasiController>()
          .startRentalWithTimer(reservasiId);
      _showResultSnackBar(
        success,
        'Sewa dimulai! Timer berjalan.',
        'Gagal memulai sewa',
      );
    }
  }

  // ==================== PICKUP METHODS ====================

  /// Widget untuk menampilkan info jadwal pickup
  Widget _buildPickupScheduleInfo(ReservasiModel reservasi) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepOrange.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule, color: Colors.deepOrange, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Jadwal Jemput',
                style: TextStyle(color: Colors.deepOrange, fontSize: 10),
              ),
              Text(
                reservasi.pickupTime ?? '-',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Widget untuk menampilkan info driver pickup
  Widget _buildPickupDriverInfo(ReservasiModel reservasi) {
    return FutureBuilder<DriverModel?>(
      future: _getDriverById(reservasi.pickupDriverId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }
        final driver = snapshot.data!;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (driver.fotoProfil.isNotEmpty)
                CircleAvatar(
                  radius: 18,
                  backgroundImage: driver.fotoProfil.startsWith('data:image')
                      ? MemoryImage(
                          base64Decode(driver.fotoProfil.split(',').last),
                        )
                      : NetworkImage(driver.fotoProfil) as ImageProvider,
                )
              else
                const CircleAvatar(
                  radius: 18,
                  child: Icon(Icons.person, size: 18),
                ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Driver Penjemput',
                    style: TextStyle(color: Colors.blue, fontSize: 10),
                  ),
                  Text(
                    driver.namaDriver,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _openWhatsApp(driver.noWa),
                    child: Text(
                      driver.noWa,
                      style: const TextStyle(color: Colors.green, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Get driver by ID
  Future<DriverModel?> _getDriverById(String? driverId) async {
    if (driverId == null || driverId.isEmpty) return null;
    final driverController = context.read<DriverController>();
    final drivers = driverController.driversList;
    try {
      return drivers.firstWhere((d) => d.driverId == driverId);
    } catch (e) {
      return null;
    }
  }

  /// Dialog untuk jadwalkan penjemputan
  void _showSchedulePickupDialog(ReservasiModel reservasi) {
    TimeOfDay selectedTime = TimeOfDay.now();
    DriverModel? selectedDriver;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final driverController = context.watch<DriverController>();
          final availableDrivers = driverController.driversList
              .where((d) => d.status == DriverStatus.available)
              .toList();

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.schedule, color: Colors.deepOrange),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Jadwalkan Penjemputan',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time Picker
                  const Text(
                    'Waktu Penjemputan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setDialogState(() => selectedTime = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.deepOrange,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            'Tap untuk ubah',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Driver Dropdown
                  const Text(
                    'Pilih Driver',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  if (availableDrivers.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tidak ada driver tersedia',
                              style: TextStyle(color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<DriverModel>(
                          value: selectedDriver,
                          isExpanded: true,
                          hint: const Text('Pilih driver...'),
                          items: availableDrivers.map((driver) {
                            return DropdownMenuItem<DriverModel>(
                              value: driver,
                              child: Row(
                                children: [
                                  if (driver.fotoProfil.isNotEmpty)
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundImage:
                                          driver.fotoProfil.startsWith(
                                            'data:image',
                                          )
                                          ? MemoryImage(
                                              base64Decode(
                                                driver.fotoProfil
                                                    .split(',')
                                                    .last,
                                              ),
                                            )
                                          : NetworkImage(driver.fotoProfil)
                                                as ImageProvider,
                                    )
                                  else
                                    const CircleAvatar(
                                      radius: 16,
                                      child: Icon(Icons.person, size: 16),
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          driver.namaDriver,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          driver.noWa,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() => selectedDriver = value);
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: availableDrivers.isEmpty || selectedDriver == null
                    ? null
                    : () {
                        Navigator.pop(context);
                        _schedulePickup(
                          reservasi.reservasiId,
                          '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                          selectedDriver!,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Jadwalkan',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Jadwalkan penjemputan
  Future<void> _schedulePickup(
    String reservasiId,
    String pickupTime,
    DriverModel driver,
  ) async {
    final controller = context.read<ReservasiController>();
    final driverController = context.read<DriverController>();

    final success = await controller.schedulePickup(
      reservasiId: reservasiId,
      pickupTime: pickupTime,
      driver: driver,
    );

    // Refresh driver list agar status driver terupdate
    if (success) {
      await driverController.loadAllDrivers();
    }

    _showResultSnackBar(
      success,
      'Penjemputan dijadwalkan jam $pickupTime',
      controller.errorMessage ?? 'Gagal menjadwalkan penjemputan',
    );
  }

  /// Mulai penjemputan (driver berangkat)
  Future<void> _startPickingUp(String reservasiId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.directions_car, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            const Text('Mulai Jemput?'),
          ],
        ),
        content: const Text(
          'Driver akan berangkat menjemput PS. User akan mendapat notifikasi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Mulai Jemput',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final controller = context.read<ReservasiController>();
      final success = await controller.startPickingUp(reservasiId);
      _showResultSnackBar(
        success,
        'Driver sedang menuju lokasi penjemputan',
        controller.errorMessage ?? 'Gagal memulai penjemputan',
      );
    }
  }

  /// Konfirmasi selesai (PS sudah di gudang)
  Future<void> _confirmCompleted(String reservasiId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check_circle, color: Colors.green),
            ),
            const SizedBox(width: 12),
            const Text('Konfirmasi Selesai?'),
          ],
        ),
        content: const Text(
          'Pastikan PS sudah diterima dan dalam kondisi baik. Stok PS akan dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Konfirmasi',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final controller = context.read<ReservasiController>();
      final driverController = context.read<DriverController>();

      final success = await controller.confirmCompleted(reservasiId);

      // Refresh driver list agar status driver terupdate (kembali available)
      if (success) {
        await driverController.loadAllDrivers();
      }

      _showResultSnackBar(
        success,
        'Reservasi selesai! Stok PS telah dikembalikan.',
        controller.errorMessage ?? 'Gagal konfirmasi selesai',
      );
    }
  }

  void _showAddDriverDialog() {
    final namaController = TextEditingController();
    final noWaController = TextEditingController();
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
                  color: const Color(0xFF11998e).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_add, color: Color(0xFF11998e)),
              ),
              const SizedBox(width: 12),
              const Text('Tambah Kurir'),
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
                    maxWidth: 400,
                    maxHeight: 400,
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
                  'Nama Kurir',
                  Icons.person,
                ),
                const SizedBox(height: 12),
                _buildDialogTextField(
                  noWaController,
                  'No. WhatsApp',
                  Icons.phone,
                  keyboardType: TextInputType.phone,
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
                if (namaController.text.isEmpty ||
                    noWaController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nama dan No. WA wajib diisi'),
                    ),
                  );
                  return;
                }
                final success = await context
                    .read<DriverController>()
                    .addDriver(
                      namaDriver: namaController.text,
                      noWa: noWaController.text,
                      fotoFile: selectedImage,
                    );
                if (context.mounted) {
                  Navigator.pop(context);
                  _showResultSnackBar(
                    success,
                    'Kurir ditambahkan',
                    'Gagal menambahkan kurir',
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF11998e),
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

  // ==================== Drivers Tab ====================
  Widget _buildDriversTab() {
    return Consumer<DriverController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF667eea)),
          );
        }

        if (controller.driversList.isEmpty) {
          return _buildEmptyState(
            Icons.local_shipping_outlined,
            'Tidak ada kurir',
            'Tambahkan kurir untuk pengiriman',
            onAction: _showAddDriverDialog,
            actionLabel: 'Tambah Kurir',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.driversList.length,
          itemBuilder: (context, index) {
            final driver = controller.driversList[index];
            return _buildDriverCard(driver);
          },
        );
      },
    );
  }

  Widget _buildDriverCard(DriverModel driver) {
    final isAvailable = driver.status == DriverStatus.available;
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
        leading: CircleAvatar(
          radius: 28,
          backgroundImage: driver.fotoProfil.isNotEmpty
              ? (driver.fotoProfil.startsWith('data:image')
                    ? MemoryImage(
                        base64Decode(driver.fotoProfil.split(',').last),
                      )
                    : NetworkImage(driver.fotoProfil) as ImageProvider)
              : null,
          child: driver.fotoProfil.isEmpty
              ? const Icon(Icons.person, size: 28)
              : null,
        ),
        title: Text(
          driver.namaDriver,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => _openWhatsApp(driver.noWa),
              child: Row(
                children: [
                  const Icon(Icons.phone, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    driver.noWa,
                    style: const TextStyle(color: Colors.green, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isAvailable
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isAvailable ? 'Available' : 'Busy',
                style: TextStyle(
                  color: isAvailable ? Colors.green : Colors.orange,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
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
          onSelected: (value) async {
            if (value == 'toggle_status') {
              final newStatus = isAvailable
                  ? DriverStatus.busy
                  : DriverStatus.available;
              await context.read<DriverController>().updateDriverStatus(
                driver.driverId,
                newStatus,
              );
            } else if (value == 'delete') {
              _confirmDeleteDriver(driver);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'toggle_status',
              child: Row(
                children: [
                  Icon(
                    isAvailable ? Icons.do_not_disturb : Icons.check_circle,
                    color: isAvailable ? Colors.orange : Colors.green,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(isAvailable ? 'Set Busy' : 'Set Available'),
                ],
              ),
            ),
            _buildPopupMenuItem(Icons.delete, 'Hapus', 'delete', Colors.red),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteDriver(DriverModel driver) async {
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
            const Text('Hapus Kurir'),
          ],
        ),
        content: Text('Yakin ingin menghapus kurir ${driver.namaDriver}?'),
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
      final success = await context.read<DriverController>().deleteDriver(
        driver.driverId,
      );
      if (mounted)
        _showResultSnackBar(success, 'Kurir dihapus', 'Gagal menghapus');
    }
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
