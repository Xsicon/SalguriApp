import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent;

import '../main.dart' show navigatorKey;
import 'api_service.dart';
import 'supabase_service.dart';
import 'unread_badge_controller.dart';

/// Runs when a push arrives while the app is backgrounded or terminated.
/// Must be a top-level function — the plugin invokes it on a separate
/// isolate that has no access to any app state built up in `main()`.
@pragma('vm:entry-point')
Future<void> pushBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Wires up Firebase Cloud Messaging: requests permission, registers this
/// device's token with the backend (`ApiService.registerPushToken`, backed
/// by the `push_tokens` table), and shows a local notification — with sound
/// — for messages that arrive while the app is in the foreground (FCM does
/// not surface a system notification for foreground messages on its own).
/// Tapping a notification, in any app state, opens the inbox.
class PushService {
  PushService._();

  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'messages',
    'Messages',
    description: 'New chat messages',
    importance: Importance.high,
  );

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(pushBackgroundHandler);

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) => _openInbox(),
    );

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen((_) => _openInbox());

    // App launched by tapping a notification while fully terminated.
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) _openInbox();

    FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);

    // Covers every sign-in path (login, signup, OTP, magic link) in one
    // place rather than needing a call added at each one.
    SupabaseService.client.auth.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.signedIn) {
        unawaited(registerCurrentToken());
      }
    });

    await registerCurrentToken();
  }

  /// Call after sign-in (and once at startup for an already-signed-in user)
  /// so the backend knows which device to push to for this account.
  static Future<void> registerCurrentToken() async {
    if (!SupabaseService.isAuthenticated) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _registerToken(token);
    } catch (e) {
      debugPrint('[push] token registration failed: $e');
    }
  }

  static Future<void> _registerToken(String token) async {
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      await ApiService.registerPushToken(token, platform);
    } catch (e) {
      debugPrint('[push] registerPushToken failed: $e');
    }
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] as String? ?? 'New message';
    final body = notification?.body ?? message.data['body'] as String? ?? '';
    await _local.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'messages',
          'Messages',
          channelDescription: 'New chat messages',
          importance: Importance.high,
          priority: Priority.high,
          // No explicit `sound:` override — plays the channel's default
          // (system) notification sound.
        ),
        iOS: DarwinNotificationDetails(presentSound: true, presentAlert: true),
      ),
    );
    unawaited(UnreadBadgeController.instance.refresh());
  }

  static void _openInbox() {
    unawaited(UnreadBadgeController.instance.refresh());
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    // The dashboard owns the Inbox tab internally; popping to root and
    // letting the user tap Inbox is simpler than reaching into its private
    // tab-index state from here. A future iteration can route to the exact
    // conversation using `message.data['related_entity_id']`.
    Navigator.of(ctx).popUntil((r) => r.isFirst);
  }
}
