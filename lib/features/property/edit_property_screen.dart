import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/agent.dart';
import '../../core/models/property.dart';
import '../../services/api_service.dart';

const _amenityOptions = [
  'Swimming Pool',
  'Garage',
  'Garden',
  'Security',
  'AC',
  'Balcony',
  'Gym',
  'Parking',
  'Elevator',
  'Rooftop',
];

class EditPropertyScreen extends StatefulWidget {
  final Property property;

  const EditPropertyScreen({super.key, required this.property});

  @override
  State<EditPropertyScreen> createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Agent selection
  List<Agent> _agents = [];
  Agent? _selectedAgent;

  // Step 1 – Basic Info
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _priceLabelController;
  late String _type;

  // Step 2 – Details
  late final TextEditingController _bedsController;
  late final TextEditingController _bathsController;
  late final TextEditingController _sqftController;
  late final TextEditingController _yearBuiltController;
  late final TextEditingController _locationController;
  late final Set<String> _selectedAmenities;

  // Location pin
  late LatLng _selectedLocation;

  // Step 3 – Images (existing URLs)
  late List<String> _imageUrls;

  @override
  void initState() {
    super.initState();
    final p = widget.property;

    _titleController = TextEditingController(text: p.title);
    _descriptionController = TextEditingController(text: p.description);
    _priceController = TextEditingController(text: p.price);
    _priceLabelController = TextEditingController(text: p.priceLabel);
    _type = p.type;

    _bedsController = TextEditingController(text: p.beds > 0 ? '${p.beds}' : '');
    _bathsController = TextEditingController(text: p.baths > 0 ? '${p.baths}' : '');
    _sqftController = TextEditingController(text: p.sqft > 0 ? '${p.sqft}' : '');
    _yearBuiltController = TextEditingController(text: '${p.yearBuilt}');
    _locationController = TextEditingController(text: p.location);
    _selectedAmenities = Set<String>.from(p.amenities);

    _selectedLocation = LatLng(p.latitude, p.longitude);
    _imageUrls = List<String>.from(p.images);
    _selectedAgent = p.agent;

    _loadAgents();
  }

  Future<void> _loadAgents() async {
    try {
      final agents = await ApiService.getAllAgents();
      if (mounted) setState(() => _agents = agents);
    } catch (e) {
      debugPrint('Error loading agents: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _priceLabelController.dispose();
    _bedsController.dispose();
    _bathsController.dispose();
    _sqftController.dispose();
    _yearBuiltController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextStep() {
    if (_currentStep < 2) _goToStep(_currentStep + 1);
  }

  void _prevStep() {
    if (_currentStep > 0) _goToStep(_currentStep - 1);
  }

  void _removeImage(int index) {
    setState(() => _imageUrls.removeAt(index));
  }

  bool _validateAllFields() {
    final errors = <String>[];
    if (_titleController.text.trim().isEmpty) errors.add('Title');
    if (_priceController.text.trim().isEmpty) errors.add('Price');
    if (_locationController.text.trim().isEmpty) errors.add('Location');

    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Missing required fields: ${errors.join(', ')}'),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_validateAllFields()) return;

    setState(() => _isSubmitting = true);

    try {
      final body = <String, dynamic>{
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'type': _type,
        'price': _priceController.text.trim(),
        'price_label': _priceLabelController.text.trim(),
        'beds': int.tryParse(_bedsController.text) ?? 0,
        'baths': int.tryParse(_bathsController.text) ?? 0,
        'sqft': int.tryParse(_sqftController.text) ?? 0,
        'year_built': int.tryParse(_yearBuiltController.text) ?? 2024,
        'location': _locationController.text.trim(),
        'amenities': _selectedAmenities.toList(),
        'images': _imageUrls,
        'latitude': _selectedLocation.latitude,
        'longitude': _selectedLocation.longitude,
        if (_selectedAgent != null) 'agent_id': _selectedAgent!.id,
      };

      await ApiService.updateProperty(widget.property.id, body);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Property updated successfully!'),
          backgroundColor: AppColors.primary,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.r, color: cs.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Edit Listing',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildStepIndicator(cs),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1BasicInfo(cs),
                _buildStep2Details(cs),
                _buildStep3Images(cs),
              ],
            ),
          ),
          _buildBottomBar(cs),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(ColorScheme cs) {
    const labels = ['Basic Info', 'Details', 'Images'];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      color: cs.surface,
      child: Row(
        children: List.generate(3, (i) {
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;
          return Expanded(
            child: GestureDetector(
              onTap: () => _goToStep(i),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (i > 0)
                        Expanded(
                          child: Container(
                            height: 2.h,
                            color: isDone || isActive ? AppColors.primary : cs.outlineVariant,
                          ),
                        ),
                      Container(
                        width: 28.w,
                        height: 28.h,
                        decoration: BoxDecoration(
                          color: isDone
                              ? AppColors.primary
                              : isActive
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : cs.surfaceContainerHighest,
                          shape: BoxShape.circle,
                          border: isActive ? Border.all(color: AppColors.primary, width: 2) : null,
                        ),
                        child: Center(
                          child: isDone
                              ? Icon(Icons.check_rounded, color: Colors.white, size: 16.r)
                              : Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    color: isActive ? AppColors.primary : cs.onSurfaceVariant,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      if (i < 2)
                        Expanded(
                          child: Container(
                            height: 2.h,
                            color: isDone && i < _currentStep - 1
                                ? AppColors.primary
                                : i < _currentStep
                                    ? AppColors.primary
                                    : cs.outlineVariant,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    labels[i],
                    style: TextStyle(
                      color: isActive ? AppColors.primary : cs.onSurfaceVariant,
                      fontSize: 11.sp,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // Step 1
  Widget _buildStep1BasicInfo(ColorScheme cs) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('BASIC INFORMATION', cs),
          SizedBox(height: 16.h),
          _buildTextField(controller: _titleController, label: 'Title', hint: 'e.g. Modern Villa in Hodan', cs: cs),
          SizedBox(height: 16.h),
          _buildDescriptionField(cs),
          SizedBox(height: 16.h),
          _buildTypeSelector(cs),
          SizedBox(height: 16.h),
          _buildTextField(controller: _priceController, label: 'Price', hint: 'e.g. \$275,000', cs: cs),
          SizedBox(height: 16.h),
          _buildTextField(controller: _priceLabelController, label: 'Price Label', hint: 'e.g. Est. \$1,450/mo', cs: cs),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  // Step 2
  Widget _buildStep2Details(ColorScheme cs) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('PROPERTY DETAILS', cs),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(child: _buildNumberField(controller: _bedsController, label: 'Beds', hint: '3', cs: cs)),
              SizedBox(width: 12.w),
              Expanded(child: _buildNumberField(controller: _bathsController, label: 'Baths', hint: '2', cs: cs)),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(child: _buildNumberField(controller: _sqftController, label: 'Sqft', hint: '1800', cs: cs)),
              SizedBox(width: 12.w),
              Expanded(child: _buildNumberField(controller: _yearBuiltController, label: 'Year Built', hint: '2024', cs: cs)),
            ],
          ),
          SizedBox(height: 16.h),
          _buildTextField(controller: _locationController, label: 'Location', hint: 'e.g. Hodan, Mogadishu', cs: cs),
          SizedBox(height: 16.h),
          _buildLocationPicker(cs),
          SizedBox(height: 16.h),
          _buildAgentSelector(cs),
          SizedBox(height: 24.h),
          _buildAmenitiesSelector(cs),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  // Step 3
  Widget _buildStep3Images(ColorScheme cs) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('PROPERTY IMAGES', cs),
          SizedBox(height: 8.h),
          Text(
            'Manage existing images',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13.sp, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 16.h),
          if (_imageUrls.isNotEmpty) ...[
            Text(
              '${_imageUrls.length} image${_imageUrls.length > 1 ? 's' : ''}',
              style: TextStyle(color: cs.onSurface, fontSize: 15.sp, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 12.h),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: _imageUrls.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: Image.network(
                        _imageUrls[index],
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: cs.surfaceContainerHighest,
                          child: Icon(Icons.broken_image, color: cs.outline),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4.h,
                      right: 4.w,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          width: 24.w,
                          height: 24.h,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(Icons.close_rounded, color: Colors.white, size: 14.r),
                          ),
                        ),
                      ),
                    ),
                    if (index == 0)
                      Positioned(
                        bottom: 4.h,
                        left: 4.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            'Cover',
                            style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ] else
            Padding(
              padding: EdgeInsets.symmetric(vertical: 32.h),
              child: Center(
                child: Text('No images', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14.sp)),
              ),
            ),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  // --- Shared widgets ---

  Widget _buildLocationPicker(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pin Location',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'Tap on the map to set the property location',
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 12.sp,
          ),
        ),
        SizedBox(height: 8.h),
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
              initialCenter: _selectedLocation,
              initialZoom: 13,
              onTap: (tapPosition, point) {
                setState(() => _selectedLocation = point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.salguri.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocation,
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
        SizedBox(height: 6.h),
        Text(
          'Lat: ${_selectedLocation.latitude.toStringAsFixed(5)}, '
          'Lng: ${_selectedLocation.longitude.toStringAsFixed(5)}',
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String text, ColorScheme cs) {
    return Text(
      text,
      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.sp, fontWeight: FontWeight.w600, letterSpacing: 0.8),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required ColorScheme cs,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: cs.onSurface, fontSize: 14.sp, fontWeight: FontWeight.w600)),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(color: cs.onSurface, fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14.sp),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required ColorScheme cs,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: cs.onSurface, fontSize: 14.sp, fontWeight: FontWeight.w600)),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(color: cs.onSurface, fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14.sp),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Description', style: TextStyle(color: cs.onSurface, fontSize: 14.sp, fontWeight: FontWeight.w600)),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: TextField(
            controller: _descriptionController,
            maxLines: 4,
            style: TextStyle(color: cs.onSurface, fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: 'Describe the property...',
              hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14.sp),
              contentPadding: EdgeInsets.all(16.r),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelector(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Type', style: TextStyle(color: cs.onSurface, fontSize: 14.sp, fontWeight: FontWeight.w600)),
        SizedBox(height: 8.h),
        Row(
          children: ['For Rent', 'For Sale'].map((type) {
            final isSelected = _type == type;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _type = type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: EdgeInsets.only(
                    right: type == 'For Rent' ? 10.w : 0,
                    left: type == 'For Sale' ? 10.w : 0,
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : cs.surface,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : cs.outlineVariant,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      type,
                      style: TextStyle(
                        color: isSelected ? AppColors.primary : cs.onSurface,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAgentSelector(ColorScheme cs) {
    // Only use the selected value if it exists in the loaded agents list
    final agentIds = _agents.map((a) => a.id).toSet();
    final currentValue = _selectedAgent != null && agentIds.contains(_selectedAgent!.id)
        ? _selectedAgent!.id
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Assign Agent', style: TextStyle(color: cs.onSurface, fontSize: 14.sp, fontWeight: FontWeight.w600)),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: cs.outlineVariant),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentValue,
              isExpanded: true,
              hint: Text(
                _agents.isEmpty ? 'Loading agents...' : 'Select an agent (optional)',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14.sp),
              ),
              icon: Icon(Icons.keyboard_arrow_down, color: cs.onSurfaceVariant),
              dropdownColor: cs.surface,
              borderRadius: BorderRadius.circular(12.r),
              items: [
                DropdownMenuItem<String>(
                  value: '',
                  child: Text('None', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14.sp)),
                ),
                ..._agents.map((agent) {
                  return DropdownMenuItem<String>(
                    value: agent.id,
                    child: Text(
                      '${agent.name}${agent.role.isNotEmpty ? ' — ${agent.role}' : ''}',
                      style: TextStyle(color: cs.onSurface, fontSize: 14.sp),
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  if (value == null || value.isEmpty) {
                    _selectedAgent = null;
                  } else {
                    _selectedAgent = _agents.firstWhere((a) => a.id == value);
                  }
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmenitiesSelector(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Amenities', style: TextStyle(color: cs.onSurface, fontSize: 17.sp, fontWeight: FontWeight.w700)),
        SizedBox(height: 14.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: _amenityOptions.map((amenity) {
            final isSelected = _selectedAmenities.contains(amenity);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedAmenities.remove(amenity);
                  } else {
                    _selectedAmenities.add(amenity);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : cs.surface,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : cs.outlineVariant,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      Icon(Icons.check_rounded, color: AppColors.primary, size: 16.r),
                      SizedBox(width: 6.w),
                    ],
                    Text(
                      amenity,
                      style: TextStyle(
                        color: isSelected ? AppColors.primary : cs.onSurface,
                        fontSize: 13.sp,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBottomBar(ColorScheme cs) {
    final isLastStep = _currentStep == 2;

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: Offset(0, -3.h),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : _prevStep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.onSurface,
                  side: BorderSide(color: cs.outlineVariant),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  textStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
                ),
                child: const Text('BACK'),
              ),
            ),
          if (_currentStep > 0) SizedBox(width: 12.w),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : isLastStep
                      ? _submit
                      : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: cs.surfaceContainerHighest,
                foregroundColor: Colors.white,
                disabledForegroundColor: cs.onSurfaceVariant,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                padding: EdgeInsets.symmetric(vertical: 16.h),
                elevation: 0,
                textStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
              child: _isSubmitting
                  ? SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(isLastStep ? 'SAVE CHANGES' : 'NEXT'),
            ),
          ),
        ],
      ),
    );
  }
}
