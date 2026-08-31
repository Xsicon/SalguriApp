/// The Job Marketplace + service-request models — mirrors
/// `Salgury.API.DTOs.VendorManagementDtos` on the backend. Distinct from
/// `service_request.dart`'s legacy `ServiceRequest` (that one auto-assigns to
/// a real-estate agent and is unrelated to Operational Services companies).
///
/// JSON keys are snake_case — the backend serializes with
/// `JsonNamingPolicy.SnakeCaseLower` in both directions.
library;

class VendorMarketplacePost {
  final String id;
  final String businessUserId;
  final String companyName;
  final String title;
  final String? description;
  final num rate;
  final String rateUnit;
  final String? packageLabel;
  final String? imageUrl;

  const VendorMarketplacePost({
    required this.id,
    required this.businessUserId,
    required this.companyName,
    required this.title,
    required this.rate,
    required this.rateUnit,
    this.description,
    this.packageLabel,
    this.imageUrl,
  });

  factory VendorMarketplacePost.fromJson(Map<String, dynamic> j) => VendorMarketplacePost(
        id: j['id'] as String,
        businessUserId: j['business_user_id'] as String,
        companyName: (j['company_name'] as String?) ?? 'Service Provider',
        title: (j['title'] as String?) ?? '',
        description: j['description'] as String?,
        rate: (j['rate'] as num?) ?? 0,
        rateUnit: (j['rate_unit'] as String?) ?? 'hr',
        packageLabel: j['package_label'] as String?,
        imageUrl: j['image_url'] as String?,
      );
}

class PropertyServiceRequest {
  final String id;
  final String scope; // property | direct
  final String? propertyLabel;
  final String? pmCompanyName;
  final String? vendorCompanyName;
  final String category;
  final String title;
  final String? description;
  /// awaiting_assignment | pending_approval | awaiting_vendor_response |
  /// assigned | in_progress | completed | declined | cancelled
  final String status;
  final DateTime createdAt;

  const PropertyServiceRequest({
    required this.id,
    required this.scope,
    required this.category,
    required this.title,
    required this.status,
    required this.createdAt,
    this.propertyLabel,
    this.pmCompanyName,
    this.vendorCompanyName,
    this.description,
  });

  factory PropertyServiceRequest.fromJson(Map<String, dynamic> j) => PropertyServiceRequest(
        id: j['id'] as String,
        scope: (j['scope'] as String?) ?? 'property',
        propertyLabel: j['property_label'] as String?,
        pmCompanyName: j['pm_company_name'] as String?,
        vendorCompanyName: j['vendor_company_name'] as String?,
        category: (j['category'] as String?) ?? 'general',
        title: (j['title'] as String?) ?? '',
        description: j['description'] as String?,
        status: (j['status'] as String?) ?? 'awaiting_assignment',
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
      );

  String get statusLabel => switch (status) {
        'awaiting_assignment' => 'Finding a provider',
        'pending_approval' => 'Being reviewed',
        'awaiting_vendor_response' => 'Awaiting response',
        'assigned' => 'Assigned',
        'in_progress' => 'In progress',
        'completed' => 'Completed',
        'declined' => 'Declined',
        'cancelled' => 'Cancelled',
        _ => status,
      };
}
