import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/models/notification.dart';
import 'api_service.dart';
import 'supabase_service.dart';

/// App-wide notification feed + bell badge, backed by the real
/// `/notifications` endpoint. Previously the dashboard's bell icon was pure
/// decoration — no tap handler, a permanently-on fake unread dot, and no
/// list behind it at all.
///
/// A single instance lives for the app's lifetime; [start] is idempotent so
/// every screen can call it in `initState` without creating duplicate
/// realtime subscriptions.
class NotificationCenter extends ChangeNotifier {
  NotificationCenter._();

  static final NotificationCenter instance = NotificationCenter._();

  List<AppNotification> _items = <AppNotification>[];

  /// Notifications, newest first.
  List<AppNotification> get items =>
      List.unmodifiable(_items..sort((a, b) => b.time.compareTo(a.time)));

  int get unreadCount => _items.where((n) => !n.read).length;
  bool get hasUnread => unreadCount > 0;

  /// Badge text capped at "9+".
  String get badgeLabel {
    final c = unreadCount;
    return c > 9 ? '9+' : '$c';
  }

  bool _started = false;
  RealtimeChannel? _channel;
  Timer? _debounce;

  void start() {
    if (_started) return;
    _started = true;
    unawaited(refresh());
    final uid = SupabaseService.currentUser?.id;
    if (uid != null) {
      _channel = SupabaseService.client
          .channel('notification_center')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'Salguri',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: uid,
            ),
            callback: (_) => _scheduleRefresh(),
          )
          .subscribe();
    }
  }

  void _scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), refresh);
  }

  Future<void> refresh() async {
    if (!SupabaseService.isAuthenticated) return;
    try {
      final rows = await ApiService.getNotifications();
      _items = rows.map(AppNotification.fromJson).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('[notifications] refresh failed: $e');
    }
  }

  Future<void> markRead(String id) async {
    final idx = _items.indexWhere((n) => n.id == id);
    if (idx == -1 || _items[idx].read) return;
    _items = [for (final n in _items) n.id == id ? n.copyWith(read: true) : n];
    notifyListeners();
    try {
      await ApiService.markNotificationRead(id);
    } catch (e) {
      debugPrint('[notifications] markRead failed: $e');
    }
  }

  Future<void> markAllRead() async {
    if (!hasUnread) return;
    _items = [for (final n in _items) n.read ? n : n.copyWith(read: true)];
    notifyListeners();
    try {
      await ApiService.markAllNotificationsRead();
    } catch (e) {
      debugPrint('[notifications] markAllRead failed: $e');
    }
  }

  /// Called on sign-out so a subsequent sign-in starts clean.
  Future<void> reset() async {
    _debounce?.cancel();
    final c = _channel;
    if (c != null) {
      await SupabaseService.unsubscribeChannel(c);
      _channel = null;
    }
    _started = false;
    _items = [];
    notifyListeners();
  }
}
