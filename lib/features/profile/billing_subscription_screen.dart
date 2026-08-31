import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';

class BillingSubscriptionScreen extends StatefulWidget {
  const BillingSubscriptionScreen({super.key});

  @override
  State<BillingSubscriptionScreen> createState() =>
      _BillingSubscriptionScreenState();
}

class _BillingSubscriptionScreenState extends State<BillingSubscriptionScreen> {
  int _selectedPlan = 1; // 0=Free, 1=Pro, 2=Premium
  bool _autoRenew = true;

  static const _planColors = [
    Color(0xFF64748B),
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
  ];

  static const _planBgColors = [
    Color(0xFFF1F5F9),
    Color(0xFFDBEAFE),
    Color(0xFFEDE9FE),
  ];

  static const _planPrices = [
    '\$0',
    '\$9.99',
    '\$24.99',
  ];

  static const _paymentMethods = [
    _PaymentMethod(
      name: 'EVC Plus',
      detail: '\u2022\u2022\u2022\u2022 4821',
      icon: Icons.phone_android,
      color: Color(0xFF22C55E),
      isDefault: true,
    ),
    _PaymentMethod(
      name: 'Zaad',
      detail: '\u2022\u2022\u2022\u2022 7390',
      icon: Icons.phone_android,
      color: Color(0xFF3B82F6),
    ),
    _PaymentMethod(
      name: 'Visa',
      detail: '\u2022\u2022\u2022\u2022 5512',
      icon: Icons.credit_card,
      color: Color(0xFF8B5CF6),
    ),
  ];

  static const _invoiceDates = [
    'Mar 1, 2026',
    'Feb 1, 2026',
    'Jan 1, 2026',
    'Dec 1, 2025',
  ];

  static const _invoiceAmounts = [
    '\$9.99',
    '\$9.99',
    '\$9.99',
    '\$9.99',
  ];

  List<String> _planNames(AppLocalizations l) => [
        l.tr('basic'),
        l.tr('pro'),
        l.tr('premium'),
      ];

  List<String> _planDescriptions(AppLocalizations l) => [
        l.tr('forCasualRenters'),
        l.tr('mostPopularRenters'),
        l.tr('forSeriousSeekers'),
      ];

  List<List<String>> _planFeatures(AppLocalizations l) => [
        [
          l.tr('browse10Listings'),
          l.tr('save5Properties'),
          l.tr('basicSearchFilters'),
          l.tr('emailSupport'),
        ],
        [
          l.tr('unlimitedViews'),
          l.tr('unlimitedSaved'),
          l.tr('advancedFilters'),
          l.tr('priorityShowing'),
          l.tr('inAppMessaging'),
          l.tr('documentStorage'),
        ],
        [
          l.tr('everythingInPro'),
          l.tr('earlyAccess'),
          l.tr('dedicatedAgent'),
          l.tr('virtualTour'),
          l.tr('creditScore'),
          l.tr('negotiation'),
          l.tr('zeroPlatformFees'),
        ],
      ];

  List<String?> _planBadges(AppLocalizations l) => [
        null,
        l.tr('popular'),
        l.tr('bestValue'),
      ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(cs, l),
            Divider(height: 1, color: cs.surfaceContainerHighest),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 40.h),
                children: [
                  _buildCurrentPlanCard(cs, l),
                  SizedBox(height: 24.h),
                  _buildSectionTitle(l.tr('chooseAPlan'), cs),
                  SizedBox(height: 12.h),
                  ...List.generate(3, (i) => _buildPlanCard(i, cs, l)),
                  SizedBox(height: 28.h),
                  _buildSectionTitle(l.tr('paymentMethods'), cs),
                  SizedBox(height: 12.h),
                  _buildPaymentMethodsCard(cs, l),
                  SizedBox(height: 28.h),
                  _buildSectionTitle(l.tr('billingHistory'), cs),
                  SizedBox(height: 12.h),
                  _buildBillingHistoryCard(cs, l),
                  SizedBox(height: 28.h),
                  _buildSectionTitle(l.tr('settings'), cs),
                  SizedBox(height: 12.h),
                  _buildSettingsCard(cs, l),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────── App Bar ────────────

  Widget _buildAppBar(ColorScheme cs, AppLocalizations l) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back, color: cs.onSurface),
          ),
          Expanded(
            child: Text(
              l.tr('billingSubscription'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          SizedBox(width: 48.w),
        ],
      ),
    );
  }

  // ──────────── Current Plan Card ────────────

  Widget _buildCurrentPlanCard(ColorScheme cs, AppLocalizations l) {
    final planColor = _planColors[_selectedPlan];
    final planName = _planNames(l)[_selectedPlan];
    final planPrice = _planPrices[_selectedPlan];
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [planColor, planColor.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: planColor.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      l.tr('currentPlan'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.workspace_premium,
                    color: Colors.white, size: 22.r),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            planName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 26.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                planPrice,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Text(
                  l.tr('perMonth'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today,
                    color: Colors.white.withValues(alpha: 0.8), size: 14.r),
                SizedBox(width: 8.w),
                Text(
                  'Renews on Apr 1, 2026',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────── Plan Cards ────────────

  Widget _buildPlanCard(int index, ColorScheme cs, AppLocalizations l) {
    final isSelected = _selectedPlan == index;
    final planColor = _planColors[index];
    final planBgColor = _planBgColors[index];
    final planName = _planNames(l)[index];
    final planDescription = _planDescriptions(l)[index];
    final planPrice = _planPrices[index];
    final features = _planFeatures(l)[index];
    final badge = _planBadges(l)[index];

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: isSelected ? planBgColor : cs.surface,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isSelected ? planColor : cs.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: planColor.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: cs.shadow.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? planColor.withValues(alpha: 0.15)
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    index == 0
                        ? Icons.person_outline
                        : index == 1
                            ? Icons.star_outline
                            : Icons.diamond_outlined,
                    color: isSelected ? planColor : cs.onSurfaceVariant,
                    size: 22.r,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            planName,
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (badge != null) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: planColor,
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                badge,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        planDescription,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      planPrice,
                      style: TextStyle(
                        color: isSelected ? planColor : cs.onSurface,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      l.tr('perMonth'),
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 14.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: features.map((f) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: isSelected ? planColor : cs.outline,
                      size: 16.r,
                    ),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text(
                        f,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            if (!isSelected) ...[
              SizedBox(height: 14.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => setState(() => _selectedPlan = index),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: planColor,
                    side: BorderSide(color: planColor.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: Text(
                    '${l.tr('switchTo')} $planName',
                    style: TextStyle(
                        fontSize: 13.sp, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
            if (isSelected) ...[
              SizedBox(height: 14.h),
              SizedBox(
                width: double.infinity,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    color: planColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle,
                          color: planColor, size: 18.r),
                      SizedBox(width: 6.w),
                      Text(
                        l.tr('currentPlanLabel'),
                        style: TextStyle(
                          color: planColor,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ──────────── Payment Methods ────────────

  Widget _buildPaymentMethodsCard(ColorScheme cs, AppLocalizations l) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ..._paymentMethods.asMap().entries.map((entry) {
            final pm = entry.value;
            final isLast = entry.key == _paymentMethods.length - 1;
            return Column(
              children: [
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  child: Row(
                    children: [
                      Container(
                        width: 42.w,
                        height: 42.h,
                        decoration: BoxDecoration(
                          color: pm.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(pm.icon, color: pm.color, size: 22.r),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  pm.name,
                                  style: TextStyle(
                                    color: cs.onSurface,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (pm.isDefault) ...[
                                  SizedBox(width: 8.w),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 7.w, vertical: 2.h),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(5.r),
                                    ),
                                    child: Text(
                                      l.tr('default_'),
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 9.sp,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              pm.detail,
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 13.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.more_horiz, color: cs.outline, size: 20.r),
                    ],
                  ),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    indent: 72.w,
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
              ],
            );
          }),
          Divider(
            height: 1,
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
          InkWell(
            onTap: () {},
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline,
                      color: AppColors.primary, size: 18.r),
                  SizedBox(width: 8.w),
                  Text(
                    'Add Payment Method',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────── Billing History ────────────

  Widget _buildBillingHistoryCard(ColorScheme cs, AppLocalizations l) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ...List.generate(_invoiceDates.length, (index) {
            final isLast = index == _invoiceDates.length - 1;
            return Column(
              children: [
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  child: Row(
                    children: [
                      Container(
                        width: 42.w,
                        height: 42.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(Icons.receipt_long_outlined,
                            color: const Color(0xFF22C55E), size: 20.r),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pro Plan',
                              style: TextStyle(
                                color: cs.onSurface,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              _invoiceDates[index],
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 13.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _invoiceAmounts[index],
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(5.r),
                            ),
                            child: Text(
                              l.tr('paid'),
                              style: TextStyle(
                                color: const Color(0xFF16A34A),
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    indent: 72.w,
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
              ],
            );
          }),
          Divider(
            height: 1,
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
          InkWell(
            onTap: () {},
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download_outlined,
                      color: AppColors.primary, size: 18.r),
                  SizedBox(width: 8.w),
                  Text(
                    'Download All Invoices',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────── Settings ────────────

  Widget _buildSettingsCard(ColorScheme cs, AppLocalizations l) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Auto-renew toggle
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              children: [
                Container(
                  width: 42.w,
                  height: 42.h,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(Icons.autorenew,
                      color: AppColors.primary, size: 22.r),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-Renew',
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Automatically renew your subscription',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _autoRenew,
                  onChanged: (v) => setState(() => _autoRenew = v),
                  activeTrackColor: AppColors.primary,
                  activeThumbColor: AppColors.white,
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            indent: 72.w,
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
          // Cancel subscription
          InkWell(
            onTap: () => _showCancelDialog(cs),
            child: Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              child: Row(
                children: [
                  Container(
                    width: 42.w,
                    height: 42.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.cancel_outlined,
                        color: const Color(0xFFEF4444), size: 22.r),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cancel Subscription',
                          style: TextStyle(
                            color: const Color(0xFFEF4444),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'You\'ll keep access until Apr 1, 2026',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 13.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: cs.outline, size: 22.r),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(ColorScheme cs) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('Cancel Subscription?',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700)),
        content: Text(
          'Your Pro plan will remain active until the end of the current billing period. After that, you\'ll be downgraded to the Basic plan.',
          style: TextStyle(fontSize: 14.sp, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child:
                Text('Keep Plan', style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Subscription will end on Apr 1, 2026')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r)),
              elevation: 0,
            ),
            child: const Text('Cancel Plan'),
          ),
        ],
      ),
    );
  }

  // ──────────── Helpers ────────────

  Widget _buildSectionTitle(String title, ColorScheme cs) {
    return Text(
      title,
      style: TextStyle(
        color: cs.outline,
        fontSize: 11.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }
}

// ──────────── Data Classes ────────────

class _PaymentMethod {
  final String name;
  final String detail;
  final IconData icon;
  final Color color;
  final bool isDefault;

  const _PaymentMethod({
    required this.name,
    required this.detail,
    required this.icon,
    required this.color,
    this.isDefault = false,
  });
}
