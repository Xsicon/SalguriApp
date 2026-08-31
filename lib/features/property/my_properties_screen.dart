import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/property.dart';
import '../../services/api_service.dart';
import 'create_property_screen.dart';
import 'edit_property_screen.dart';
import 'property_details_screen.dart';

class MyPropertiesScreen extends StatefulWidget {
  const MyPropertiesScreen({super.key});

  @override
  State<MyPropertiesScreen> createState() => _MyPropertiesScreenState();
}

class _MyPropertiesScreenState extends State<MyPropertiesScreen> {
  List<Property> _properties = [];
  bool _isLoading = true;
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    try {
      final properties = await ApiService.getMyProperties();
      setState(() {
        _properties = properties;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading properties: $e');
      setState(() {
        _properties = [];
        _isLoading = false;
      });
    }
  }

  int get _totalTenants {
    // Estimate tenants based on occupied properties
    return _properties.where((p) => p.type == 'For Rent').length.clamp(0, 99);
  }

  String get _monthlyTotal {
    // Sum prices for rental properties
    double total = 0;
    for (final p in _properties) {
      final numeric = p.price.replaceAll(RegExp(r'[^\d.]'), '');
      final value = double.tryParse(numeric) ?? 0;
      if (p.priceLabel.contains('/mo')) {
        total += value;
      } else {
        // Estimate monthly from price label if available
        final moMatch = RegExp(r'\$([\d,]+)/mo').firstMatch(p.priceLabel);
        if (moMatch != null) {
          final moValue =
              double.tryParse(moMatch.group(1)!.replaceAll(',', '')) ?? 0;
          total += moValue;
        }
      }
    }
    if (total == 0 && _properties.isNotEmpty) {
      total = 2850; // Fallback display value
    }
    return '\$${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  // Simulated maintenance status per property (by index for demo)
  String? _maintenanceStatus(int index) {
    if (index == 1) return 'MAINTENANCE';
    return null;
  }

  String? _maintenanceSubtext(int index) {
    if (index == 1) return 'Water heater repair request active';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(cs),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary))
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _loadProperties,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAddPropertyButton(cs),
                            _buildStatsCard(cs),
                            _buildSectionHeader(cs),
                            _buildPropertyList(cs),
                            SizedBox(height: 24.h),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(cs),
    );
  }

  // ---------- AppBar ----------

  Widget _buildAppBar(ColorScheme cs) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back, color: cs.onSurface),
          ),
          Expanded(
            child: Text(
              'My Properties',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.settings_outlined, color: cs.onSurface),
          ),
        ],
      ),
    );
  }

  // ---------- Add Property Button ----------

  Widget _buildAddPropertyButton(ColorScheme cs) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0.h),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () async {
            final created = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const CreatePropertyScreen()),
            );
            if (created == true) _loadProperties();
          },
          icon: Icon(Icons.add, size: 20.r),
          label: const Text('ADD NEW PROPERTY'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 0,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            textStyle: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Stats Card ----------

  Widget _buildStatsCard(ColorScheme cs) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0.h),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 12.w),
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
            _buildStatColumn(
              cs,
              'PROPERTIES',
              '${_properties.length}',
              AppColors.primary,
            ),
            _buildStatDivider(cs),
            _buildStatColumn(
              cs,
              'TENANTS',
              '$_totalTenants',
              const Color(0xFF16A34A),
            ),
            _buildStatDivider(cs),
            _buildStatColumn(
              cs,
              'MONTHLY',
              _monthlyTotal,
              const Color(0xFFF59E0B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(
      ColorScheme cs, String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider(ColorScheme cs) {
    return Container(
      width: 1.w,
      height: 36.h,
      color: cs.outlineVariant.withValues(alpha: 0.5),
    );
  }

  // ---------- Section Header ----------

  Widget _buildSectionHeader(ColorScheme cs) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Your Assets',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${_properties.length} Total',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Property List ----------

  Widget _buildPropertyList(ColorScheme cs) {
    if (_properties.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 48.h),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.home_work_outlined, color: cs.outline, size: 48.r),
              SizedBox(height: 12.h),
              Text(
                'No properties yet',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Add your first property to get started',
                style: TextStyle(
                  color: cs.outline,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: _properties.asMap().entries.map((entry) {
          final index = entry.key;
          final property = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _buildPropertyCard(cs, property, index),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPropertyCard(ColorScheme cs, Property property, int index) {
    final maintenance = _maintenanceStatus(index);
    final subtext = _maintenanceSubtext(index);
    final imageUrl =
        property.images.isNotEmpty ? property.images.first : '';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PropertyDetailsScreen(property: property),
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(12.r),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: SizedBox(
                    width: 80.w,
                    height: 80.h,
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: cs.surfaceContainerHighest,
                              child: Icon(Icons.home_outlined,
                                  color: cs.outline, size: 28.r),
                            ),
                          )
                        : Container(
                            color: cs.surfaceContainerHighest,
                            child: Icon(Icons.home_outlined,
                                color: cs.outline, size: 28.r),
                          ),
                  ),
                ),
                SizedBox(width: 12.w),
                // Info
                Expanded(
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
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (maintenance != null) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                maintenance,
                                style: TextStyle(
                                  color: const Color(0xFFD97706),
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              color: cs.onSurfaceVariant, size: 14.r),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              property.location,
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          property.type.toUpperCase(),
                          style: TextStyle(
                            color: const Color(0xFF16A34A),
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (subtext != null) ...[
                        SizedBox(height: 6.h),
                        Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: const Color(0xFFD97706), size: 14.r),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Text(
                                subtext,
                                style: TextStyle(
                                  color: const Color(0xFFD97706),
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
            SizedBox(height: 12.h),
            // Action icons row
            Container(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionIcon(
                      cs, Icons.chat_bubble_outline, 'Message', () {}),
                  _buildActionIcon(
                      cs, Icons.build_outlined, 'Service', () {}),
                  _buildActionIcon(
                      cs, Icons.payments_outlined, 'Payment', () {}),
                  _buildActionIcon(
                      cs, Icons.edit_outlined, 'Edit', () async {
                    final updated = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => EditPropertyScreen(property: property),
                      ),
                    );
                    if (updated == true) _loadProperties();
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIcon(
      ColorScheme cs, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 20.r),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Bottom Nav ----------

  Widget _buildBottomNav(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (i) => setState(() => _currentNavIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: cs.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: cs.outline,
        selectedFontSize: 11.sp,
        unselectedFontSize: 11.sp,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'HOME',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            activeIcon: Icon(Icons.search),
            label: 'SEARCH',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'EXPLORE',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'INBOX',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'PROFILE',
          ),
        ],
      ),
    );
  }
}
