import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/agent.dart';
import '../../core/models/property.dart';
import '../../core/models/service_category.dart';
import '../../services/api_service.dart';
import '../property/property_details_screen.dart';

// ---------- Static data for categories ----------

const _categories = [
  {'icon': Icons.apps, 'label': 'All'},
  {'icon': Icons.home_outlined, 'label': 'Residential'},
  {'icon': Icons.business_outlined, 'label': 'Commercial'},
  {'icon': Icons.diamond_outlined, 'label': 'Luxury'},
  {'icon': Icons.landscape_outlined, 'label': 'Land'},
];

// Icon mapping for service categories
const _serviceIconMap = <String, IconData>{
  'legal': Icons.gavel_outlined,
  'movers': Icons.local_shipping_outlined,
  'moving': Icons.local_shipping_outlined,
  'interior': Icons.chair_outlined,
  'cleaning': Icons.cleaning_services_outlined,
  'plumbing': Icons.plumbing_outlined,
  'electrical': Icons.electrical_services_outlined,
  'painting': Icons.format_paint_outlined,
  'carpentry': Icons.carpenter_outlined,
  'landscaping': Icons.grass_outlined,
  'security': Icons.security_outlined,
  'pest': Icons.bug_report_outlined,
};

class ExploreHubScreen extends StatefulWidget {
  const ExploreHubScreen({super.key});

  @override
  State<ExploreHubScreen> createState() => _ExploreHubScreenState();
}

class _ExploreHubScreenState extends State<ExploreHubScreen> {
  int _selectedTab = 0;
  int _selectedCategory = 0;
  List<Property> _trendingProperties = [];
  List<Agent> _topAgents = [];
  List<ServiceCategory> _serviceCategories = [];
  bool _isLoading = true;

  static const _tabs = ['Properties', 'Commercial', 'Services'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getProperties(limit: 6),
        ApiService.getTopAgents(limit: 5),
        ApiService.getServiceCategories(popular: true),
      ]);
      if (!mounted) return;
      setState(() {
        _trendingProperties = results[0] as List<Property>;
        _topAgents = results[1] as List<Agent>;
        _serviceCategories = results[2] as List<ServiceCategory>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading explore data: $e');
      if (!mounted) return;
      setState(() {
        _trendingProperties = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildSearchBar()),
              SliverToBoxAdapter(child: _buildFeaturedBanner()),
              SliverToBoxAdapter(child: _buildTabRow()),
              SliverToBoxAdapter(child: _buildCategoryFilter()),
              SliverToBoxAdapter(child: _buildMarketInsights()),
              SliverToBoxAdapter(child: _buildTrendingNow()),
              SliverToBoxAdapter(child: _buildPopularServices()),
              SliverToBoxAdapter(child: _buildTopRatedAgents()),
              SliverToBoxAdapter(child: SizedBox(height: 24.h)),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Search Bar ----------

  Widget _buildSearchBar() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surface,
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
      child: Container(
        height: 46.h,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            SizedBox(width: 14.w),
            Icon(Icons.search, color: cs.outline, size: 22.r),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                'Search properties, agents, or area',
                style: TextStyle(
                  color: cs.outline,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Icon(Icons.tune_outlined, color: cs.outline, size: 20.r),
            SizedBox(width: 14.w),
          ],
        ),
      ),
    );
  }

  // ---------- Featured Banner ----------

  Widget _buildFeaturedBanner() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0.h),
      child: Container(
        height: 200.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: cs.surfaceContainerHighest,
                child: Center(
                  child: Icon(Icons.image_outlined, color: cs.outline, size: 48.r),
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
            // Gradient overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
            ),
            // Featured badge
            Positioned(
              top: 14.h,
              left: 14.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  'FEATURED',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            // Content
            Positioned(
              bottom: 16.h,
              left: 16.w,
              right: 16.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pearl Towers',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: AppColors.white60, size: 14.r),
                      SizedBox(width: 4.w),
                      Text(
                        'Downtown, Mogadishu',
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.8),
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Luxury waterfront living with panoramic city views',
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.7),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
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

  // ---------- Tab Row ----------

  Widget _buildTabRow() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0.h),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTab == index;
          return Padding(
            padding: EdgeInsets.only(right: 10.w),
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : cs.surface,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : cs.outlineVariant,
                  ),
                ),
                child: Text(
                  _tabs[index],
                  style: TextStyle(
                    color: isSelected ? AppColors.white : cs.onSurfaceVariant,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ---------- Category Filter ----------

  Widget _buildCategoryFilter() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(top: 18.h),
      child: SizedBox(
        height: 90.h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          itemCount: _categories.length,
          separatorBuilder: (_, __) => SizedBox(width: 16.w),
          itemBuilder: (context, index) {
            final cat = _categories[index];
            final isSelected = _selectedCategory == index;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = index),
              child: Column(
                children: [
                  Container(
                    width: 56.w,
                    height: 56.h,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : cs.surfaceContainerHighest,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : cs.outlineVariant,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        cat['icon'] as IconData,
                        color: isSelected ? AppColors.white : cs.onSurfaceVariant,
                        size: 24.r,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    cat['label'] as String,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : cs.onSurfaceVariant,
                      fontSize: 11.sp,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------- Market Insights ----------

  Widget _buildMarketInsights() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Market Insights',
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Container(
            padding: EdgeInsets.all(18.r),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14.r),
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
                  width: 44.w,
                  height: 44.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.trending_up,
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
                        'Property prices up 12% this quarter',
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Mogadishu real estate market is trending upward',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: cs.outline, size: 22.r),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Trending Now ----------

  Widget _buildTrendingNow() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 0.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trending Now',
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'SEE ALL',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          if (_isLoading)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_trendingProperties.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Center(
                child: Text(
                  'No trending properties',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14.sp),
                ),
              ),
            )
          else
            SizedBox(
              height: 270.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _trendingProperties.length,
                separatorBuilder: (_, __) => SizedBox(width: 14.w),
                itemBuilder: (context, index) {
                  final prop = _trendingProperties[index];
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
      width: 220.w,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                height: 140.h,
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
              Positioned(
                top: 10.h,
                right: 10.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    property.price,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Info
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + Rating
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        property.title,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(Icons.star, color: const Color(0xFFF59E0B), size: 14.r),
                    SizedBox(width: 2.w),
                    Text(
                      property.rating.toString(),
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                // Location
                Text(
                  property.location,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.h),
                // Bed + Bath
                Row(
                  children: [
                    _buildPropertyStat(Icons.bed_outlined, '${property.beds} Bed'),
                    SizedBox(width: 14.w),
                    _buildPropertyStat(Icons.bathtub_outlined, '${property.baths} Bath'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyStat(IconData icon, String value) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: cs.outline, size: 16.r),
        SizedBox(width: 4.w),
        Text(
          value,
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ---------- Popular Services ----------

  IconData _iconForService(String name) {
    final lower = name.toLowerCase();
    for (final entry in _serviceIconMap.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return Icons.miscellaneous_services_outlined;
  }

  Widget _buildPopularServices() {
    final cs = Theme.of(context).colorScheme;
    if (_serviceCategories.isEmpty) return const SizedBox.shrink();

    final colors = [
      (const Color(0xFFEEF2FF), const Color(0xFF3B82F6)),
      (const Color(0xFFFEF3C7), const Color(0xFFF59E0B)),
      (const Color(0xFFFCE7F3), const Color(0xFFEC4899)),
      (const Color(0xFFDCFCE7), const Color(0xFF22C55E)),
      (const Color(0xFFE0E7FF), const Color(0xFF6366F1)),
      (const Color(0xFFFEE2E2), const Color(0xFFEF4444)),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 0.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popular Services',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 14.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 16.h,
              crossAxisSpacing: 16.w,
              childAspectRatio: 1.0,
            ),
            itemCount: _serviceCategories.length.clamp(0, 6),
            itemBuilder: (context, index) {
              final svc = _serviceCategories[index];
              final colorPair = colors[index % colors.length];
              return GestureDetector(
                onTap: () {},
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(14.r),
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44.w,
                        height: 44.h,
                        decoration: BoxDecoration(
                          color: colorPair.$1,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            _iconForService(svc.name),
                            color: colorPair.$2,
                            size: 22.r,
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        svc.name,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------- Top Rated Agents ----------

  Widget _buildTopRatedAgents() {
    final cs = Theme.of(context).colorScheme;
    if (_topAgents.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 0.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Rated Agents',
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'SEE ALL',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          SizedBox(
            height: 110.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _topAgents.length,
              separatorBuilder: (_, __) => SizedBox(width: 16.w),
              itemBuilder: (context, index) {
                final agent = _topAgents[index];
                return GestureDetector(
                  onTap: () {},
                  child: SizedBox(
                    width: 76.w,
                    child: Column(
                      children: [
                        Container(
                          width: 60.w,
                          height: 60.h,
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: cs.shadow.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              agent.initials,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          agent.name.split(' ').first,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 2.h),
                        if (agent.rating > 0)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.star, color: const Color(0xFFF59E0B), size: 12.r),
                              SizedBox(width: 2.w),
                              Text(
                                agent.rating.toString(),
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
