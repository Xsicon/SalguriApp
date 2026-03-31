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
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
