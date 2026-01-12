/// Snapshot of user consent data, matching the structure of `gotrust_pb_ydt` cookie.
///
/// This model represents what is stored in SharedPreferences on mobile
/// or as a browser cookie on web. It maintains compatibility with the
/// React implementation's consent cookie format.
class ConsentSnapshot {
  final String subjectIdentity;
  final int domainId;
  final String domainUrl;
  final int consentVersion;
  final List<String> consentedCookies;
  final List<String> availableCookies;
  final CategoryChoices categoryChoices;

  const ConsentSnapshot({
    required this.subjectIdentity,
    required this.domainId,
    required this.domainUrl,
    required this.consentVersion,
    required this.consentedCookies,
    required this.availableCookies,
    required this.categoryChoices,
  });

  factory ConsentSnapshot.fromJson(Map<String, dynamic> json) {
    return ConsentSnapshot(
      subjectIdentity: json['subject_identity'] as String? ?? '',
      domainId: json['domain_id'] as int? ?? 0,
      domainUrl: json['domain_url'] as String? ?? '',
      consentVersion: json['consent_version'] as int? ?? 1,
      consentedCookies: (json['consented_cookies'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      availableCookies: (json['available_cookies'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      categoryChoices: CategoryChoices.fromJson(
          json['category_choices'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject_identity': subjectIdentity,
      'domain_id': domainId,
      'domain_url': domainUrl,
      'consent_version': consentVersion,
      'consented_cookies': consentedCookies,
      'available_cookies': availableCookies,
      'category_choices': categoryChoices.toJson(),
    };
  }

  ConsentSnapshot copyWith({
    String? subjectIdentity,
    int? domainId,
    String? domainUrl,
    int? consentVersion,
    List<String>? consentedCookies,
    List<String>? availableCookies,
    CategoryChoices? categoryChoices,
  }) {
    return ConsentSnapshot(
      subjectIdentity: subjectIdentity ?? this.subjectIdentity,
      domainId: domainId ?? this.domainId,
      domainUrl: domainUrl ?? this.domainUrl,
      consentVersion: consentVersion ?? this.consentVersion,
      consentedCookies: consentedCookies ?? this.consentedCookies,
      availableCookies: availableCookies ?? this.availableCookies,
      categoryChoices: categoryChoices ?? this.categoryChoices,
    );
  }

  /// Check if there are new cookies compared to this snapshot
  bool hasNewCookies(List<String> currentCookies) {
    final newCookies = currentCookies
        .where((cookie) => !availableCookies.contains(cookie))
        .toList();
    return newCookies.isNotEmpty;
  }

  /// Check if consent version has changed
  bool hasVersionChanged(int currentVersion) {
    return currentVersion > consentVersion;
  }
}

/// Category-level consent choices (5 standard categories).
class CategoryChoices {
  final bool necessary;
  final bool analytics;
  final bool marketing;
  final bool functional;
  final bool performance;

  const CategoryChoices({
    required this.necessary,
    required this.analytics,
    required this.marketing,
    required this.functional,
    required this.performance,
  });

  factory CategoryChoices.fromJson(Map<String, dynamic> json) {
    return CategoryChoices(
      necessary: json['necessary'] as bool? ?? true, // Always true
      analytics: json['analytics'] as bool? ?? false,
      marketing: json['marketing'] as bool? ?? false,
      functional: json['functional'] as bool? ?? false,
      performance: json['performance'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'necessary': necessary,
      'analytics': analytics,
      'marketing': marketing,
      'functional': functional,
      'performance': performance,
    };
  }

  /// Create category choices from a consent map (category ID -> bool)
  factory CategoryChoices.fromConsentMap(
    Map<int, bool> consentMap,
    List<dynamic>? categoryRecords,
  ) {
    // Default values
    bool analytics = false;
    bool marketing = false;
    bool functional = false;
    bool performance = false;

    // Map category IDs to their types based on names or flags
    if (categoryRecords != null) {
      for (final record in categoryRecords) {
        if (record is Map<String, dynamic>) {
          final categoryId = record['category_id'] as int?;
          final categoryName =
              (record['category_name'] as String?)?.toLowerCase() ?? '';
          final isMarketingFlag = record['is_marketing'] as bool? ?? false;

          if (categoryId != null && consentMap.containsKey(categoryId)) {
            final consent = consentMap[categoryId] ?? false;

            if (isMarketingFlag ||
                categoryName.contains('marketing') ||
                categoryName.contains('advertising')) {
              marketing = marketing || consent;
            } else if (categoryName.contains('analytic') ||
                categoryName.contains('statistic')) {
              analytics = analytics || consent;
            } else if (categoryName.contains('functional') ||
                categoryName.contains('preference')) {
              functional = functional || consent;
            } else if (categoryName.contains('performance') ||
                categoryName.contains('measurement')) {
              performance = performance || consent;
            }
          }
        }
      }
    }

    return CategoryChoices(
      necessary: true, // Always true
      analytics: analytics,
      marketing: marketing,
      functional: functional,
      performance: performance,
    );
  }

  CategoryChoices copyWith({
    bool? necessary,
    bool? analytics,
    bool? marketing,
    bool? functional,
    bool? performance,
  }) {
    return CategoryChoices(
      necessary: necessary ?? this.necessary,
      analytics: analytics ?? this.analytics,
      marketing: marketing ?? this.marketing,
      functional: functional ?? this.functional,
      performance: performance ?? this.performance,
    );
  }
}
