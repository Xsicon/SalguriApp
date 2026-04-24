import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/locale_notifier.dart';
import '../../core/theme/theme_notifier.dart';
import '../../services/supabase_service.dart';
import '../auth/login_screen.dart';
// import '../property/my_properties_screen.dart'; // Disabled – landlord feature
import '../explore/saved_items_screen.dart';
import 'edit_profile_screen.dart';
import 'billing_subscription_screen.dart';
import 'help_center_screen.dart';
import 'order_history_screen.dart';
import 'terms_of_service_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _pushNotifications = false;
  String? _avatarUrl;
  bool _uploadingAvatar = false;
  String _selectedLanguage = 'English (US)';

  static const _languages = [
    'English (US)',
    'Somali',
  ];

  @override
  void initState() {
    super.initState();
    _loadNotificationPref();
    _loadLanguagePref();
    _avatarUrl =
        SupabaseService.currentUser?.userMetadata?['avatar_url'] as String?;
  }

  Future<void> _loadLanguagePref() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('app_language');
    if (lang != null && mounted) {
      setState(() => _selectedLanguage = lang);
    }
  }

  void _showLanguagePicker() {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.tr('selectLanguage'),
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ..._languages.map((lang) {
              final isSelected = lang == _selectedLanguage;
              return ListTile(
                title: Text(
                  lang,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('app_language', lang);
                  localeNotifier.value = lang == 'Somali'
                      ? const Locale('so')
                      : const Locale('en');
                  if (!mounted) return;
                  setState(() => _selectedLanguage = lang);
                  Navigator.of(ctx).pop();
                },
              );
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _uploadingAvatar = true);
    debugPrint('=== AVATAR UPLOAD START ===');
    debugPrint('Picked file path: ${picked.path}');
    final file = File(picked.path);
    debugPrint('File exists: ${file.existsSync()}');
    debugPrint('File size: ${file.lengthSync()} bytes');
    try {
      final url = await SupabaseService.uploadProfileAvatar(file);
      debugPrint('=== AVATAR UPLOAD SUCCESS ===');
      debugPrint('Public URL: $url');
      if (!mounted) return;
      setState(() {
        _avatarUrl = url;
        _uploadingAvatar = false;
      });
    } catch (e, st) {
      debugPrint('=== AVATAR UPLOAD ERROR ===');
      debugPrint('Error: $e');
      debugPrint('Stack: $st');
      if (!mounted) return;
      setState(() => _uploadingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload photo: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _loadNotificationPref() async {
    final prefs = await SharedPreferences.getInstance();
    final status = await Permission.notification.status;
    setState(() {
      _pushNotifications =
          (prefs.getBool('push_notifications') ?? true) && status.isGranted;
    });
  }

  Future<void> _toggleNotifications(bool enabled) async {
    if (enabled) {
      final status = await Permission.notification.request();
      if (!status.isGranted) {
        if (!mounted) return;
        final l = AppLocalizations.of(context);
        if (status.isPermanentlyDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l.tr('notificationsBlocked')),
              action: SnackBarAction(
                label: l.tr('settings'),
                onPressed: () => openAppSettings(),
              ),
            ),
          );
        }
        return;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications', enabled);
    if (!mounted) return;
    setState(() => _pushNotifications = enabled);
  }

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
    final l = AppLocalizations.of(context);
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
          GestureDetector(
            onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
            child: Stack(
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
                    image: _avatarUrl != null
                        ? DecorationImage(
                            image: NetworkImage(_avatarUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _avatarUrl != null
                      ? null
                      : Center(
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
                    child: Center(
                      child: _uploadingAvatar
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : const Icon(Icons.camera_alt, color: AppColors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified, color: AppColors.primary, size: 16),
                const SizedBox(width: 6),
                Text(
                  l.tr('proMember'),
                  style: const TextStyle(
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
    final l = AppLocalizations.of(context);
    return _buildSection(
      title: l.tr('accountManagement'),
      children: [
        _buildNavRow(
          icon: Icons.person_outline,
          label: l.tr('personalInfo'),
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
          label: l.tr('billingSubscription'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const BillingSubscriptionScreen()),
            );
          },
        ),
      ],
    );
  }

  // ---------- Preferences ----------

  Widget _buildPreferencesSection() {
    final isDark = themeNotifier.value == ThemeMode.dark;
    final l = AppLocalizations.of(context);
    return _buildSection(
      title: l.tr('preferences'),
      children: [
        _buildToggleRow(
          icon: Icons.notifications_outlined,
          label: l.tr('pushNotifications'),
          value: _pushNotifications,
          onChanged: _toggleNotifications,
        ),
        _buildDivider(),
        _buildToggleRow(
          icon: Icons.dark_mode_outlined,
          label: l.tr('darkMode'),
          value: isDark,
          onChanged: (v) {
            themeNotifier.value = v ? ThemeMode.dark : ThemeMode.light;
          },
        ),
        _buildDivider(),
        _buildNavRow(
          icon: Icons.language,
          label: l.tr('language'),
          trailing: Text(
            _selectedLanguage,
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          onTap: _showLanguagePicker,
        ),
      ],
    );
  }

  // ---------- Activity ----------

  Widget _buildActivitySection() {
    final l = AppLocalizations.of(context);
    return _buildSection(
      title: l.tr('activity'),
      children: [
        // My Properties disabled – landlord feature (kept for business app)
        // _buildNavRow(
        //   icon: Icons.home_work_outlined,
        //   label: 'My Properties',
        //   onTap: () {
        //     Navigator.of(context).push(
        //       MaterialPageRoute(builder: (_) => const MyPropertiesScreen()),
        //     );
        //   },
        // ),
        // _buildDivider(),
        _buildNavRow(
          icon: Icons.history,
          label: l.tr('orderHistory'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const OrderHistoryScreen()),
            );
          },
        ),
        _buildDivider(),
        _buildNavRow(
          icon: Icons.bookmark_outline,
          label: l.tr('savedItems'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SavedItemsScreen()),
            );
          },
        ),
      ],
    );
  }

  // ---------- Support ----------

  Widget _buildSupportSection() {
    final l = AppLocalizations.of(context);
    return _buildSection(
      title: l.tr('supportSection'),
      children: [
        _buildNavRow(
          icon: Icons.help_outline,
          label: l.tr('helpCenter'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
            );
          },
        ),
        _buildDivider(),
        _buildNavRow(
          icon: Icons.description_outlined,
          label: l.tr('termsOfService'),
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
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _onSignOut,
          icon: const Icon(Icons.logout, size: 20),
          label: Text(l.tr('logOut')),
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
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Text(
        '${l.tr('versionLabel').toUpperCase()} ${AppStrings.version.toUpperCase()}',
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
