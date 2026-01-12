/// Represents a single cookie consent record mapping category, cookie, and consent status.
///
/// Mirrors the TypeScript `CookieConsent` interface from cookie-banner.tsx.
class CookieConsent {
  final int categoryId;
  final int consentRecordId;
  final bool consentStatus;
  final int cookieId;
  final int? serviceId;

  const CookieConsent({
    required this.categoryId,
    required this.consentRecordId,
    required this.consentStatus,
    required this.cookieId,
    this.serviceId,
  });

  factory CookieConsent.fromJson(Map<String, dynamic> json) {
    return CookieConsent(
      categoryId: json['category_id'] as int,
      consentRecordId: json['consent_record_id'] as int,
      consentStatus: json['consent_status'] as bool,
      cookieId: json['cookie_id'] as int,
      serviceId: json['service_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'consent_record_id': consentRecordId,
      'consent_status': consentStatus,
      'cookie_id': cookieId,
      if (serviceId != null) 'service_id': serviceId,
    };
  }

  CookieConsent copyWith({
    int? categoryId,
    int? consentRecordId,
    bool? consentStatus,
    int? cookieId,
    int? serviceId,
  }) {
    return CookieConsent(
      categoryId: categoryId ?? this.categoryId,
      consentRecordId: consentRecordId ?? this.consentRecordId,
      consentStatus: consentStatus ?? this.consentStatus,
      cookieId: cookieId ?? this.cookieId,
      serviceId: serviceId ?? this.serviceId,
    );
  }
}
