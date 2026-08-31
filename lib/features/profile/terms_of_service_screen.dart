import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  List<_TermsSection> _sections(AppLocalizations l) => [
        _TermsSection(
            icon: Icons.handshake_outlined,
            title: l.tr('termsSection1Title'),
            body: l.tr('termsSection1')),
        _TermsSection(
            icon: Icons.person_outline,
            title: l.tr('termsSection2Title'),
            body: l.tr('termsSection2')),
        _TermsSection(
            icon: Icons.apartment_outlined,
            title: l.tr('termsSection3Title'),
            body: l.tr('termsSection3')),
        _TermsSection(
            icon: Icons.payment_outlined,
            title: l.tr('termsSection4Title'),
            body: l.tr('termsSection4')),
        _TermsSection(
            icon: Icons.privacy_tip_outlined,
            title: l.tr('termsSection5Title'),
            body: l.tr('termsSection5')),
        _TermsSection(
            icon: Icons.block_outlined,
            title: l.tr('termsSection6Title'),
            body: l.tr('termsSection6')),
        _TermsSection(
            icon: Icons.gavel_outlined,
            title: l.tr('termsSection7Title'),
            body: l.tr('termsSection7')),
        _TermsSection(
            icon: Icons.cancel_outlined,
            title: l.tr('termsSection8Title'),
            body: l.tr('termsSection8')),
        _TermsSection(
            icon: Icons.mail_outline,
            title: l.tr('termsSection9Title'),
            body:
                '${l.tr('termsSection9')}\n\n  ${l.tr('termsEmail')}\n  ${l.tr('termsAddress')}\n\n${l.tr('termsResponse')}'),
      ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    final sections = _sections(l);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(l.tr('termsOfService')),
        centerTitle: true,
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 32.h),
        children: [
          _buildHeaderCard(cs, l),
          SizedBox(height: 20.h),
          for (final section in sections) ...[
            _buildSectionCard(section, cs),
            SizedBox(height: 16.h),
          ],
          _buildFooter(cs, l),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(ColorScheme cs, AppLocalizations l) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.description_outlined,
              color: AppColors.primary, size: 36.r),
          SizedBox(height: 12.h),
          Text(
            '${l.tr('appName')} ${l.tr('termsOfService')}',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            l.tr('lastUpdated'),
            style: TextStyle(
              color: cs.outline,
              fontSize: 13.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            l.tr('termsIntro'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 13.sp,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(_TermsSection section, ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36.w,
                  height: 36.h,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child:
                      Icon(section.icon, color: AppColors.primary, size: 20.r),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    section.title,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              section.body,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 13.sp,
                fontWeight: FontWeight.w400,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(ColorScheme cs, AppLocalizations l) {
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Column(
        children: [
          Divider(color: cs.surfaceContainerHighest),
          SizedBox(height: 12.h),
          Text(
            '${l.tr('appName')} ${l.tr('version')}',
            style: TextStyle(
              color: cs.outline,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            l.tr('tagline'),
            style: TextStyle(
              color: cs.outline,
              fontSize: 11.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsSection {
  final IconData icon;
  final String title;
  final String body;

  const _TermsSection({
    required this.icon,
    required this.title,
    required this.body,
  });
}
