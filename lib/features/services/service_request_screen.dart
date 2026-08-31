import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/rental.dart';
import '../../core/models/service_category.dart';
import '../../core/models/service_item.dart';
import '../../services/api_service.dart';
import 'service_checkout_screen.dart';

// ---------------------------------------------------------------------------
// Urgency level enum
// ---------------------------------------------------------------------------

enum _Urgency { emergency, urgent, standard }

extension _UrgencyExt on _Urgency {
  String localizedLabel(AppLocalizations l) {
    switch (this) {
      case _Urgency.emergency:
        return l.tr('emergency');
      case _Urgency.urgent:
        return l.tr('urgent');
      case _Urgency.standard:
        return l.tr('standard');
    }
  }

  String get label {
    switch (this) {
      case _Urgency.emergency:
        return 'Emergency';
      case _Urgency.urgent:
        return 'Urgent';
      case _Urgency.standard:
        return 'Standard';
    }
  }

  double get surcharge {
    switch (this) {
      case _Urgency.emergency:
        return 50;
      case _Urgency.urgent:
        return 25;
      case _Urgency.standard:
        return 0;
    }
  }

  String get surchargeLabel {
    final s = surcharge;
    return s > 0 ? '+\$${s.toStringAsFixed(0)}' : '\$0';
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ServiceRequestScreen extends StatefulWidget {
  final Rental? rental;

  const ServiceRequestScreen({super.key, this.rental});

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  final Set<String> _selectedItemIds = {};
  String? _activeCategoryId;
  _Urgency _urgency = _Urgency.urgent;
  final TextEditingController _descController = TextEditingController();

  static const double _serviceFee = 100.0;

  List<ServiceCategory> _categories = [];
  final Map<String, List<ServiceItem>> _itemsByCategoryId = {};
  final Set<String> _loadingCategoryIds = {};
  bool _isLoadingCategories = true;

  bool get _isLoadingActiveItems {
    final activeCategoryId = _activeCategoryId;
    return activeCategoryId != null &&
        _loadingCategoryIds.contains(activeCategoryId);
  }

  ServiceCategory? get _activeCategory {
    final activeCategoryId = _activeCategoryId;
    if (activeCategoryId == null) return null;
    for (final category in _categories) {
      if (category.id == activeCategoryId) return category;
    }
    return null;
  }

  List<ServiceItem> get _visibleItems {
    final activeCategoryId = _activeCategoryId;
    if (activeCategoryId == null) return <ServiceItem>[];
    return _itemsByCategoryId[activeCategoryId] ?? <ServiceItem>[];
  }

  List<ServiceItem> get _selectedItems => _itemsByCategoryId.values
      .expand((items) => items)
      .where((item) => _selectedItemIds.contains(item.id))
      .toList();

  double get _itemsTotal => _selectedItems.fold(0.0, (sum, i) => sum + i.price);

  double get _total => _itemsTotal + _urgency.surcharge + _serviceFee;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await ApiService.getServiceCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        if (categories.isNotEmpty) {
          final firstCategoryId = categories.first.id;
          _activeCategoryId = firstCategoryId;
        }
        _isLoadingCategories = false;
      });
      if (_categories.isNotEmpty) {
        _loadItems(_categories[0].id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCategories = false);
      debugPrint('Failed to load service categories: $e');
    }
  }

  Future<void> _loadItems(String categoryId) async {
    if (_itemsByCategoryId.containsKey(categoryId) ||
        _loadingCategoryIds.contains(categoryId)) {
      return;
    }

    setState(() => _loadingCategoryIds.add(categoryId));
    try {
      final items = await ApiService.getServiceItems(categoryId);
      if (!mounted) return;
      setState(() {
        _itemsByCategoryId[categoryId] = items;
        _loadingCategoryIds.remove(categoryId);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCategoryIds.remove(categoryId));
      debugPrint('Failed to load service items: $e');
    }
  }

  void _selectCategory(ServiceCategory category) {
    setState(() {
      _activeCategoryId = category.id;
    });

    _loadItems(category.id);
  }

  String _serviceItemsTitle(AppLocalizations l) {
    final activeCategory = _activeCategory;
    if (activeCategory == null) {
      return l.tr('selectOneOrMoreCategories');
    }
    return '${activeCategory.name} ${l.tr('issues')}';
  }

  void _toggleItem(ServiceItem item) {
    setState(() {
      if (_selectedItemIds.contains(item.id)) {
        _selectedItemIds.remove(item.id);
      } else {
        _selectedItemIds.add(item.id);
      }
    });
  }

  String _categoryNameForItem(ServiceItem item) {
    for (final category in _categories) {
      if (category.id == item.categoryId) return category.name;
    }
    return 'Service';
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20.r,
            color: cs.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l.tr('serviceRequest'),
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
          ? Center(
              child: Text(
                l.tr('noCategoriesAvailable'),
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15.sp),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 20.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSelectedProperty(cs),
                        SizedBox(height: 24.h),
                        _buildCategorySelector(cs),
                        SizedBox(height: 24.h),
                        _buildServiceItems(cs),
                        SizedBox(height: 24.h),
                        _buildDescription(cs),
                        SizedBox(height: 24.h),
                        _buildUrgencySelector(cs),
                        SizedBox(height: 24.h),
                        if (_selectedItems.isNotEmpty ||
                            _urgency != _Urgency.standard)
                          _buildSelectedSummary(cs),
                        SizedBox(height: 100.h),
                      ],
                    ),
                  ),
                ),
                _buildBottomBar(cs),
              ],
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Selected Property Card
  // ---------------------------------------------------------------------------

  Widget _buildSelectedProperty(ColorScheme cs) {
    final l = AppLocalizations.of(context);
    final rental = widget.rental;
    final address = rental != null
        ? '${rental.address}, ${rental.location.split(',').first.trim()}'
        : '123 Peace Street, Hodan';
    final subtitle = rental != null
        ? rental.location.contains(',')
              ? '${rental.location.split(',').last.trim()}, Somalia'
              : rental.location
        : 'Mogadishu, Somalia';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.tr('selectedProperty'),
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 38.w,
                height: 38.h,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Center(
                  child: Icon(
                    Icons.location_on_outlined,
                    color: AppColors.primary,
                    size: 20.r,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2.h),
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
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: cs.onSurfaceVariant,
                size: 22.r,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Category Selector
  // ---------------------------------------------------------------------------

  Widget _buildCategorySelector(ColorScheme cs) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.tr('selectCategory'),
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 14.h),
        SizedBox(
          height: 90.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (context, index) => SizedBox(width: 14.w),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isActive = _activeCategoryId == cat.id;
              final hasSelections =
                  (_itemsByCategoryId[cat.id] ?? <ServiceItem>[]).any(
                    (item) => _selectedItemIds.contains(item.id),
                  );
              final isMarked = isActive || hasSelections;
              return GestureDetector(
                onTap: () => _selectCategory(cat),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 58.w,
                      height: 58.h,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary
                            : hasSelections
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: isMarked
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              cat.icon,
                              color: isActive
                                  ? Colors.white
                                  : hasSelections
                                  ? AppColors.primary
                                  : cs.onSurfaceVariant,
                              size: 26.r,
                            ),
                          ),
                          if (isActive || hasSelections)
                            Positioned(
                              top: 5.h,
                              right: 5.w,
                              child: Icon(
                                hasSelections
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_checked_rounded,
                                color: isActive
                                    ? Colors.white
                                    : AppColors.primary,
                                size: 15.r,
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      cat.name,
                      style: TextStyle(
                        color: isMarked
                            ? AppColors.primary
                            : cs.onSurfaceVariant,
                        fontSize: 12.sp,
                        fontWeight: isMarked
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
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Service Sub-Items
  // ---------------------------------------------------------------------------

  Widget _buildServiceItems(ColorScheme cs) {
    final l = AppLocalizations.of(context);
    final items = _visibleItems;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _serviceItemsTitle(l),
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 14.h),
        SizedBox(
          height: 140.h,
          child: _isLoadingActiveItems
              ? const Center(child: CircularProgressIndicator())
              : items.isEmpty
              ? Center(
                  child: Text(
                    _activeCategoryId == null
                        ? l.tr('selectCategoryFirst')
                        : l.tr('noItemsAvailable'),
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14.sp),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => SizedBox(width: 12.w),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = _selectedItemIds.contains(item.id);
                    return GestureDetector(
                      onTap: () => _toggleItem(item),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 130.w,
                        padding: EdgeInsets.all(14.r),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : cs.outlineVariant,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: 36.w,
                                  height: 36.h,
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      item.icon,
                                      size: 18.r,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    width: 22.w,
                                    height: 22.h,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 14.r,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              item.name,
                              style: TextStyle(
                                color: cs.onSurface,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '\$${item.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Description
  // ---------------------------------------------------------------------------

  Widget _buildDescription(ColorScheme cs) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.tr('description'),
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: TextField(
            controller: _descController,
            maxLines: 4,
            style: TextStyle(color: cs.onSurface, fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: l.tr('descriptionHint'),
              hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14.sp),
              contentPadding: EdgeInsets.all(16.r),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Urgency Selector
  // ---------------------------------------------------------------------------

  Widget _buildUrgencySelector(ColorScheme cs) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.tr('urgencyLevel'),
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 14.h),
        Row(
          children: _Urgency.values.map((u) {
            final isSelected = _urgency == u;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _urgency = u),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: EdgeInsets.only(
                    right: u != _Urgency.standard ? 10.w : 0,
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.05)
                        : cs.surface,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : cs.outlineVariant,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        u.localizedLabel(l),
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : cs.onSurface,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        u.surchargeLabel,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : cs.onSurfaceVariant,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Selected Services Summary
  // ---------------------------------------------------------------------------

  Widget _buildSelectedSummary(ColorScheme cs) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.tr('selectedServices'),
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 14.h),
          ..._selectedItems.map(
            (item) => _buildSummaryRow(
              item.name,
              '\$${item.price.toStringAsFixed(2)}',
              cs,
            ),
          ),
          if (_urgency != _Urgency.standard)
            _buildSummaryRow(
              'Urgency: ${_urgency.localizedLabel(l)}',
              '\$${_urgency.surcharge.toStringAsFixed(2)}',
              cs,
            ),
          Divider(color: cs.outlineVariant, height: 24.h),
          _buildSummaryRow(
            l.tr('serviceFee'),
            '\$${_serviceFee.toStringAsFixed(2)}',
            cs,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, ColorScheme cs) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: cs.onSurface, fontSize: 14.sp)),
          Text(
            value,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom Bar
  // ---------------------------------------------------------------------------

  Widget _buildBottomBar(ColorScheme cs) {
    final l = AppLocalizations.of(context);
    final hasItems = _selectedItems.isNotEmpty;
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.tr('totalPrice'),
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                '\$${_total.toStringAsFixed(2)}',
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: ElevatedButton(
              onPressed: hasItems
                  ? () {
                      final rental = widget.rental;
                      final address = rental != null
                          ? '${rental.address}, ${rental.location.split(',').first.trim()}'
                          : '123 Peace Street, Hodan';
                      final subtitle = rental != null
                          ? rental.location.contains(',')
                                ? '${rental.location.split(',').last.trim()}, Somalia'
                                : rental.location
                          : 'Mogadishu, Somalia';

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ServiceCheckoutScreen(
                            items: _selectedItems
                                .map(
                                  (i) => CheckoutServiceItem(
                                    name: i.name,
                                    price: i.price,
                                    icon: i.icon,
                                    categoryId: i.categoryId,
                                    categoryName: _categoryNameForItem(i),
                                  ),
                                )
                                .toList(),
                            urgencyLabel: _urgency.label,
                            urgencySurcharge: _urgency.surcharge,
                            serviceFee: _serviceFee,
                            propertyAddress: address,
                            propertySubtitle: subtitle,
                            description: _descController.text.trim(),
                          ),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: cs.surfaceContainerHighest,
                foregroundColor: Colors.white,
                disabledForegroundColor: cs.onSurfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 16.h),
                elevation: 0,
                textStyle: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              child: Text(l.tr('bookService')),
            ),
          ),
        ],
      ),
    );
  }
}
