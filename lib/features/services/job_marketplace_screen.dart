import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/vendor_marketplace.dart';
import '../../services/api_service.dart';
import 'request_service_screen.dart';

/// The Job Marketplace's "discover" half — service-provider companies could
/// already list what they offer (business-app's Service Posts), but nothing
/// let a customer actually browse that list before this. Tapping a listing
/// starts a direct request to that specific company.
class JobMarketplaceScreen extends StatefulWidget {
  const JobMarketplaceScreen({super.key});

  @override
  State<JobMarketplaceScreen> createState() => _JobMarketplaceScreenState();
}

class _JobMarketplaceScreenState extends State<JobMarketplaceScreen> {
  List<VendorMarketplacePost>? _posts;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final posts = await ApiService.getVendorMarketplacePosts();
      if (!mounted) return;
      setState(() => _posts = posts);
    } catch (e) {
      if (!mounted) return;
      setState(() => _posts = const []);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load providers: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Service Providers', style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: _posts == null
            ? Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                onRefresh: _load,
                child: _posts!.isEmpty
                    ? ListView(children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 80.h),
                          child: Center(
                            child: Text('No service providers are listed yet.',
                                style: TextStyle(color: AppColors.textMuted)),
                          ),
                        ),
                      ])
                    : ListView.separated(
                        padding: EdgeInsets.all(16.r),
                        itemCount: _posts!.length,
                        separatorBuilder: (_, __) => SizedBox(height: 10.h),
                        itemBuilder: (context, i) {
                          final p = _posts![i];
                          return InkWell(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => RequestServiceScreen(directVendor: p),
                              ),
                            ),
                            borderRadius: BorderRadius.circular(14.r),
                            child: Container(
                              padding: EdgeInsets.all(14.r),
                              decoration: BoxDecoration(
                                color: AppColors.cardBg,
                                borderRadius: BorderRadius.circular(14.r),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.companyName,
                                      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                                  SizedBox(height: 4.h),
                                  Text(p.title,
                                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                                  if (p.description != null) ...[
                                    SizedBox(height: 4.h),
                                    Text(p.description!,
                                        maxLines: 2, overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 12.sp, color: AppColors.textMuted)),
                                  ],
                                  SizedBox(height: 8.h),
                                  Text('\$${p.rate}/${p.rateUnit}',
                                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
      ),
    );
  }
}
