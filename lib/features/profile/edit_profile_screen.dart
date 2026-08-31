import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/locale_notifier.dart';
import '../../core/theme/theme_notifier.dart';
import '../../services/api_service.dart';
import '../../services/supabase_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;

  bool _pushNotifications = true;
  String _language = 'English (US)';

  final Set<String> _selectedPropertyTypes = {};

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final meta = SupabaseService.currentUser?.userMetadata;
    _fullNameCtrl = TextEditingController(
      text: (meta?['full_name'] as String?) ?? '',
    );
    _phoneCtrl = TextEditingController(
      text: SupabaseService.currentUser?.phone ?? '',
    );
    _emailCtrl = TextEditingController(
      text: (meta?['email'] as String?) ??
          SupabaseService.currentUser?.email ??
          '',
    );

    // Restore saved preferences from metadata if available
    final prefs = meta?['property_preferences'] as List<dynamic>?;
    if (prefs != null) {
      _selectedPropertyTypes.addAll(prefs.cast<String>());
    }
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  String get _userInitials {
    final name = _fullNameCtrl.text.trim();
    if (name.isEmpty) return 'U';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final l = AppLocalizations.of(context);
    try {
      // Update Supabase auth metadata
      await SupabaseService.client.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': _fullNameCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'property_preferences': _selectedPropertyTypes.toList(),
          },
        ),
      );

      // Also update backend profile
      await ApiService.updateProfile(
        fullName: _fullNameCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.tr('profileUpdated'))),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l.tr('failedUpdateProfile')} $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l.tr('editProfile'),
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 24.h),
            _buildAvatarSection(cs),
            SizedBox(height: 32.h),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildPersonalInfoSection(cs, l),
                  SizedBox(height: 24.h),
                  _buildPreferencesSection(cs, l),
                ],
              ),
            ),
            SizedBox(height: 32.h),
            _buildSaveButton(l),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  // ---------- Avatar ----------

  Widget _buildAvatarSection(ColorScheme cs) {
    return Center(
      child: GestureDetector(
        onTap: () {
          // TODO: image picker
        },
        child: Stack(
          children: [
            Container(
              width: 100.w,
              height: 100.h,
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
                  style: TextStyle(
                    color: const Color(0xFFF59E0B),
                    fontSize: 36.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 34.w,
                height: 34.h,
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
                  child: Icon(Icons.camera_alt, color: AppColors.white, size: 16.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Personal Information ----------

  Widget _buildPersonalInfoSection(ColorScheme cs, AppLocalizations l) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(cs, l.tr('personalInformation')),
          SizedBox(height: 12.h),
          _buildLabel(cs, l.tr('fullName')),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _fullNameCtrl,
            style: TextStyle(fontSize: 16.sp, color: cs.onSurface),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            decoration: _inputDecoration(l.tr('enterFullName')),
          ),
          SizedBox(height: 16.h),
          _buildLabel(cs, l.tr('phoneNumber')),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _phoneCtrl,
            readOnly: true,
            style: TextStyle(fontSize: 16.sp, color: cs.onSurfaceVariant),
            decoration: _inputDecoration(l.tr('phoneNumberHint')).copyWith(
              suffixIcon: Icon(Icons.lock_outline, color: cs.outline, size: 20.r),
            ),
          ),
          SizedBox(height: 16.h),
          _buildLabel(cs, l.tr('emailAddress')),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(fontSize: 16.sp, color: cs.onSurface),
            decoration: _inputDecoration(l.tr('enterEmail')),
          ),
        ],
      ),
    );
  }

  // ---------- Preferences ----------

  Widget _buildPreferencesSection(ColorScheme cs, AppLocalizations l) {
    final isDark = themeNotifier.value == ThemeMode.dark;
    final propertyTypes = [
      l.tr('villa'),
      l.tr('commercial'),
      l.tr('services'),
    ];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(cs, l.tr('preferences')),
          SizedBox(height: 12.h),
          // Property type chips
          _buildLabel(cs, l.tr('propertyTypePreferences')),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: propertyTypes.map((type) {
              final selected = _selectedPropertyTypes.contains(type);
              return ChoiceChip(
                label: Text(type),
                selected: selected,
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _selectedPropertyTypes.add(type);
                    } else {
                      _selectedPropertyTypes.remove(type);
                    }
                  });
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                backgroundColor: cs.surface,
                labelStyle: TextStyle(
                  color: selected ? AppColors.primary : cs.onSurface,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 14.sp,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                  side: BorderSide(
                    color: selected ? AppColors.primary : cs.outlineVariant,
                  ),
                ),
                showCheckmark: false,
              );
            }).toList(),
          ),
          SizedBox(height: 20.h),
          // Toggles card
          Container(
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
            child: Column(
              children: [
                _buildToggleRow(
                  cs: cs,
                  icon: Icons.notifications_outlined,
                  label: l.tr('pushNotifications'),
                  value: _pushNotifications,
                  onChanged: (v) => setState(() => _pushNotifications = v),
                ),
                Divider(
                  height: 1,
                  indent: 52.w,
                  color: cs.surfaceContainerHighest,
                ),
                _buildToggleRow(
                  cs: cs,
                  icon: Icons.dark_mode_outlined,
                  label: l.tr('darkMode'),
                  value: isDark,
                  onChanged: (v) {
                    themeNotifier.value =
                        v ? ThemeMode.dark : ThemeMode.light;
                    setState(() {});
                  },
                ),
                Divider(
                  height: 1,
                  indent: 52.w,
                  color: cs.surfaceContainerHighest,
                ),
                _buildLanguageRow(cs, l),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Language Row ----------

  Widget _buildLanguageRow(ColorScheme cs, AppLocalizations l) {
    return InkWell(
      onTap: () async {
        final languages = ['English (US)', 'Somali'];
        final picked = await showModalBottomSheet<String>(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (ctx) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 12.h),
                  Container(
                    width: 36.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    l.tr('selectLanguage'),
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  ...languages.map(
                    (lang) => ListTile(
                      title: Text(lang),
                      trailing: lang == _language
                          ? const Icon(Icons.check, color: AppColors.primary)
                          : null,
                      onTap: () => Navigator.pop(ctx, lang),
                    ),
                  ),
                  SizedBox(height: 8.h),
                ],
              ),
            );
          },
        );
        if (picked != null && picked != _language) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('app_language', picked);
          localeNotifier.value = picked == 'Somali'
              ? const Locale('so')
              : const Locale('en');
          setState(() => _language = picked);
        }
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
        child: Row(
          children: [
            Icon(Icons.language, color: AppColors.primary, size: 22.r),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                l.tr('language'),
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              _language,
              style: TextStyle(
                color: cs.outline,
                fontSize: 13.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(width: 4.w),
            Icon(Icons.chevron_right, color: cs.outline, size: 22.r),
          ],
        ),
      ),
    );
  }

  // ---------- Save Button ----------

  Widget _buildSaveButton(AppLocalizations l) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: SizedBox(
        width: double.infinity,
        height: 56.h,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            elevation: 4,
            shadowColor: AppColors.primary.withValues(alpha: 0.3),
            textStyle: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          child: _isSaving
              ? SizedBox(
                  width: 24.w,
                  height: 24.h,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.white,
                  ),
                )
              : Text(l.tr('saveChanges')),
        ),
      ),
    );
  }

  // ---------- Shared Helpers ----------

  Widget _buildSectionTitle(ColorScheme cs, String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w),
      child: Text(
        title,
        style: TextStyle(
          color: cs.outline,
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildLabel(ColorScheme cs, String text) {
    return Text(
      text,
      style: TextStyle(
        color: cs.onSurface,
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildToggleRow({
    required ColorScheme cs,
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 11.h),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22.r),
          SizedBox(width: 14.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 14.sp,
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

  InputDecoration _inputDecoration(String hint) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: cs.outline,
        fontSize: 16.sp,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: cs.surface,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }
}
