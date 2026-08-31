import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back, color: cs.onSurface),
            iconSize: 24.r,
          ),
          Expanded(
            child: Text(
              l.tr('savedItems'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.settings_outlined, color: cs.onSurface),
            iconSize: 24.r,
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
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
      child: Container(
        height: 42.h,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isSelected = _selectedTab == index;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.all(3.r),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(9.r),
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
                        fontSize: 13.sp,
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
        SliverToBoxAdapter(child: SizedBox(height: 24.h)),
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
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_savedProperties.length} ${l.tr('savedProperties')}',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 14.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14.h,
              crossAxisSpacing: 14.w,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 110.h,
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
              Positioned(
                top: 8.h,
                right: 8.w,
                child: GestureDetector(
                  onTap: () => _unsaveProperty(property),
                  child: Container(
                    width: 30.w,
                    height: 30.h,
                    decoration: const BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.favorite,
                      color: const Color(0xFFEF4444),
                      size: 16.r,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.price,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    property.title,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    property.location,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(Icons.bed_outlined, color: cs.outline, size: 13.r),
                      SizedBox(width: 2.w),
                      Text('${property.beds}',
                          style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500)),
                      SizedBox(width: 8.w),
                      Icon(Icons.bathtub_outlined, color: cs.outline, size: 13.r),
                      SizedBox(width: 2.w),
                      Text('${property.baths}',
                          style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500)),
                      SizedBox(width: 8.w),
                      Icon(Icons.square_foot_outlined,
                          color: cs.outline, size: 13.r),
                      SizedBox(width: 2.w),
                      Flexible(
                        child: Text('${property.sqft}',
                            style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 32.h,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        padding: EdgeInsets.zero,
                        elevation: 0,
                        textStyle: TextStyle(
                          fontSize: 12.sp,
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
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
      children: [
        if (active.isNotEmpty) ...[
          Text(
            '${active.length} ${l.tr('active')}',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12.h),
          ...active.map((sr) => _buildServiceRequestCard(sr, cs, l)),
        ],
        if (past.isNotEmpty) ...[
          SizedBox(height: 20.h),
          Text(
            '${past.length} ${l.tr('past')}',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12.h),
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
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
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
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              categoryIcon,
              color: isActive ? AppColors.primary : cs.onSurfaceVariant,
              size: 24.r,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sr.displayTitle,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  '${sr.shortNumber}  •  ${sr.displayCategory}',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (sr.etaMinutes != null && isActive) ...[
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(Icons.schedule, color: cs.outline, size: 13.r),
                      SizedBox(width: 4.w),
                      Text(
                        '${l.tr('eta')} ${sr.etaMinutes} min',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontSize: 11.sp,
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
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
      children: [
        Text(
          '${_savedLots.length} ${l.tr('savedLots')}',
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 12.h),
        ..._savedLots.map((lot) => _buildLotCard(lot, cs, l)),
      ],
    );
  }

  Widget _buildLotCard(Property lot, ColorScheme cs, AppLocalizations l) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: cs.surface,
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
      child: Row(
        children: [
          SizedBox(
            width: 120.w,
            height: 110.h,
            child: Image.network(
              lot.images.isNotEmpty ? lot.images.first : '',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: cs.surfaceContainerHighest,
                child: Center(
                  child: Icon(Icons.terrain_outlined,
                      color: cs.outline, size: 32.r),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lot.price,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    lot.title,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          color: cs.outline, size: 13.r),
                      SizedBox(width: 3.w),
                      Flexible(
                        child: Text(
                          lot.location,
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
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(Icons.square_foot_outlined,
                          color: cs.outline, size: 13.r),
                      SizedBox(width: 3.w),
                      Text(
                        '${lot.sqft} ${l.tr('sqft')}',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _unsaveProperty(lot),
                        child: Icon(Icons.favorite,
                            color: const Color(0xFFEF4444), size: 20.r),
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
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
      children: [
        Text(
          '${_collections.length} ${l.tr('lists')}',
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 14.h),
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
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.r),
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
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24.r),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name == 'default' ? l.tr('favorites') : name,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    '$count ${count == 1 ? l.tr('item') : l.tr('items')}',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 13.sp,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: cs.outline, size: 22.r),
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
      padding: EdgeInsets.symmetric(vertical: 60.h),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 72.w,
              height: 72.h,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: cs.outline, size: 36.r),
            ),
            SizedBox(height: 16.h),
            Text(
              title,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              subtitle,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 13.sp,
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
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: properties.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_open_outlined, color: cs.outline, size: 48.r),
                  SizedBox(height: 12.h),
                  Text(
                    l.tr('listIsEmpty'),
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(20.r),
              itemCount: properties.length,
              itemBuilder: (context, index) {
                final p = properties[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 14.h),
                  decoration: BoxDecoration(
                    color: cs.surface,
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
                  child: Row(
                    children: [
                      SizedBox(
                        width: 110.w,
                        height: 100.h,
                        child: Image.network(
                          p.images.isNotEmpty ? p.images.first : '',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: cs.surfaceContainerHighest,
                            child: Center(
                              child: Icon(Icons.home_outlined,
                                  color: cs.outline, size: 28.r),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(12.r),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.price,
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                p.title,
                                style: TextStyle(
                                  color: cs.onSurface,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                p.location,
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 12.sp,
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
