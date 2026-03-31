class Agent {
  final String id;
  final String name;
  final String role;
  final double rating;
  final int deals;
  final String? phone;
  final String? email;
  final String? avatarUrl;
  final String? userId;
  final int propertyCount;

  const Agent({
    required this.id,
    required this.name,
    this.role = '',
    this.rating = 0.0,
    this.deals = 0,
    this.phone,
    this.email,
    this.avatarUrl,
    this.userId,
    this.propertyCount = 0,
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      deals: json['deals'] as int? ?? 0,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      userId: json['user_id'] as String?,
      propertyCount: json['property_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'role': role,
    'rating': rating,
    'deals': deals,
    if (phone != null) 'phone': phone,
    if (email != null) 'email': email,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
  };

  String get initials {
    if (name.isEmpty) return '?';
    return name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .join();
  }
}
