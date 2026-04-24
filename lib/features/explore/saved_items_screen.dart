import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/property.dart';
import '../../core/models/service_request.dart';
import '../../services/api_service.dart';

class SavedItemsScreen extends StatefulWidget {
  const SavedItemsScreen({super.key});

  @override
  State<SavedItemsScreen> createState() => _SavedItemsScreenState();
}

class _SavedItemsScreenState extends State<SavedItemsScreen> {
  int _selectedTab = 0;
  List<Property> _savedProperties = [];
  List<Property> _savedLots = [];
  List<ServiceRequest> _serviceRequests = [];
  List<String> _collections = [];
  Map<String, int> _collectionCounts = {};
  bool _isLoading = true;

  static const _collectionIcons = <String, IconData>{
    'default': Icons.favorite_outline,
    'To Visit': Icons.location_on_outlined,
    'Top Picks': Icons.star_outline,
    'Investment': Icons.trending_up,
  };

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getSavedItems(),
        ApiService.getSavedCollections(),
        ApiService.getActiveServiceRequests(),
      ]);

      final items = results[0] as List<Map<String, dynamic>>;
      final collections = results[1] as List<String>;
      final services = results[2] as List<ServiceRequest>;

      final allProperties = items
          .where((item) => item['property'] != null)
          .map((item) => Property.fromJson(item['property']))
          .toList();

      final properties = allProperties
          .where((p) => p.type.toLowerCase() != 'land')
          .toList();
      final lots = allProperties
          .where((p) => p.type.toLowerCase() == 'land')
          .toList();

      // Build collection counts
      final counts = <String, int>{
        for (final c in collections) c: 0,
      };
      for (final item in items) {
        // Try both possible key names
        final col = (item['collection'] ?? item['Collection'])?.toString() ?? 'default';
        counts[col] = (counts[col] ?? 0) + 1;
      }
      debugPrint('Collections: $collections');
      debugPrint('Items collection fields: ${items.map((i) => i['collection'] ?? i['Collection']).toList()}');
      debugPrint('Counts: $counts');

      if (!mounted) return;
      setState(() {
        _savedProperties = properties;
        _savedLots = lots;
        _serviceRequests = services;
        _collections = collections;
        _collectionCounts = counts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading saved items: $e');
      if (!mounted) return;
      setState(() {
        _savedProperties = [];
        _savedLots = [];
        _serviceRequests = [];
        _collections = [];
        _collectionCounts = {};
        _isLoading = false;
      });
    }
  }

  Future<void> _unsaveProperty(Property property) async {
    final l = AppLocalizations.of(context);
    try {
      await ApiService.unsaveItem(property.id);
      setState(() {
        _savedProperties.removeWhere((p) => p.id == property.id);
        _savedLots.removeWhere((p) => p.id == property.id);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.tr('removedFromSaved'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l.tr('failedToRemove')} $e')),
      );
    }
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
            _buildAppBar(l),
            Divider(height: 1, color: cs.surfaceContainerHighest),
            _buildTabRow(l),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _loadAllData,
                      child: _buildTabContent(l),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(AppLocalizations l) {
    switch (_selectedTab) {
      case 0:
        return _buildPropertiesTab(l);
      case 1:
        return _buildServicesTab(l);
      case 2:
        return _buildLotsTab(l);
      case 3:
        return _buildListsTab(l);
      default:
        return _buildPropertiesTab(l);
    }
  }

  // ──────────── App Bar ────────────

  Widget _buildAppBar(AppLocalizations l) {
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
              l.tr('savedItems'),
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

  // ──────────── Tab Row ────────────

  Widget _buildTabRow(AppLocalizations l) {
    final cs = Theme.of(context).colorScheme;
    final tabs = [l.tr('properties'), l.tr('services'), l.tr('lots'), l.tr('lists')];
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

  // ══════════════════════════════════════════════════════════════════════════════
  // TAB 0 — Properties
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildPropertiesTab(AppLocalizations l) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildPropertyGrid(l)),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildPropertyGrid(AppLocalizations l) {
    final cs = Theme.of(context).colorScheme;
    if (_savedProperties.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite_border,
        title: l.tr('noSavedProperties'),
        subtitle: l.tr('propertiesSavedAppearHere'),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_savedProperties.length} ${l.tr('savedProperties')}',
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
              return _buildSavedPropertyCard(_savedProperties[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSavedPropertyCard(Property property) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.price,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
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
                  Row(
                    children: [
                      Icon(Icons.bed_outlined, color: cs.outline, size: 13),
                      const SizedBox(width: 2),
                      Text('${property.beds}',
                          style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      Icon(Icons.bathtub_outlined, color: cs.outline, size: 13),
                      const SizedBox(width: 2),
                      Text('${property.baths}',
                          style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      Icon(Icons.square_foot_outlined,
                          color: cs.outline, size: 13),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text('${property.sqft}',
                            style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 11,
                                fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const Spacer(),
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
                      child: Text(l.tr('viewDetails')),
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

  // ══════════════════════════════════════════════════════════════════════════════
  // TAB 1 — Services
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildServicesTab(AppLocalizations l) {
    final cs = Theme.of(context).colorScheme;
    if (_serviceRequests.isEmpty) {
      return ListView(
        children: [
          _buildEmptyState(
            icon: Icons.build_outlined,
            title: l.tr('noServiceRequests'),
            subtitle: l.tr('serviceRequestsAppearHere'),
          ),
        ],
      );
    }

    final active = _serviceRequests
        .where((s) =>
            s.status == 'pending' ||
            s.status == 'accepted' ||
            s.status == 'in_progress')
        .toList();
    final past = _serviceRequests
        .where((s) =>
            s.status == 'completed' ||
            s.status == 'cancelled')
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        if (active.isNotEmpty) ...[
          Text(
            '${active.length} ${l.tr('active')}',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ...active.map((sr) => _buildServiceRequestCard(sr, cs, l)),
        ],
        if (past.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            '${past.length} ${l.tr('past')}',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ...past.map((sr) => _buildServiceRequestCard(sr, cs, l)),
        ],
      ],
    );
  }

  Widget _buildServiceRequestCard(ServiceRequest sr, ColorScheme cs, AppLocalizations l) {
    final isActive = sr.status == 'pending' ||
        sr.status == 'accepted' ||
        sr.status == 'in_progress';

    final statusColor = switch (sr.status) {
      'pending' => const Color(0xFFF59E0B),
      'accepted' || 'in_progress' => AppColors.primary,
      'completed' => const Color(0xFF22C55E),
      'cancelled' => const Color(0xFFEF4444),
      _ => cs.onSurfaceVariant,
    };

    final statusBg = switch (sr.status) {
      'pending' => const Color(0xFFFEF3C7),
      'accepted' || 'in_progress' => AppColors.primarySoft,
      'completed' => const Color(0xFFDCFCE7),
      'cancelled' => const Color(0xFFFEE2E2),
      _ => cs.surfaceContainerHighest,
    };

    final statusLabel = switch (sr.status) {
      'pending' => l.tr('pending'),
      'accepted' => l.tr('accepted'),
      'in_progress' => l.tr('inProgress'),
      'completed' => l.tr('completed'),
      'cancelled' => l.tr('cancelled'),
      _ => sr.status,
    };

    final categoryIcon = switch (sr.displayCategory.toLowerCase()) {
      String c when c.contains('electric') => Icons.electrical_services,
      String c when c.contains('plumb') => Icons.plumbing,
      String c when c.contains('clean') => Icons.cleaning_services_outlined,
      String c when c.contains('paint') => Icons.format_paint_outlined,
      String c when c.contains('ac') || c.contains('hvac') => Icons.ac_unit,
      _ => Icons.build_outlined,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              categoryIcon,
              color: isActive ? AppColors.primary : cs.onSurfaceVariant,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sr.displayTitle,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${sr.shortNumber}  •  ${sr.displayCategory}',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (sr.etaMinutes != null && isActive) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule, color: cs.outline, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        '${l.tr('eta')} ${sr.etaMinutes} min',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // TAB 2 — Lots (Land)
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildLotsTab(AppLocalizations l) {
    final cs = Theme.of(context).colorScheme;
    if (_savedLots.isEmpty) {
      return ListView(
        children: [
          _buildEmptyState(
            icon: Icons.terrain_outlined,
            title: l.tr('noSavedLots'),
            subtitle: l.tr('lotsAppearHere'),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          '${_savedLots.length} ${l.tr('savedLots')}',
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        ..._savedLots.map((lot) => _buildLotCard(lot, cs, l)),
      ],
    );
  }

  Widget _buildLotCard(Property lot, ColorScheme cs, AppLocalizations l) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 110,
            child: Image.network(
              lot.images.isNotEmpty ? lot.images.first : '',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: cs.surfaceContainerHighest,
                child: Center(
                  child: Icon(Icons.terrain_outlined,
                      color: cs.outline, size: 32),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lot.price,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lot.title,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          color: cs.outline, size: 13),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          lot.location,
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.square_foot_outlined,
                          color: cs.outline, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        '${lot.sqft} ${l.tr('sqft')}',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _unsaveProperty(lot),
                        child: Icon(Icons.favorite,
                            color: const Color(0xFFEF4444), size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // TAB 3 — Lists (Collections)
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildListsTab(AppLocalizations l) {
    final cs = Theme.of(context).colorScheme;
    if (_collections.isEmpty) {
      return ListView(
        children: [
          _buildEmptyState(
            icon: Icons.list_alt_outlined,
            title: l.tr('noListsYet'),
            subtitle: l.tr('createListToOrganize'),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          '${_collections.length} ${l.tr('lists')}',
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        ..._collections.map((name) => _buildListTile(name, cs, l)),
      ],
    );
  }

  Widget _buildListTile(String name, ColorScheme cs, AppLocalizations l) {
    final count = _collectionCounts[name] ?? 0;
    final icon = _collectionIcons[name] ?? Icons.folder_outlined;

    return GestureDetector(
      onTap: () => _openCollection(name),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name == 'default' ? l.tr('favorites') : name,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$count ${count == 1 ? l.tr('item') : l.tr('items')}',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: cs.outline, size: 22),
          ],
        ),
      ),
    );
  }

  void _openCollection(String name) async {
    final l = AppLocalizations.of(context);
    try {
      final items = await ApiService.getSavedItems(collection: name);
      final properties = items
          .where((item) => item['property'] != null)
          .map((item) => Property.fromJson(item['property']))
          .toList();

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _CollectionDetailScreen(
            name: name == 'default' ? l.tr('favorites') : name,
            properties: properties,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l.tr('failedToLoadList')} $e')),
      );
    }
  }

  // ──────────── Shared Helpers ────────────

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: cs.outline, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// Collection Detail Screen (shown when tapping a list)
// ════════════════════════════════════════════════════════════════════════════════

class _CollectionDetailScreen extends StatelessWidget {
  final String name;
  final List<Property> properties;

  const _CollectionDetailScreen({
    required this.name,
    required this.properties,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: properties.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_open_outlined, color: cs.outline, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    l.tr('listIsEmpty'),
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: properties.length,
              itemBuilder: (context, index) {
                final p = properties[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
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
                  child: Row(
                    children: [
                      SizedBox(
                        width: 110,
                        height: 100,
                        child: Image.network(
                          p.images.isNotEmpty ? p.images.first : '',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: cs.surfaceContainerHighest,
                            child: Center(
                              child: Icon(Icons.home_outlined,
                                  color: cs.outline, size: 28),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.price,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p.title,
                                style: TextStyle(
                                  color: cs.onSurface,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p.location,
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
