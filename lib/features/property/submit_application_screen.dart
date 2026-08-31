import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/property.dart';
import '../../services/api_service.dart';
import '../../services/supabase_service.dart';
import '../rental/my_applications_screen.dart';

/// Reached from the property details "APPLY TO RENT" button. Submits a
/// rental application for staff review — this is the first step of the real
/// rental pipeline (application → approval → lease → deposit), not an
/// instant self-service booking.
class SubmitApplicationScreen extends StatefulWidget {
  final Property property;

  const SubmitApplicationScreen({super.key, required this.property});

  @override
  State<SubmitApplicationScreen> createState() => _SubmitApplicationScreenState();
}

class _SubmitApplicationScreenState extends State<SubmitApplicationScreen> {
  final _incomeController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  Property get p => widget.property;

  @override
  void dispose() {
    _incomeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final currentUserId = SupabaseService.currentUser?.id;
    if (p.ownerUserId != null && p.ownerUserId == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot apply to your own property'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ApiService.submitApplication(
        propertyId: p.id,
        monthlyIncome: double.tryParse(_incomeController.text),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted — the owner will review it soon.'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MyApplicationsScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg.contains('already have an active application')
              ? 'You already have an active application for this property'
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
      appBar: AppBar(title: const Text('Apply to Rent')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPropertySummary(),
            _buildApplicationForm(),
            SizedBox(height: 24.h),
          ],
        ),
      ),
      bottomNavigationBar: _buildSubmitButton(),
    );
  }

  Widget _buildPropertySummary() {
    return Container(
      margin: EdgeInsets.all(20.r),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18.r),
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
            borderRadius: BorderRadius.circular(12.r),
            child: SizedBox(
              width: 80.w,
              height: 80.h,
              child: p.images.isNotEmpty
                  ? Image.network(p.images.first, fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _imagePlaceholder())
                  : _imagePlaceholder(),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, color: AppColors.primary, size: 14.r),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        p.location,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  p.price,
                  style: TextStyle(color: AppColors.primary, fontSize: 14.sp, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.divider,
      child: Center(child: Icon(Icons.home_outlined, color: AppColors.textMuted, size: 32.r)),
    );
  }

  Widget _buildApplicationForm() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18.r),
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
            Text(
              'Applicant Details',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'The owner reviews this before drafting a lease — there is no credit '
              'bureau check, so tell them what they need to know.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5.sp),
            ),
            SizedBox(height: 20.h),
            Text(
              'Monthly Income (\$)',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: _incomeController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
              style: TextStyle(fontSize: 15.sp, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g. 1200 (optional)',
                prefixIcon: Container(
                  padding: EdgeInsets.all(14.r),
                  child: Text('\$', style: TextStyle(fontSize: 16.sp, color: AppColors.primary, fontWeight: FontWeight.w700)),
                ),
                prefixIconConstraints: BoxConstraints(minWidth: 40.w),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Employment / Notes',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: _notesController,
              maxLines: 4,
              style: TextStyle(fontSize: 14.sp, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Employer, role, references — anything the owner should know',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, MediaQuery.of(context).padding.bottom + 14.h),
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
        height: 56.h,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? SizedBox(
                  width: 22.w, height: 22.h,
                  child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : const Text('SUBMIT APPLICATION'),
        ),
      ),
    );
  }
}
