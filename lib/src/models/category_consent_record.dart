import 'cookie_properties.dart';
import 'service_properties.dart';

/// Category consent record with services and independent cookies.
///
/// Mirrors TypeScript `CategoryConsentRecordProperties` interface.
class CategoryConsentRecordProperties {
  final List<ServiceProperties> services;
  final List<CookieProperties> independentCookies;
  final int categoryId;
  final String categoryName;
  final String categoryDescription;
  final bool categoryNecessary;
  final bool isMarketing;
  final bool categoryUnclassified;
  final bool categoryDefaultOptOut;
  final int domainId;
  final String subjectIdentity;

  const CategoryConsentRecordProperties({
    required this.services,
    required this.independentCookies,
    required this.categoryId,
    required this.categoryName,
    required this.categoryDescription,
    required this.categoryNecessary,
    required this.isMarketing,
    required this.categoryUnclassified,
    required this.categoryDefaultOptOut,
    required this.domainId,
    required this.subjectIdentity,
  });

  factory CategoryConsentRecordProperties.fromJson(Map<String, dynamic> json) {
    return CategoryConsentRecordProperties(
      services: (json['services'] as List<dynamic>?)
              ?.map((e) =>
                  ServiceProperties.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      independentCookies: (json['independent_cookies'] as List<dynamic>?)
              ?.map((e) =>
                  CookieProperties.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      categoryId: json['category_id'] as int,
      categoryName: json['category_name'] as String? ?? '',
      categoryDescription: json['category_description'] as String? ?? '',
      categoryNecessary: json['category_necessary'] as bool? ?? false,
      isMarketing: json['is_marketing'] as bool? ?? false,
      categoryUnclassified: json['category_unclassified'] as bool? ?? false,
      categoryDefaultOptOut:
          json['catefory_default_opt_out'] as bool? ?? false, // Note: typo in original API
      domainId: json['domain_id'] as int? ?? 0,
      subjectIdentity: json['subject_identity'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'services': services.map((s) => s.toJson()).toList(),
      'independent_cookies': independentCookies.map((c) => c.toJson()).toList(),
      'category_id': categoryId,
      'category_name': categoryName,
      'category_description': categoryDescription,
      'category_necessary': categoryNecessary,
      'is_marketing': isMarketing,
      'category_unclassified': categoryUnclassified,
      'catefory_default_opt_out': categoryDefaultOptOut, // Keep typo for API compatibility
      'domain_id': domainId,
      'subject_identity': subjectIdentity,
    };
  }

  /// Get all cookies from both services and independent cookies list
  List<CookieProperties> getAllCookies() {
    final allCookies = <CookieProperties>[];
    for (final service in services) {
      allCookies.addAll(service.cookies);
    }
    allCookies.addAll(independentCookies);
    return allCookies;
  }

  CategoryConsentRecordProperties copyWith({
    List<ServiceProperties>? services,
    List<CookieProperties>? independentCookies,
    int? categoryId,
    String? categoryName,
    String? categoryDescription,
    bool? categoryNecessary,
    bool? isMarketing,
    bool? categoryUnclassified,
    bool? categoryDefaultOptOut,
    int? domainId,
    String? subjectIdentity,
  }) {
    return CategoryConsentRecordProperties(
      services: services ?? this.services,
      independentCookies: independentCookies ?? this.independentCookies,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryDescription: categoryDescription ?? this.categoryDescription,
      categoryNecessary: categoryNecessary ?? this.categoryNecessary,
      isMarketing: isMarketing ?? this.isMarketing,
      categoryUnclassified: categoryUnclassified ?? this.categoryUnclassified,
      categoryDefaultOptOut: categoryDefaultOptOut ?? this.categoryDefaultOptOut,
      domainId: domainId ?? this.domainId,
      subjectIdentity: subjectIdentity ?? this.subjectIdentity,
    );
  }
}
