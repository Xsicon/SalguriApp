import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/models/chat_message.dart';

/// Supabase is responsible ONLY for:
///   - Authentication (sign up, sign in, OTP, sign out, password reset)
///   - File Storage (chat images)
///   - Realtime subscriptions (chat messages, conversation updates)
///
/// All business data (properties, rentals, service requests, etc.)
/// is fetched through ApiService → .NET backend.
class SupabaseService {
  SupabaseService._();

  static const String _supabaseUrl = 'https://yvooccmbtokzfnqibyig.supabase.co';
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl2b29jY21idG9remZucWlieWlnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI1NjMxNjUsImV4cCI6MjA3ODEzOTE2NX0.C4mzc_un5Zv1sDls5wYZbOT5nzxvMfkJfrzM0wJ4oFU';

  static bool _initialized = false;

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
    _initialized = true;
  }

  static User? get currentUser => _initialized ? client.auth.currentUser : null;

  static bool get isAuthenticated => currentUser != null;

  // ─── Auth ──────────────────────────────────────────────────────────────────

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final data = <String, dynamic>{};
    if (fullName != null) data['full_name'] = fullName;

    return client.auth.signUp(email: email, password: password, data: data);
  }

  static Future<AuthResponse> verifyEmailOTP({
    required String email,
    required String token,
  }) async {
    return client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
  }

  static Future<void> sendEmailOTP({required String email}) async {
    await client.auth.signInWithOtp(email: email);
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> updatePassword(String newPassword) async {
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // ─── Storage ───────────────────────────────────────────────────────────────

  static Future<String> uploadChatImage(
    String filePath,
    String fileName,
  ) async {
    final path = 'chat-images/${currentUser!.id}/$fileName';
    await client.storage
        .from('chat')
        .upload(path, Uri.parse(filePath).toFilePath() as dynamic);
    return client.storage.from('chat').getPublicUrl(path);
  }

  /// Upload a profile avatar and save the URL to user metadata.
  static Future<String> uploadProfileAvatar(File imageFile) async {
    final userId = currentUser!.id;
    final ext = imageFile.path.split('.').last.toLowerCase();
    final contentType = ext == 'jpg' ? 'image/jpeg' : 'image/$ext';
    final filename = 'avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final path = 'property-images/$userId/avatars/$filename';
    final bytes = await imageFile.readAsBytes();

    await client.storage
        .from('properties')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType),
        );

    final publicUrl = client.storage.from('properties').getPublicUrl(path);

    // Persist the URL in Supabase user metadata
    await client.auth.updateUser(
      UserAttributes(data: {'avatar_url': publicUrl}),
    );

    return publicUrl;
  }

  // ─── Realtime ──────────────────────────────────────────────────────────────

  static const String _schema = 'Salguri';

  /// Subscribe to new messages in a conversation.
  static RealtimeChannel subscribeToMessages(
    String conversationId,
    void Function(ChatMessage message) onMessage,
  ) {
    final channel = client.channel('messages:$conversationId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: _schema,
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            try {
              final msg = ChatMessage.fromJson(payload.newRecord);
              onMessage(msg);
            } catch (e) {
              debugPrint('Error parsing realtime message: $e');
            }
          },
        )
        .subscribe();
    return channel;
  }

  /// Subscribe to conversation list updates.
  static RealtimeChannel subscribeToConversations(void Function() onUpdate) {
    final channel = client.channel('conversations_updates');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: _schema,
          table: 'conversations',
          callback: (_) => onUpdate(),
        )
        .subscribe();
    return channel;
  }

  static Future<void> unsubscribeChannel(RealtimeChannel channel) async {
    await client.removeChannel(channel);
  }
}
