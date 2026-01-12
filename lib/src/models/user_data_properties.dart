import 'banner_design.dart';
import 'category_consent_record.dart';

/// Main user data properties containing banner configuration and consent records.
///
/// Mirrors TypeScript `UserDataProperties` interface.
class UserDataProperties {
  final String languageCode;
  final String bannerCode;
  final BannerConfigurations bannerConfiguration;
  final String bannerTitle;
  final String bannerDescription;
  final List<CategoryConsentRecordProperties> categoryConsentRecord;
  final String compliancePolicyLink;
  final int? consentVersion;

  const UserDataProperties({
    required this.languageCode,
    required this.bannerCode,
    required this.bannerConfiguration,
    required this.bannerTitle,
    required this.bannerDescription,
    required this.categoryConsentRecord,
    required this.compliancePolicyLink,
    this.consentVersion,
  });

  factory UserDataProperties.fromJson(Map<String, dynamic> json) {
    return UserDataProperties(
      languageCode: json['language_code'] as String? ?? 'en',
      bannerCode: json['banner_code'] as String? ?? '',
      bannerConfiguration: BannerConfigurations.fromJson(
          json['banner_configuration'] as Map<String, dynamic>? ?? {}),
      bannerTitle: json['banner_title'] as String? ?? '',
      bannerDescription: json['banner_description'] as String? ?? '',
      categoryConsentRecord:
          (json['category_consent_record'] as List<dynamic>?)
                  ?.map((e) => CategoryConsentRecordProperties.fromJson(
                      e as Map<String, dynamic>))
                  .toList() ??
              [],
      compliancePolicyLink: json['compliance_policy_link'] as String? ?? '',
      consentVersion: json['consent_version'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language_code': languageCode,
      'banner_code': bannerCode,
      'banner_configuration': bannerConfiguration.toJson(),
      'banner_title': bannerTitle,
      'banner_description': bannerDescription,
      'category_consent_record':
          categoryConsentRecord.map((c) => c.toJson()).toList(),
      'compliance_policy_link': compliancePolicyLink,
      if (consentVersion != null) 'consent_version': consentVersion,
    };
  }

  UserDataProperties copyWith({
    String? languageCode,
    String? bannerCode,
    BannerConfigurations? bannerConfiguration,
    String? bannerTitle,
    String? bannerDescription,
    List<CategoryConsentRecordProperties>? categoryConsentRecord,
    String? compliancePolicyLink,
    int? consentVersion,
  }) {
    return UserDataProperties(
      languageCode: languageCode ?? this.languageCode,
      bannerCode: bannerCode ?? this.bannerCode,
      bannerConfiguration: bannerConfiguration ?? this.bannerConfiguration,
      bannerTitle: bannerTitle ?? this.bannerTitle,
      bannerDescription: bannerDescription ?? this.bannerDescription,
      categoryConsentRecord:
          categoryConsentRecord ?? this.categoryConsentRecord,
      compliancePolicyLink: compliancePolicyLink ?? this.compliancePolicyLink,
      consentVersion: consentVersion ?? this.consentVersion,
    );
  }
}
