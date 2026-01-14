import '../models/models.dart';

/// Consent helper utilities mirroring React implementation logic.
class ConsentHelpers {
  /// Get consent status for a specific category slug.
  ///
  /// Mirrors the React `getConsentBySlug` function.
  static bool getConsentBySlug({
    required Map<int, bool> consentsByCategory,
    required String slug,
    required UserDataProperties? data,
  }) {
    if (data?.categoryConsentRecord.isEmpty ?? true) {
      return slug == 'necessary';
    }

    final records = data!.categoryConsentRecord;

    // Helper to read consent for a category
    bool readConsent(CategoryConsentRecordProperties? rec) {
      if (rec == null) return false;
      if (rec.categoryNecessary) return true;
      return consentsByCategory[rec.categoryId] ?? false;
    }

    // Necessary is always true
    if (slug == 'necessary') {
      final necessary = records.where((r) => r.categoryNecessary).firstOrNull;
      return readConsent(necessary);
    }

    // Marketing: prefer explicit flag, then name patterns
    if (slug == 'marketing') {
      final marketing = records.where((r) => r.isMarketing).firstOrNull ??
          records
              .where((r) =>
                  r.categoryName.toLowerCase().contains('marketing') ||
                  r.categoryName.toLowerCase().contains('advertising'))
              .firstOrNull;
      return readConsent(marketing);
    }

    // Functional / Preferences
    if (slug == 'functional') {
      final functional = records
          .where((r) =>
              r.categoryName.toLowerCase().contains('functional') ||
              r.categoryName.toLowerCase().contains('preference'))
          .firstOrNull;
      return readConsent(functional);
    }

    // Performance / Measurement
    if (slug == 'performance') {
      final performance = records
          .where((r) =>
              r.categoryName.toLowerCase().contains('performance') ||
              r.categoryName.toLowerCase().contains('measurement'))
          .firstOrNull;
      return readConsent(performance);
    }

    // Analytics / Statistics
    if (slug == 'analytics') {
      final analytics = records
          .where((r) =>
              r.categoryName.toLowerCase().contains('analytic') ||
              r.categoryName.toLowerCase().contains('statistic'))
          .firstOrNull;
      return readConsent(analytics);
    }

    return false;
  }

  /// Build effective consent map applying DNT and necessary category rules.
  ///
  /// Mirrors the React `buildEffectiveConsent` function.
  static Map<int, bool> buildEffectiveConsent({
    required Map<int, bool> rawConsent,
    required UserDataProperties? data,
    required bool dntEnabled,
  }) {
    final effective = Map<int, bool>.from(rawConsent);

    if (data?.categoryConsentRecord.isEmpty ?? true) {
      return effective;
    }

    final records = data!.categoryConsentRecord;

    // Force necessary categories to true
    for (final record in records) {
      if (record.categoryNecessary) {
        effective[record.categoryId] = true;
      }
    }

    // If DNT is enabled, force marketing to false
    if (dntEnabled) {
      for (final record in records) {
        if (record.isMarketing ||
            record.categoryName.toLowerCase().contains('marketing')) {
          effective[record.categoryId] = false;
        }
      }
    }

    return effective;
  }

  /// Build a consent snapshot from current state.
  static ConsentSnapshot buildConsentSnapshot({
    required String subjectIdentity,
    required int domainId,
    required String domainUrl,
    required UserDataProperties? userData,
    required Map<int, bool> consentsByCategory,
  }) {
    // Collect consented and available cookie IDs
    final consentedCookies = <String>[];
    final availableCookies = <String>[];

    if (userData != null) {
      for (final category in userData.categoryConsentRecord) {
        final allCookies = category.getAllCookies();
        final categoryConsent = consentsByCategory[category.categoryId] ?? false;

        for (final cookie in allCookies) {
          final cookieIdStr = cookie.cookieId.toString();
          availableCookies.add(cookieIdStr);

          if (category.categoryNecessary || categoryConsent) {
            consentedCookies.add(cookieIdStr);
          }
        }
      }
    }

    // Build category choices
    final categoryChoices = CategoryChoices(
      necessary: true,
      analytics: getConsentBySlug(
        consentsByCategory: consentsByCategory,
        slug: 'analytics',
        data: userData,
      ),
      marketing: getConsentBySlug(
        consentsByCategory: consentsByCategory,
        slug: 'marketing',
        data: userData,
      ),
      functional: getConsentBySlug(
        consentsByCategory: consentsByCategory,
        slug: 'functional',
        data: userData,
      ),
      performance: getConsentBySlug(
        consentsByCategory: consentsByCategory,
        slug: 'performance',
        data: userData,
      ),
    );

    return ConsentSnapshot(
      subjectIdentity: subjectIdentity,
      domainId: domainId,
      domainUrl: domainUrl,
      consentVersion: userData?.consentVersion ?? 1,
      consentedCookies: consentedCookies,
      availableCookies: availableCookies,
      categoryChoices: categoryChoices,
    );
  }

  /// Check if new cookies or version changes require re-consent.
  static bool needsReconsent({
    required ConsentSnapshot? storedSnapshot,
    required UserDataProperties? currentData,
  }) {
    // Always show the banner on app restart
    return true;
    
    // Previous logic (commented out for reference):
    // if (storedSnapshot == null) {
    //   return true; // No consent stored
    // }
    //
    // if (currentData == null) {
    //   return false; // Can't determine without data
    // }
    //
    // // Check version change
    // final currentVersion = currentData.consentVersion ?? 1;
    // if (storedSnapshot.hasVersionChanged(currentVersion)) {
    //   return true;
    // }
    //
    // // Check for new cookies
    // final currentCookies = <String>[];
    // for (final category in currentData.categoryConsentRecord) {
    //   for (final cookie in category.getAllCookies()) {
    //     currentCookies.add(cookie.cookieId.toString());
    //   }
    // }
    //
    // if (storedSnapshot.hasNewCookies(currentCookies)) {
    //   return true;
    // }
    //
    // return false;
  }

  /// Initialize category consent from stored snapshot and API data.
  static Map<int, bool> initializeCategoryConsent({
    required ConsentSnapshot? storedSnapshot,
    required UserDataProperties? userData,
  }) {
    final consent = <int, bool>{};

    if (userData == null) {
      return consent;
    }

    // If no stored consent, use default opt-in from categories
    if (storedSnapshot == null) {
      for (final category in userData.categoryConsentRecord) {
        if (category.categoryNecessary) {
          consent[category.categoryId] = true;
        } else {
          consent[category.categoryId] = !category.categoryDefaultOptOut;
        }
      }
      return consent;
    }

    // Use stored consent
    final choices = storedSnapshot.categoryChoices;
    for (final category in userData.categoryConsentRecord) {
      if (category.categoryNecessary) {
        consent[category.categoryId] = true;
      } else if (category.isMarketing ||
          category.categoryName.toLowerCase().contains('marketing')) {
        consent[category.categoryId] = choices.marketing;
      } else if (category.categoryName.toLowerCase().contains('analytic') ||
          category.categoryName.toLowerCase().contains('statistic')) {
        consent[category.categoryId] = choices.analytics;
      } else if (category.categoryName.toLowerCase().contains('functional') ||
          category.categoryName.toLowerCase().contains('preference')) {
        consent[category.categoryId] = choices.functional;
      } else if (category.categoryName.toLowerCase().contains('performance') ||
          category.categoryName.toLowerCase().contains('measurement')) {
        consent[category.categoryId] = choices.performance;
      } else {
        // Default to false for unknown categories
        consent[category.categoryId] = false;
      }
    }

    return consent;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
