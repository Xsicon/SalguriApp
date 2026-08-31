import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/document_template.dart';
import '../../services/api_service.dart';
import 'document_signing_screen.dart';
import 'submit_deposit_screen.dart';

/// Tenant's "My Leases" — reached from the Lease Summary card's "View All"
/// link (previously dead — no `onTap` at all). Lists every lease this
/// account is the linked tenant on, across every property manager.
class MyLeasesScreen extends StatefulWidget {
  const MyLeasesScreen({super.key});

  @override
  State<MyLeasesScreen> createState() => _MyLeasesScreenState();
}

class _MyLeasesScreenState extends State<MyLeasesScreen> {
  List<MyLeaseSummary>? _leases;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final leases = await ApiService.getMyLeases();
      if (!mounted) return;
      setState(() {
        _leases = leases;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _openLease(MyLeaseSummary lease) async {
    final isFullySigned = lease.businessSigned && lease.tenantSigned;
    if (isFullySigned && lease.sealedDocumentUrl != null) {
      try {
        final url = await ApiService.getSealedDocumentUrl(
          documentType: 'lease',
          documentId: lease.id,
        );
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not open document: $e')));
      }
      return;
    }
    // An archived lease with no sealed document was closed out without ever
    // being signed — there's nothing to sign and nothing to view.
    if (lease.status == 'archived') {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('This lease has been archived.')));
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentSigningScreen(
          documentType: 'lease',
          documentId: lease.id,
          templateId: lease.templateId,
          fallbackDocumentUrl: lease.documentUrl,
        ),
      ),
    );
    await _load();
  }

  Future<void> _openDeposit(MyLeaseSummary lease) async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => SubmitDepositScreen(lease: lease)),
    );
    if (submitted == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leases')),
      body: SafeArea(
        child: Builder(builder: (context) {
          final leases = _leases;
          if (leases == null && _error == null) {
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
          if (leases!.isEmpty) {
            return const Center(child: Text('No leases yet.'));
          }
          return RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
              itemCount: leases.length,
              separatorBuilder: (_, _) => SizedBox(height: 10.h),
              itemBuilder: (_, i) => _LeaseCard(
                lease: leases[i],
                onTap: () => _openLease(leases[i]),
                onDeposit: () => _openDeposit(leases[i]),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _LeaseCard extends StatelessWidget {
  final MyLeaseSummary lease;
  final VoidCallback onTap;
  final VoidCallback onDeposit;
  const _LeaseCard({required this.lease, required this.onTap, required this.onDeposit});

  (String, Color) get _statusStyle => switch (lease.status) {
        'signed' => ('SIGNED', AppColors.success),
        'action_required' => ('ACTION REQUIRED', AppColors.error),
        'archived' => ('ARCHIVED', AppColors.textMuted),
        _ => ('PENDING SIGNATURE', AppColors.warning),
      };

  @override
  Widget build(BuildContext context) {
    final (label, color) = _statusStyle;
    final needsMySignature = !lease.tenantSigned && lease.status != 'archived';
    final isFullySigned = lease.businessSigned && lease.tenantSigned;
    final needsDeposit = isFullySigned && lease.depositStatus != 'confirmed';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lease.unitLabel.isEmpty ? lease.propertyTitle : lease.unitLabel,
                        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      if (lease.propertyAddress.isNotEmpty) ...[
                        SizedBox(height: 3.h),
                        Text(
                          lease.propertyAddress,
                          style: TextStyle(fontSize: 12.sp, color: AppColors.textMuted),
                        ),
                      ],
                    ],
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
            if (needsMySignature) ...[
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('View & Sign'),
                ),
              ),
            ],
            if (needsDeposit) ...[
              SizedBox(height: 12.h),
              _DepositAction(status: lease.depositStatus, onTap: onDeposit),
            ],
          ],
        ),
      ),
    );
  }
}

class _DepositAction extends StatelessWidget {
  final String status;
  final VoidCallback onTap;
  const _DepositAction({required this.status, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (label, color, filled) = switch (status) {
      'pending_review' => ('Deposit Under Review', AppColors.warning, false),
      'rejected' => ('Resubmit Deposit Receipt', AppColors.error, true),
      _ => ('Submit Security Deposit', AppColors.primary, true),
    };
    return SizedBox(
      width: double.infinity,
      child: filled
          ? ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              child: Text(label),
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color),
                shape: const StadiumBorder(),
              ),
              child: Text(label),
            ),
    );
  }
}
