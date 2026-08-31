import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/models/chat_message.dart';
import 'api_service.dart';

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

  /// Without a timeout, a request on a bad connection hangs forever with no
  /// error and no visible feedback — the screen just spins, indistinguishable
  /// from the app being broken, and (worse, for sign-up/sign-in) the account
  /// never actually gets created server-side even though nothing tells the
  /// user that happened. Matches the timeout added to ApiService's own calls.
  static Future<T> _withTimeout<T>(Future<T> request) {
    return request.timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception(
        'Could not reach the server. Check your connection and try again.',
      ),
    );
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final data = <String, dynamic>{};
    if (fullName != null) data['full_name'] = fullName;

    final response = await _withTimeout(
        client.auth.signUp(email: email, password: password, data: data));
    // Supabase deliberately returns a normal, error-free response even when
    // the email is already registered (so a signup attempt can't be used to
    // discover which emails exist) — no new account is created, and the only
    // tell is an empty `identities` array. Without this check the caller has
    // no way to know signup silently did nothing.
    if (response.user?.identities?.isEmpty ?? false) {
      throw Exception('An account with this email already exists. Try signing in instead.');
    }
    return response;
  }

  static Future<AuthResponse> verifyEmailOTP({
    required String email,
    required String token,
  }) async {
    return _withTimeout(client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    ));
  }

  static Future<void> sendEmailOTP({required String email}) async {
    await _withTimeout(client.auth.signInWithOtp(email: email));
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return _withTimeout(client.auth.signInWithPassword(email: email, password: password));
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

  /// Uploads a security-deposit receipt (private bucket — RLS restricts
  /// reads to the lease's org members and its own tenant). Path convention
  /// matches signed-documents/lease-documents: <business_user_id>/lease/<lease_id>/...
  /// Returns just the storage path (not a public URL) — a signed URL is
  /// generated on demand by whoever reads it, same as sealed documents.
  static Future<String> uploadDepositReceipt({
    required String businessUserId,
    required String leaseId,
    required File file,
  }) async {
    final ext = file.path.split('.').last.toLowerCase();
    final contentType = switch (ext) {
      'pdf' => 'application/pdf',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      _ => 'application/octet-stream',
    };
    final filename = 'receipt_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final path = '$businessUserId/lease/$leaseId/$filename';
    final bytes = await file.readAsBytes();
    await client.storage.from('deposit-receipts').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType),
        );
    return path;
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

    // Auth metadata is what this device's own session reads locally...
    await client.auth.updateUser(
      UserAttributes(data: {'avatar_url': publicUrl}),
    );
    // ...but "Salguri".profiles.avatar_url is the copy everyone ELSE reads
    // (conversation participant records, the messaging directory) — that
    // row was never being written at all, which is why a real uploaded
    // avatar never showed up anywhere but this device's own profile screen.
    await ApiService.updateProfile(avatarUrl: publicUrl);

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

  /// Subscribe to conversation list updates. Listens for both new
  /// conversations (insert — e.g. someone messaging you for the first time)
  /// and existing ones changing (update — e.g. a new last message). A
  /// brand-new conversation only ever fires an insert, so without this an
  /// already-open inbox screen would never learn about it.
  static RealtimeChannel subscribeToConversations(void Function() onUpdate) {
    final channel = client.channel('conversations_updates');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: _schema,
          table: 'conversations',
          callback: (_) => onUpdate(),
        )
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
