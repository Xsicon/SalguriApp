import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/document_template.dart';
import '../../services/api_service.dart';

/// Tenant's "My Applications" — every rental application this account has
/// submitted, across every property/owner, with its current review status.
class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  List<MyApplicationSummary>? _applications;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final applications = await ApiService.getMyApplications();
      if (!mounted) return;
      setState(() {
        _applications = applications;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _withdraw(MyApplicationSummary application) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw application?'),
        content: Text('This withdraws your application for ${application.propertyTitle}. '
            'You can apply again later if it\'s still available.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.withdrawApplication(application.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not withdraw: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Applications')),
      body: SafeArea(
        child: Builder(builder: (context) {
          final applications = _applications;
          if (applications == null && _error == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_error != null) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.r),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            );
          }
          if (applications!.isEmpty) {
            return const Center(child: Text('No applications yet.'));
          }
          return RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
              itemCount: applications.length,
              separatorBuilder: (context, index) => SizedBox(height: 10.h),
              itemBuilder: (context, i) => _ApplicationCard(
                application: applications[i],
                onWithdraw: () => _withdraw(applications[i]),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final MyApplicationSummary application;
  final VoidCallback onWithdraw;
  const _ApplicationCard({required this.application, required this.onWithdraw});

  (String, Color) get _statusStyle => switch (application.status) {
        'approved' => ('APPROVED', AppColors.success),
        'on_hold' => ('ON HOLD', AppColors.textSecondary),
        'incomplete' => ('INCOMPLETE', AppColors.error),
        'withdrawn' => ('WITHDRAWN', AppColors.textMuted),
        'closed' => ('PROPERTY TAKEN', AppColors.textMuted),
        _ => ('UNDER REVIEW', AppColors.warning),
      };

  @override
  Widget build(BuildContext context) {
    final (label, color) = _statusStyle;
    final canWithdraw = application.status == 'under_review' ||
        application.status == 'on_hold' ||
        application.status == 'approved';
    final noteVisible = (application.status == 'incomplete' || application.status == 'on_hold') &&
        (application.reviewerNotes ?? '').isNotEmpty;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  application.propertyTitle,
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6.r)),
                child: Text(
                  label,
                  style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            'Submitted ${_formatDate(application.submittedAt)}',
            style: TextStyle(fontSize: 12.sp, color: AppColors.textMuted),
          ),
          if (noteVisible) ...[
            SizedBox(height: 8.h),
            Text(
              application.reviewerNotes!,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: application.status == 'incomplete' ? AppColors.error : AppColors.textSecondary,
              ),
            ),
          ],
          if (canWithdraw) ...[
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onWithdraw,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error),
                  shape: const StadiumBorder(),
                ),
                child: const Text('Withdraw Application'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
