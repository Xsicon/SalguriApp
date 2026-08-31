import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';

class ServiceBookingConfirmationScreen extends StatelessWidget {
  final String requestNumber;
  final String propertyAddress;
  final String propertySubtitle;
  final List<String> serviceNames;
  final List<String> scheduledTimes;
  final double totalAmount;
  final String serviceRequestId;

  const ServiceBookingConfirmationScreen({
    super.key,
    required this.requestNumber,
    required this.propertyAddress,
    required this.propertySubtitle,
    required this.serviceNames,
    required this.scheduledTimes,
    required this.totalAmount,
    required this.serviceRequestId,
  });

  void _backToHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
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
        automaticallyImplyLeading: false,
        title: Text(
          l.tr('bookingConfirmed'),
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.r),
                child: Column(
                  children: [
                    _buildSuccessHeader(cs, l),
                    SizedBox(height: 20.h),
                    _buildBookingSummary(cs, l),
                  ],
                ),
              ),
            ),
            _buildBottomButton(context, l),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessHeader(ColorScheme cs, AppLocalizations l) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(22.r),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            width: 72.w,
            height: 72.h,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available_rounded,
              color: AppColors.primary,
              size: 38.r,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            l.tr('bookingConfirmedTitle'),
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 21.sp,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            l.tr('bookingConfirmedMessage'),
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 14.sp,
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              requestNumber,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingSummary(ColorScheme cs, AppLocalizations l) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.tr('bookingSummary'),
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 16.h),
          _summaryRow(cs, l.tr('selectedProperty'), propertyAddress),
          _summaryRow(cs, l.tr('location'), propertySubtitle),
          Divider(height: 28.h),
          ...List.generate(serviceNames.length, (index) {
            final schedule = index < scheduledTimes.length
                ? scheduledTimes[index]
                : scheduledTimes.isNotEmpty
                ? scheduledTimes.first
                : '';
            return _summaryRow(
              cs,
              serviceNames[index],
              schedule,
              icon: Icons.schedule_rounded,
            );
          }),
          Divider(height: 28.h),
          _summaryRow(
            cs,
            l.tr('estimatedTotal'),
            '\$${totalAmount.toStringAsFixed(2)}',
            valueColor: AppColors.primary,
            isEmphasized: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    ColorScheme cs,
    String label,
    String value, {
    IconData? icon,
    Color? valueColor,
    bool isEmphasized = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 14.sp,
                fontWeight: isEmphasized ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Flexible(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14.r, color: cs.onSurfaceVariant),
                  SizedBox(width: 4.w),
                ],
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: valueColor ?? cs.onSurfaceVariant,
                      fontSize: 14.sp,
                      fontWeight: isEmphasized
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context, AppLocalizations l) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
      color: Theme.of(context).colorScheme.surface,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _backToHome(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
            padding: EdgeInsets.symmetric(vertical: 17.h),
            elevation: 0,
          ),
          child: Text(
            l.tr('backToHome'),
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
