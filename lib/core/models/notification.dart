import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// The kind of event a notification represents. Mirrors the backend's
/// `notifications.type` column (see `NotificationService.NotifyAsync` call
/// sites) — drives the leading icon/color here and how the host screen
/// routes when the user taps it.
enum AppNotificationType { message, application, lease, deposit, system }

AppNotificationType appNotificationTypeFromString(String? raw) => switch (raw) {
      'message' => AppNotificationType.message,
      'application' => AppNotificationType.application,
      'lease' => AppNotificationType.lease,
      'deposit' => AppNotificationType.deposit,
      _ => AppNotificationType.system,
    };

extension AppNotificationTypeUi on AppNotificationType {
  IconData get icon => switch (this) {
        AppNotificationType.message => Icons.chat_bubble_outline,
        AppNotificationType.application => Icons.assignment_outlined,
        AppNotificationType.lease => Icons.description_outlined,
        AppNotificationType.deposit => Icons.account_balance_wallet_outlined,
        AppNotificationType.system => Icons.info_outline,
      };

  Color get color => switch (this) {
        AppNotificationType.message => const Color(0xFF0EA5E9),
        AppNotificationType.application => AppColors.primary,
        AppNotificationType.lease => AppColors.success,
        AppNotificationType.deposit => AppColors.warning,
        AppNotificationType.system => AppColors.textMuted,
      };
}

class AppNotification {
  final String id;
  final AppNotificationType type;
  final String title;
  final String body;
  final DateTime time;
  final bool read;

  /// Related record id (conversation/application/lease id) for routing.
  final String? targetId;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    this.read = false,
    this.targetId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as String,
        type: appNotificationTypeFromString(j['type'] as String?),
        title: (j['title'] as String?) ?? '',
        body: (j['body'] as String?) ?? '',
        time: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
        read: (j['read'] as bool?) ?? false,
        targetId: j['related_entity_id'] as String?,
      );

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        time: time,
        read: read ?? this.read,
        targetId: targetId,
      );

  /// Short relative age, e.g. "now", "5m", "3h", "2d".
  String relativeTime(DateTime now) {
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
