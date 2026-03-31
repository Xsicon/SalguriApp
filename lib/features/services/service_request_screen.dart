import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
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
  int _selectedCategoryIndex = 0;
  final Set<String> _selectedItemIds = {};
  _Urgency _urgency = _Urgency.urgent;
  final TextEditingController _descController = TextEditingController();

  static const double _serviceFee = 100.0;

  List<ServiceCategory> _categories = [];
  List<ServiceItem> _currentItems = [];
  bool _isLoadingCategories = true;
  bool _isLoadingItems = false;

  ServiceCategory get _currentCategory => _categories[_selectedCategoryIndex];

  List<ServiceItem> get _selectedItems =>
      _currentItems.where((i) => _selectedItemIds.contains(i.id)).toList();

  double get _itemsTotal =>
      _selectedItems.fold(0.0, (sum, i) => sum + i.price);

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
    setState(() => _isLoadingItems = true);
    try {
      final items = await ApiService.getServiceItems(categoryId);
      if (!mounted) return;
      setState(() {
        _currentItems = items;
        _isLoadingItems = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingItems = false);
      debugPrint('Failed to load service items: $e');
    }
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

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: cs.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Service Request',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? Center(
                  child: Text(
                    'No service categories available.',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSelectedProperty(cs),
                            const SizedBox(height: 24),
                            _buildCategorySelector(cs),
                            const SizedBox(height: 24),
                            _buildServiceItems(cs),
                            const SizedBox(height: 24),
                            _buildDescription(cs),
                            const SizedBox(height: 24),
                            _buildUrgencySelector(cs),
                            const SizedBox(height: 24),
                            if (_selectedItems.isNotEmpty || _urgency != _Urgency.standard)
                              _buildSelectedSummary(cs),
                            const SizedBox(height: 100),
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
          'SELECTED PROPERTY',
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
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
              Icon(Icons.keyboard_arrow_down_rounded, color: cs.onSurfaceVariant, size: 22),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Category',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isActive = index == _selectedCategoryIndex;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategoryIndex = index;
                    _selectedItemIds.clear();
                  });
                  _loadItems(cat.id);
                },
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primary : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Icon(
                          cat.icon,
                          color: isActive ? Colors.white : cs.onSurfaceVariant,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cat.name,
                      style: TextStyle(
                        color: isActive ? AppColors.primary : cs.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
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
    final cat = _currentCategory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${cat.name} Issues',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Swipe for more',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 140,
          child: _isLoadingItems
              ? const Center(child: CircularProgressIndicator())
              : _currentItems.isEmpty
                  ? Center(
                      child: Text(
                        'No items available.',
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _currentItems.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final item = _currentItems[index];
                        final isSelected = _selectedItemIds.contains(item.id);
                        return GestureDetector(
                          onTap: () => _toggleItem(item),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 130,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : cs.outlineVariant,
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
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: cs.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Icon(item.icon, size: 18, color: cs.onSurfaceVariant),
                                      ),
                                    ),
                                    if (isSelected)
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.check_rounded, color: Colors.white, size: 14),
                                        ),
                                      ),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  item.name,
                                  style: TextStyle(
                                    color: cs.onSurface,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${item.price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 14,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: TextField(
            controller: _descController,
            maxLines: 4,
            style: TextStyle(color: cs.onSurface, fontSize: 14),
            decoration: InputDecoration(
              hintText: "Tell us more about the issue... (e.g., 'Master bedroom light flickering')",
              hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
              contentPadding: const EdgeInsets.all(16),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Urgency Level',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: _Urgency.values.map((u) {
            final isSelected = _urgency == u;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _urgency = u),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: EdgeInsets.only(
                    right: u != _Urgency.standard ? 10 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.05)
                        : cs.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : cs.outlineVariant,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        u.label,
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : cs.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        u.surchargeLabel,
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : cs.onSurfaceVariant,
                          fontSize: 12,
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Services',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          ..._selectedItems.map(
            (item) => _buildSummaryRow(
              item.name,
              '\$${item.price.toStringAsFixed(2)}',
              cs,
            ),
          ),
          if (_urgency != _Urgency.standard)
            _buildSummaryRow(
              'Urgency: ${_urgency.label}',
              '\$${_urgency.surcharge.toStringAsFixed(2)}',
              cs,
            ),
          Divider(color: cs.outlineVariant, height: 24),
          _buildSummaryRow(
            'Service Fee',
            '\$${_serviceFee.toStringAsFixed(2)}',
            cs,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: cs.onSurface, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 14,
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
    final hasItems = _selectedItems.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                'Total Price',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '\$${_total.toStringAsFixed(2)}',
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
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
                                .map((i) => CheckoutServiceItem(
                                      name: i.name,
                                      price: i.price,
                                      icon: i.icon,
                                      categoryId: _currentCategory.id,
                                    ))
                                .toList(),
                            urgencyLabel: _urgency.label,
                            urgencySurcharge: _urgency.surcharge,
                            serviceFee: _serviceFee,
                            propertyAddress: address,
                            propertySubtitle: subtitle,
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
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              child: const Text('PROCEED TO CHECKOUT'),
            ),
          ),
        ],
      ),
    );
  }
}
