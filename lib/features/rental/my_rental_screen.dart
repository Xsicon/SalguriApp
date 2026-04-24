import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/maintenance_request.dart';
import '../../core/models/rental.dart';
import '../../services/api_service.dart';
import '../dashboard/dashboard_screen.dart';
import '../services/service_request_screen.dart';
import 'pay_rent_screen.dart';

class MyRentalScreen extends StatefulWidget {
  final Rental rental;

  const MyRentalScreen({super.key, required this.rental});

  @override
  State<MyRentalScreen> createState() => _MyRentalScreenState();
}

class _MyRentalScreenState extends State<MyRentalScreen> {
  List<MaintenanceRequest> _maintenanceRequests = [];
  bool _isLoading = true;
  late Rental _rental;

  Rental get rental => _rental;

  @override
  void initState() {
    super.initState();
    _rental = widget.rental;
    _loadRentalDetails();
  }

  bool get _isDemoRental => rental.id == 'demo';

  Future<void> _loadRentalDetails() async {
    // Skip Supabase queries for the fallback demo rental (not a valid UUID)
    if (_isDemoRental) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final requests = await ApiService.getMaintenanceRequests(rental.id);

      setState(() {
        _maintenanceRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading rental details: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, cs, l),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary))
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _loadRentalDetails,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPropertyHero(cs, l),
                            _buildRentStatusCard(cs, l),
                            _buildQuickInfoGrid(cs, l),
                            _buildLeaseSummary(cs, l),
                            _buildMaintenance(context, cs, l),
                            const SizedBox(height: 16),
                            _buildCancelRental(cs, l),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Header ----------

  Widget _buildHeader(BuildContext context, ColorScheme cs, AppLocalizations l) {
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
              l.tr('myRental'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.share_outlined, color: cs.onSurface),
          ),
        ],
      ),
    );
  }

  // ---------- Property Hero ----------

  Widget _buildPropertyHero(ColorScheme cs, AppLocalizations l) {
    final imageUrl = rental.imageUrl.isNotEmpty
        ? rental.imageUrl
        : 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Container(
        height: 220,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: cs.surfaceContainerHighest,
                child: Center(
                  child:
                      Icon(Icons.apartment, color: cs.outline, size: 48),
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                  stops: [0.3, 1.0],
                ),
              ),
            ),
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${rental.leaseStatus.toUpperCase()} ${l.tr('lease')}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rental.address,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        rental.location,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Rent Status Card ----------

  Widget _buildRentStatusCard(ColorScheme cs, AppLocalizations l) {
    final dueFormatted =
        DateFormat('MMM d, yyyy').format(rental.nextDueDate);
    final daysUntilDue =
        rental.nextDueDate.difference(DateTime.now()).inDays;
    final dueLabel = rental.isPaid
        ? 'PAID'
        : daysUntilDue > 0
            ? 'DUE IN $daysUntilDue DAYS'
            : 'OVERDUE';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.tr('rentStatus'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${rental.monthlyRent.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    dueLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${l.tr('due')} $dueFormatted',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final paid = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => PayRentScreen(rental: rental),
                    ),
                  );
                  if (paid == true && mounted) {
                    setState(() {
                      _rental = rental.copyWith(isPaid: true);
                    });
                  }
                },
                icon: const Icon(Icons.payments_outlined, size: 20),
                label: Text(l.tr('payRentNow')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Quick Info Grid ----------

  Widget _buildQuickInfoGrid(ColorScheme cs, AppLocalizations l) {
    final bedsLabel = rental.beds > 0 ? '${rental.beds} Beds' : '--';
    final bathsLabel = rental.baths > 0
        ? '${rental.baths % 1 == 0 ? rental.baths.toInt() : rental.baths} Baths'
        : '--';
    final sqftLabel = rental.sqft > 0
        ? NumberFormat('#,###').format(rental.sqft)
        : '--';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          _buildInfoTile(cs, Icons.bed_outlined, bedsLabel, l.tr('rooms')),
          const SizedBox(width: 10),
          _buildInfoTile(cs, Icons.bathtub_outlined, bathsLabel, l.tr('toilets')),
          const SizedBox(width: 10),
          _buildInfoTile(cs, Icons.square_foot_outlined, sqftLabel, l.tr('sqFt')),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
      ColorScheme cs, IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Lease Summary ----------

  Widget _buildLeaseSummary(ColorScheme cs, AppLocalizations l) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final startDate = rental.leaseStart != null
        ? dateFormat.format(rental.leaseStart!)
        : '--';
    final endDate = rental.leaseEnd != null
        ? dateFormat.format(rental.leaseEnd!)
        : '--';
    final depositLabel = rental.securityDeposit > 0
        ? '\$${rental.securityDeposit.toStringAsFixed(2)}'
        : '\$${rental.monthlyRent.toStringAsFixed(2)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.tr('leaseSummary'),
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                l.tr('viewAll'),
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                _buildLeaseRow(cs, l.tr('leaseTerm'), rental.leaseTerm),
                _leaseRowDivider(cs),
                _buildLeaseRow(cs, l.tr('startDate'), startDate),
                _leaseRowDivider(cs),
                _buildLeaseRow(cs, l.tr('endDate'), endDate),
                _leaseRowDivider(cs),
                _buildLeaseRow(cs, l.tr('securityDeposit'), depositLabel),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaseRow(ColorScheme cs, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _leaseRowDivider(ColorScheme cs) {
    return Divider(
        height: 1, color: cs.outlineVariant.withValues(alpha: 0.3));
  }

  // ---------- Maintenance ----------

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'plumbing':
        return Icons.plumbing;
      case 'electrical':
        return Icons.electrical_services;
      case 'hvac':
        return Icons.ac_unit;
      default:
        return Icons.build_outlined;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'in_progress':
        return const Color(0xFFD97706);
      case 'resolved':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  Color _statusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'in_progress':
        return const Color(0xFFFEF3C7);
      case 'resolved':
        return const Color(0xFFDCFCE7);
      default:
        return const Color(0xFFEEF2FF);
    }
  }

  Widget _buildMaintenance(BuildContext context, ColorScheme cs, AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.tr('maintenance'),
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ServiceRequestScreen(rental: rental),
                    ),
                  );
                },
                child: Row(
                  children: [
                    const Icon(Icons.add, color: AppColors.primary, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      l.tr('newRequest'),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_maintenanceRequests.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: cs.outline, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    l.tr('noMaintenanceRequests'),
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._maintenanceRequests.map((req) {
              final dateFormat = DateFormat('MMM dd, yyyy');
              final dateLabel = req.status == 'resolved' && req.resolvedAt != null
                  ? 'Resolved on ${dateFormat.format(req.resolvedAt!)}'
                  : 'Reported on ${dateFormat.format(req.reportedAt)}';
              final statusLabel = req.status.toUpperCase().replaceAll('_', ' ');
              final sColor = _statusColor(req.status);
              final sBgColor = _statusBgColor(req.status);
              final catIcon = _categoryIcon(req.category);
              final catBgColor = _statusBgColor(req.status);
              final catIconColor = _statusColor(req.status);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: catBgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(catIcon, color: catIconColor, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    req.title,
                                    style: TextStyle(
                                      color: cs.onSurface,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: sBgColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(
                                      color: sColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateLabel,
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // ---------- Cancel Rental ----------

  Widget _buildCancelRental(ColorScheme cs, AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _showCancelConfirmation(),
          icon: const Icon(Icons.cancel_outlined, size: 18),
          label: Text(l.tr('cancelRental')),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void _showCancelConfirmation() {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.tr('cancelRental')),
        content: Text(l.tr('cancelRentalConfirm')),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.tr('noKeepIt')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _cancelRental();
            },
            child: Text(l.tr('yesCancel'), style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelRental() async {
    final l = AppLocalizations.of(context);
    try {
      await ApiService.cancelRental(rental.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.tr('rentalCancelled')),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
