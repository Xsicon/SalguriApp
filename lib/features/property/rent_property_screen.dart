import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/property.dart';
import '../../services/api_service.dart';
import '../../services/supabase_service.dart';
import '../dashboard/dashboard_screen.dart';

class RentPropertyScreen extends StatefulWidget {
  final Property property;

  const RentPropertyScreen({super.key, required this.property});

  @override
  State<RentPropertyScreen> createState() => _RentPropertyScreenState();
}

class _RentPropertyScreenState extends State<RentPropertyScreen> {
  final _rentController = TextEditingController();
  final _depositController = TextEditingController();
  String _leaseTerm = '12 Months (Fixed)';
  bool _isSubmitting = false;

  Property get p => widget.property;

  static const _leaseOptions = [
    '6 Months (Fixed)',
    '12 Months (Fixed)',
    '24 Months (Fixed)',
    'Month-to-Month',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill rent from property price if it looks like a monthly amount
    final numericPrice = p.price.replaceAll(RegExp(r'[^\d.]'), '');
    final priceValue = double.tryParse(numericPrice) ?? 0;
    if (priceValue > 0 && priceValue < 50000) {
      _rentController.text = priceValue.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _rentController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Block renting your own property
    final currentUserId = SupabaseService.currentUser?.id;
    if (p.ownerUserId != null && p.ownerUserId == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot rent your own property'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final rent = double.tryParse(_rentController.text) ?? 0;
    if (rent <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid monthly rent amount')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ApiService.createRental(
        propertyId: p.id,
        monthlyRent: rent,
        leaseTerm: _leaseTerm,
        securityDeposit: double.tryParse(_depositController.text) ?? 0,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rental created successfully!'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg.contains('active rental')
              ? 'You already have an active rental'
              : 'Error: $msg'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Rent Property'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPropertySummary(),
            _buildRentalForm(),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildSubmitButton(),
    );
  }

  Widget _buildPropertySummary() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 80,
              height: 80,
              child: p.images.isNotEmpty
                  ? Image.network(p.images.first, fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _imagePlaceholder())
                  : _imagePlaceholder(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        p.location,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildMiniStat(Icons.bed_rounded, '${p.beds} Bed'),
                    const SizedBox(width: 12),
                    _buildMiniStat(Icons.bathtub_rounded, '${p.baths} Bath'),
                    const SizedBox(width: 12),
                    _buildMiniStat(Icons.square_foot_rounded, '${p.sqft} sqft'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textMuted, size: 14),
        const SizedBox(width: 3),
        Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.divider,
      child: const Center(child: Icon(Icons.home_outlined, color: AppColors.textMuted, size: 32)),
    );
  }

  Widget _buildRentalForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rental Details',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            // Monthly Rent
            const Text(
              'Monthly Rent (\$)',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _rentController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g. 850',
                prefixIcon: Container(
                  padding: const EdgeInsets.all(14),
                  child: const Text('\$', style: TextStyle(fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.w700)),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 40),
              ),
            ),
            const SizedBox(height: 20),
            // Security Deposit
            const Text(
              'Security Deposit (\$)',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _depositController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g. 2450 (optional)',
                prefixIcon: Container(
                  padding: const EdgeInsets.all(14),
                  child: const Text('\$', style: TextStyle(fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.w700)),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 40),
              ),
            ),
            const SizedBox(height: 20),
            // Lease Term
            const Text(
              'Lease Term',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _leaseOptions.map((term) {
                final isSelected = _leaseTerm == term;
                return GestureDetector(
                  onTap: () => setState(() => _leaseTerm = term),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primarySoft : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      term,
                      style: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : const Text('CONFIRM RENTAL'),
        ),
      ),
    );
  }
}
