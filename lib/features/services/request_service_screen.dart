import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/rental.dart';
import '../../core/models/vendor_marketplace.dart';
import '../../services/api_service.dart';
import 'my_service_requests_screen.dart';

/// Submits a service request — the customer-facing entry point that
/// previously didn't exist anywhere in the app. Two modes:
///   - [directVendor] set: a direct booking with the specific company the
///     customer picked in the Job Marketplace.
///   - [directVendor] null: a request tied to the customer's active leased
///     property, routed through that property's PM's own dispatch rules.
class RequestServiceScreen extends StatefulWidget {
  final VendorMarketplacePost? directVendor;
  const RequestServiceScreen({super.key, this.directVendor});

  @override
  State<RequestServiceScreen> createState() => _RequestServiceScreenState();
}

class _RequestServiceScreenState extends State<RequestServiceScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _category = TextEditingController();

  Rental? _activeRental;
  bool _loadingRental = true;
  bool _submitting = false;

  bool get _isDirect => widget.directVendor != null;

  @override
  void initState() {
    super.initState();
    _category.text = widget.directVendor?.packageLabel ?? '';
    if (_isDirect) {
      _loadingRental = false;
    } else {
      ApiService.getActiveRental().then((r) {
        if (!mounted) return;
        setState(() {
          _activeRental = r;
          _loadingRental = false;
        });
      });
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _category.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    if (!_isDirect && _activeRental == null) return;

    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ApiService.createVendorServiceRequest(
        scope: _isDirect ? 'direct' : 'property',
        rentalId: _isDirect ? null : _activeRental!.id,
        vendorBusinessUserId: _isDirect ? widget.directVendor!.businessUserId : null,
        category: _category.text.trim().isEmpty ? 'general' : _category.text.trim(),
        title: _title.text.trim(),
        description: _description.text.trim().isEmpty ? null : _description.text.trim(),
      );
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Request sent.')));
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const MyServiceRequestsScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      messenger.showSnackBar(SnackBar(content: Text('Could not send request: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Request Service', style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: _loadingRental
            ? Center(child: CircularProgressIndicator(color: AppColors.primary))
            : (!_isDirect && _activeRental == null)
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.r),
                      child: Text(
                        'You need an active lease to request property service. '
                        'Try the Job Marketplace to book a provider directly instead.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14.sp, color: AppColors.textMuted),
                      ),
                    ),
                  )
                : Form(
                    key: _form,
                    child: ListView(
                      padding: EdgeInsets.all(20.r),
                      children: [
                        if (_isDirect) ...[
                          Container(
                            padding: EdgeInsets.all(14.r),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            child: Text(
                              'Requesting from ${widget.directVendor!.companyName}',
                              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                            ),
                          ),
                          SizedBox(height: 16.h),
                        ] else ...[
                          Container(
                            padding: EdgeInsets.all(14.r),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            child: Text(
                              'For your property: ${_activeRental!.address}',
                              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                            ),
                          ),
                          SizedBox(height: 16.h),
                        ],
                        Text('CATEGORY', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
                        SizedBox(height: 6.h),
                        TextFormField(
                          controller: _category,
                          decoration: const InputDecoration(hintText: 'e.g. plumbing, cleaning, landscaping'),
                        ),
                        SizedBox(height: 16.h),
                        Text('TITLE', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
                        SizedBox(height: 6.h),
                        TextFormField(
                          controller: _title,
                          decoration: const InputDecoration(hintText: 'e.g. Leaking kitchen faucet'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        SizedBox(height: 16.h),
                        Text('DESCRIPTION', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
                        SizedBox(height: 6.h),
                        TextFormField(
                          controller: _description,
                          maxLines: 4,
                          decoration: const InputDecoration(hintText: 'Describe what needs to be done'),
                        ),
                        SizedBox(height: 24.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: Size.fromHeight(52.h),
                              shape: const StadiumBorder(),
                              elevation: 0,
                            ),
                            child: _submitting
                                ? SizedBox(width: 22.w, height: 22.h, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text('Submit Request', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
