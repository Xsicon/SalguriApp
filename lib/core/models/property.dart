import 'agent.dart';

class Property {
  final String id;
  final String title;
  final String location;
  final String price;
  final String priceLabel;
  final int beds;
  final int baths;
  final int sqft;
  final int yearBuilt;
  final double rating;
  final int reviews;
  final String description;
  final List<String> images;
  final List<String> amenities;
  final Agent? agent;
  final String type;
  final double latitude;
  final double longitude;
  final String? ownerUserId;

  const Property({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    this.priceLabel = '',
    required this.beds,
    required this.baths,
    required this.sqft,
    required this.yearBuilt,
    required this.rating,
    this.reviews = 0,
    required this.description,
    required this.images,
    required this.amenities,
    this.agent,
    this.type = 'For Sale',
    this.latitude = 2.0469,
    this.longitude = 45.3182,
    this.ownerUserId,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] as String,
      title: json['title'] as String,
      location: json['location'] as String,
      price: json['price'] as String,
      priceLabel: json['price_label'] as String? ?? '',
      beds: json['beds'] as int? ?? 0,
      baths: json['baths'] as int? ?? 0,
      sqft: json['sqft'] as int? ?? 0,
      yearBuilt: json['year_built'] as int? ?? 2024,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviews: json['reviews'] as int? ?? 0,
      description: json['description'] as String? ?? '',
      images: List<String>.from(json['images'] ?? []),
      amenities: List<String>.from(json['amenities'] ?? []),
      agent: json['agent'] != null ? Agent.fromJson(json['agent']) : null,
      type: json['type'] as String? ?? 'For Sale',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 2.0469,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 45.3182,
      ownerUserId: json['owner_user_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'location': location,
    'price': price,
    'price_label': priceLabel,
    'beds': beds,
    'baths': baths,
    'sqft': sqft,
    'year_built': yearBuilt,
    'description': description,
    'images': images,
    'amenities': amenities,
    if (agent != null) 'agent_id': agent!.id,
    'type': type,
    'latitude': latitude,
    'longitude': longitude,
  };
}
