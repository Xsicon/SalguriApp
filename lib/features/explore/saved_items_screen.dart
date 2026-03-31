import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/property.dart';
import '../../services/api_service.dart';

class SavedItemsScreen extends StatefulWidget {
  const SavedItemsScreen({super.key});

  @override
  State<SavedItemsScreen> createState() => _SavedItemsScreenState();
}

class _SavedItemsScreenState extends State<SavedItemsScreen> {
  int _selectedTab = 0;
  List<Property> _savedProperties = [];
  List<String> _collections = [];
  bool _isLoading = true;

  final _tabs = const ['Properties', 'Services', 'Lots', 'Lists'];

  // Demo saved searches
  final _savedSearches = const [
    {'label': '3+ Beds, Hodan', 'icon': Icons.bed_outlined},
    {'label': 'Under \$200k', 'icon': Icons.attach_money},
    {'label': 'Near Beach, 2+ Bath', 'icon': Icons.bathtub_outlined},
    {'label': 'New Construction', 'icon': Icons.construction},
  ];

  static const _collectionIcons = <String, IconData>{
    'default': Icons.favorite_outline,
    'To Visit': Icons.location_on_outlined,
    'Top Picks': Icons.star_outline,
    'Investment': Icons.trending_up,
  };

  @override
  void initState() {
    super.initState();
    _loadSavedItems();
  }

  Future<void> _loadSavedItems() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getSavedItems(),
        ApiService.getSavedCollections(),
      ]);
      final items = results[0] as List<Map<String, dynamic>>;
      final collections = results[1] as List<String>;

      final properties = items
          .where((item) => item['property'] != null)
          .map((item) => Property.fromJson(item['property']))
          .toList();

      if (!mounted) return;
      setState(() {
        _savedProperties = properties;
        _collections = collections;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading saved items: $e');
      if (!mounted) return;
      setState(() {
        _savedProperties = [];
        _collections = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _unsaveProperty(Property property) async {
    try {
      await ApiService.unsaveItem(property.id);
      setState(() {
        _savedProperties.removeWhere((p) => p.id == property.id);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from saved items')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Divider(height: 1, color: cs.surfaceContainerHighest),
            _buildTabRow(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _loadSavedItems,
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(child: _buildCollectionsSection()),
                          SliverToBoxAdapter(child: _buildPropertyGrid()),
                          SliverToBoxAdapter(
                              child: _buildRecentSavedSearches()),
                          const SliverToBoxAdapter(child: SizedBox(height: 24)),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- App Bar ----------

  Widget _buildAppBar() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back, color: cs.onSurface),
            iconSize: 24,
          ),
          Expanded(
            child: Text(
              'Saved Items',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.settings_outlined, color: cs.onSurface),
            iconSize: 24,
          ),
        ],
      ),
    );
  }

  // ---------- Tab Row ----------

  Widget _buildTabRow() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: List.generate(_tabs.length, (index) {
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
                      _tabs[index],
                      style: TextStyle(
                        color: isSelected ? AppColors.white : cs.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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

  // ---------- Collections Section ----------

  Widget _buildCollectionsSection() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Collections',
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'SEE ALL',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCreateListCard(),
                const SizedBox(width: 12),
                ..._collections.map((name) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _buildCollectionCard(
                        name: name,
                        count: _savedProperties.length,
                        icon: _collectionIcons[name] ?? Icons.folder_outlined,
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateListCard() {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create List',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionCard({
    required String name,
    required int count,
    required IconData icon,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 120,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$count items',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Property Grid ----------

  Widget _buildPropertyGrid() {
    final cs = Theme.of(context).colorScheme;
    if (_savedProperties.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.favorite_border, color: cs.outline, size: 48),
              const SizedBox(height: 12),
              Text(
                'No saved properties yet',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_savedProperties.length} Saved Properties',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.58,
            ),
            itemCount: _savedProperties.length,
            itemBuilder: (context, index) {
              return _buildSavedPropertyCard(_savedProperties[index], index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSavedPropertyCard(Property property, int index) {
    final cs = Theme.of(context).colorScheme;
    // Alternate button labels for variety
    final buttonLabels = ['Request', 'Schedule', 'Notify', 'Details', 'Request', 'Schedule'];
    final buttonLabel = buttonLabels[index % buttonLabels.length];

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
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
          // Image with heart icon
          Stack(
            children: [
              SizedBox(
                height: 110,
                width: double.infinity,
                child: Image.network(
                  property.images.isNotEmpty ? property.images.first : '',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: cs.surfaceContainerHighest,
                    child: Center(
                      child: Icon(Icons.home_outlined,
                          color: cs.outline, size: 32),
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
              // Heart / unsave icon
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _unsaveProperty(property),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Color(0xFFEF4444),
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Info section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price
                  Text(
                    property.price,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Title
                  Text(
                    property.title,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Location
                  Text(
                    property.location,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Bed / Bath / Sqft
                  Row(
                    children: [
                      Icon(Icons.bed_outlined, color: cs.outline, size: 13),
                      const SizedBox(width: 2),
                      Text(
                        '${property.beds}',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.bathtub_outlined, color: cs.outline, size: 13),
                      const SizedBox(width: 2),
                      Text(
                        '${property.baths}',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.square_foot_outlined,
                          color: cs.outline, size: 13),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          '${property.sqft}',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Action button
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.zero,
                        elevation: 0,
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text(buttonLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Recent Saved Searches ----------

  Widget _buildRecentSavedSearches() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Saved Searches',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _savedSearches.map((search) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      search['icon'] as IconData,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      search['label'] as String,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.close,
                      color: cs.outline,
                      size: 14,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
