class ConversationParticipant {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String role;

  const ConversationParticipant({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.role,
  });

  factory ConversationParticipant.fromJson(Map<String, dynamic> json) {
    return ConversationParticipant(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'user',
    );
  }
}

class Conversation {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastMessageText;
  final DateTime? lastMessageAt;
  final List<ConversationParticipant> participants;
  final int unreadCount;

  const Conversation({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageText,
    this.lastMessageAt,
    this.participants = const [],
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(
    Map<String, dynamic> json, {
    List<ConversationParticipant> participants = const [],
    int unreadCount = 0,
  }) {
    return Conversation(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastMessageText: json['last_message_text'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      participants: participants,
      unreadCount: unreadCount,
    );
  }

  /// Get the other participant (not the current user).
  ConversationParticipant? otherParticipant(String currentUserId) {
    try {
      return participants.firstWhere((p) => p.userId != currentUserId);
    } catch (_) {
      return participants.isNotEmpty ? participants.first : null;
    }
  }
}
