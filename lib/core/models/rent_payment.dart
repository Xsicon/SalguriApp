class RentPayment {
  final String id;
  final String rentalId;
  final double amount;
  final double platformFee;
  final String paymentMethod;
  final String status;
  final DateTime createdAt;

  const RentPayment({
    required this.id,
    required this.rentalId,
    required this.amount,
    this.platformFee = 0,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
  });

  factory RentPayment.fromJson(Map<String, dynamic> json) {
    return RentPayment(
      id: json['id'] as String,
      rentalId: json['rental_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      platformFee: (json['platform_fee'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['payment_method'] as String? ?? '',
      status: json['status'] as String? ?? 'paid',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
