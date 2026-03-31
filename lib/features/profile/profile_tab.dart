import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/theme_notifier.dart';
import '../../services/supabase_service.dart';
import '../auth/login_screen.dart';
import '../property/my_properties_screen.dart';
import 'edit_profile_screen.dart';
import 'help_center_screen.dart';
import 'terms_of_service_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _pushNotifications = true;

  String get _userName {
    final meta = SupabaseService.currentUser?.userMetadata;
    return (meta?['full_name'] as String?) ?? 'User';
  }

  String get _userEmail {
    final meta = SupabaseService.currentUser?.userMetadata;
    final email = (meta?['email'] as String?) ??
        SupabaseService.currentUser?.email;
    if (email != null && email.isNotEmpty) return email;
    return SupabaseService.currentUser?.phone ?? '';
  }

  String get _userInitials {
    final parts = _userName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U';
  }

  Future<void> _onSignOut() async {
    await SupabaseService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),
          _buildAccountSection(),
          const SizedBox(height: 24),
          _buildPreferencesSection(),
          const SizedBox(height: 24),
          _buildActivitySection(),
          const SizedBox(height: 24),
          _buildSupportSection(),
          const SizedBox(height: 24),
          _buildLogOutButton(),
          _buildVersionText(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ---------- Profile Header ----------

  Widget _buildProfileHeader() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 28),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFEF3C7),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    width: 4,
                  ),
                ),
                child: Center(
                  child: Text(
                    _userInitials,
                    style: const TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.surface, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.edit, color: AppColors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            _userName,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          // Email / Phone
          Text(
            _userEmail,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),
          // PRO MEMBER badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, color: AppColors.primary, size: 16),
                SizedBox(width: 6),
                Text(
                  'PRO MEMBER',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Account Management ----------

  Widget _buildAccountSection() {
    return _buildSection(
      title: 'ACCOUNT MANAGEMENT',
      children: [
        _buildNavRow(
          icon: Icons.person_outline,
          label: 'Personal Information',
          onTap: () async {
            final updated = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => const EditProfileScreen(),
              ),
            );
            if (updated == true && mounted) setState(() {});
          },
        ),
        _buildDivider(),
        _buildNavRow(
          icon: Icons.credit_card_outlined,
          label: 'Billing & Subscription',
          onTap: () {},
        ),
      ],
    );
  }

  // ---------- Preferences ----------

  Widget _buildPreferencesSection() {
    final isDark = themeNotifier.value == ThemeMode.dark;
    return _buildSection(
      title: 'PREFERENCES',
      children: [
        _buildToggleRow(
          icon: Icons.notifications_outlined,
          label: 'Push Notifications',
          value: _pushNotifications,
          onChanged: (v) => setState(() => _pushNotifications = v),
        ),
        _buildDivider(),
        _buildToggleRow(
          icon: Icons.dark_mode_outlined,
          label: 'Dark Mode',
          value: isDark,
          onChanged: (v) {
            themeNotifier.value = v ? ThemeMode.dark : ThemeMode.light;
          },
        ),
        _buildDivider(),
        _buildNavRow(
          icon: Icons.language,
          label: 'Language',
          trailing: Text(
            'English (US)',
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          onTap: () {},
        ),
      ],
    );
  }

  // ---------- Activity ----------

  Widget _buildActivitySection() {
    return _buildSection(
      title: 'ACTIVITY',
      children: [
        _buildNavRow(
          icon: Icons.home_work_outlined,
          label: 'My Properties',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyPropertiesScreen()),
            );
          },
        ),
        _buildDivider(),
        _buildNavRow(
          icon: Icons.history,
          label: 'Order History',
          onTap: () {},
        ),
        _buildDivider(),
        _buildNavRow(
          icon: Icons.bookmark_outline,
          label: 'Saved Items',
          onTap: () {},
        ),
      ],
    );
  }

  // ---------- Support ----------

  Widget _buildSupportSection() {
    return _buildSection(
      title: 'SUPPORT',
      children: [
        _buildNavRow(
          icon: Icons.help_outline,
          label: 'Help Center',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
            );
          },
        ),
        _buildDivider(),
        _buildNavRow(
          icon: Icons.description_outlined,
          label: 'Terms of Service',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const TermsOfServiceScreen()),
            );
          },
        ),
      ],
    );
  }

  // ---------- Log Out ----------

  Widget _buildLogOutButton() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _onSignOut,
          icon: const Icon(Icons.logout, size: 20),
          label: const Text('Log Out'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFEF4444),
            side: const BorderSide(color: Color(0xFFFEE2E2)),
            backgroundColor: cs.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Version ----------

  Widget _buildVersionText() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Text(
        'VERSION ${AppStrings.version.toUpperCase()}',
        style: TextStyle(
          color: Theme.of(context).colorScheme.outline,
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 2,
        ),
      ),
    );
  }

  // ---------- Shared Builders ----------

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              title,
              style: TextStyle(
                color: cs.outline,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Container(
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
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildNavRow({
    required IconData icon,
    required String label,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null) ...[
              trailing,
              const SizedBox(width: 4),
            ],
            Icon(
              Icons.chevron_right,
              color: cs.outline,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.white,
            activeTrackColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 52,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}
