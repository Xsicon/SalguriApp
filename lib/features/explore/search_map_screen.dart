import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back, color: cs.onSurface),
            iconSize: 24,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              style: TextStyle(fontSize: 15, color: cs.onSurface),
              decoration: InputDecoration(
                hintText: 'Search properties, agents, or area',
                hintStyle: TextStyle(color: cs.outline, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: cs.outline, size: 22),
                suffixIcon: Icon(
                  Icons.tune_outlined,
                  color: cs.onSurfaceVariant,
                  size: 22,
                ),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
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
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        itemCount: _locationTags.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: index == 0
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : cs.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: index == 0 ? AppColors.primary : cs.outlineVariant,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: index == 0 ? AppColors.primary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  _locationTags[index],
                  style: TextStyle(
                    color: index == 0 ? AppColors.primary : cs.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: index == 0 ? FontWeight.w600 : FontWeight.w500,
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
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  // ---------- Map Section ----------

  Widget _buildMapSection() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 320,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
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
          onTap: (_, _) => setState(() => _selectedProperty = null),
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
                width: isSelected ? 50 : 40,
                height: isSelected ? 50 : 40,
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
                    child: const Center(
                      child: Icon(Icons.home, color: AppColors.white, size: 18),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SizedBox(
        height: 80,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _categories.length,
          separatorBuilder: (_, _) => const SizedBox(width: 14),
          itemBuilder: (context, index) {
            final cat = _categories[index];
            final isSelected = _selectedCategoryIndex == index;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategoryIndex = index),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
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
                        color: isSelected
                            ? AppColors.white
                            : cs.onSurfaceVariant,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat['label'] as String,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : cs.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
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
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        itemCount: _filterLabels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _filterLabels[index],
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: cs.onSurfaceVariant,
                  size: 18,
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
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Text(
              '${_properties.length} Properties Found',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _properties.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
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
        width: 240,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
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
              height: 100,
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
                      size: 32,
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
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        property.price,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.favorite_border, color: cs.outline, size: 18),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${property.title}, ${property.location}',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.bed_outlined, color: cs.outline, size: 14),
                      const SizedBox(width: 3),
                      Text(
                        '${property.beds}',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.bathtub_outlined, color: cs.outline, size: 14),
                      const SizedBox(width: 3),
                      Text(
                        '${property.baths}',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.square_foot_outlined,
                        color: cs.outline,
                        size: 14,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${property.sqft} sqft',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
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

  // ---------- Sponsored Listings ----------

  Widget _buildSponsoredListings() {
    final cs = Theme.of(context).colorScheme;
    // Use top-rated properties as featured/sponsored listings
    final featured = _properties.where((p) => p.rating >= 4.5).take(2).toList();
    if (featured.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Featured Listings',
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'TOP',
                  style: TextStyle(
                    color: Color(0xFFF59E0B),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...featured.map(
            (prop) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDE68A)),
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
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: prop.images.isNotEmpty
                          ? Image.network(
                              prop.images.first,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: cs.surfaceContainerHighest,
                                child: Icon(
                                  Icons.home_outlined,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                              ),
                            )
                          : Container(
                              color: cs.surfaceContainerHighest,
                              child: Icon(
                                Icons.home_outlined,
                                color: AppColors.primary,
                                size: 28,
                              ),
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prop.title,
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            prop.location,
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '${prop.beds} Bed',
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${prop.baths} Bath',
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      prop.price,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
    final avgRating = (_marketStats['average_rating'] ?? 0.0).toStringAsFixed(
      1,
    );
    final avgSqft = _marketStats['average_sqft'] ?? 0;
    final avgBeds = _marketStats['average_beds'] ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Market Stats',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
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
                _buildStatRow(
                  'Listed Properties',
                  '$total',
                  Icons.home_outlined,
                  AppColors.primary,
                ),
                Divider(height: 24, color: cs.outlineVariant),
                _buildStatRow(
                  'For Rent',
                  '$forRent',
                  Icons.vpn_key_outlined,
                  const Color(0xFF22C55E),
                ),
                Divider(height: 24, color: cs.outlineVariant),
                _buildStatRow(
                  'For Sale',
                  '$forSale',
                  Icons.sell_outlined,
                  const Color(0xFFF59E0B),
                ),
                Divider(height: 24, color: cs.outlineVariant),
                _buildStatRow(
                  'Avg Rating',
                  avgRating,
                  Icons.star_outline,
                  const Color(0xFFF59E0B),
                ),
                Divider(height: 24, color: cs.outlineVariant),
                _buildStatRow(
                  'Avg Size',
                  '$avgSqft sqft',
                  Icons.square_foot,
                  AppColors.primary,
                ),
                Divider(height: 24, color: cs.outlineVariant),
                _buildStatRow(
                  'Avg Beds',
                  '$avgBeds',
                  Icons.bed_outlined,
                  const Color(0xFF6366F1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: Icon(icon, color: iconColor, size: 20)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 16,
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
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
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'SEE ALL',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._topAgents.map((agent) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
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
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          agent.initials,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            agent.name,
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              if (agent.rating > 0) ...[
                                const Icon(
                                  Icons.star,
                                  color: Color(0xFFF59E0B),
                                  size: 14,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  agent.rating.toString(),
                                  style: TextStyle(
                                    color: cs.onSurface,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Text(
                                agent.deals > 0
                                    ? '${agent.deals} deals'
                                    : '${agent.propertyCount} properties',
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 12,
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
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trusted Services',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(display.length, (i) {
              final svc = display[i];
              final colorPair = _svcColors[i % _svcColors.length];
              final lower = svc.name.toLowerCase();
              IconData icon = Icons.miscellaneous_services_outlined;
              for (final entry in _svcIconMap.entries) {
                if (lower.contains(entry.key)) {
                  icon = entry.value;
                  break;
                }
              }
              return Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colorPair.$1,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(icon, color: colorPair.$2, size: 24),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    svc.name,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 11,
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
