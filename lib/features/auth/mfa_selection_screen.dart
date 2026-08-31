import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';

enum MfaMethod { sms, authenticator }

class MfaSelectionScreen extends StatefulWidget {
  const MfaSelectionScreen({super.key});

  @override
  State<MfaSelectionScreen> createState() => _MfaSelectionScreenState();
}

class _MfaSelectionScreenState extends State<MfaSelectionScreen> {
  MfaMethod _selected = MfaMethod.sms;

  void _onContinue() {
    // TODO: Navigate to the appropriate setup screen based on _selected
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
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 28.h),
                      _buildHeader(),
                      SizedBox(height: 28.h),
                      _buildOptionCard(
                        method: MfaMethod.sms,
                        icon: Icons.sms_outlined,
                        title: 'SMS Verification',
                        description:
                            'Receive a code via text message to your registered mobile number.',
                        badge: null,
                      ),
                      SizedBox(height: 14.h),
                      _buildOptionCard(
                        method: MfaMethod.authenticator,
                        icon: Icons.lock_outlined,
                        title: 'Authenticator App',
                        description:
                            'Use Google Authenticator, Authy, or Microsoft Authenticator for the highest level of security.',
                        badge: 'RECOMMENDED',
                      ),
                      SizedBox(height: 24.h),
                      _buildInfoBox(),
                      SizedBox(height: 24.h),
                      _buildRemindLater(),
                      SizedBox(height: 20.h),
                      _buildContinueButton(),
                      SizedBox(height: 24.h),
                    ],
                  ),
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
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.arrow_back, color: cs.onSurface),
            iconSize: 24.r,
          ),
          Expanded(
            child: Text(
              'SECURITY',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Secure Your Account',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 26.sp,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Choose how you want to receive your verification codes to keep your Salguri account safe.',
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ---------- Option Card ----------

  Widget _buildOptionCard({
    required MfaMethod method,
    required IconData icon,
    required String title,
    required String description,
    required String? badge,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = _selected == method;

    return GestureDetector(
      onTap: () => setState(() => _selected = method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.06)
              : cs.surface,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : cs.outlineVariant,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radio indicator
            Container(
              width: 22.w,
              height: 22.h,
              margin: EdgeInsets.only(top: 2.h),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : cs.outline,
                  width: isSelected ? 2 : 1.5,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12.w,
                        height: 12.h,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 14.w),
            // Icon
            Container(
              width: 44.w,
              height: 44.h,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: isSelected ? AppColors.primary : cs.onSurfaceVariant,
                  size: 24.r,
                ),
              ),
            ),
            SizedBox(width: 14.w),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (badge != null) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    description,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Info Box ----------

  Widget _buildInfoBox() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.primary,
            size: 20.r,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Two-factor authentication adds an extra layer of security. Even if someone discovers your password, they won\u2019t be able to access your account.',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 13.sp,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Remind Me Later ----------

  Widget _buildRemindLater() {
    return Center(
      child: GestureDetector(
        onTap: () {
          // TODO: Skip MFA setup and navigate forward
          Navigator.of(context).maybePop();
        },
        child: Text(
          'Not now, remind me later',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ---------- Continue Button ----------

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton(
        onPressed: _onContinue,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: 17.h),
          textStyle: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        child: const Text('CONTINUE'),
      ),
    );
  }
}
