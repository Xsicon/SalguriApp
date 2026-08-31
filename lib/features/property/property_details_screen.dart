import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/property.dart';
import '../../services/api_service.dart';
// import '../../services/supabase_service.dart'; // Disabled – landlord feature
import 'contact_agent_screen.dart';
// import 'edit_property_screen.dart'; // Disabled – landlord feature
import 'schedule_showing_screen.dart';
import 'submit_application_screen.dart';

class PropertyDetailsScreen extends StatefulWidget {
  final Property property;

  const PropertyDetailsScreen({super.key, required this.property});

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  bool _isSaved = false;
  bool _isRented = false;

  Property get p => widget.property;

  @override
  void initState() {
    super.initState();
    _checkSaved();
    _checkRented();
  }

  Future<void> _checkSaved() async {
    try {
      final saved = await ApiService.isPropertySaved(p.id);
      if (mounted) setState(() => _isSaved = saved);
    } catch (_) {}
  }

  Future<void> _checkRented() async {
    try {
      final rental = await ApiService.getActiveRental();
      if (mounted && rental != null && rental.propertyId == p.id) {
        setState(() => _isRented = true);
      }
    } catch (_) {}
  }

  Future<void> _toggleSave() async {
    try {
      if (_isSaved) {
        await ApiService.unsaveItem(p.id);
      } else {
        await ApiService.saveItem(propertyId: p.id);
      }
      if (mounted) setState(() => _isSaved = !_isSaved);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildImageCarousel()),
                    SliverToBoxAdapter(child: _buildTitleSection()),
                    SliverToBoxAdapter(child: _buildSpecsGrid()),
                    SliverToBoxAdapter(child: _buildPaymentEstimator()),
                    SliverToBoxAdapter(child: _buildDescription()),
                    SliverToBoxAdapter(child: _buildAmenities()),
                    SliverToBoxAdapter(child: _buildAgentCard()),
                    SliverToBoxAdapter(child: _buildLocationMap()),
                    SliverToBoxAdapter(child: SizedBox(height: 16.h)),
                  ],
                ),
                // Sticky back button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8.h,
                  left: 12.w,
                  child: _buildCircleButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  // ---------- Image Carousel ----------

  Widget _buildImageCarousel() {
    final cs = Theme.of(context).colorScheme;
    if (p.images.isEmpty) {
      return SizedBox(
        height: 280.h,
        child: Container(
          color: cs.surfaceContainerHighest,
          child: Center(
            child: Icon(Icons.home_outlined, color: cs.outline, size: 48.r),
          ),
        ),
      );
    }
    return Stack(
      children: [
        SizedBox(
          height: 280.h,
          child: PageView.builder(
            controller: _pageController,
            itemCount: p.images.length,
            onPageChanged: (index) {
              setState(() => _currentImageIndex = index);
            },
            itemBuilder: (context, index) {
              return Image.network(
                p.images[index],
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, _, _) => Container(
                  color: cs.surfaceContainerHighest,
                  child: Center(
                    child: Icon(Icons.home_outlined, color: cs.outline, size: 48.r),
                  ),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: cs.surfaceContainerHighest,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        // Share button
        Positioned(
          top: MediaQuery.of(context).padding.top + 8.h,
          right: 56.w,
          child: _buildCircleButton(
            icon: Icons.share_outlined,
            onTap: () {},
          ),
        ),
        // Favorite button
        Positioned(
          top: MediaQuery.of(context).padding.top + 8.h,
          right: 12.w,
          child: GestureDetector(
            onTap: _toggleSave,
            child: Container(
              width: 36.w,
              height: 36.h,
              decoration: const BoxDecoration(
                color: Colors.black38,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isSaved ? Icons.favorite : Icons.favorite_border,
                color: _isSaved ? const Color(0xFFEF4444) : AppColors.white,
                size: 20.r,
              ),
            ),
          ),
        ),
        // Image indicators
        Positioned(
          bottom: 16.h,
          left: 0.w,
          right: 0.w,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(p.images.length, (index) {
              final isActive = index == _currentImageIndex;
              return Container(
                width: isActive ? 24.w : 8.w,
                height: 8.h,
                margin: EdgeInsets.symmetric(horizontal: 3.w),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.white : AppColors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              );
            }),
          ),
        ),
        // Image counter
        Positioned(
          bottom: 16.h,
          right: 16.w,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              '${_currentImageIndex + 1}/${p.images.length}',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white.withValues(alpha: 0.15)),
            ),
            child: Icon(icon, color: AppColors.white, size: 20.r),
          ),
        ),
      ),
    );
  }

  // ---------- Title Section ----------

  Widget _buildTitleSection() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type badge + Rating
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  p.type,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.star, color: const Color(0xFFF59E0B), size: 18.r),
              SizedBox(width: 4.w),
              Text(
                p.rating.toString(),
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 4.w),
              Text(
                '(${p.reviews} reviews)',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // Title
          Text(
            p.title,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6.h),
          // Location
          Row(
            children: [
              Icon(Icons.location_on_outlined, color: cs.onSurfaceVariant, size: 18.r),
              SizedBox(width: 4.w),
              Text(
                p.location,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          // Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                p.price,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (p.priceLabel.isNotEmpty) ...[
                SizedBox(width: 8.w),
                Padding(
                  padding: EdgeInsets.only(bottom: 3.h),
                  child: Text(
                    p.priceLabel,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ---------- Specs Grid ----------

  Widget _buildSpecsGrid() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0.h),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            _buildSpecItem(Icons.bed_outlined, '${p.beds}', 'Beds'),
            _buildSpecDivider(),
            _buildSpecItem(Icons.bathtub_outlined, '${p.baths}', 'Baths'),
            _buildSpecDivider(),
            _buildSpecItem(Icons.square_foot_outlined, '${p.sqft}', 'Sq Ft'),
            _buildSpecDivider(),
            _buildSpecItem(Icons.calendar_today_outlined, '${p.yearBuilt}', 'Built'),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecItem(IconData icon, String value, String label) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 22.r),
          SizedBox(height: 6.h),
          Text(
            value,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecDivider() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 1.w,
      height: 40.h,
      color: cs.outlineVariant,
    );
  }

  // ---------- Payment Estimator ----------

  Widget _buildPaymentEstimator() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0.h),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.calculate_outlined,
                color: AppColors.primary,
                size: 22.r,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Payment Estimate',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    p.priceLabel.isNotEmpty ? p.priceLabel : 'Contact agent',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 22.r),
          ],
        ),
      ),
    );
  }

  // ---------- Description ----------

  Widget _buildDescription() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 0.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            p.description,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 14.sp,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Amenities ----------

  Widget _buildAmenities() {
    final cs = Theme.of(context).colorScheme;
    final amenityIcons = <String, IconData>{
      'Swimming Pool': Icons.pool_outlined,
      'Pool': Icons.pool_outlined,
      'Garage': Icons.garage_outlined,
      'Garden': Icons.yard_outlined,
      'Security': Icons.security_outlined,
      'AC': Icons.ac_unit_outlined,
      'Balcony': Icons.balcony_outlined,
      'Elevator': Icons.elevator_outlined,
      'Gym': Icons.fitness_center_outlined,
      'Rooftop': Icons.roofing_outlined,
      'Parking': Icons.local_parking_outlined,
      'Beach Access': Icons.beach_access_outlined,
    };

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 0.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amenities',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 14.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: p.amenities.map((amenity) {
              final icon = amenityIcons[amenity] ?? Icons.check_circle_outline;
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: AppColors.primary, size: 18.r),
                    SizedBox(width: 8.w),
                    Text(
                      amenity,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
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

  // ---------- Agent Card ----------

  Widget _buildAgentCard() {
    final cs = Theme.of(context).colorScheme;
    final agent = p.agent;
    if (agent == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 0.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Property Agent',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 14.h),
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 50.w,
                  height: 50.h,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    shape: BoxShape.circle,
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
                SizedBox(width: 14.w),
                // Info
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
                      SizedBox(height: 2.h),
                      Text(
                        agent.role,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 13.sp,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(Icons.star, color: const Color(0xFFF59E0B), size: 14.r),
                          SizedBox(width: 3.w),
                          Text(
                            agent.rating.toString(),
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Icon(Icons.handshake_outlined, color: cs.outline, size: 14.r),
                          SizedBox(width: 3.w),
                          Text(
                            '${agent.deals} deals',
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
                // Contact buttons
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ContactAgentScreen(property: p),
                          ),
                        );
                      },
                      child: _buildContactButton(Icons.phone_outlined),
                    ),
                    SizedBox(height: 8.h),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ContactAgentScreen(property: p),
                          ),
                        );
                      },
                      child: _buildContactButton(Icons.chat_outlined),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton(IconData icon) {
    return Container(
      width: 38.w,
      height: 38.h,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Icon(icon, color: AppColors.primary, size: 18.r),
    );
  }

  // ---------- Location Map ----------

  Widget _buildLocationMap() {
    final cs = Theme.of(context).colorScheme;
    final propertyLocation = LatLng(p.latitude, p.longitude);

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 0.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  color: cs.onSurfaceVariant, size: 16.r),
              SizedBox(width: 4.w),
              Text(
                p.location,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            height: 200.h,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: propertyLocation,
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.salguri.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: propertyLocation,
                      width: 40.w,
                      height: 40.h,
                      child: Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 40.r,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Bottom Action Buttons ----------

  // Disabled – landlord feature (kept for business app)
  // bool get _isOwner {
  //   final currentUserId = SupabaseService.currentUser?.id;
  //   return p.ownerUserId != null && p.ownerUserId == currentUserId;
  // }

  Widget _buildBottomActions() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(
        20.w,
        14.h,
        20.w,
        MediaQuery.of(context).padding.bottom + 14.h,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      // Owner actions disabled – landlord feature (kept for business app)
      child: _isRented
          ? _buildRentedBanner()
          : _buildVisitorActions(),
    );
  }

  Widget _buildRentedBanner() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22.r),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'You are currently renting this property',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Disabled – landlord feature (kept for business app)
  // Widget _buildOwnerActions() {
  //   return Row(
  //     children: [
  //       Expanded(
  //         child: OutlinedButton.icon(
  //           onPressed: () async {
  //             final updated = await Navigator.of(context).push<bool>(
  //               MaterialPageRoute(
  //                 builder: (_) => EditPropertyScreen(property: p),
  //               ),
  //             );
  //             if (updated == true && mounted) {
  //               Navigator.of(context).pop();
  //             }
  //           },
  //           icon: const Icon(Icons.edit_outlined, size: 18),
  //           label: const Text('EDIT'),
  //         ),
  //       ),
  //       const SizedBox(width: 12),
  //       Expanded(
  //         child: ElevatedButton.icon(
  //           onPressed: () {
  //             Navigator.of(context).push(
  //               MaterialPageRoute(
  //                 builder: (_) => ContactAgentScreen(property: p),
  //               ),
  //             );
  //           },
  //           icon: const Icon(Icons.chat_outlined, size: 18),
  //           label: const Text('MESSAGES'),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildVisitorActions() {
    return Row(
      children: [
        // Tour button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ScheduleShowingScreen(property: p),
                ),
              );
            },
            icon: Icon(Icons.calendar_today_outlined, size: 16.r),
            label: const Text('TOUR'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              padding: EdgeInsets.symmetric(vertical: 13.h),
              textStyle: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        // Contact button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ContactAgentScreen(property: p),
                ),
              );
            },
            icon: Icon(Icons.chat_outlined, size: 16.r),
            label: const Text('CHAT'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              padding: EdgeInsets.symmetric(vertical: 13.h),
              textStyle: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        // Apply button — submits a rental application for staff review; it
        // does not instantly create a lease (there is no self-service
        // booking path, matching how the rest of the rental pipeline works).
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: p.isAvailableToApply
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SubmitApplicationScreen(property: p),
                      ),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              disabledBackgroundColor: AppColors.divider,
              disabledForegroundColor: AppColors.textMuted,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              padding: EdgeInsets.symmetric(vertical: 15.h),
              elevation: 2,
              shadowColor: AppColors.primary.withValues(alpha: 0.3),
              textStyle: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            child: Text(p.isAvailableToApply ? 'APPLY TO RENT' : 'NOT AVAILABLE'),
          ),
        ),
      ],
    );
  }
}
