import 'package:flutter/material.dart';
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
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildSuccessHeader(cs, l),
                    const SizedBox(height: 20),
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: AppColors.primary,
              size: 38,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l.tr('bookingConfirmedTitle'),
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l.tr('bookingConfirmedMessage'),
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 14,
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              requestNumber,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 13,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.tr('bookingSummary'),
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),
          _summaryRow(cs, l.tr('selectedProperty'), propertyAddress),
          _summaryRow(cs, l.tr('location'), propertySubtitle),
          const Divider(height: 28),
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
          const Divider(height: 28),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 14,
                fontWeight: isEmphasized ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: valueColor ?? cs.onSurfaceVariant,
                      fontSize: 14,
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      color: Theme.of(context).colorScheme.surface,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _backToHome(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 17),
            elevation: 0,
          ),
          child: Text(
            l.tr('backToHome'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
