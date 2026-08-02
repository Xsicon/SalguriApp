import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/document_template.dart';
import '../../services/api_service.dart';
import 'document_signing_screen.dart';

/// Tenant's "My Inspections" — lists every inspection this account is the
/// linked tenant on. Mirrors `my_leases_screen.dart`.
class MyInspectionsScreen extends StatefulWidget {
  const MyInspectionsScreen({super.key});

  @override
  State<MyInspectionsScreen> createState() => _MyInspectionsScreenState();
}

class _MyInspectionsScreenState extends State<MyInspectionsScreen> {
  List<MyInspectionSummary>? _inspections;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final inspections = await ApiService.getMyInspections();
      if (!mounted) return;
      setState(() {
        _inspections = inspections;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _openInspection(MyInspectionSummary inspection) async {
    final isFullySigned = inspection.businessSigned && inspection.tenantSigned;
    if (isFullySigned && inspection.sealedReportUrl != null) {
      try {
        final url = await ApiService.getSealedDocumentUrl(
          documentType: 'inspection',
          documentId: inspection.id,
        );
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not open report: $e')));
      }
      return;
    }
    if (!inspection.signOffRequired || inspection.tenantSigned) {
      // Nothing for the tenant to do — a routine inspection with no sign-off
      // requirement, or one they've already signed.
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentSigningScreen(
          documentType: 'inspection',
          documentId: inspection.id,
          templateId: inspection.templateId,
          fallbackDocumentUrl: inspection.reportUrl,
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Inspections')),
      body: SafeArea(
        child: Builder(builder: (context) {
          final inspections = _inspections;
          if (inspections == null && _error == null) {
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
          if (inspections!.isEmpty) {
            return const Center(child: Text('No inspections yet.'));
          }
          return RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: inspections.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) =>
                  _InspectionCard(inspection: inspections[i], onTap: () => _openInspection(inspections[i])),
            ),
          );
        }),
      ),
    );
  }
}

class _InspectionCard extends StatelessWidget {
  final MyInspectionSummary inspection;
  final VoidCallback onTap;
  const _InspectionCard({required this.inspection, required this.onTap});

  (String, Color) get _statusStyle => switch (inspection.status) {
        'report_ready' => ('REPORT READY', AppColors.success),
        'signature_required' => ('SIGNATURE REQUIRED', AppColors.warning),
        'archived' => ('ARCHIVED', AppColors.textMuted),
        _ => ('SCHEDULED', AppColors.textSecondary),
      };

  @override
  Widget build(BuildContext context) {
    final (label, color) = _statusStyle;
    final needsMySignature = inspection.signOffRequired && !inspection.tenantSigned &&
        inspection.status == 'signature_required';

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
                        inspection.title.isEmpty ? inspection.propertyTitle : inspection.title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      if (inspection.propertyAddress.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          inspection.propertyAddress,
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
                  child: const Text('Sign Now'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
