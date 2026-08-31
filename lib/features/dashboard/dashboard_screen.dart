import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/nav/bottom_nav_bar.dart';
import '../../core/models/property.dart';
import '../../core/models/rental.dart';
import '../../core/models/service_category.dart';
import '../../core/models/service_request.dart';
import '../../services/api_service.dart';
import '../../core/l10n/app_localizations.dart';
import '../../services/supabase_service.dart';
import '../../main.dart';
import '../profile/profile_tab.dart';
import '../property/properties_screen.dart';
import '../property/property_details_screen.dart';
import '../property/property_filter_screen.dart';
import '../rental/my_applications_screen.dart';
import '../rental/my_leases_screen.dart';
import '../rental/my_rental_screen.dart';
import '../inbox/inbox_screen.dart';
import '../services/service_request_screen.dart';
import '../services/service_tracking_screen.dart';
import '../services/job_marketplace_screen.dart';
import '../services/my_service_requests_screen.dart';
import '../explore/explore_hub_screen.dart';
import '../explore/saved_items_screen.dart';
import '../notifications/notifications_screen.dart';
import '../rental/pay_rent_screen.dart';
import '../../services/notification_center.dart';

const _quickActions = [
  {'icon': Icons.search_rounded, 'label': 'Search', 'gradient': [0xFF2563EB, 0xFF3B82F6]},
  {'icon': Icons.favorite_rounded, 'label': 'Saved', 'gradient': [0xFFEF4444, 0xFFF87171]},
  {'icon': Icons.build_rounded, 'label': 'Support', 'gradient': [0xFFF59E0B, 0xFFFBBF24]},
  {'icon': Icons.mail_rounded, 'label': 'Inbox', 'gradient': [0xFF6366F1, 0xFF818CF8]},
];


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with RouteAware {
  int _currentNavIndex = 0;

  // Data from Salguri schema
  List<Property> _properties = [];
  Rental? _activeRental;
  List<ServiceRequest> _serviceRequests = [];
  bool _isLoading = true;
  bool _rentPaidLocally = false;

  String get _userName {
    final meta = SupabaseService.currentUser?.userMetadata;
    final name = meta?['full_name'] as String?;
    return name ?? 'User';
  }

  String get _firstName {
    final parts = _userName.split(' ');
    return parts.first;
  }

  String? get _avatarUrl =>
      SupabaseService.currentUser?.userMetadata?['avatar_url'] as String?;

  String _greeting(AppLocalizations l) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l.tr('goodMorning');
    if (hour < 17) return l.tr('goodAfternoon');
    return l.tr('goodEvening');
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // A route was popped back to this screen — reload data
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getProperties(limit: 3),
        ApiService.getActiveRental(),
        ApiService.getActiveServiceRequests(),
        ApiService.getServiceCategories(),
      ]);
      final categories = results[3] as List<ServiceCategory>;
      final categoryMap = {for (final c in categories) c.id: c.name};
      final requests = (results[2] as List<ServiceRequest>).map((req) {
        final name = categoryMap[req.category];
        return name != null ? req.copyWith(categoryName: name) : req;
      }).toList();

      var rental = results[1] as Rental?;
      if (_rentPaidLocally && rental != null) {
        rental = rental.copyWith(isPaid: true);
      }

      setState(() {
        _properties = results[0] as List<Property>;
        _activeRental = rental;
        _serviceRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: IndexedStack(
          index: _currentNavIndex,
          children: [
            _buildHomeTab(),
            const PropertyFilterScreen(),
            const ExploreHubScreen(),
            InboxScreen(onBack: () => setState(() => _currentNavIndex = 0)),
            const ProfileTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ---------- Home Tab ----------

  Widget _buildHomeTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeroHeader()),
          SliverToBoxAdapter(child: _buildQuickActions()),
          SliverToBoxAdapter(child: _buildCurrentRental()),
          SliverToBoxAdapter(child: _buildActiveRequests()),
          SliverToBoxAdapter(child: _buildRecommendedProperties()),
          SliverToBoxAdapter(child: _buildBottomActions()),
          SliverToBoxAdapter(child: SizedBox(height: 32.h)),
        ],
      ),
    );
  }

  // ---------- Hero Header with Gradient ----------

  Widget _buildHeroHeader() {
    final l = AppLocalizations.of(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2563EB),
            Color(0xFF1D4ED8),
            Color(0xFF1E40AF),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 28.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: avatar + logo + bell
              Row(
                children: [
                  Container(
                    width: 42.w,
                    height: 42.h,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)],
                      ),
                      shape: BoxShape.circle,
                      image: _avatarUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_avatarUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _avatarUrl == null
                        ? Center(
                            child: Text(
                              _firstName.isNotEmpty ? _firstName[0].toUpperCase() : 'U',
                              style: TextStyle(
                                color: const Color(0xFF92400E),
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          )
                        : null,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    l.tr('appName'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  // Notification bell
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    ),
                    child: AnimatedBuilder(
                      animation: NotificationCenter.instance,
                      builder: (context, _) {
                        final hasUnread = NotificationCenter.instance.hasUnread;
                        return Container(
                          width: 42.w,
                          height: 42.h,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Icon(
                                  Icons.notifications_outlined,
                                  color: Colors.white,
                                  size: 22.r,
                                ),
                              ),
                              if (hasUnread)
                                Positioned(
                                  top: 10.h,
                                  right: 10.w,
                                  child: Container(
                                    width: 9.w,
                                    height: 9.h,
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              // Greeting
              Text(
                '${_greeting(l)},',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '$_firstName!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                l.tr('welcomeBack'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Quick Actions ----------

  Widget _buildQuickActions() {
    final l = AppLocalizations.of(context);
    final quickActionLabels = {
      'Search': l.tr('search'),
      'Saved': l.tr('saved'),
      'Support': l.tr('support'),
      'Inbox': l.tr('inbox'),
    };
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0.h),
      child: _buildGlassCard(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: (_quickActions).map((action) {
            final key = action['label'] as String;
            return GestureDetector(
              onTap: () => _onQuickAction(key),
              child: _buildQuickActionItem(
                icon: action['icon'] as IconData,
                label: quickActionLabels[key] ?? key,
                gradientColors: (action['gradient'] as List<int>)
                    .map((c) => Color(c))
                    .toList(),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required List<Color> gradientColors,
  }) {
    return Column(
      children: [
        Container(
          width: 52.w,
          height: 52.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Icon(icon, color: Colors.white, size: 24.r),
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _onQuickAction(String label) {
    switch (label) {
      case 'Search':
        setState(() => _currentNavIndex = 1);
      case 'Saved':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SavedItemsScreen()),
        );
      case 'Inbox':
        setState(() => _currentNavIndex = 3);
      case 'Support':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ServiceRequestScreen(rental: _activeRental),
          ),
        );
      default:
        break;
    }
  }

  // ---------- Current Rental ----------

  Widget _buildCurrentRental() {
    if (_activeRental == null) return const SizedBox.shrink();
    final rental = _activeRental!;
    final dueDateFormatted = DateFormat('MMM d, yyyy').format(rental.nextDueDate);
    final rentFormatted = '\$${rental.monthlyRent.toStringAsFixed(0)}/mo';
    final leaseLabel = rental.leaseStatus.toUpperCase();

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Current Rental', trailing: leaseLabel),
          SizedBox(height: 14.h),
          _buildGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Address + Paid badge
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rental.address,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            rental.location,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 13.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(
                      rental.isPaid ? 'Paid' : 'Due',
                      isPositive: rental.isPaid,
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                // Rent + Due date
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoColumn('MONTHLY RENT', rentFormatted, isHighlight: true),
                    ),
                    Expanded(
                      child: _buildInfoColumn('NEXT DUE DATE', dueDateFormatted),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MyRentalScreen(rental: rental),
                            ),
                          );
                        },
                        child: const Text('VIEW DETAILS'),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final paid = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => PayRentScreen(rental: rental),
                            ),
                          );
                          if (paid == true && mounted) {
                            _rentPaidLocally = true;
                            setState(() {
                              _activeRental = _activeRental?.copyWith(isPaid: true);
                            });
                          }
                        },
                        child: const Text('PAY RENT'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Active Requests ----------

  IconData _categoryIcon(ServiceRequest req) {
    final name = (req.categoryName ?? req.category).toLowerCase();
    if (name.contains('electric')) return Icons.electrical_services;
    if (name.contains('plumb')) return Icons.plumbing;
    if (name.contains('clean')) return Icons.cleaning_services;
    if (name.contains('ac') || name.contains('hvac') || name.contains('air'))
      return Icons.ac_unit;
    if (name.contains('paint')) return Icons.format_paint_outlined;
    if (name.contains('lock') || name.contains('secur'))
      return Icons.lock_outlined;
    return Icons.build_outlined;
  }

  Widget _buildActiveRequests() {
    if (_serviceRequests.isEmpty) return const SizedBox.shrink();
    final pendingCount =
        _serviceRequests.where((r) => r.status == 'pending').length;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 0.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Active Requests',
            trailing: pendingCount > 0 ? '$pendingCount Pending' : null,
            trailingColor: AppColors.error,
          ),
          SizedBox(height: 14.h),
          ..._serviceRequests.map((req) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: _buildRequestCard(req),
              )),
        ],
      ),
    );
  }

  Widget _buildRequestCard(ServiceRequest req) {
    final l = AppLocalizations.of(context);
    return _buildGlassCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Center(
                  child: Icon(
                    _categoryIcon(req),
                    color: AppColors.primary,
                    size: 22.r,
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.displayTitle,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      req.shortNumber,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (req.statusMessage.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Container(
                            width: 7.w,
                            height: 7.h,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              req.statusMessage,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (req.etaMinutes != null) ...[
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time_rounded, color: AppColors.primary, size: 18.r),
                  SizedBox(width: 8.w),
                  Text(
                    l.tr('estimatedArrival'),
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13.sp),
                  ),
                  const Spacer(),
                  Text(
                    '${req.etaMinutes} ${l.tr('min')}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final cancelled = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => ServiceTrackingScreen(request: req),
                  ),
                );
                if (cancelled == true) _loadData();
              },
              child: Text(l.tr('trackLive')),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Recommended Properties ----------

  Widget _buildRecommendedProperties() {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 0.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.tr('recommended'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 19.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PropertiesScreen()),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    l.tr('seeAll'),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (_properties.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Center(
                child: Text(
                  l.tr('noPropertiesAvailable'),
                  style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 14.sp),
                ),
              ),
            )
          else
            SizedBox(
              height: 290.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: _properties.length,
                separatorBuilder: (_, __) => SizedBox(width: 16.w),
                itemBuilder: (context, index) {
                  final prop = _properties[index];
                  return GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PropertyDetailsScreen(property: prop),
                      ),
                    ),
                    child: _buildPropertyCard(property: prop),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard({required Property property}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 230.w,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property image with price badge
          Stack(
            children: [
              SizedBox(
                height: 150.h,
                width: double.infinity,
                child: Image.network(
                  property.images.isNotEmpty ? property.images.first : '',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: cs.surfaceContainerHighest,
                    child: Center(
                      child: Icon(Icons.home_outlined, color: cs.outline, size: 40.r),
                    ),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: cs.surfaceContainerHighest,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Price tag
              Positioned(
                top: 12.h,
                right: 12.w,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: AppColors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        property.price,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Type badge
              Positioned(
                top: 12.h,
                left: 12.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    property.type,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Info
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.title,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, color: AppColors.primary, size: 15.r),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        property.location,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                // Stats row
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPropertyStat(Icons.bed_rounded, '${property.beds}'),
                      Container(width: 1.w, height: 16.h, color: cs.outlineVariant),
                      _buildPropertyStat(Icons.bathtub_rounded, '${property.baths}'),
                      Container(width: 1.w, height: 16.h, color: cs.outlineVariant),
                      _buildPropertyStat(Icons.star_rounded, property.rating.toString()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyStat(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 16.r),
        SizedBox(width: 4.w),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ---------- Bottom Action Buttons ----------

  Widget _buildBottomActions() {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 0.h),
      child: Column(
        children: [
          _buildActionRow(Icons.grid_view_rounded, l.tr('viewAllProperties'), () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PropertiesScreen()),
            );
          }),
          SizedBox(height: 12.h),
          _buildActionRow(Icons.handyman_rounded, l.tr('seeAllServices'), () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ServiceRequestScreen(rental: _activeRental),
              ),
            );
          }),
          SizedBox(height: 12.h),
          _buildActionRow(Icons.assignment_outlined, 'Applications', () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyApplicationsScreen()),
            );
          }),
          SizedBox(height: 12.h),
          _buildActionRow(Icons.description_outlined, 'Leases', () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyLeasesScreen()),
            );
          }),
          SizedBox(height: 12.h),
          _buildActionRow(Icons.storefront_outlined, 'Service Providers', () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const JobMarketplaceScreen()),
            );
          }),
          SizedBox(height: 12.h),
          _buildActionRow(Icons.checklist_outlined, 'My Service Requests', () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyServiceRequestsScreen()),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionRow(IconData icon, String label, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: _buildGlassCard(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(child: Icon(icon, color: AppColors.primary, size: 20.r)),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              width: 32.w,
              height: 32.h,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Center(
                child: Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 14.r),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Bottom Nav ----------

  Widget _buildBottomNav() {
    return BottomNavBar(
      currentIndex: _currentNavIndex,
      onTap: (i) {
        setState(() => _currentNavIndex = i);
        if (i == 0) _loadData();
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Shared Widgets
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildGlassCard({required Widget child, EdgeInsets? padding}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: padding ?? EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader(String title, {String? trailing, Color? trailingColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 19.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (trailing != null)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: (trailingColor ?? AppColors.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              trailing,
              style: TextStyle(
                color: trailingColor ?? AppColors.primary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusBadge(String text, {required bool isPositive}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isPositive ? AppColors.successSoft : AppColors.errorSoft,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.check_circle_rounded : Icons.warning_rounded,
            color: isPositive ? AppColors.success : AppColors.error,
            size: 14.r,
          ),
          SizedBox(width: 5.w),
          Text(
            text,
            style: TextStyle(
              color: isPositive ? AppColors.success : AppColors.error,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, {bool isHighlight = false}) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: cs.outline,
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          value,
          style: TextStyle(
            color: isHighlight ? AppColors.primary : cs.onSurface,
            fontSize: isHighlight ? 22.sp : 17.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
