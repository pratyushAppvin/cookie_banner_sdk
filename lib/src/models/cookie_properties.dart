/// Represents a single cookie with all its metadata and consent status.
///
/// Mirrors TypeScript `CookieProperties` interface.
class CookieProperties {
  final int cookieId;
  final String cookieKey;
  final String vendorName;
  final String cookieType;
  final String description;
  final String expiration;
  final bool consent;
  final int consentRecordId;
  final int? serviceId;
  final int? categoryId;
  final String? categoryName;
  final int? domainId;
  final bool? consentStatus;

  const CookieProperties({
    required this.cookieId,
    required this.cookieKey,
    required this.vendorName,
    required this.cookieType,
    required this.description,
    required this.expiration,
    required this.consent,
    required this.consentRecordId,
    this.serviceId,
    this.categoryId,
    this.categoryName,
    this.domainId,
    this.consentStatus,
  });

  factory CookieProperties.fromJson(Map<String, dynamic> json) {
    return CookieProperties(
      cookieId: json['cookie_id'] as int,
      cookieKey: json['cookie_key'] as String? ?? '',
      vendorName: json['vendor_name'] as String? ?? '',
      cookieType: json['cookie_type'] as String? ?? '',
      description: json['description'] as String? ?? '',
      expiration: json['expiration'] as String? ?? '',
      consent: json['consent'] as bool? ?? false,
      consentRecordId: json['consent_record_id'] as int? ?? 0,
      serviceId: json['service_id'] as int?,
      categoryId: json['category_id'] as int?,
      categoryName: json['category_name'] as String?,
      domainId: json['domain_id'] as int?,
      consentStatus: json['consent_status'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cookie_id': cookieId,
      'cookie_key': cookieKey,
      'vendor_name': vendorName,
      'cookie_type': cookieType,
      'description': description,
      'expiration': expiration,
      'consent': consent,
      'consent_record_id': consentRecordId,
      if (serviceId != null) 'service_id': serviceId,
      if (categoryId != null) 'category_id': categoryId,
      if (categoryName != null) 'category_name': categoryName,
      if (domainId != null) 'domain_id': domainId,
      if (consentStatus != null) 'consent_status': consentStatus,
    };
  }

  CookieProperties copyWith({
    int? cookieId,
    String? cookieKey,
    String? vendorName,
    String? cookieType,
    String? description,
    String? expiration,
    bool? consent,
    int? consentRecordId,
    int? serviceId,
    int? categoryId,
    String? categoryName,
    int? domainId,
    bool? consentStatus,
  }) {
    return CookieProperties(
      cookieId: cookieId ?? this.cookieId,
      cookieKey: cookieKey ?? this.cookieKey,
      vendorName: vendorName ?? this.vendorName,
      cookieType: cookieType ?? this.cookieType,
      description: description ?? this.description,
      expiration: expiration ?? this.expiration,
      consent: consent ?? this.consent,
      consentRecordId: consentRecordId ?? this.consentRecordId,
      serviceId: serviceId ?? this.serviceId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      domainId: domainId ?? this.domainId,
      consentStatus: consentStatus ?? this.consentStatus,
    );
  }
}
