import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../services/api_service.dart';
import 'service_booking_confirmation_screen.dart';

// ---------------------------------------------------------------------------
// Public data transfer object — passed from ServiceRequestScreen
// ---------------------------------------------------------------------------

class CheckoutServiceItem {
  final String name;
  final double price;
  final IconData icon;
  final String categoryId;
  final String categoryName;

  const CheckoutServiceItem({
    required this.name,
    required this.price,
    required this.icon,
    required this.categoryId,
    required this.categoryName,
  });
}

class _TimeSlot {
  final String label;
  bool isSelected;
  _TimeSlot(this.label) : isSelected = false;
}

// Provider name per category
String _providerFor(String categoryId) {
  const map = {
    'electrical': 'FixPro Electrical',
    'plumbing': 'City Plumbing',
    'hvac': 'CoolAir Services',
    'cleaning': 'CleanPro Team',
    'painting': 'ColorMaster Pro',
  };
  return map[categoryId] ?? 'Salguri Provider';
}

// Generate 3 time slots starting from next rounded hour
List<_TimeSlot> _generateSlots(AppLocalizations l) {
  final now = DateTime.now();
  // Round up to next 30-min mark
  final startMinute = now.minute < 30 ? 30 : 60;
  var base = DateTime(
    now.year,
    now.month,
    now.day,
    now.hour,
  ).add(Duration(minutes: startMinute));

  final slots = <_TimeSlot>[];
  for (int i = 0; i < 3; i++) {
    final t = base.add(Duration(minutes: i * 90));
    final hour = t.hour;
    final minute = t.minute == 0 ? '00' : '${t.minute}';
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final isToday = t.day == now.day;
    final dayLabel = isToday ? l.tr('today') : l.tr('tomorrow');
    slots.add(_TimeSlot('$dayLabel, $displayHour:$minute $period'));
  }
  slots.first.isSelected = true;
  return slots;
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ServiceCheckoutScreen extends StatefulWidget {
  final List<CheckoutServiceItem> items;
  final String urgencyLabel;
  final double urgencySurcharge;
  final double serviceFee;
  final String propertyAddress;
  final String propertySubtitle;
  final String description;

  const ServiceCheckoutScreen({
    super.key,
    required this.items,
    required this.urgencyLabel,
    required this.urgencySurcharge,
    required this.serviceFee,
    required this.propertyAddress,
    required this.propertySubtitle,
    this.description = '',
  });

  @override
  State<ServiceCheckoutScreen> createState() => _ServiceCheckoutScreenState();
}

class _ServiceCheckoutScreenState extends State<ServiceCheckoutScreen> {
  bool _isSubmitting = false;

  // Each item gets its own set of time slots
  List<List<_TimeSlot>>? _itemSlots;

  static const double _platformFeeRate = 0.025; // 2.5%

  double get _subtotal => widget.items.fold(0.0, (s, i) => s + i.price);

  double get _platformFee =>
      double.parse((_subtotal * _platformFeeRate).toStringAsFixed(2));

  double get _total =>
      _subtotal + widget.urgencySurcharge + widget.serviceFee + _platformFee;

  String get _requestCategory {
    final categoryNames = <String>{
      for (final item in widget.items) item.categoryName,
    };
    return categoryNames.join(', ');
  }

  List<List<_TimeSlot>> _getItemSlots(AppLocalizations l) {
    _itemSlots ??= List.generate(widget.items.length, (_) => _generateSlots(l));
    return _itemSlots!;
  }

  List<String> _selectedSlotLabels() {
    final itemSlots = _itemSlots ?? <List<_TimeSlot>>[];
    return itemSlots
        .map((slots) => slots.firstWhere((slot) => slot.isSelected).label)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    final itemSlots = _getItemSlots(l);

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
          l.tr('confirmBooking'),
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel(l.tr('orderSummary'), cs),
                  SizedBox(height: 12.h),
                  ...List.generate(widget.items.length, (i) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 14.h),
                      child: _buildServiceCard(
                        widget.items[i],
                        itemSlots[i],
                        cs,
                      ),
                    );
                  }),
                  SizedBox(height: 8.h),
                  _buildPriceBreakdown(cs),
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
  // Section label
  // ---------------------------------------------------------------------------

  Widget _buildSectionLabel(String text, ColorScheme cs) {
    return Text(
      text,
      style: TextStyle(
        color: cs.onSurfaceVariant,
        fontSize: 12.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Service card
  // ---------------------------------------------------------------------------

  Widget _buildServiceCard(
    CheckoutServiceItem item,
    List<_TimeSlot> slots,
    ColorScheme cs,
  ) {
    final l = AppLocalizations.of(context);
    final isUrgent = widget.urgencyLabel != 'Standard';
    final urgencyColor = widget.urgencyLabel == 'Emergency'
        ? const Color(0xFFEF4444)
        : const Color(0xFFF59E0B);
    final urgencyBg = widget.urgencyLabel == 'Emergency'
        ? const Color(0xFFFEE2E2)
        : const Color(0xFFFEF3C7);
    final provider = _providerFor(item.categoryId);
    final eta = widget.urgencyLabel == 'Emergency'
        ? '30 mins'
        : widget.urgencyLabel == 'Urgent'
        ? '45 mins'
        : '1–2 hours';

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                    child: Icon(item.icon, color: AppColors.primary, size: 22.r),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: TextStyle(
                                color: cs.onSurface,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (isUrgent) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 3.h,
                              ),
                              decoration: BoxDecoration(
                                color: urgencyBg,
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                widget.urgencyLabel,
                                style: TextStyle(
                                  color: urgencyColor,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        provider,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 13.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: const Color(0xFFF59E0B),
                            size: 14.r,
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            '4.8 (94 reviews)',
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 12.sp,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            '•',
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 12.sp,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'ETA: $eta',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Schedule time
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: cs.outlineVariant)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.tr('scheduleTime'),
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                SizedBox(height: 10.h),
                SizedBox(
                  height: 40.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: slots.length,
                    separatorBuilder: (context, index) =>
                        SizedBox(width: 8.w),
                    itemBuilder: (context, idx) {
                      final slot = slots[idx];
                      return GestureDetector(
                        onTap: () => setState(() {
                          for (final s in slots) {
                            s.isSelected = false;
                          }
                          slot.isSelected = true;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 10.h,
                          ),
                          decoration: BoxDecoration(
                            color: slot.isSelected
                                ? AppColors.primary.withValues(alpha: 0.06)
                                : cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: slot.isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: slot.isSelected ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            slot.label,
                            style: TextStyle(
                              color: slot.isSelected
                                  ? AppColors.primary
                                  : cs.onSurfaceVariant,
                              fontSize: 13.sp,
                              fontWeight: slot.isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Price Breakdown
  // ---------------------------------------------------------------------------

  Widget _buildPriceBreakdown(ColorScheme cs) {
    final l = AppLocalizations.of(context);
    final hasUrgencySurcharge = widget.urgencySurcharge > 0;

    return Container(
      padding: EdgeInsets.all(18.r),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.tr('priceBreakdown'),
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 16.h),
          _priceRow(l.tr('subtotal'), '\$${_subtotal.toStringAsFixed(2)}', cs),
          if (hasUrgencySurcharge)
            _priceRow(
              '${widget.urgencyLabel} Fee',
              '+\$${widget.urgencySurcharge.toStringAsFixed(2)}',
              cs,
              valueColor: const Color(0xFFF59E0B),
              icon: Icons.info_outline_rounded,
            ),
          _priceRow(
            l.tr('serviceFee'),
            '+\$${widget.serviceFee.toStringAsFixed(2)}',
            cs,
          ),
          _priceRow(
            l.tr('platformFee'),
            '+\$${_platformFee.toStringAsFixed(2)}',
            cs,
          ),
          Divider(color: cs.outlineVariant, height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.tr('totalAmount'),
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '\$${_total.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(
    String label,
    String value,
    ColorScheme cs, {
    Color? valueColor,
    IconData? icon,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14.sp),
              ),
              if (icon != null) ...[
                SizedBox(width: 4.w),
                Icon(icon, size: 14.r, color: valueColor ?? cs.onSurfaceVariant),
              ],
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? cs.onSurface,
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
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSubmitting
              ? null
              : () async {
                  setState(() => _isSubmitting = true);
                  try {
                    final req = await ApiService.createServiceRequest(
                      category: _requestCategory,
                      description: widget.description,
                      urgency: widget.urgencyLabel,
                      totalAmount: _total,
                      paymentMethod: 'Booking',
                      scheduledTime: _selectedSlotLabels().join(' | '),
                    );
                    if (!mounted) return;
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ServiceBookingConfirmationScreen(
                          requestNumber: req.shortNumber,
                          propertyAddress: widget.propertyAddress,
                          propertySubtitle: widget.propertySubtitle,
                          serviceNames: widget.items
                              .map((item) => item.name)
                              .toList(),
                          scheduledTimes: _selectedSlotLabels(),
                          totalAmount: _total,
                          serviceRequestId: req.id,
                        ),
                      ),
                    );
                  } catch (e, st) {
                    debugPrint('=== createServiceRequest ERROR ===');
                    debugPrint('Error: $e');
                    debugPrint('Stack: $st');
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } finally {
                    if (mounted) setState(() => _isSubmitting = false);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
            padding: EdgeInsets.symmetric(vertical: 17.h),
            elevation: 0,
            textStyle: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${l.tr('bookNow')} \$${_total.toStringAsFixed(2)}'),
              SizedBox(width: 8.w),
              Icon(Icons.arrow_forward_rounded, size: 18.r),
            ],
          ),
        ),
      ),
    );
  }
}
