import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/maintenance_request.dart';
import '../../core/models/rental.dart';
import '../../services/api_service.dart';
import '../dashboard/dashboard_screen.dart';
import '../services/service_request_screen.dart';
import 'my_inspections_screen.dart';
import 'my_leases_screen.dart';
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
                            _buildInspectionsLink(context, cs),
                            _buildMaintenance(context, cs, l),
                            SizedBox(height: 16.h),
                            _buildCancelRental(cs, l),
                            SizedBox(height: 32.h),
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
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
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
                fontSize: 18.sp,
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
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 0.h),
      child: Container(
        height: 220.h,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
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
                      Icon(Icons.apartment, color: cs.outline, size: 48.r),
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
              top: 14.h,
              right: 14.w,
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  '${rental.leaseStatus.toUpperCase()} ${l.tr('lease')}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 16.h,
              left: 16.w,
              right: 16.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rental.address,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          color: Colors.white70, size: 14.r),
                      SizedBox(width: 4.w),
                      Text(
                        rental.location,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13.sp,
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
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0.h),
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16.r),
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
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '\$${rental.monthlyRent.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    dueLabel,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    color: Colors.white70, size: 16.r),
                SizedBox(width: 8.w),
                Text(
                  '${l.tr('due')} $dueFormatted',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
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
                icon: Icon(Icons.payments_outlined, size: 20.r),
                label: Text(l.tr('payRentNow')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  textStyle: TextStyle(
                    fontSize: 15.sp,
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
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0.h),
      child: Row(
        children: [
          _buildInfoTile(cs, Icons.bed_outlined, bedsLabel, l.tr('rooms')),
          SizedBox(width: 10.w),
          _buildInfoTile(cs, Icons.bathtub_outlined, bathsLabel, l.tr('toilets')),
          SizedBox(width: 10.w),
          _buildInfoTile(cs, Icons.square_foot_outlined, sqftLabel, l.tr('sqFt')),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
      ColorScheme cs, IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24.r),
            SizedBox(height: 8.h),
            Text(
              value,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 10.sp,
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
      padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 0.h),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.tr('leaseSummary'),
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MyLeasesScreen()),
                ),
                child: Text(
                  l.tr('viewAll'),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14.r),
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
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 14.sp,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _leaseRowDivider(ColorScheme cs) {
    return Divider(
        height: 1.h, color: cs.outlineVariant.withValues(alpha: 0.3));
  }

  // ---------- Inspections ----------

  Widget _buildInspectionsLink(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0.h),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MyInspectionsScreen()),
        ),
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Icon(Icons.fact_check_outlined, color: AppColors.primary, size: 22.r),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Inspections',
                        style: TextStyle(color: cs.onSurface, fontSize: 15.sp, fontWeight: FontWeight.w700)),
                    SizedBox(height: 2.h),
                    Text('Reports and sign-off requests for your unit',
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.sp)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
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
      padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 0.h),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.tr('maintenance'),
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 18.sp,
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
                    Icon(Icons.add, color: AppColors.primary, size: 18.r),
                    SizedBox(width: 4.w),
                    Text(
                      l.tr('newRequest'),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (_maintenanceRequests.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: cs.outline, size: 36.r),
                  SizedBox(height: 8.h),
                  Text(
                    l.tr('noMaintenanceRequests'),
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 14.sp,
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
                padding: EdgeInsets.only(bottom: 10.h),
                child: Container(
                  padding: EdgeInsets.all(14.r),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48.w,
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: catBgColor,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(catIcon, color: catIconColor, size: 24.r),
                      ),
                      SizedBox(width: 14.w),
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
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8.w, vertical: 3.h),
                                  decoration: BoxDecoration(
                                    color: sBgColor,
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(
                                      color: sColor,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              dateLabel,
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 12.sp,
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
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _showCancelConfirmation(),
          icon: Icon(Icons.cancel_outlined, size: 18.r),
          label: Text(l.tr('cancelRental')),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            padding: EdgeInsets.symmetric(vertical: 14.h),
            textStyle: TextStyle(
              fontSize: 14.sp,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
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
