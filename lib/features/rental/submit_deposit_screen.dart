import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/document_template.dart';
import '../../services/api_service.dart';
import '../../services/supabase_service.dart';

/// Lets a tenant confirm their security deposit once a lease is fully
/// signed. No payment gateway exists yet, so this is the "manual" path:
/// upload a photo of the receipt for an out-of-band payment (bank transfer,
/// mobile money, cash) and have the business review it. A real "Pay Now"
/// gateway path is intentionally left as a disabled placeholder here rather
/// than simulated — a fake success state would be actively misleading.
class SubmitDepositScreen extends StatefulWidget {
  final MyLeaseSummary lease;
  const SubmitDepositScreen({super.key, required this.lease});

  @override
  State<SubmitDepositScreen> createState() => _SubmitDepositScreenState();
}

class _SubmitDepositScreenState extends State<SubmitDepositScreen> {
  final _amountController = TextEditingController();
  File? _receipt;
  bool _submitting = false;
  String? _error;

  bool get _wasRejected => widget.lease.depositStatus == 'rejected';
  bool get _pendingReview => widget.lease.depositStatus == 'pending_review';

  @override
  void initState() {
    super.initState();
    if (widget.lease.depositAmount != null) {
      _amountController.text = widget.lease.depositAmount!.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    setState(() => _receipt = File(picked.path));
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid deposit amount.');
      return;
    }
    if (_receipt == null) {
      setState(() => _error = 'Attach a photo of your payment receipt.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final path = await SupabaseService.uploadDepositReceipt(
        businessUserId: widget.lease.businessUserId,
        leaseId: widget.lease.id,
        file: _receipt!,
      );
      await ApiService.submitLeaseDeposit(
        leaseId: widget.lease.id,
        amount: amount,
        receiptPath: path,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not submit: $e';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security Deposit')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_pendingReview) _StatusBanner(
                color: AppColors.warning,
                icon: Icons.hourglass_top_rounded,
                text: 'Your receipt is awaiting review. You can resubmit below if you need to correct it.',
              ),
              if (_wasRejected) _StatusBanner(
                color: AppColors.error,
                icon: Icons.error_outline_rounded,
                text: widget.lease.depositAmount == null
                    ? 'Your previous receipt was rejected. Please resubmit.'
                    : 'Your previous receipt was rejected: resubmit with a valid receipt.',
              ),
              SizedBox(height: 12.h),
              Text(
                'Two ways to confirm your deposit',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              SizedBox(height: 12.h),
              _PayGatewayOption(),
              SizedBox(height: 12.h),
              _ManualUploadCard(
                amountController: _amountController,
                receipt: _receipt,
                onPickCamera: () => _pickReceipt(ImageSource.camera),
                onPickGallery: () => _pickReceipt(ImageSource.gallery),
              ),
              if (_error != null) ...[
                SizedBox(height: 12.h),
                Text(_error!, style: TextStyle(color: AppColors.error, fontSize: 13.sp)),
              ],
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: const StadiumBorder(),
                  ),
                  child: _submitting
                      ? SizedBox(
                          width: 20.r,
                          height: 20.r,
                          child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Submit for Review'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;
  const _StatusBanner({required this.color, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20.r),
          SizedBox(width: 10.w),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12.5.sp, color: color))),
        ],
      ),
    );
  }
}

/// The real payment-gateway path — intentionally disabled. Building a fake
/// "processing" animation here would misrepresent that a real charge
/// happened, which is exactly the problem this feature exists to avoid.
class _PayGatewayOption extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.55,
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.credit_card_rounded, color: AppColors.textMuted, size: 22.r),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pay Now', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  SizedBox(height: 2.h),
                  Text('Coming soon — direct payment isn’t available yet.',
                      style: TextStyle(fontSize: 11.5.sp, color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualUploadCard extends StatelessWidget {
  final TextEditingController amountController;
  final File? receipt;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;

  const _ManualUploadCard({
    required this.amountController,
    required this.receipt,
    required this.onPickCamera,
    required this.onPickGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 22.r),
              SizedBox(width: 12.w),
              Text('Upload Receipt', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            'Already paid the deposit by bank transfer, mobile money, or cash? Upload a photo of your receipt and it’ll be reviewed.',
            style: TextStyle(fontSize: 12.sp, color: AppColors.textMuted),
          ),
          SizedBox(height: 14.h),
          TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount paid',
              prefixText: '\$ ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
          ),
          SizedBox(height: 14.h),
          if (receipt != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: Image.file(receipt!, height: 140.h, width: double.infinity, fit: BoxFit.cover),
            ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickCamera,
                  icon: Icon(Icons.camera_alt_outlined, size: 18.r),
                  label: const Text('Camera'),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickGallery,
                  icon: Icon(Icons.photo_library_outlined, size: 18.r),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
