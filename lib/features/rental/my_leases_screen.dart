import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/document_template.dart';
import '../../services/api_service.dart';
import 'document_signing_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Leases')),
      body: SafeArea(
        child: Builder(builder: (context) {
          final leases = _leases;
          if (leases == null && _error == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: leases.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _LeaseCard(lease: leases[i], onTap: () => _openLease(leases[i])),
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
  const _LeaseCard({required this.lease, required this.onTap});

  (String, Color) get _statusStyle => switch (lease.status) {
        'signed' => ('SIGNED', AppColors.success),
        'action_required' => ('ACTION REQUIRED', AppColors.error),
        'archived' => ('ARCHIVED', AppColors.textMuted),
        _ => ('PENDING SIGNATURE', AppColors.warning),
      };

  @override
  Widget build(BuildContext context) {
    final (label, color) = _statusStyle;
    final needsMySignature = !lease.tenantSigned;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
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
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      if (lease.propertyAddress.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          lease.propertyAddress,
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ],
            ),
            if (needsMySignature) ...[
              const SizedBox(height: 12),
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
          ],
        ),
      ),
    );
  }
}
