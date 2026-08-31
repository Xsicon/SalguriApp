import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../services/supabase_service.dart';
import '../profile/terms_of_service_screen.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onCreateAccount() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).tr('agreeRequired')),
        ),
      );
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final fullName = _nameController.text.trim();

    setState(() => _isLoading = true);
    try {
      await SupabaseService.signUp(
        email: email,
        password: password,
        fullName: fullName.isNotEmpty ? fullName : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).tr('accountCreated'))),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Divider(height: 1, color: cs.surfaceContainerHighest),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    _buildForm(),
                    _buildLoginRedirect(),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- App Bar ----------

  Widget _buildAppBar() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back, color: cs.onSurface),
            iconSize: 24.r,
          ),
          Expanded(
            child: Text(
              AppLocalizations.of(context).tr('createAccount'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(width: 48.w),
        ],
      ),
    );
  }

  // ---------- Header ----------

  Widget _buildHeader() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).tr('joinSalguri'),
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 26.sp,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            AppLocalizations.of(context).tr('startJourney'),
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Form ----------

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FieldLabel(text: AppLocalizations.of(context).tr('fullName')),
            SizedBox(height: 8.h),
            _buildTextField(
              controller: _nameController,
              hint: AppLocalizations.of(context).tr('fullNameHint'),
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? AppLocalizations.of(context).tr('nameRequired') : null,
            ),
            SizedBox(height: 20.h),
            _FieldLabel(text: AppLocalizations.of(context).tr('emailAddress')),
            SizedBox(height: 8.h),
            _buildTextField(
              controller: _emailController,
              hint: AppLocalizations.of(context).tr('emailHint'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return AppLocalizations.of(context).tr('emailRequired');
                if (!v.contains('@')) return AppLocalizations.of(context).tr('emailInvalid');
                return null;
              },
            ),
            SizedBox(height: 20.h),
            _FieldLabel(text: AppLocalizations.of(context).tr('password')),
            SizedBox(height: 8.h),
            _buildPasswordField(
              controller: _passwordController,
              obscure: _obscurePassword,
              onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
              validator: (v) {
                if (v == null || v.length < 6) return AppLocalizations.of(context).tr('passwordMinLength');
                return null;
              },
            ),
            SizedBox(height: 20.h),
            _FieldLabel(text: AppLocalizations.of(context).tr('confirmPassword')),
            SizedBox(height: 8.h),
            _buildPasswordField(
              controller: _confirmPasswordController,
              obscure: _obscureConfirmPassword,
              onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              validator: (v) {
                if (v != _passwordController.text) return AppLocalizations.of(context).tr('passwordsNoMatch');
                return null;
              },
            ),
            SizedBox(height: 24.h),
            _buildTermsCheckbox(),
            SizedBox(height: 24.h),
            _buildCreateAccountButton(),
          ],
        ),
      ),
    );
  }

  // ---------- Individual Field Builders ----------

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      style: TextStyle(fontSize: 16.sp, color: cs.onSurface),
      decoration: _inputDecoration(hint),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: TextStyle(fontSize: 16.sp, color: cs.onSurface),
      decoration: _inputDecoration('').copyWith(
        hintText: '\u2022' * 8,
        suffixIcon: GestureDetector(
          onTap: onToggle,
          child: Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: Icon(
              obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: cs.outline,
              size: 22.r,
            ),
          ),
        ),
        suffixIconConstraints: BoxConstraints(minWidth: 40.w, minHeight: 40.h),
      ),
    );
  }

  // ---------- Terms Checkbox ----------

  Widget _buildTermsCheckbox() {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22.w,
          height: 22.h,
          child: Checkbox(
            value: _agreedToTerms,
            onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
            side: BorderSide(color: cs.outlineVariant),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Text.rich(
              TextSpan(
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14.sp, height: 1.4),
                children: [
                  TextSpan(text: AppLocalizations.of(context).tr('agreeToTerms')),
                  TextSpan(
                    text: AppLocalizations.of(context).tr('termsOfService'),
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                    recognizer: TapGestureRecognizer()..onTap = () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
                      );
                    },
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: AppLocalizations.of(context).tr('privacyPolicy'),
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                    recognizer: TapGestureRecognizer()..onTap = () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
                      );
                    },
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------- Create Account Button ----------

  Widget _buildCreateAccountButton() {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _onCreateAccount,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          elevation: 4,
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
          textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, letterSpacing: 1),
        ),
        child: _isLoading
            ? SizedBox(
                width: 24.w,
                height: 24.h,
                child: const CircularProgressIndicator(color: AppColors.white, strokeWidth: 2.5),
              )
            : Text(AppLocalizations.of(context).tr('createAccount')),
      ),
    );
  }

  // ---------- Login Redirect ----------

  Widget _buildLoginRedirect() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Center(
        child: Text.rich(
          TextSpan(
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14.sp),
            children: [
              TextSpan(text: AppLocalizations.of(context).tr('alreadyHaveAccount')),
              TextSpan(
                text: AppLocalizations.of(context).tr('logIn'),
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Shared Input Decoration ----------

  InputDecoration _inputDecoration(String hint) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: cs.outline, fontSize: 16.sp, fontWeight: FontWeight.w400),
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

// ---------- Field Label ----------

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
