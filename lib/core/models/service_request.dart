class ServiceRequest {
  final String id;
  final String userId;
  final String requestNumber;
  final String category; // may be a UUID
  final String? categoryName; // human-readable name from API or local lookup
  final String status;
  final String statusMessage;
  final int? etaMinutes;
  final String? description;
  final String? scheduledTime;
  final String? assignedAgentId;
  final String? assignedAgentUserId;
  final String? assignedAgentName;
  final double? assignedAgentRating;
  final int? assignedAgentDeals;
  final String? assignedAgentPhone;
  final String? assignedAgentAvatarUrl;
  final DateTime createdAt;

  String get shortNumber {
    final digits = requestNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 4) return 'SR-${digits.substring(0, 4)}';
    if (digits.isNotEmpty) return 'SR-$digits';
    return 'SR-${id.substring(0, 4).toUpperCase()}';
  }

  /// Readable category — prefers categoryName, otherwise checks if category
  /// itself is human-readable (not a UUID).
  String get displayCategory {
    if (categoryName != null && categoryName!.isNotEmpty) return categoryName!;
    // If category looks like a UUID, return a generic label
    if (RegExp(r'^[0-9a-fA-F-]{20,}$').hasMatch(category)) {
      return 'Service';
    }
    return category;
  }

  String get displayTitle {
    if (description != null && description!.isNotEmpty) return description!;
    return '$displayCategory Request';
  }

  bool get hasAssignedAgent => assignedAgentId != null && assignedAgentName != null;

  String get agentInitials {
    if (assignedAgentName == null) return '?';
    return assignedAgentName!.split(' ').map((n) => n.isNotEmpty ? n[0] : '').join();
  }

  ServiceRequest copyWith({String? categoryName}) {
    return ServiceRequest(
      id: id,
      userId: userId,
      requestNumber: requestNumber,
      category: category,
      categoryName: categoryName ?? this.categoryName,
      status: status,
      statusMessage: statusMessage,
      etaMinutes: etaMinutes,
      description: description,
      scheduledTime: scheduledTime,
      assignedAgentId: assignedAgentId,
      assignedAgentUserId: assignedAgentUserId,
      assignedAgentName: assignedAgentName,
      assignedAgentRating: assignedAgentRating,
      assignedAgentDeals: assignedAgentDeals,
      assignedAgentPhone: assignedAgentPhone,
      assignedAgentAvatarUrl: assignedAgentAvatarUrl,
      createdAt: createdAt,
    );
  }

  const ServiceRequest({
    required this.id,
    required this.userId,
    required this.requestNumber,
    required this.category,
    this.categoryName,
    required this.status,
    this.statusMessage = '',
    this.etaMinutes,
    this.description,
    this.scheduledTime,
    this.assignedAgentId,
    this.assignedAgentUserId,
    this.assignedAgentName,
    this.assignedAgentRating,
    this.assignedAgentDeals,
    this.assignedAgentPhone,
    this.assignedAgentAvatarUrl,
    required this.createdAt,
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    return ServiceRequest(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      requestNumber: json['request_number'] as String,
      category: json['category'] as String,
      categoryName: json['category_name'] as String?,
      status: json['status'] as String? ?? 'pending',
      statusMessage: json['status_message'] as String? ?? '',
      etaMinutes: json['eta_minutes'] as int?,
      description: json['description'] as String?,
      scheduledTime: json['scheduled_time'] as String?,
      assignedAgentId: json['assigned_agent_id'] as String?,
      assignedAgentUserId: json['assigned_agent_user_id'] as String?,
      assignedAgentName: json['assigned_agent_name'] as String?,
      assignedAgentRating: (json['assigned_agent_rating'] as num?)?.toDouble(),
      assignedAgentDeals: json['assigned_agent_deals'] as int?,
      assignedAgentPhone: json['assigned_agent_phone'] as String?,
      assignedAgentAvatarUrl: json['assigned_agent_avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
