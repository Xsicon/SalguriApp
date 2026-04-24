import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/rental.dart';


// ---------------------------------------------------------------------------
// Pay Rent Screen
// ---------------------------------------------------------------------------

enum _AmountOption { full, partial, custom }

enum _PaymentMethod { evcPlus, zaad, creditCard }

extension _PaymentMethodExt on _PaymentMethod {
  String get label {
    switch (this) {
      case _PaymentMethod.evcPlus:
        return 'EVC Plus';
      case _PaymentMethod.zaad:
        return 'Zaad';
      case _PaymentMethod.creditCard:
        return 'Credit Card';
    }
  }

  String get subtitle {
    switch (this) {
      case _PaymentMethod.evcPlus:
        return 'Hormuud Mobile Money';
      case _PaymentMethod.zaad:
        return 'Telesom Mobile Money';
      case _PaymentMethod.creditCard:
        return 'Visa, Mastercard, Amex';
    }
  }

  IconData get icon {
    switch (this) {
      case _PaymentMethod.evcPlus:
        return Icons.phone_android_rounded;
      case _PaymentMethod.zaad:
        return Icons.phone_android_rounded;
      case _PaymentMethod.creditCard:
        return Icons.credit_card_rounded;
    }
  }

  Color get color {
    switch (this) {
      case _PaymentMethod.evcPlus:
        return const Color(0xFF22C55E);
      case _PaymentMethod.zaad:
        return const Color(0xFF3B82F6);
      case _PaymentMethod.creditCard:
        return const Color(0xFF8B5CF6);
    }
  }
}

class PayRentScreen extends StatefulWidget {
  final Rental rental;

  const PayRentScreen({super.key, required this.rental});

  @override
  State<PayRentScreen> createState() => _PayRentScreenState();
}

class _PayRentScreenState extends State<PayRentScreen> {
  _AmountOption _amountOption = _AmountOption.full;
  _PaymentMethod _paymentMethod = _PaymentMethod.evcPlus;
  bool _autoPayEnabled = false;
  bool _isPaying = false;

  final _customController = TextEditingController();

  static const double _platformFeeRate = 0.02;

  double get _baseAmount {
    switch (_amountOption) {
      case _AmountOption.full:
        return widget.rental.monthlyRent;
      case _AmountOption.partial:
        return widget.rental.monthlyRent / 2;
      case _AmountOption.custom:
        return double.tryParse(_customController.text) ?? 0;
    }
  }

  double get _platformFee =>
      double.parse((_baseAmount * _platformFeeRate).toStringAsFixed(2));

  double get _totalAmount => _baseAmount + _platformFee;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _onPay() async {
    if (_baseAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }
    setState(() => _isPaying = true);
    // Simulate a short delay for UX feedback
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _isPaying = false);
    _showSuccessSheet();
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PaySuccessSheet(
        amount: _totalAmount,
        address: widget.rental.address,
        method: _paymentMethod.label,
        onDone: () {
          Navigator.of(context).pop(); // close sheet
          Navigator.of(context).pop(true); // back with paid=true
        },
      ),
    );
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
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: cs.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Pay Rent',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history_rounded,
                color: cs.onSurfaceVariant, size: 22),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResidenceCard(cs),
            const SizedBox(height: 20),
            _buildAmountSection(cs),
            const SizedBox(height: 20),
            _buildPaymentMethodSection(cs),
            const SizedBox(height: 20),
            _buildAutoPayRow(cs),
            const SizedBox(height: 20),
            _buildSummaryCard(cs),
          ],
        ),
      ),
      bottomNavigationBar: _buildPayButton(cs),
    );
  }

  // ---------- Residence Card ----------

  Widget _buildResidenceCard(ColorScheme cs) {
    final daysUntilDue =
        widget.rental.nextDueDate.difference(DateTime.now()).inDays;
    final isOverdue = daysUntilDue < 0;
    final dueText = isOverdue
        ? 'OVERDUE'
        : daysUntilDue == 0
            ? 'DUE TODAY'
            : 'DUE IN $daysUntilDue DAYS';
    final dueColor = isOverdue
        ? const Color(0xFFEF4444)
        : daysUntilDue <= 3
            ? const Color(0xFFF59E0B)
            : AppColors.primary;
    final dueBgColor = isOverdue
        ? const Color(0xFFFEE2E2)
        : daysUntilDue <= 3
            ? const Color(0xFFFEF3C7)
            : const Color(0xFFEEF2FF);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.apartment_rounded,
                color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT RESIDENCE',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.rental.address,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.rental.location,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: dueBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              dueText,
              style: TextStyle(
                color: dueColor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Amount Section ----------

  Widget _buildAmountSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Amount',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _AmountChip(
              label: 'Full',
              sublabel:
                  '\$${widget.rental.monthlyRent.toStringAsFixed(0)}',
              isSelected: _amountOption == _AmountOption.full,
              onTap: () =>
                  setState(() => _amountOption = _AmountOption.full),
            ),
            const SizedBox(width: 10),
            _AmountChip(
              label: 'Partial',
              sublabel:
                  '\$${(widget.rental.monthlyRent / 2).toStringAsFixed(0)}',
              isSelected: _amountOption == _AmountOption.partial,
              onTap: () =>
                  setState(() => _amountOption = _AmountOption.partial),
            ),
            const SizedBox(width: 10),
            _AmountChip(
              label: 'Other',
              sublabel: 'Custom',
              isSelected: _amountOption == _AmountOption.custom,
              onTap: () =>
                  setState(() => _amountOption = _AmountOption.custom),
            ),
          ],
        ),
        if (_amountOption == _AmountOption.custom) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _customController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Enter amount',
              prefixText: '\$ ',
              filled: true,
              fillColor: cs.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ],
    );
  }

  // ---------- Payment Method ----------

  Widget _buildPaymentMethodSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ..._PaymentMethod.values.map((method) {
          final isSelected = _paymentMethod == method;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => setState(() => _paymentMethod = method),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.05)
                      : cs.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : cs.outlineVariant,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: method.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(method.icon,
                          color: method.color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            method.label,
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            method.subtitle,
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : cs.outlineVariant,
                          width: 2,
                        ),
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 14)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ---------- Auto Pay Toggle ----------

  Widget _buildAutoPayRow(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.autorenew_rounded,
                color: Color(0xFFF59E0B), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recurring Auto-pay',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Enable monthly automatic payments',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _autoPayEnabled,
            onChanged: (v) => setState(() => _autoPayEnabled = v),
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  // ---------- Summary Card ----------

  Widget _buildSummaryCard(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Summary',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _buildSummaryRow(cs, 'Monthly Rent',
              '\$${_baseAmount.toStringAsFixed(2)}'),
          const SizedBox(height: 10),
          _buildSummaryRow(
              cs, 'Platform Fee (2%)', '\$${_platformFee.toStringAsFixed(2)}',
              valueColor: const Color(0xFFF59E0B)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: cs.outlineVariant),
          ),
          _buildSummaryRow(
            cs,
            'Total Amount',
            '\$${_totalAmount.toStringAsFixed(2)}',
            labelBold: true,
            valueBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    ColorScheme cs,
    String label,
    String value, {
    Color? valueColor,
    bool labelBold = false,
    bool valueBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 14,
            fontWeight: labelBold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? cs.onSurface,
            fontSize: 14,
            fontWeight: valueBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ---------- Pay Button ----------

  Widget _buildPayButton(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isPaying ? null : _onPay,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 17),
                elevation: 0,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              child: _isPaying
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text('PAY \$${_totalAmount.toStringAsFixed(2)} NOW'),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'By proceeding, you agree to our Terms of Service. '
            'Your payment is secured and encrypted.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Amount chip
// ---------------------------------------------------------------------------

class _AmountChip extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool isSelected;
  final VoidCallback onTap;

  const _AmountChip({
    required this.label,
    required this.sublabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : cs.outlineVariant,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : cs.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                sublabel,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white70
                      : cs.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Success Bottom Sheet
// ---------------------------------------------------------------------------

class _PaySuccessSheet extends StatelessWidget {
  final double amount;
  final String address;
  final String method;
  final VoidCallback onDone;

  const _PaySuccessSheet({
    required this.amount,
    required this.address,
    required this.method,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (_, v, child) =>
                Transform.scale(scale: v, child: child),
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFF22C55E),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 40),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Payment Successful!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${amount.toStringAsFixed(2)} paid via $method',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'for $address',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 15),
                elevation: 0,
                textStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
              child: const Text('BACK TO MY RENTAL'),
            ),
          ),
        ],
      ),
    );
  }
}
