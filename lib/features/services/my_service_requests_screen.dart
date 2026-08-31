import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/vendor_marketplace.dart';
import '../../services/api_service.dart';

/// Status list for the customer's own service requests — mirrors the
/// existing "My Applications"/"My Leases" pattern. Previously there was no
/// way for a customer to even create one of these, let alone track it.
class MyServiceRequestsScreen extends StatefulWidget {
  const MyServiceRequestsScreen({super.key});

  @override
  State<MyServiceRequestsScreen> createState() => _MyServiceRequestsScreenState();
}

class _MyServiceRequestsScreenState extends State<MyServiceRequestsScreen> {
  List<PropertyServiceRequest>? _requests;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final requests = await ApiService.getMyServiceRequests();
      if (!mounted) return;
      setState(() => _requests = requests);
    } catch (e) {
      if (!mounted) return;
      setState(() => _requests = const []);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load requests: $e')),
      );
    }
  }

  Color _statusColor(String status) => switch (status) {
        'completed' => AppColors.success,
        'declined' || 'cancelled' => AppColors.error,
        'awaiting_assignment' || 'pending_approval' || 'awaiting_vendor_response' => AppColors.warning,
        _ => AppColors.primary,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('My Service Requests', style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: _requests == null
            ? Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                onRefresh: _load,
                child: _requests!.isEmpty
                    ? ListView(children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 80.h),
                          child: Center(
                            child: Text("You haven't requested any services yet.",
                                style: TextStyle(color: AppColors.textMuted)),
                          ),
                        ),
                      ])
                    : ListView.separated(
                        padding: EdgeInsets.all(16.r),
                        itemCount: _requests!.length,
                        separatorBuilder: (_, __) => SizedBox(height: 10.h),
                        itemBuilder: (context, i) {
                          final r = _requests![i];
                          final provider = r.vendorCompanyName ?? r.pmCompanyName;
                          return Container(
                            padding: EdgeInsets.all(14.r),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(r.title,
                                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                      decoration: BoxDecoration(
                                        color: _statusColor(r.status).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(r.statusLabel,
                                          style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: _statusColor(r.status))),
                                    ),
                                  ],
                                ),
                                if (provider != null) ...[
                                  SizedBox(height: 4.h),
                                  Text(provider, style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
                                ],
                                if (r.propertyLabel != null) ...[
                                  SizedBox(height: 2.h),
                                  Text(r.propertyLabel!, style: TextStyle(fontSize: 12.sp, color: AppColors.textMuted)),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),
      ),
    );
  }
}
