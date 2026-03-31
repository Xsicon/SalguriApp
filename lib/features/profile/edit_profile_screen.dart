import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
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

  final List<String> _propertyTypes = ['Villa', 'Commercial', 'Services'];
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
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 18,
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
            const SizedBox(height: 24),
            _buildAvatarSection(cs),
            const SizedBox(height: 32),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildPersonalInfoSection(cs),
                  const SizedBox(height: 24),
                  _buildPreferencesSection(cs),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildSaveButton(),
            const SizedBox(height: 32),
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
                  child: Icon(Icons.camera_alt, color: AppColors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Personal Information ----------

  Widget _buildPersonalInfoSection(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(cs, 'PERSONAL INFORMATION'),
          const SizedBox(height: 12),
          _buildLabel(cs, 'Full Name'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _fullNameCtrl,
            style: TextStyle(fontSize: 16, color: cs.onSurface),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            decoration: _inputDecoration('Enter your full name'),
          ),
          const SizedBox(height: 16),
          _buildLabel(cs, 'Phone Number'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneCtrl,
            readOnly: true,
            style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant),
            decoration: _inputDecoration('Phone number').copyWith(
              suffixIcon: Icon(Icons.lock_outline, color: cs.outline, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          _buildLabel(cs, 'Email Address'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(fontSize: 16, color: cs.onSurface),
            decoration: _inputDecoration('Enter your email address'),
          ),
        ],
      ),
    );
  }

  // ---------- Preferences ----------

  Widget _buildPreferencesSection(ColorScheme cs) {
    final isDark = themeNotifier.value == ThemeMode.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(cs, 'PREFERENCES'),
          const SizedBox(height: 12),
          // Property type chips
          _buildLabel(cs, 'Property Type Preferences'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _propertyTypes.map((type) {
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
                  fontSize: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: selected ? AppColors.primary : cs.outlineVariant,
                  ),
                ),
                showCheckmark: false,
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          // Toggles card
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
            child: Column(
              children: [
                _buildToggleRow(
                  cs: cs,
                  icon: Icons.notifications_outlined,
                  label: 'Push Notifications',
                  value: _pushNotifications,
                  onChanged: (v) => setState(() => _pushNotifications = v),
                ),
                Divider(
                  height: 1,
                  indent: 52,
                  color: cs.surfaceContainerHighest,
                ),
                _buildToggleRow(
                  cs: cs,
                  icon: Icons.dark_mode_outlined,
                  label: 'Dark Mode',
                  value: isDark,
                  onChanged: (v) {
                    themeNotifier.value =
                        v ? ThemeMode.dark : ThemeMode.light;
                    setState(() {});
                  },
                ),
                Divider(
                  height: 1,
                  indent: 52,
                  color: cs.surfaceContainerHighest,
                ),
                _buildLanguageRow(cs),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Language Row ----------

  Widget _buildLanguageRow(ColorScheme cs) {
    return InkWell(
      onTap: () async {
        final languages = ['English (US)', 'Khmer', 'Chinese'];
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
                  const SizedBox(height: 12),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select Language',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...languages.map(
                    (lang) => ListTile(
                      title: Text(lang),
                      trailing: lang == _language
                          ? const Icon(Icons.check, color: AppColors.primary)
                          : null,
                      onTap: () => Navigator.pop(ctx, lang),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
        if (picked != null && picked != _language) {
          setState(() => _language = picked);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            const Icon(Icons.language, color: AppColors.primary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Language',
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              _language,
              style: TextStyle(
                color: cs.outline,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: cs.outline, size: 22),
          ],
        ),
      ),
    );
  }

  // ---------- Save Button ----------

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            shadowColor: AppColors.primary.withValues(alpha: 0.3),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.white,
                  ),
                )
              : const Text('Save Changes'),
        ),
      ),
    );
  }

  // ---------- Shared Helpers ----------

  Widget _buildSectionTitle(ColorScheme cs, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: cs.outline,
          fontSize: 11,
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
        fontSize: 13,
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

  InputDecoration _inputDecoration(String hint) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: cs.outline,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: cs.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }
}
