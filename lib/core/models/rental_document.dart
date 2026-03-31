class RentalDocument {
  final String id;
  final String rentalId;
  final String userId;
  final String fileName;
  final String fileUrl;
  final String description;
  final DateTime uploadedAt;

  const RentalDocument({
    required this.id,
    required this.rentalId,
    required this.userId,
    required this.fileName,
    this.fileUrl = '',
    this.description = '',
    required this.uploadedAt,
  });

  factory RentalDocument.fromJson(Map<String, dynamic> json) {
    return RentalDocument(
      id: json['id'] as String,
      rentalId: json['rental_id'] as String,
      userId: json['user_id'] as String,
      fileName: json['file_name'] as String,
      fileUrl: json['file_url'] as String? ?? '',
      description: json['description'] as String? ?? '',
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
    );
  }
}
