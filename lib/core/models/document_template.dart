/// Mirrors `business-app`'s `document_signing_models.dart` — both apps read
/// the same `Salgury.API` `DocumentSigningController` response shape, but
/// each Flutter project is independent so the model is duplicated, not shared.
class DocumentField {
  final String id;
  final String fieldType; // signature | date | text
  final String assignedRole; // tenant | co_tenant | business
  final int pageNumber;
  final double xPercent;
  final double yPercent;
  final double widthPercent;
  final double heightPercent;

  const DocumentField({
    required this.id,
    required this.fieldType,
    required this.assignedRole,
    required this.pageNumber,
    required this.xPercent,
    required this.yPercent,
    required this.widthPercent,
    required this.heightPercent,
  });

  factory DocumentField.fromJson(Map<String, dynamic> j) => DocumentField(
        id: j['id'] as String,
        fieldType: (j['field_type'] as String?) ?? 'signature',
        assignedRole: (j['assigned_role'] as String?) ?? 'tenant',
        pageNumber: (j['page_number'] as num?)?.toInt() ?? 1,
        xPercent: (j['x_percent'] as num?)?.toDouble() ?? 0,
        yPercent: (j['y_percent'] as num?)?.toDouble() ?? 0,
        widthPercent: (j['width_percent'] as num?)?.toDouble() ?? 0.3,
        heightPercent: (j['height_percent'] as num?)?.toDouble() ?? 0.06,
      );
}

class DocumentTemplate {
  final String id;
  final String name;
  final String basePdfUrl;
  final List<DocumentField> fields;

  const DocumentTemplate({
    required this.id,
    required this.name,
    required this.basePdfUrl,
    required this.fields,
  });

  factory DocumentTemplate.fromJson(Map<String, dynamic> j) => DocumentTemplate(
        id: j['id'] as String,
        name: (j['name'] as String?) ?? '',
        basePdfUrl: (j['base_pdf_url'] as String?) ?? '',
        fields: ((j['fields'] as List?) ?? const [])
            .map((f) => DocumentField.fromJson(f as Map<String, dynamic>))
            .toList(growable: false),
      );
}

class MyLeaseSummary {
  final String id;
  final String businessUserId;
  final String unitLabel;
  final String propertyTitle;
  final String propertyAddress;
  final String status;
  final String? templateId;
  final String? documentUrl;
  final bool businessSigned;
  final bool tenantSigned;
  final String? sealedDocumentUrl;
  final String depositStatus;
  final double? depositAmount;

  const MyLeaseSummary({
    required this.id,
    required this.businessUserId,
    required this.unitLabel,
    required this.propertyTitle,
    required this.propertyAddress,
    required this.status,
    required this.businessSigned,
    required this.tenantSigned,
    this.templateId,
    this.documentUrl,
    this.sealedDocumentUrl,
    this.depositStatus = 'unpaid',
    this.depositAmount,
  });

  factory MyLeaseSummary.fromJson(Map<String, dynamic> j) => MyLeaseSummary(
        id: j['id'] as String,
        businessUserId: j['business_user_id'] as String? ?? '',
        unitLabel: (j['unit_label'] as String?) ?? '',
        propertyTitle: (j['property_title'] as String?) ?? '',
        propertyAddress: (j['property_address'] as String?) ?? '',
        status: (j['status'] as String?) ?? 'pending_signature',
        templateId: j['template_id'] as String?,
        documentUrl: j['document_url'] as String?,
        businessSigned: (j['business_signed'] as bool?) ?? false,
        tenantSigned: (j['tenant_signed'] as bool?) ?? false,
        sealedDocumentUrl: j['sealed_document_url'] as String?,
        depositStatus: (j['deposit_status'] as String?) ?? 'unpaid',
        depositAmount: (j['deposit_amount'] as num?)?.toDouble(),
      );
}

class MyInspectionSummary {
  final String id;
  final String unitLabel;
  final String propertyTitle;
  final String propertyAddress;
  final String title;
  final String status;
  final String? templateId;
  final String? reportUrl;
  final bool signOffRequired;
  final bool businessSigned;
  final bool tenantSigned;
  final String? sealedReportUrl;

  const MyInspectionSummary({
    required this.id,
    required this.unitLabel,
    required this.propertyTitle,
    required this.propertyAddress,
    required this.title,
    required this.status,
    required this.signOffRequired,
    required this.businessSigned,
    required this.tenantSigned,
    this.templateId,
    this.reportUrl,
    this.sealedReportUrl,
  });

  factory MyInspectionSummary.fromJson(Map<String, dynamic> j) => MyInspectionSummary(
        id: j['id'] as String,
        unitLabel: (j['unit_label'] as String?) ?? '',
        propertyTitle: (j['property_title'] as String?) ?? '',
        propertyAddress: (j['property_address'] as String?) ?? '',
        title: (j['title'] as String?) ?? '',
        status: (j['status'] as String?) ?? 'scheduled',
        templateId: j['template_id'] as String?,
        reportUrl: j['report_url'] as String?,
        signOffRequired: (j['sign_off_required'] as bool?) ?? false,
        businessSigned: (j['business_signed'] as bool?) ?? false,
        tenantSigned: (j['tenant_signed'] as bool?) ?? false,
        sealedReportUrl: j['sealed_report_url'] as String?,
      );
}

class MyApplicationSummary {
  final String id;
  final String? propertyId;
  final String propertyTitle;
  final String status;
  final double? monthlyIncome;
  final String? notes;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewerNotes;

  const MyApplicationSummary({
    required this.id,
    required this.propertyTitle,
    required this.status,
    required this.submittedAt,
    this.propertyId,
    this.monthlyIncome,
    this.notes,
    this.reviewedAt,
    this.reviewerNotes,
  });

  factory MyApplicationSummary.fromJson(Map<String, dynamic> j) => MyApplicationSummary(
        id: j['id'] as String,
        propertyId: j['property_id'] as String?,
        propertyTitle: (j['property_title'] as String?) ?? '',
        status: (j['status'] as String?) ?? 'under_review',
        monthlyIncome: (j['monthly_income'] as num?)?.toDouble(),
        notes: j['notes'] as String?,
        submittedAt: DateTime.tryParse(j['submitted_at'] as String? ?? '') ?? DateTime.now(),
        reviewedAt: j['reviewed_at'] == null ? null : DateTime.tryParse(j['reviewed_at'] as String),
        reviewerNotes: j['reviewer_notes'] as String?,
      );
}

class SubmitSignatureResult {
  final bool allSignaturesComplete;
  final String? sealedDocumentUrl;

  const SubmitSignatureResult({
    required this.allSignaturesComplete,
    this.sealedDocumentUrl,
  });

  factory SubmitSignatureResult.fromJson(Map<String, dynamic> j) => SubmitSignatureResult(
        allSignaturesComplete: (j['all_signatures_complete'] as bool?) ?? false,
        sealedDocumentUrl: j['sealed_document_url'] as String?,
      );
}
