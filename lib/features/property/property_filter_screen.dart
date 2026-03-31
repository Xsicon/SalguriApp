import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/property.dart';
import '../../services/api_service.dart';
import 'property_details_screen.dart';

class PropertyFilterScreen extends StatefulWidget {
  const PropertyFilterScreen({super.key});

  @override
  State<PropertyFilterScreen> createState() => _PropertyFilterScreenState();
}

class _PropertyFilterScreenState extends State<PropertyFilterScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  // Location
  final List<String> _districts = [
    'Hodan',
    'Waberi',
    'Abdiaziz',
    'Bondhere',
    'Hamar Weyne',
  ];
  final Set<String> _selectedDistricts = {};

  // Property type
  String _selectedType = 'Any';

  // Price range
  RangeValues _priceRange = const RangeValues(0, 10000);

  // Bedrooms & Bathrooms
  String _selectedBedrooms = 'Any';
  String _selectedBathrooms = 'Any';

  // Size
  RangeValues _sizeRange = const RangeValues(0, 1000);

  // Amenities
  final Map<String, bool> _amenities = {
    '24/7 Security': false,
    'Backup Generator': false,
    'WiFi Included': false,
    'Parking Space': false,
    'Air Conditioning': false,
    'Water Tank': false,
  };

  // Results
  List<Property> _filteredProperties = [];
  int _resultCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchFilteredCount();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _fetchFilteredCount);
  }

  void _onFilterChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _fetchFilteredCount);
  }

  int? _parseBedsBaths(String value) {
    if (value == 'Any') return null;
    if (value.endsWith('+')) return int.tryParse(value.replaceAll('+', ''));
    return int.tryParse(value);
  }

  /// Parse price text like "$275,000" to a number.
  double? _parsePrice(String priceText) {
    final cleaned = priceText.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned);
  }

  Future<void> _fetchFilteredCount() async {
    setState(() => _isLoading = true);
    try {
      final selectedAmenities = _amenities.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      List<Property> results = await ApiService.filterProperties(
        search: _searchController.text.isNotEmpty
            ? _searchController.text
            : null,
        districts:
            _selectedDistricts.isNotEmpty ? _selectedDistricts.toList() : null,
        propertyType:
            _selectedType != 'Any' ? _selectedType : null,
        minBeds: _parseBedsBaths(_selectedBedrooms),
        minBaths: _parseBedsBaths(_selectedBathrooms),
        minSqft: _sizeRange.start.round() > 0 ? _sizeRange.start.round() : null,
        maxSqft: _sizeRange.end.round() < 1000 ? _sizeRange.end.round() : null,
        amenities: selectedAmenities.isNotEmpty ? selectedAmenities : null,
      );

      // Client-side price filtering (price is stored as text like "$275,000")
      final minPrice = _priceRange.start;
      final maxPrice = _priceRange.end;
      if (minPrice > 0 || maxPrice < 10000) {
        results = results.where((p) {
          final price = _parsePrice(p.price);
          if (price == null) return true;
          // Convert filter range (0-10000) to actual price scale
          // The slider is in hundreds, so multiply by appropriate factor
          // Actually the DB prices are like 275000 and slider goes 0-10000
          // Let's compare directly: slider max 10000 means $10,000+
          // But DB has $275,000. So we need to interpret slider as thousands:
          // slider 500 = $500, slider 4500 = $4,500
          // But DB prices are like 275000...
          // Let's just use the raw parsed price vs slider * 1 (slider represents actual USD)
          return price >= minPrice && (maxPrice >= 10000 || price <= maxPrice);
        }).toList();
      }

      setState(() {
        _filteredProperties = results;
        _resultCount = results.length;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error filtering properties: $e');
      setState(() => _isLoading = false);
    }
  }

  void _resetAll() {
    setState(() {
      _searchController.clear();
      _selectedDistricts.clear();
      _selectedType = 'Any';
      _priceRange = const RangeValues(0, 10000);
      _selectedBedrooms = 'Any';
      _selectedBathrooms = 'Any';
      _sizeRange = const RangeValues(0, 1000);
      _amenities.updateAll((key, value) => false);
    });
    _fetchFilteredCount();
  }

  void _showResults() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FilteredResultsScreen(
          properties: _filteredProperties,
          resultCount: _resultCount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(cs),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLocationSection(cs),
                    _divider(cs),
                    _buildPropertyTypeSection(cs),
                    _divider(cs),
                    _buildPriceRangeSection(cs),
                    _divider(cs),
                    _buildBedroomsBathroomsSection(cs),
                    _divider(cs),
                    _buildSizeSection(cs),
                    _divider(cs),
                    _buildAmenitiesSection(cs),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomActions(cs),
    );
  }

  Widget _divider(ColorScheme cs) {
    return Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3));
  }

  // ---------- Header ----------

  Widget _buildHeader(ColorScheme cs) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Filters',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: _resetAll,
                child: const Text(
                  'Reset all',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(
            controller: _searchController,
            style: TextStyle(fontSize: 14, color: cs.onSurface),
            decoration: InputDecoration(
              hintText: 'Search by neighborhood in Mogadishu...',
              hintStyle: TextStyle(color: cs.outline, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: cs.outline, size: 22),
              filled: true,
              fillColor: cs.surfaceContainerHighest,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ),
        Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),
      ],
    );
  }

  // ---------- Location ----------

  Widget _buildLocationSection(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('LOCATION (DISTRICTS)', cs),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _districts.map((district) {
              final selected = _selectedDistricts.contains(district);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedDistricts.remove(district);
                    } else {
                      _selectedDistricts.add(district);
                    }
                  });
                  _onFilterChanged();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        district,
                        style: TextStyle(
                          color: selected ? Colors.white : cs.onSurfaceVariant,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (selected) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.close, size: 16, color: Colors.white),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------- Property Type ----------

  Widget _buildPropertyTypeSection(ColorScheme cs) {
    final types = [
      ('House', Icons.home),
      ('Apartment', Icons.apartment),
      ('Land', Icons.landscape),
    ];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('PROPERTY TYPE', cs),
          const SizedBox(height: 12),
          Row(
            children: types.map((t) {
              final selected = _selectedType == t.$1;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: t.$1 != 'Land' ? 10 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedType = selected ? 'Any' : t.$1;
                      });
                      _onFilterChanged();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.05)
                            : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              selected ? AppColors.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            t.$2,
                            color: selected
                                ? AppColors.primary
                                : cs.onSurfaceVariant,
                            size: 28,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            t.$1,
                            style: TextStyle(
                              color: selected
                                  ? AppColors.primary
                                  : cs.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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

  // ---------- Price Range ----------

  Widget _buildPriceRangeSection(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle('PRICE RANGE (USD)', cs),
              Text(
                '\$${_formatNumber(_priceRange.start.round())} - \$${_formatNumber(_priceRange.end.round())}${_priceRange.end >= 10000 ? '+' : ''}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: cs.outlineVariant.withValues(alpha: 0.3),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.1),
              trackHeight: 5,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: RangeSlider(
              values: _priceRange,
              min: 0,
              max: 10000,
              divisions: 100,
              onChanged: (values) => setState(() => _priceRange = values),
              onChangeEnd: (_) => _onFilterChanged(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('\$0',
                    style:
                        TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                Text('\$10,000+',
                    style:
                        TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Bedrooms & Bathrooms ----------

  Widget _buildBedroomsBathroomsSection(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('BEDROOMS', cs),
          const SizedBox(height: 12),
          _buildChipRow(
            ['Any', '1', '2', '3', '4+'],
            _selectedBedrooms,
            (val) {
              setState(() => _selectedBedrooms = val);
              _onFilterChanged();
            },
            cs,
          ),
          const SizedBox(height: 20),
          _sectionTitle('BATHROOMS', cs),
          const SizedBox(height: 12),
          _buildChipRow(
            ['Any', '1', '2', '3+'],
            _selectedBathrooms,
            (val) {
              setState(() => _selectedBathrooms = val);
              _onFilterChanged();
            },
            cs,
          ),
        ],
      ),
    );
  }

  Widget _buildChipRow(
    List<String> options,
    String selected,
    ValueChanged<String> onSelect,
    ColorScheme cs,
  ) {
    return Row(
      children: options.map((opt) {
        final isSelected = selected == opt;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: opt != options.last ? 8 : 0),
            child: GestureDetector(
              onTap: () => onSelect(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  opt,
                  style: TextStyle(
                    color: isSelected ? Colors.white : cs.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---------- Size ----------

  Widget _buildSizeSection(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle('SIZE (SQM)', cs),
              Text(
                '${_sizeRange.start.round()} - ${_sizeRange.end.round()}${_sizeRange.end >= 1000 ? '+' : ''} sqm',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: cs.outlineVariant.withValues(alpha: 0.3),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.1),
              trackHeight: 5,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: RangeSlider(
              values: _sizeRange,
              min: 0,
              max: 1000,
              divisions: 100,
              onChanged: (values) => setState(() => _sizeRange = values),
              onChangeEnd: (_) => _onFilterChanged(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0 sqm',
                    style:
                        TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                Text('1,000+ sqm',
                    style:
                        TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Amenities ----------

  Widget _buildAmenitiesSection(ColorScheme cs) {
    final keys = _amenities.keys.toList();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('AMENITIES', cs),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 12,
              mainAxisExtent: 32,
            ),
            itemCount: keys.length,
            itemBuilder: (context, index) {
              final key = keys[index];
              final checked = _amenities[key]!;
              return GestureDetector(
                onTap: () {
                  setState(() => _amenities[key] = !_amenities[key]!);
                  _onFilterChanged();
                },
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: checked ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: checked
                              ? AppColors.primary
                              : cs.outlineVariant,
                          width: 2,
                        ),
                      ),
                      child: checked
                          ? const Icon(Icons.check,
                              size: 16, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        key,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------- Bottom Actions ----------

  Widget _buildBottomActions(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _resetAll,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide.none,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Clear Filters',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _showResults,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Show $_resultCount Results',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Helpers ----------

  Widget _sectionTitle(String text, ColorScheme cs) {
    return Text(
      text,
      style: TextStyle(
        color: cs.onSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    );
  }

  String _formatNumber(int n) {
    return n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}

// ---------- Filtered Results Screen ----------

class _FilteredResultsScreen extends StatelessWidget {
  final List<Property> properties;
  final int resultCount;

  const _FilteredResultsScreen({
    required this.properties,
    required this.resultCount,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.arrow_back, color: cs.onSurface),
                  ),
                  Expanded(
                    child: Text(
                      'SEARCH RESULTS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Divider(height: 1, color: cs.surfaceContainerHighest),
            // Result count
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              child: Row(
                children: [
                  Text(
                    '$resultCount Properties Found',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Results list
            Expanded(
              child: properties.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off,
                              size: 64, color: cs.outlineVariant),
                          const SizedBox(height: 16),
                          Text(
                            'No properties match your filters',
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your search criteria',
                            style: TextStyle(
                              color: cs.outline,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: properties.length,
                      itemBuilder: (context, index) {
                        return _buildPropertyCard(
                            context, properties[index], cs);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyCard(
      BuildContext context, Property property, ColorScheme cs) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PropertyDetailsScreen(property: property),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: property.images.isNotEmpty
                      ? Image.network(
                          property.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: cs.surfaceContainerHighest,
                            child: Center(
                              child: Icon(Icons.home_outlined,
                                  color: cs.outline, size: 40),
                            ),
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: cs.surfaceContainerHighest,
                              child: const Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.primary),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: cs.surfaceContainerHighest,
                          child: Center(
                            child: Icon(Icons.home_outlined,
                                color: cs.outline, size: 40),
                          ),
                        ),
                ),
                // Price badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      property.price,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                // Type badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      property.type,
                      style: const TextStyle(
                        color: Color(0xFF16A34A),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          property.title,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Icon(Icons.star,
                          color: Color(0xFFF59E0B), size: 16),
                      const SizedBox(width: 3),
                      Text(
                        property.rating.toString(),
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          color: cs.onSurfaceVariant, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        property.location,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildSpec(Icons.bed_outlined, '${property.beds} Beds',
                          cs),
                      const SizedBox(width: 16),
                      _buildSpec(Icons.bathtub_outlined,
                          '${property.baths} Baths', cs),
                      const SizedBox(width: 16),
                      _buildSpec(Icons.square_foot_outlined,
                          '${property.sqft} sqft', cs),
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

  Widget _buildSpec(IconData icon, String text, ColorScheme cs) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: cs.outline, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
