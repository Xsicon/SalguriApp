import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/property.dart';
import '../../core/models/rental.dart';
import '../../core/models/service_category.dart';
import '../../core/models/service_request.dart';
import '../../services/api_service.dart';
import '../../services/supabase_service.dart';
import '../profile/profile_tab.dart';
import '../property/properties_screen.dart';
import '../property/property_details_screen.dart';
import '../property/property_filter_screen.dart';
import '../rental/my_rental_screen.dart';
import '../inbox/inbox_screen.dart';
import '../services/service_request_screen.dart';
import '../services/service_tracking_screen.dart';
import '../explore/explore_hub_screen.dart';
import '../explore/saved_items_screen.dart';
import '../rental/pay_rent_screen.dart';

const _quickActions = [
  {
    'icon': Icons.search_rounded,
    'label': 'Search',
    'gradient': [0xFF0D9488, 0xFF14B8A6],
  },
  {
    'icon': Icons.favorite_rounded,
    'label': 'Saved',
    'gradient': [0xFFEF4444, 0xFFF87171],
  },
  {
    'icon': Icons.build_rounded,
    'label': 'Support',
    'gradient': [0xFFF59E0B, 0xFFFBBF24],
  },
  {
    'icon': Icons.mail_rounded,
    'label': 'Inbox',
    'gradient': [0xFF6366F1, 0xFF818CF8],
  },
];

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentNavIndex = 0;

  // Data from Salguri schema
  List<Property> _properties = [];
  Rental? _activeRental;
  List<ServiceRequest> _serviceRequests = [];
  bool _isLoading = true;

  String get _userName {
    final meta = SupabaseService.currentUser?.userMetadata;
    final name = meta?['full_name'] as String?;
    return name ?? 'User';
  }

  String get _firstName {
    final parts = _userName.split(' ');
    return parts.first;
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  void initState() {
    super.initState();
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

      setState(() {
        _properties = results[0] as List<Property>;
        _activeRental = results[1] as Rental?;
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
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  // ---------- Hero Header with Gradient ----------

  Widget _buildHeroHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D9488), Color(0xFF0F766E), Color(0xFF115E59)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: avatar + logo + bell
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _firstName.isNotEmpty
                            ? _firstName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Color(0xFF92400E),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Salguri',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  // Notification bell
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      children: [
                        const Center(
                          child: Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF0D9488),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Greeting
              Text(
                '$_greeting,',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$_firstName!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Welcome back to your home dashboard',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: _buildGlassCard(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: (_quickActions).map((action) {
            return GestureDetector(
              onTap: () => _onQuickAction(action['label'] as String),
              child: _buildQuickActionItem(
                icon: action['icon'] as IconData,
                label: action['label'] as String,
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
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(child: Icon(icon, color: Colors.white, size: 24)),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
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
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const SavedItemsScreen()));
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
    final dueDateFormatted = DateFormat(
      'MMM d, yyyy',
    ).format(rental.nextDueDate);
    final rentFormatted = '\$${rental.monthlyRent.toStringAsFixed(0)}/mo';
    final leaseLabel = rental.leaseStatus.toUpperCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Current Rental', trailing: leaseLabel),
          const SizedBox(height: 14),
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
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            rental.location,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 13,
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
                const SizedBox(height: 20),
                // Rent + Due date
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoColumn(
                        'MONTHLY RENT',
                        rentFormatted,
                        isHighlight: true,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoColumn(
                        'NEXT DUE DATE',
                        dueDateFormatted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PayRentScreen(rental: rental),
                            ),
                          );
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
    if (name.contains('ac') || name.contains('hvac') || name.contains('air')) {
      return Icons.ac_unit;
    }
    if (name.contains('paint')) return Icons.format_paint_outlined;
    if (name.contains('lock') || name.contains('secur')) {
      return Icons.lock_outlined;
    }
    return Icons.build_outlined;
  }

  Widget _buildActiveRequests() {
    if (_serviceRequests.isEmpty) return const SizedBox.shrink();
    final pendingCount = _serviceRequests
        .where((r) => r.status == 'pending')
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Active Requests',
            trailing: pendingCount > 0 ? '$pendingCount Pending' : null,
            trailingColor: AppColors.error,
          ),
          const SizedBox(height: 14),
          ..._serviceRequests.map(
            (req) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildRequestCard(req),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(ServiceRequest req) {
    return _buildGlassCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Icon(
                    _categoryIcon(req),
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.displayTitle,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      req.shortNumber,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (req.statusMessage.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              req.statusMessage,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 13,
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
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Estimated arrival',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${req.etaMinutes} min',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
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
              child: const Text('TRACK LIVE'),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Recommended Properties ----------

  Widget _buildRecommendedProperties() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recommended',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PropertiesScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_properties.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No properties available',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 290,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: _properties.length,
                separatorBuilder: (_, _) => const SizedBox(width: 16),
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
      width: 230,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
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
                height: 150,
                width: double.infinity,
                child: Image.network(
                  property.images.isNotEmpty ? property.images.first : '',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: cs.surfaceContainerHighest,
                    child: Center(
                      child: Icon(
                        Icons.home_outlined,
                        color: cs.outline,
                        size: 40,
                      ),
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
                top: 12,
                right: 12,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        property.price,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Type badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    property.type,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Info
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.title,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.primary,
                      size: 15,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        property.location,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Stats row
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPropertyStat(Icons.bed_rounded, '${property.beds}'),
                      Container(width: 1, height: 16, color: cs.outlineVariant),
                      _buildPropertyStat(
                        Icons.bathtub_rounded,
                        '${property.baths}',
                      ),
                      Container(width: 1, height: 16, color: cs.outlineVariant),
                      _buildPropertyStat(
                        Icons.star_rounded,
                        property.rating.toString(),
                      ),
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
        Icon(icon, color: AppColors.primary, size: 16),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ---------- Bottom Action Buttons ----------

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: [
          _buildActionRow(Icons.grid_view_rounded, 'View All Properties', () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const PropertiesScreen()));
          }),
          const SizedBox(height: 12),
          _buildActionRow(Icons.handyman_rounded, 'See All Services', () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ServiceRequestScreen(rental: _activeRental),
              ),
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.primary,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Bottom Nav ----------

  Widget _buildBottomNav() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (i) {
          setState(() => _currentNavIndex = i);
          if (i == 0) _loadData();
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded),
            activeIcon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore_rounded),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            activeIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Inbox',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Shared Widgets
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildGlassCard({required Widget child, EdgeInsets? padding}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
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

  Widget _buildSectionHeader(
    String title, {
    String? trailing,
    Color? trailingColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: (trailingColor ?? AppColors.primary).withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              trailing,
              style: TextStyle(
                color: trailingColor ?? AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusBadge(String text, {required bool isPositive}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPositive ? AppColors.successSoft : AppColors.errorSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.check_circle_rounded : Icons.warning_rounded,
            color: isPositive ? AppColors.success : AppColors.error,
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: isPositive ? AppColors.success : AppColors.error,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: cs.outline,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: isHighlight ? AppColors.primary : cs.onSurface,
            fontSize: isHighlight ? 22 : 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
