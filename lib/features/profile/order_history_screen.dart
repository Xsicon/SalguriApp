import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/rent_payment.dart';
import '../../core/models/rental.dart';
import '../../core/models/service_request.dart';
import '../../services/api_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  int _selectedTab = 0;
  bool _isLoading = true;

  List<RentPayment> _rentPayments = [];
  List<ServiceRequest> _serviceRequests = [];
  List<Map<String, dynamic>> _showings = [];
  Rental? _activeRental;

  final _dateFormat = DateFormat('MMM d, yyyy');

  List<String> _tabs(AppLocalizations l) => [
        l.tr('all'),
        l.tr('payments'),
        l.tr('services'),
        l.tr('showings'),
      ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load rental first to get payment history
      final rental = await ApiService.getActiveRental();
      final results = await Future.wait([
        if (rental != null)
          ApiService.getRentPayments(rental.id)
        else
          Future.value(<Map<String, dynamic>>[]),
        ApiService.getAllServiceRequests(),
        ApiService.getShowings(),
      ]);

      final paymentMaps = results[0] as List<Map<String, dynamic>>;
      final payments =
          paymentMaps.map((e) => RentPayment.fromJson(e)).toList();

      if (!mounted) return;
      setState(() {
        _activeRental = rental;
        _rentPayments = payments;
        _serviceRequests = results[1] as List<ServiceRequest>;
        _showings = results[2] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading order history: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<_OrderItem> _allOrders(AppLocalizations l) {
    final orders = <_OrderItem>[];

    for (final p in _rentPayments) {
      orders.add(_OrderItem(
        type: _OrderType.payment,
        title: l.tr('rentPayment'),
        subtitle: _activeRental?.address ?? 'Rental',
        amount: '\$${p.amount.toStringAsFixed(2)}',
        date: p.createdAt,
        status: p.status,
        icon: Icons.home_outlined,
        iconColor: const Color(0xFF22C55E),
        iconBg: const Color(0xFFDCFCE7),
        detail: p.paymentMethod,
      ));
    }

    for (final sr in _serviceRequests) {
      orders.add(_OrderItem(
        type: _OrderType.service,
        title: sr.displayTitle,
        subtitle: sr.displayCategory,
        amount: sr.shortNumber,
        date: sr.createdAt,
        status: sr.status,
        icon: _serviceIcon(sr.displayCategory),
        iconColor: const Color(0xFF3B82F6),
        iconBg: const Color(0xFFDBEAFE),
      ));
    }

    for (final s in _showings) {
      final date = DateTime.tryParse(s['requested_date']?.toString() ?? '') ??
          DateTime.tryParse(s['created_at']?.toString() ?? '') ??
          DateTime.now();
      orders.add(_OrderItem(
        type: _OrderType.showing,
        title: l.tr('propertyShowing'),
        subtitle: s['requested_time']?.toString() ?? '',
        amount: '${s['number_of_people'] ?? 1} ${l.tr('guests')}',
        date: date,
        status: (s['status'] as String?) ?? 'pending',
        icon: Icons.calendar_today_outlined,
        iconColor: const Color(0xFF8B5CF6),
        iconBg: const Color(0xFFEDE9FE),
        detail: s['notes']?.toString(),
      ));
    }

    orders.sort((a, b) => b.date.compareTo(a.date));
    return orders;
  }

  List<_OrderItem> _filteredOrders(AppLocalizations l) {
    final all = _allOrders(l);
    return switch (_selectedTab) {
      1 => all.where((o) => o.type == _OrderType.payment).toList(),
      2 => all.where((o) => o.type == _OrderType.service).toList(),
      3 => all.where((o) => o.type == _OrderType.showing).toList(),
      _ => all,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(cs, l),
            Divider(height: 1, color: cs.surfaceContainerHighest),
            _buildTabRow(cs, l),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary))
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _loadData,
                      child: _buildOrderList(cs, l),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────── App Bar ────────────

  Widget _buildAppBar(ColorScheme cs, AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back, color: cs.onSurface),
          ),
          Expanded(
            child: Text(
              l.tr('orderHistory'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ──────────── Tab Row ────────────

  Widget _buildTabRow(ColorScheme cs, AppLocalizations l) {
    final tabs = _tabs(l);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isSelected = _selectedTab == index;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      tabs[index],
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.white
                            : cs.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ──────────── Summary Cards ────────────

  Widget _buildSummaryRow(ColorScheme cs, AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          _buildSummaryCard(
            cs,
            icon: Icons.payments_outlined,
            label: l.tr('payments'),
            value: '${_rentPayments.length}',
            color: const Color(0xFF22C55E),
            bg: const Color(0xFFDCFCE7),
          ),
          const SizedBox(width: 10),
          _buildSummaryCard(
            cs,
            icon: Icons.build_outlined,
            label: l.tr('services'),
            value: '${_serviceRequests.length}',
            color: const Color(0xFF3B82F6),
            bg: const Color(0xFFDBEAFE),
          ),
          const SizedBox(width: 10),
          _buildSummaryCard(
            cs,
            icon: Icons.calendar_today_outlined,
            label: l.tr('showings'),
            value: '${_showings.length}',
            color: const Color(0xFF8B5CF6),
            bg: const Color(0xFFEDE9FE),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    ColorScheme cs, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bg,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────── Order List ────────────

  Widget _buildOrderList(ColorScheme cs, AppLocalizations l) {
    final orders = _filteredOrders(l);

    if (orders.isEmpty) {
      return ListView(
        children: [
          _buildSummaryRow(cs, l),
          const SizedBox(height: 40),
          _buildEmptyState(cs, l),
        ],
      );
    }

    // Group by month
    final grouped = <String, List<_OrderItem>>{};
    for (final order in orders) {
      final key = DateFormat('MMMM yyyy').format(order.date);
      grouped.putIfAbsent(key, () => []).add(order);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _buildSummaryRow(cs, l),
        ...grouped.entries.expand((entry) => [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    color: cs.outline,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              ...entry.value.map((order) => _buildOrderCard(order, cs, l)),
            ]),
      ],
    );
  }

  Widget _buildOrderCard(_OrderItem order, ColorScheme cs, AppLocalizations l) {
    final statusColor = switch (order.status) {
      'paid' || 'completed' => const Color(0xFF22C55E),
      'pending' => const Color(0xFFF59E0B),
      'accepted' || 'in_progress' || 'confirmed' => AppColors.primary,
      'cancelled' => const Color(0xFFEF4444),
      _ => cs.onSurfaceVariant,
    };

    final statusBg = switch (order.status) {
      'paid' || 'completed' => const Color(0xFFDCFCE7),
      'pending' => const Color(0xFFFEF3C7),
      'accepted' || 'in_progress' || 'confirmed' => AppColors.primarySoft,
      'cancelled' => const Color(0xFFFEE2E2),
      _ => cs.surfaceContainerHighest,
    };

    final statusLabel = switch (order.status) {
      'paid' => l.tr('paid'),
      'completed' => l.tr('completed'),
      'pending' => l.tr('pending'),
      'accepted' => l.tr('accepted'),
      'in_progress' => l.tr('inProgress'),
      'confirmed' => l.tr('confirmed'),
      'cancelled' => l.tr('cancelled'),
      _ => order.status,
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: order.iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(order.icon, color: order.iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.title,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      _dateFormat.format(order.date),
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    if (order.subtitle.isNotEmpty) ...[
                      Text('  \u2022  ',
                          style: TextStyle(
                              color: cs.outline, fontSize: 12)),
                      Flexible(
                        child: Text(
                          order.subtitle,
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                if (order.detail != null && order.detail!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        order.type == _OrderType.payment
                            ? Icons.account_balance_wallet_outlined
                            : Icons.info_outline,
                        color: cs.outline,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          order.detail!,
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                order.amount,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs, AppLocalizations l) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_outlined,
                color: cs.outline, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            l.tr('noOrdersYet'),
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.tr('transactionsAppearHere'),
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────── Helpers ────────────

  IconData _serviceIcon(String category) {
    final c = category.toLowerCase();
    if (c.contains('electric')) return Icons.electrical_services;
    if (c.contains('plumb')) return Icons.plumbing;
    if (c.contains('clean')) return Icons.cleaning_services_outlined;
    if (c.contains('paint')) return Icons.format_paint_outlined;
    if (c.contains('ac') || c.contains('hvac')) return Icons.ac_unit;
    return Icons.build_outlined;
  }
}

// ──────────── Data Classes ────────────

enum _OrderType { payment, service, showing }

class _OrderItem {
  final _OrderType type;
  final String title;
  final String subtitle;
  final String amount;
  final DateTime date;
  final String status;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String? detail;

  const _OrderItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.status,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.detail,
  });
}
