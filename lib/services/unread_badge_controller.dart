import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'api_service.dart';
import 'supabase_service.dart';

/// App-wide unread count for the bottom-nav Inbox badge, backed by the
/// generic `/notifications` endpoint (one unread notification per
/// conversation with unread messages, plus any other alert type later).
///
/// A single instance lives for the app's lifetime; [start] is idempotent so
/// every screen's bottom nav can call it in `initState` without creating
/// duplicate realtime subscriptions.
class UnreadBadgeController extends ChangeNotifier {
  UnreadBadgeController._();

  static final UnreadBadgeController instance = UnreadBadgeController._();

  int _count = 0;
  int get count => _count;

  bool _started = false;
  RealtimeChannel? _channel;
  RealtimeChannel? _notificationsChannel;
  Timer? _debounce;

  void start() {
    if (_started) return;
    _started = true;
    unawaited(refresh());
    _channel = SupabaseService.subscribeToConversations(_scheduleRefresh);
    final uid = SupabaseService.currentUser?.id;
    if (uid != null) {
      _notificationsChannel = SupabaseService.client
          .channel('unread_badge_notifications')
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
    if (!SupabaseService.isAuthenticated) {
      if (_count != 0) {
        _count = 0;
        notifyListeners();
      }
      return;
    }
    try {
      final c = await ApiService.getUnreadNotificationCount();
      if (c != _count) {
        _count = c;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[unread-badge] refresh failed: $e');
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
    final nc = _notificationsChannel;
    if (nc != null) {
      await SupabaseService.unsubscribeChannel(nc);
      _notificationsChannel = null;
    }
    _started = false;
    _count = 0;
    notifyListeners();
  }
}
