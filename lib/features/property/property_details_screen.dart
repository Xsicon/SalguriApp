import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/property.dart';
import '../../services/api_service.dart';
// import '../../services/supabase_service.dart'; // Disabled – landlord feature
import 'contact_agent_screen.dart';
// import 'edit_property_screen.dart'; // Disabled – landlord feature
import 'rent_property_screen.dart';
import 'schedule_showing_screen.dart';

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
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  ],
                ),
                // Sticky back button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 12,
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
        height: 280,
        child: Container(
          color: cs.surfaceContainerHighest,
          child: Center(
            child: Icon(Icons.home_outlined, color: cs.outline, size: 48),
          ),
        ),
      );
    }
    return Stack(
      children: [
        SizedBox(
          height: 280,
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
                    child: Icon(Icons.home_outlined, color: cs.outline, size: 48),
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
          top: MediaQuery.of(context).padding.top + 8,
          right: 56,
          child: _buildCircleButton(
            icon: Icons.share_outlined,
            onTap: () {},
          ),
        ),
        // Favorite button
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 12,
          child: GestureDetector(
            onTap: _toggleSave,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.black38,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isSaved ? Icons.favorite : Icons.favorite_border,
                color: _isSaved ? const Color(0xFFEF4444) : AppColors.white,
                size: 20,
              ),
            ),
          ),
        ),
        // Image indicators
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(p.images.length, (index) {
              final isActive = index == _currentImageIndex;
              return Container(
                width: isActive ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.white : AppColors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ),
        // Image counter
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_currentImageIndex + 1}/${p.images.length}',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 12,
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white.withValues(alpha: 0.15)),
            ),
            child: Icon(icon, color: AppColors.white, size: 20),
          ),
        ),
      ),
    );
  }

  // ---------- Title Section ----------

  Widget _buildTitleSection() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type badge + Rating
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  p.type,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.star, color: Color(0xFFF59E0B), size: 18),
              const SizedBox(width: 4),
              Text(
                p.rating.toString(),
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${p.reviews} reviews)',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Title
          Text(
            p.title,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          // Location
          Row(
            children: [
              Icon(Icons.location_on_outlined, color: cs.onSurfaceVariant, size: 18),
              const SizedBox(width: 4),
              Text(
                p.location,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                p.price,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (p.priceLabel.isNotEmpty) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    p.priceLabel,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 13,
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
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
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecDivider() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 1,
      height: 40,
      color: cs.outlineVariant,
    );
  }

  // ---------- Payment Estimator ----------

  Widget _buildPaymentEstimator() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calculate_outlined,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Payment Estimate',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p.priceLabel.isNotEmpty ? p.priceLabel : 'Contact agent',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 22),
          ],
        ),
      ),
    );
  }

  // ---------- Description ----------

  Widget _buildDescription() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            p.description,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 14,
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amenities',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: p.amenities.map((amenity) {
              final icon = amenityIcons[amenity] ?? Icons.check_circle_outline;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      amenity,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 13,
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Property Agent',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      agent.initials,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
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
                      const SizedBox(height: 2),
                      Text(
                        agent.role,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Color(0xFFF59E0B), size: 14),
                          const SizedBox(width: 3),
                          Text(
                            agent.rating.toString(),
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.handshake_outlined, color: cs.outline, size: 14),
                          const SizedBox(width: 3),
                          Text(
                            '${agent.deals} deals',
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
                    const SizedBox(height: 8),
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
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: AppColors.primary, size: 18),
    );
  }

  // ---------- Location Map ----------

  Widget _buildLocationMap() {
    final cs = Theme.of(context).colorScheme;
    final propertyLocation = LatLng(p.latitude, p.longitude);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  color: cs.onSurfaceVariant, size: 16),
              const SizedBox(width: 4),
              Text(
                p.location,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
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
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 40,
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
        20,
        14,
        20,
        MediaQuery.of(context).padding.bottom + 14,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'You are currently renting this property',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 14,
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
            icon: const Icon(Icons.calendar_today_outlined, size: 16),
            label: const Text('TOUR'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 13),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
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
            icon: const Icon(Icons.chat_outlined, size: 16),
            label: const Text('CHAT'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 13),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Rent button
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RentPropertyScreen(property: p),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15),
              elevation: 2,
              shadowColor: AppColors.primary.withValues(alpha: 0.3),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            child: const Text('RENT NOW'),
          ),
        ),
      ],
    );
  }
}
