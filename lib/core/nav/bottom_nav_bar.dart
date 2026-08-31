import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../services/notification_center.dart';
import '../../services/unread_badge_controller.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';

/// The app's single bottom navigation bar — Home / Search / Explore /
/// Inbox / Profile. Every root screen renders this instead of building its
/// own copy, so the Inbox unread badge (backed by [UnreadBadgeController])
/// only needs to be wired up in one place.
///
/// Built as a plain Row of custom items rather than Flutter's built-in
/// `BottomNavigationBar` — that widget lays out and sizes each icon
/// internally, which silently clipped the badge's `Positioned` overflow.
/// A hand-rolled layout gives full control over that, same as business-app's
/// nav bar (which never had this problem).
class BottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  @override
  void initState() {
    super.initState();
    // Idempotent — safe even if another instance already started it.
    UnreadBadgeController.instance.start();
    NotificationCenter.instance.start();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: UnreadBadgeController.instance,
      builder: (context, _) {
        final unread = UnreadBadgeController.instance.count;
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64.h,
              child: Row(
                children: [
                  _NavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: l.tr('home'),
                    selected: widget.currentIndex == 0,
                    onTap: () => widget.onTap(0),
                  ),
                  _NavItem(
                    icon: Icons.search_rounded,
                    activeIcon: Icons.search_rounded,
                    label: l.tr('search'),
                    selected: widget.currentIndex == 1,
                    onTap: () => widget.onTap(1),
                  ),
                  _NavItem(
                    icon: Icons.explore_outlined,
                    activeIcon: Icons.explore_rounded,
                    label: l.tr('explore'),
                    selected: widget.currentIndex == 2,
                    onTap: () => widget.onTap(2),
                  ),
                  _NavItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    activeIcon: Icons.chat_bubble_rounded,
                    label: l.tr('inbox'),
                    selected: widget.currentIndex == 3,
                    onTap: () => widget.onTap(3),
                    badgeCount: unread,
                  ),
                  _NavItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: l.tr('profile'),
                    selected: widget.currentIndex == 4,
                    onTap: () => widget.onTap(4),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = selected ? AppColors.primary : cs.outline;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(selected ? activeIcon : icon, color: color, size: 22.r),
                if (badgeCount > 0)
                  Positioned(
                    right: -8.w,
                    top: -4.h,
                    child: Container(
                      constraints: BoxConstraints(minWidth: 16.w, minHeight: 16.h),
                      padding: EdgeInsets.symmetric(horizontal: 3.w),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white, width: 1.5.w),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
