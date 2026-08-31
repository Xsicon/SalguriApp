import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/agent.dart';
import '../../core/models/property.dart';
import '../../core/models/service_category.dart';
import '../../services/api_service.dart';

class SearchMapScreen extends StatefulWidget {
  const SearchMapScreen({super.key});

  @override
  State<SearchMapScreen> createState() => _SearchMapScreenState();
}

class _SearchMapScreenState extends State<SearchMapScreen> {
  final _searchController = TextEditingController();
  final _mapController = MapController();
  final _scrollController = ScrollController();

  List<Property> _properties = [];
  List<Agent> _topAgents = [];
  List<ServiceCategory> _serviceCategories = [];
  Map<String, dynamic> _marketStats = {};
  bool _isLoading = true;
  int _selectedCategoryIndex = 0;
  Property? _selectedProperty;

  // Mogadishu center
  static const _defaultCenter = LatLng(2.0469, 45.3182);

  final _locationTags = const [
    'Kalkoonle',
    'Saqiish',
    'Kulaa',
    'Kulaa Tari...',
    'Hodan',
  ];

  final _categories = const [
    {'icon': Icons.grid_view, 'label': 'All'},
    {'icon': Icons.terrain, 'label': 'Land'},
    {'icon': Icons.home_outlined, 'label': 'Residential'},
    {'icon': Icons.apartment, 'label': 'Apartment'},
    {'icon': Icons.business, 'label': 'Commercial'},
    {'icon': Icons.villa, 'label': 'Villa'},
  ];

  final _filterLabels = const [
    'Price Range',
    'Bedrooms',
    'Property Size',
    'Public',
  ];

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getAllProperties(),
        ApiService.getTopAgents(limit: 5),
        ApiService.getServiceCategories(popular: true),
        ApiService.getMarketStats(),
      ]);
      if (!mounted) return;
      setState(() {
        _properties = results[0] as List<Property>;
        _topAgents = results[1] as List<Agent>;
        _serviceCategories = results[2] as List<ServiceCategory>;
        _marketStats = results[3] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading properties: $e');
      if (!mounted) return;
      setState(() {
        _properties = [];
        _isLoading = false;
      });
    }
  }

  void _onSearch(String query) {
    // Search filtering could be implemented here
    debugPrint('Search: $query');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildLocationTags(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _buildMapAndContent(),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Search Bar ----------

  Widget _buildSearchBar() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0.h),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back, color: cs.onSurface),
            iconSize: 24.r,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 40.w, minHeight: 40.h),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              style: TextStyle(fontSize: 15.sp, color: cs.onSurface),
              decoration: InputDecoration(
                hintText: 'Search properties, agents, or area',
                hintStyle: TextStyle(color: cs.outline, fontSize: 14.sp),
                prefixIcon: Icon(Icons.search, color: cs.outline, size: 22.r),
                suffixIcon: Icon(Icons.tune_outlined,
                    color: cs.onSurfaceVariant, size: 22.r),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Location Tags ----------

  Widget _buildLocationTags() {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 48.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 6.h),
        itemCount: _locationTags.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: index == 0
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : cs.surface,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: index == 0 ? AppColors.primary : cs.outlineVariant,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14.r,
                  color: index == 0 ? AppColors.primary : cs.onSurfaceVariant,
                ),
                SizedBox(width: 4.w),
                Text(
                  _locationTags[index],
                  style: TextStyle(
                    color:
                        index == 0 ? AppColors.primary : cs.onSurfaceVariant,
                    fontSize: 13.sp,
                    fontWeight:
                        index == 0 ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------- Map and Scrollable Content ----------

  Widget _buildMapAndContent() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(child: _buildMapSection()),
        SliverToBoxAdapter(child: _buildCategoryIcons()),
        SliverToBoxAdapter(child: _buildFilterBar()),
        SliverToBoxAdapter(child: _buildOverlayCards()),
        SliverToBoxAdapter(child: _buildSponsoredListings()),
        SliverToBoxAdapter(child: _buildMarketStats()),
        SliverToBoxAdapter(child: _buildTopLocalAgents()),
        SliverToBoxAdapter(child: _buildTrustedServices()),
        SliverToBoxAdapter(child: SizedBox(height: 24.h)),
      ],
    );
  }

  // ---------- Map Section ----------

  Widget _buildMapSection() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 320.h,
      margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _defaultCenter,
          initialZoom: 13.0,
          onTap: (_, __) => setState(() => _selectedProperty = null),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.salguri.app',
          ),
          MarkerLayer(
            markers: _properties.map((property) {
              final isSelected = _selectedProperty?.id == property.id;
              return Marker(
                point: LatLng(property.latitude, property.longitude),
                width: isSelected ? 50.w : 40.w,
                height: isSelected ? 50.h : 40.h,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedProperty = property),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.white,
                        width: isSelected ? 3 : 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.home,
                        color: AppColors.white,
                        size: 18.r,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------- Category Icons ----------

  Widget _buildCategoryIcons() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0.h),
      child: SizedBox(
        height: 80.h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _categories.length,
          separatorBuilder: (_, __) => SizedBox(width: 14.w),
          itemBuilder: (context, index) {
            final cat = _categories[index];
            final isSelected = _selectedCategoryIndex == index;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategoryIndex = index),
              child: Column(
                children: [
                  Container(
                    width: 52.w,
                    height: 52.h,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : cs.surfaceContainerHighest,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : cs.outlineVariant,
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
                  SizedBox(height: 6.h),
                  Text(
                    cat['label'] as String,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : cs.onSurfaceVariant,
                      fontSize: 11.sp,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
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

  // ---------- Filter Bar ----------

  Widget _buildFilterBar() {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 44.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 4.h),
        itemCount: _filterLabels.length,
        separatorBuilder: (_, __) => SizedBox(width: 10.w),
        itemBuilder: (context, index) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _filterLabels[index],
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 4.w),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: cs.onSurfaceVariant,
                  size: 18.r,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------- Overlay Property Cards ----------

  Widget _buildOverlayCards() {
    final cs = Theme.of(context).colorScheme;
    if (_properties.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 0.h, 20.w, 10.h),
            child: Text(
              '${_properties.length} Properties Found',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            height: 180.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: _properties.length,
              separatorBuilder: (_, __) => SizedBox(width: 12.w),
              itemBuilder: (context, index) {
                return _buildOverlayPropertyCard(_properties[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayPropertyCard(Property property) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = _selectedProperty?.id == property.id;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedProperty = property);
        _mapController.move(
          LatLng(property.latitude, property.longitude),
          14.0,
        );
      },
      child: Container(
        width: 240.w,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : cs.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
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
            // Image
            SizedBox(
              height: 100.h,
              width: double.infinity,
              child: Image.network(
                property.images.isNotEmpty ? property.images.first : '',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: cs.surfaceContainerHighest,
                  child: Center(
                    child: Icon(Icons.home_outlined,
                        color: cs.outline, size: 32.r),
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
            // Info
            Padding(
              padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        property.price,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.favorite_border,
                          color: cs.outline, size: 18.r),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    '${property.title}, ${property.location}',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(Icons.bed_outlined, color: cs.outline, size: 14.r),
                      SizedBox(width: 3.w),
                      Text(
                        '${property.beds}',
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 12.sp),
                      ),
                      SizedBox(width: 10.w),
                      Icon(Icons.bathtub_outlined,
                          color: cs.outline, size: 14.r),
                      SizedBox(width: 3.w),
                      Text(
                        '${property.baths}',
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 12.sp),
                      ),
                      SizedBox(width: 10.w),
                      Icon(Icons.square_foot_outlined,
                          color: cs.outline, size: 14.r),
                      SizedBox(width: 3.w),
                      Text(
                        '${property.sqft} sqft',
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 12.sp),
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

  // ---------- Sponsored Listings ----------

  Widget _buildSponsoredListings() {
    final cs = Theme.of(context).colorScheme;
    // Use top-rated properties as featured/sponsored listings
    final featured = _properties.where((p) => p.rating >= 4.5).take(2).toList();
    if (featured.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 0.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Featured Listings',
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  'TOP',
                  style: TextStyle(
                    color: const Color(0xFFF59E0B),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          ...featured.map((prop) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Container(
                  padding: EdgeInsets.all(14.r),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: const Color(0xFFFDE68A),
                    ),
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
                        width: 56.w,
                        height: 56.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: prop.images.isNotEmpty
                            ? Image.network(
                                prop.images.first,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  color: cs.surfaceContainerHighest,
                                  child: Icon(Icons.home_outlined,
                                      color: AppColors.primary, size: 28.r),
                                ),
                              )
                            : Container(
                                color: cs.surfaceContainerHighest,
                                child: Icon(Icons.home_outlined,
                                    color: AppColors.primary, size: 28.r),
                              ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prop.title,
                              style: TextStyle(
                                color: cs.onSurface,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              prop.location,
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 12.sp,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                Text(
                                  '${prop.beds} Bed',
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 11.sp,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  '${prop.baths} Bath',
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 11.sp,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        prop.price,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // ---------- Market Stats ----------

  Widget _buildMarketStats() {
    final cs = Theme.of(context).colorScheme;
    final total = _marketStats['total_properties'] ?? _properties.length;
    final forRent = _marketStats['for_rent'] ?? 0;
    final forSale = _marketStats['for_sale'] ?? 0;
    final avgRating = (_marketStats['average_rating'] ?? 0.0).toStringAsFixed(1);
    final avgSqft = _marketStats['average_sqft'] ?? 0;
    final avgBeds = _marketStats['average_beds'] ?? 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 0.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Market Stats',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
            ),
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
            child: Column(
              children: [
                _buildStatRow('Listed Properties', '$total', Icons.home_outlined,
                    AppColors.primary),
                Divider(height: 24.h, color: cs.outlineVariant),
                _buildStatRow('For Rent', '$forRent', Icons.vpn_key_outlined,
                    const Color(0xFF22C55E)),
                Divider(height: 24.h, color: cs.outlineVariant),
                _buildStatRow('For Sale', '$forSale', Icons.sell_outlined,
                    const Color(0xFFF59E0B)),
                Divider(height: 24.h, color: cs.outlineVariant),
                _buildStatRow('Avg Rating', avgRating, Icons.star_outline,
                    const Color(0xFFF59E0B)),
                Divider(height: 24.h, color: cs.outlineVariant),
                _buildStatRow('Avg Size', '$avgSqft sqft', Icons.square_foot,
                    AppColors.primary),
                Divider(height: 24.h, color: cs.outlineVariant),
                _buildStatRow('Avg Beds', '$avgBeds', Icons.bed_outlined,
                    const Color(0xFF6366F1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
      String label, String value, IconData icon, Color iconColor) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 40.w,
          height: 40.h,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Center(child: Icon(icon, color: iconColor, size: 20.r)),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ---------- Top Local Agents ----------

  Widget _buildTopLocalAgents() {
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
                'Top Local Agents',
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'SEE ALL',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          ..._topAgents.map((agent) {
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Container(
                padding: EdgeInsets.all(14.r),
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
                      width: 48.w,
                      height: 48.h,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          agent.initials,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            agent.name,
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Row(
                            children: [
                              if (agent.rating > 0) ...[
                                Icon(Icons.star,
                                    color: const Color(0xFFF59E0B), size: 14.r),
                                SizedBox(width: 3.w),
                                Text(
                                  agent.rating.toString(),
                                  style: TextStyle(
                                    color: cs.onSurface,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                              ],
                              Text(
                                agent.deals > 0 ? '${agent.deals} deals' : '${agent.propertyCount} properties',
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 14.w, vertical: 8.h),
                        textStyle: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('Contact'),
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

  // ---------- Trusted Services ----------

  static const _svcIconMap = <String, IconData>{
    'legal': Icons.gavel,
    'finance': Icons.account_balance,
    'photo': Icons.camera_alt_outlined,
    'repair': Icons.build_outlined,
    'clean': Icons.cleaning_services_outlined,
    'plumb': Icons.plumbing_outlined,
    'electr': Icons.electrical_services_outlined,
    'mov': Icons.local_shipping_outlined,
    'paint': Icons.format_paint_outlined,
    'secur': Icons.security_outlined,
  };

  static const _svcColors = [
    (Color(0xFFEEF2FF), Color(0xFF3B82F6)),
    (Color(0xFFDCFCE7), Color(0xFF22C55E)),
    (Color(0xFFFEE2E2), Color(0xFFEF4444)),
    (Color(0xFFFEF3C7), Color(0xFFF59E0B)),
  ];

  Widget _buildTrustedServices() {
    final cs = Theme.of(context).colorScheme;
    final display = _serviceCategories.take(4).toList();
    if (display.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 0.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trusted Services',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(display.length, (i) {
              final svc = display[i];
              final colorPair = _svcColors[i % _svcColors.length];
              final lower = svc.name.toLowerCase();
              IconData icon = Icons.miscellaneous_services_outlined;
              for (final entry in _svcIconMap.entries) {
                if (lower.contains(entry.key)) { icon = entry.value; break; }
              }
              return Column(
                children: [
                  Container(
                    width: 56.w,
                    height: 56.h,
                    decoration: BoxDecoration(
                      color: colorPair.$1,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(icon, color: colorPair.$2, size: 24.r),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    svc.name,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
