import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  static const _lastUpdated = 'March 1, 2026';

  static const _sections = [
    _TermsSection(
      icon: Icons.handshake_outlined,
      title: '1. Acceptance of Terms',
      body:
          'By accessing or using the Salguri mobile application ("App"), you agree to be '
          'bound by these Terms of Service ("Terms"). If you do not agree to these Terms, '
          'you may not access or use the App. These Terms constitute a legally binding '
          'agreement between you and Salguri.\n\n'
          'We reserve the right to modify these Terms at any time. We will notify you of '
          'material changes by posting the updated Terms within the App. Your continued '
          'use of the App after such changes constitutes acceptance of the revised Terms.',
    ),
    _TermsSection(
      icon: Icons.person_outline,
      title: '2. User Accounts',
      body:
          'To access certain features of the App, you must create an account. You agree to:\n\n'
          '  a) Provide accurate, current, and complete information during registration.\n'
          '  b) Maintain the security and confidentiality of your login credentials.\n'
          '  c) Notify us immediately of any unauthorized use of your account.\n'
          '  d) Accept responsibility for all activities that occur under your account.\n\n'
          'You must be at least 18 years old to create an account and use the App. '
          'We reserve the right to suspend or terminate accounts that violate these Terms.',
    ),
    _TermsSection(
      icon: Icons.apartment_outlined,
      title: '3. Property Listings',
      body:
          'Property owners and agents who list properties on Salguri represent and warrant that:\n\n'
          '  a) They have the legal right to list the property for sale or rent.\n'
          '  b) All listing information, including descriptions, photos, and pricing, is '
          'accurate and not misleading.\n'
          '  c) The property complies with all applicable local laws and regulations.\n\n'
          'Salguri does not own, manage, or control any properties listed on the platform. '
          'We act solely as an intermediary connecting property owners with prospective '
          'tenants and buyers. We do not guarantee the accuracy of any listing.',
    ),
    _TermsSection(
      icon: Icons.payment_outlined,
      title: '4. Payments & Transactions',
      body:
          'Salguri facilitates rent payments and other financial transactions between users. '
          'By using our payment features, you agree that:\n\n'
          '  a) You are responsible for ensuring sufficient funds are available.\n'
          '  b) All payment information you provide is accurate and authorized.\n'
          '  c) Transaction fees, if applicable, will be clearly disclosed before confirmation.\n'
          '  d) Completed transactions are final unless otherwise specified.\n\n'
          'Salguri uses secure third-party payment processors and does not store your '
          'payment credentials on our servers.',
    ),
    _TermsSection(
      icon: Icons.privacy_tip_outlined,
      title: '5. Privacy & Data Protection',
      body:
          'Your privacy is important to us. Our collection and use of personal data is '
          'governed by our Privacy Policy, which is incorporated into these Terms by '
          'reference.\n\n'
          'We collect only the information necessary to provide and improve our services. '
          'Your personal data will not be sold to third parties. You have the right to '
          'request access to, correction of, or deletion of your personal data at any time '
          'by contacting our support team.',
    ),
    _TermsSection(
      icon: Icons.block_outlined,
      title: '6. Prohibited Conduct',
      body: 'You agree not to:\n\n'
          '  a) Use the App for any unlawful purpose or in violation of any applicable laws.\n'
          '  b) Post false, misleading, or fraudulent property listings.\n'
          '  c) Harass, threaten, or discriminate against other users.\n'
          '  d) Attempt to gain unauthorized access to other user accounts or our systems.\n'
          '  e) Use automated tools, bots, or scrapers to access the App.\n'
          '  f) Interfere with or disrupt the App\'s functionality or servers.\n\n'
          'Violation of these rules may result in immediate account suspension or termination.',
    ),
    _TermsSection(
      icon: Icons.gavel_outlined,
      title: '7. Limitation of Liability',
      body:
          'To the maximum extent permitted by law, Salguri and its officers, directors, '
          'employees, and agents shall not be liable for any indirect, incidental, special, '
          'consequential, or punitive damages arising out of or related to your use of '
          'the App.\n\n'
          'Salguri does not guarantee the quality, safety, or legality of listed properties, '
          'the accuracy of listings, or the ability of users to complete transactions. '
          'Users are advised to conduct their own due diligence before entering into any '
          'agreements.',
    ),
    _TermsSection(
      icon: Icons.cancel_outlined,
      title: '8. Termination',
      body:
          'We may terminate or suspend your access to the App at any time, with or without '
          'cause, and with or without notice. Upon termination:\n\n'
          '  a) Your right to use the App will immediately cease.\n'
          '  b) Any outstanding payment obligations will remain in effect.\n'
          '  c) Provisions that by their nature should survive termination will continue '
          'to apply.\n\n'
          'You may also delete your account at any time through the App settings.',
    ),
    _TermsSection(
      icon: Icons.mail_outline,
      title: '9. Contact Us',
      body:
          'If you have any questions about these Terms of Service, please contact us:\n\n'
          '  Email: support@salguri.com\n'
          '  Address: Mogadishu, Somalia\n\n'
          'We aim to respond to all inquiries within 48 hours.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Terms of Service'),
        centerTitle: true,
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Header card
          _buildHeaderCard(cs),
          const SizedBox(height: 20),

          // Sections
          for (final section in _sections) ...[
            _buildSectionCard(section, cs),
            const SizedBox(height: 16),
          ],

          // Footer
          _buildFooter(cs),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.description_outlined,
              color: AppColors.primary, size: 36),
          const SizedBox(height: 12),
          Text(
            '${AppStrings.appName} Terms of Service',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Last updated: $_lastUpdated',
            style: TextStyle(
              color: cs.outline,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Please read these terms carefully before using the Salguri platform. '
            'By using our services, you agree to be bound by these terms.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 13,
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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      Icon(section.icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    section.title,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              section.body,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          Divider(color: cs.surfaceContainerHighest),
          const SizedBox(height: 12),
          Text(
            '${AppStrings.appName} ${AppStrings.version}',
            style: TextStyle(
              color: cs.outline,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.tagline,
            style: TextStyle(
              color: cs.outline,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Data Model ----------

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
