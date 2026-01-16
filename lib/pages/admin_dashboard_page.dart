import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/reservasi_controller.dart';
import '../models/reservasi_model.dart';

class AdminDashboardPage extends StatefulWidget {
  final Function(String? statusFilter)? onNavigateToReservasi;

  const AdminDashboardPage({super.key, this.onNavigateToReservasi});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final MapController _mapController = MapController();

  // Konstanta warna tema
  static const Color _primaryColor = Color(0xFF2563EB);
  static const Color _secondaryColor = Color(0xFF7C3AED);
  static const Color _bgColor = Color(0xFFF8FAFC);
  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = Color(0xFF1E293B);
  static const Color _textSecondary = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await context.read<ReservasiController>().loadAllReservasi();
    await context.read<ReservasiController>().loadActiveRentalStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: _primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Statistics Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Consumer<ReservasiController>(
                  builder: (context, controller, _) {
                    return _buildStatisticsSection(controller);
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Maps Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Consumer<ReservasiController>(
                  builder: (context, controller, _) {
                    return _buildMapsCard(controller);
                  },
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(ReservasiController controller) {
    // Calculate statistics
    final allReservasi = controller.reservasiList;

    // Pending (belum bayar)
    final pendingPayment = allReservasi
        .where((r) => r.status == ReservasiStatus.belumBayar)
        .toList();

    // Menunggu konfirmasi (sudah bayar, perlu approve)
    final waitingConfirmation = allReservasi
        .where((r) => r.status == ReservasiStatus.paid)
        .toList();

    // Sedang diantar (shipping)
    final shippingOrders = allReservasi
        .where((r) => r.status == ReservasiStatus.shipping)
        .toList();

    // Unit yang sedang disewa (status active)
    final activeRentals = allReservasi
        .where((r) => r.status == ReservasiStatus.active)
        .toList();
    final totalUnitDisewa = activeRentals.fold<int>(
      0,
      (sum, r) => sum + r.jumlahUnit,
    );

    // Transaksi yang sudah selesai
    final completedTransactions = allReservasi
        .where(
          (r) =>
              r.status == ReservasiStatus.finished ||
              r.status == ReservasiStatus.completed,
        )
        .toList();

    // Total pendapatan dari transaksi selesai
    final totalPendapatan = completedTransactions.fold<int>(
      0,
      (sum, r) => sum + r.totalHarga,
    );

    return Column(
      children: [
        // Row 1: Pending & Konfirmasi
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Pending',
                pendingPayment.length.toString(),
                Icons.hourglass_empty_rounded,
                const Color(0xFF64748B),
                'Menunggu pembayaran',
                onTap: () => widget.onNavigateToReservasi?.call(
                  ReservasiStatus.belumBayar,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                'Konfirmasi',
                waitingConfirmation.length.toString(),
                Icons.pending_actions_rounded,
                const Color(0xFFF59E0B),
                'Menunggu approve',
                onTap: () =>
                    widget.onNavigateToReservasi?.call(ReservasiStatus.paid),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Row 2: Sedang Diantar & Unit Disewa
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Diantar',
                shippingOrders.length.toString(),
                Icons.local_shipping_rounded,
                const Color(0xFF3B82F6),
                'Sedang diantar',
                onTap: () => widget.onNavigateToReservasi?.call(
                  ReservasiStatus.shipping,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                'Disewa',
                totalUnitDisewa.toString(),
                Icons.sports_esports_rounded,
                _primaryColor,
                'Sedang aktif disewa',
                onTap: () =>
                    widget.onNavigateToReservasi?.call(ReservasiStatus.active),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Row 3: Selesai & Pendapatan
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Selesai',
                completedTransactions.length.toString(),
                Icons.check_circle_rounded,
                const Color(0xFF10B981),
                'Transaksi selesai',
                onTap: () => widget.onNavigateToReservasi?.call(
                  ReservasiStatus.completed,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                'Pendapatan',
                _formatCurrency(totalPendapatan),
                Icons.account_balance_wallet_rounded,
                const Color(0xFF10B981),
                'Total pendapatan',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Arrow indicator for tappable cards
          if (onTap != null)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.chevron_right_rounded, color: color, size: 16),
            ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }

  Widget _buildMapsCard(ReservasiController controller) {
    // Get all active reservations with coordinates
    final activeWithLocation = controller.reservasiList.where((r) {
      // Filter hanya yang punya koordinat dan statusnya aktif/shipping/installed
      final hasKordinat = r.kordinat != null && r.kordinat!.isNotEmpty;
      final hasLatLng = r.latitude != null && r.longitude != null;
      final isActiveStatus =
          r.status == ReservasiStatus.active ||
          r.status == ReservasiStatus.shipping ||
          r.status == ReservasiStatus.installed;
      return (hasKordinat || hasLatLng) && isActiveStatus;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.map_rounded,
                        color: _primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lokasi Penyewa',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${activeWithLocation.length} lokasi aktif',
                          style: TextStyle(fontSize: 12, color: _textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Live',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Map
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            child: SizedBox(
              height: 300,
              child: activeWithLocation.isEmpty
                  ? _buildEmptyMapState()
                  : _buildFlutterMap(activeWithLocation),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMapState() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Belum ada lokasi penyewa aktif',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlutterMap(List<ReservasiModel> reservasiList) {
    // Parse coordinates
    List<Marker> markers = [];
    LatLng? center;

    for (var reservasi in reservasiList) {
      LatLng? position;

      // Try to get from latitude/longitude first
      if (reservasi.latitude != null && reservasi.longitude != null) {
        position = LatLng(reservasi.latitude!, reservasi.longitude!);
      }
      // Otherwise try to parse from kordinat string
      else if (reservasi.kordinat != null && reservasi.kordinat!.isNotEmpty) {
        try {
          final parts = reservasi.kordinat!.split(',');
          if (parts.length == 2) {
            final lat = double.tryParse(parts[0].trim());
            final lng = double.tryParse(parts[1].trim());
            if (lat != null && lng != null) {
              position = LatLng(lat, lng);
            }
          }
        } catch (e) {
          print('Error parsing kordinat: $e');
        }
      }

      if (position != null) {
        center ??= position;

        Color markerColor;
        switch (reservasi.status) {
          case 'active':
            markerColor = Colors.green;
            break;
          case 'shipping':
            markerColor = Colors.blue;
            break;
          case 'installed':
            markerColor = Colors.teal;
            break;
          default:
            markerColor = Colors.orange;
        }

        markers.add(
          Marker(
            point: position,
            width: 80,
            height: 80,
            child: GestureDetector(
              onTap: () => _showReservasiDetail(reservasi),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: markerColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: markerColor.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.gamepad,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      '${reservasi.jumlahUnit} unit',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: markerColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    // Default center to Indonesia if no markers
    center ??= const LatLng(-6.2088, 106.8456); // Jakarta

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 12,
        minZoom: 5,
        maxZoom: 18,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.quadraplay.app',
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }

  void _showReservasiDetail(ReservasiModel reservasi) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.location_on, color: _primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reservasi #${reservasi.reservasiId.substring(0, 8)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      _buildStatusBadge(reservasi.status),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Details
            _buildDetailRow(
              Icons.gamepad,
              'Unit',
              '${reservasi.jumlahUnit} unit × ${reservasi.jumlahHari} hari',
            ),
            _buildDetailRow(Icons.location_on, 'Alamat', reservasi.alamat),
            _buildDetailRow(Icons.phone, 'No. WA', reservasi.noWA),
            _buildDetailRow(
              Icons.attach_money,
              'Total',
              'Rp ${_formatCurrency(reservasi.totalHarga)}',
            ),

            if (reservasi.status == ReservasiStatus.active &&
                reservasi.waktuSewaBerakhir != null)
              _buildDetailRow(
                Icons.timer,
                'Sisa Waktu',
                reservasi.getSisaWaktuFormatted(),
              ),

            const SizedBox(height: 20),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openWhatsApp(reservasi.noWA),
                    icon: const Icon(Icons.message, color: Colors.green),
                    label: const Text(
                      'WhatsApp',
                      style: TextStyle(color: Colors.green),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.green),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openMaps(reservasi),
                    icon: const Icon(Icons.directions, color: Colors.white),
                    label: const Text(
                      'Navigasi',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'active':
        color = Colors.green;
        text = 'AKTIF';
        break;
      case 'shipping':
        color = Colors.blue;
        text = 'DIKIRIM';
        break;
      case 'installed':
        color = Colors.teal;
        text = 'TERPASANG';
        break;
      default:
        color = Colors.grey;
        text = status.toUpperCase();
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[400]),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
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
      ),
    );
  }

  Future<void> _openWhatsApp(String phone) async {
    String formattedPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '62${formattedPhone.substring(1)}';
    }
    final url = Uri.parse('https://wa.me/$formattedPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openMaps(ReservasiModel reservasi) async {
    String query;
    if (reservasi.latitude != null && reservasi.longitude != null) {
      query = '${reservasi.latitude},${reservasi.longitude}';
    } else if (reservasi.kordinat != null && reservasi.kordinat!.isNotEmpty) {
      query = reservasi.kordinat!;
    } else {
      query = Uri.encodeComponent(reservasi.alamat);
    }

    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  String _formatCurrency(int amount) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(amount);
  }
}
