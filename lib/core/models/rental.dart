class Rental {
  final String id;
  final String userId;
  final String? propertyId;
  final String address;
  final String location;
  final double monthlyRent;
  final DateTime nextDueDate;
  final bool isPaid;
  final String leaseStatus;
  final int beds;
  final double baths;
  final int sqft;
  final DateTime? leaseStart;
  final DateTime? leaseEnd;
  final String leaseTerm;
  final double securityDeposit;
  final String imageUrl;

  const Rental({
    required this.id,
    required this.userId,
    this.propertyId,
    required this.address,
    required this.location,
    required this.monthlyRent,
    required this.nextDueDate,
    required this.isPaid,
    this.leaseStatus = 'active',
    this.beds = 0,
    this.baths = 0,
    this.sqft = 0,
    this.leaseStart,
    this.leaseEnd,
    this.leaseTerm = '12 Months (Fixed)',
    this.securityDeposit = 0,
    this.imageUrl = '',
  });

  Rental copyWith({bool? isPaid}) {
    return Rental(
      id: id,
      userId: userId,
      propertyId: propertyId,
      address: address,
      location: location,
      monthlyRent: monthlyRent,
      nextDueDate: nextDueDate,
      isPaid: isPaid ?? this.isPaid,
      leaseStatus: leaseStatus,
      beds: beds,
      baths: baths,
      sqft: sqft,
      leaseStart: leaseStart,
      leaseEnd: leaseEnd,
      leaseTerm: leaseTerm,
      securityDeposit: securityDeposit,
      imageUrl: imageUrl,
    );
  }

  factory Rental.fromJson(Map<String, dynamic> json) {
    return Rental(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      propertyId: json['property_id'] as String?,
      address: json['address'] as String,
      location: json['location'] as String,
      monthlyRent: (json['monthly_rent'] as num).toDouble(),
      nextDueDate: DateTime.parse(json['next_due_date'] as String),
      isPaid: json['is_paid'] as bool? ?? false,
      leaseStatus: json['lease_status'] as String? ?? 'active',
      beds: json['beds'] as int? ?? 0,
      baths: (json['baths'] as num?)?.toDouble() ?? 0,
      sqft: json['sqft'] as int? ?? 0,
      leaseStart: json['lease_start'] != null
          ? DateTime.parse(json['lease_start'] as String)
          : null,
      leaseEnd: json['lease_end'] != null
          ? DateTime.parse(json['lease_end'] as String)
          : null,
      leaseTerm: json['lease_term'] as String? ?? '12 Months (Fixed)',
      securityDeposit: (json['security_deposit'] as num?)?.toDouble() ?? 0,
      imageUrl: json['image_url'] as String? ?? '',
    );
  }
}
