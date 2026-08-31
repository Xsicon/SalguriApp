import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/notification.dart';
import '../../services/notification_center.dart';
import '../inbox/inbox_screen.dart';
import '../rental/my_applications_screen.dart';
import '../rental/my_leases_screen.dart';

/// Full notifications list — reached by tapping the bell on the dashboard.
/// Previously there was no such screen at all; the bell icon did nothing.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _center = NotificationCenter.instance;

  @override
  void initState() {
    super.initState();
    _center.refresh();
  }

  void _onTap(AppNotification n) {
    _center.markRead(n.id);
    switch (n.type) {
      case AppNotificationType.message:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const InboxScreen()),
        );
      case AppNotificationType.application:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MyApplicationsScreen()),
        );
      case AppNotificationType.lease:
      case AppNotificationType.deposit:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MyLeasesScreen()),
        );
      case AppNotificationType.system:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          AnimatedBuilder(
            animation: _center,
            builder: (context, _) => _center.hasUnread
                ? TextButton(
                    onPressed: _center.markAllRead,
                    child: const Text('Mark all read'),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _center,
          builder: (context, _) {
            final items = _center.items;
            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(24.r),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_none, size: 44.r, color: AppColors.textMuted),
                      SizedBox(height: 12.h),
                      Text(
                        'You\'re all caught up',
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: _center.refresh,
              child: ListView.separated(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                itemCount: items.length,
                separatorBuilder: (context, index) => Divider(height: 1.h, color: AppColors.border),
                itemBuilder: (context, i) => _NotificationTile(
                  notification: items[i],
                  onTap: () => _onTap(items[i]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return InkWell(
      onTap: onTap,
      child: Container(
        color: notification.read ? Colors.transparent : AppColors.primary.withValues(alpha: 0.06),
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: notification.type.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(notification.type.icon, size: 20.r, color: notification.type.color),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: notification.read ? FontWeight.w600 : FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        notification.relativeTime(now),
                        style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    notification.body,
                    style: TextStyle(fontSize: 12.5.sp, color: AppColors.textSecondary, height: 1.3.h),
                  ),
                ],
              ),
            ),
            if (!notification.read) ...[
              SizedBox(width: 8.w),
              Container(
                margin: EdgeInsets.only(top: 6.h),
                width: 8.w,
                height: 8.h,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
