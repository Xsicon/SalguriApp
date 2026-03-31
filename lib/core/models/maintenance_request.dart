class MaintenanceRequest {
  final String id;
  final String rentalId;
  final String userId;
  final String title;
  final String description;
  final String category;
  final String status;
  final DateTime reportedAt;
  final DateTime? resolvedAt;

  const MaintenanceRequest({
    required this.id,
    required this.rentalId,
    required this.userId,
    required this.title,
    this.description = '',
    this.category = 'general',
    this.status = 'pending',
    required this.reportedAt,
    this.resolvedAt,
  });

  factory MaintenanceRequest.fromJson(Map<String, dynamic> json) {
    return MaintenanceRequest(
      id: json['id'] as String,
      rentalId: json['rental_id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
      status: json['status'] as String? ?? 'pending',
      reportedAt: DateTime.parse(json['reported_at'] as String),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
    );
  }
}
