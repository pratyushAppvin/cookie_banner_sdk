import '../models/consent_snapshot.dart';

/// Utility class for evaluating consent status.
///
/// Provides convenient methods for host apps to check whether
/// specific categories of tracking are allowed based on the stored
/// consent snapshot.
///
/// Example usage:
/// ```dart
/// final snapshot = await consentStorage.loadConsent();
/// if (ConsentEvaluator.isAnalyticsAllowed(snapshot)) {
///   // Initialize Firebase Analytics
///   await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
/// }
/// ```
class ConsentEvaluator {
  /// Check if analytics tracking is allowed.
  ///
  /// Returns true if the user has consented to analytics cookies.
  /// Returns false if no consent has been given or analytics is denied.
  static bool isAnalyticsAllowed(ConsentSnapshot? snapshot) {
    if (snapshot == null) return false;
    return snapshot.categoryChoices.analytics;
  }

  /// Check if marketing/advertising tracking is allowed.
  ///
  /// Returns true if the user has consented to marketing cookies.
  /// Returns false if no consent has been given or marketing is denied.
  static bool isMarketingAllowed(ConsentSnapshot? snapshot) {
    if (snapshot == null) return false;
    return snapshot.categoryChoices.marketing;
  }

  /// Check if functional cookies are allowed.
  ///
  /// Returns true if the user has consented to functional cookies.
  /// Returns false if no consent has been given or functional is denied.
  static bool isFunctionalAllowed(ConsentSnapshot? snapshot) {
    if (snapshot == null) return false;
    return snapshot.categoryChoices.functional;
  }

  /// Check if performance tracking is allowed.
  ///
  /// Returns true if the user has consented to performance cookies.
  /// Returns false if no consent has been given or performance is denied.
  static bool isPerformanceAllowed(ConsentSnapshot? snapshot) {
    if (snapshot == null) return false;
    return snapshot.categoryChoices.performance;
  }

  /// Check if necessary cookies are allowed.
  ///
  /// Always returns true if a snapshot exists, as necessary cookies are always enabled.
  static bool isNecessaryAllowed(ConsentSnapshot? snapshot) {
    if (snapshot == null) return false;
    return snapshot.categoryChoices.necessary;
  }

  /// Check if a specific category is allowed by its slug.
  ///
  /// [snapshot] - The stored consent snapshot
  /// [slug] - The category slug ('necessary', 'analytics', 'marketing', 'functional', 'performance')
  ///
  /// Returns true if consent was given for this category slug.
  /// Returns false if the category is not found or consent is denied.
  static bool isCategoryAllowedBySlug(ConsentSnapshot? snapshot, String slug) {
    if (snapshot == null) return false;
    
    switch (slug.toLowerCase()) {
      case 'necessary':
        return snapshot.categoryChoices.necessary;
      case 'analytics':
        return snapshot.categoryChoices.analytics;
      case 'marketing':
        return snapshot.categoryChoices.marketing;
      case 'functional':
        return snapshot.categoryChoices.functional;
      case 'performance':
        return snapshot.categoryChoices.performance;
      default:
        return false;
    }
  }

  /// Check if a specific cookie is allowed by its ID (name).
  ///
  /// [snapshot] - The stored consent snapshot
  /// [cookieId] - The string identifier of the cookie to check
  ///
  /// Returns true if this specific cookie has been consented to.
  static bool isCookieAllowed(ConsentSnapshot? snapshot, String cookieId) {
    if (snapshot == null) return false;
    return snapshot.consentedCookies.contains(cookieId);
  }

  /// Get all category slugs that have been consented to.
  ///
  /// Returns a list of category slugs where consent is true.
  static List<String> getAllowedCategorySlugs(ConsentSnapshot? snapshot) {
    if (snapshot == null) return [];
    
    final List<String> allowed = [];
    final choices = snapshot.categoryChoices;
    
    if (choices.necessary) allowed.add('necessary');
    if (choices.analytics) allowed.add('analytics');
    if (choices.marketing) allowed.add('marketing');
    if (choices.functional) allowed.add('functional');
    if (choices.performance) allowed.add('performance');
    
    return allowed;
  }

  /// Get all cookie IDs that have been consented to.
  ///
  /// Returns the list of cookie identifiers the user has explicitly allowed.
  static List<String> getAllowedCookieIds(ConsentSnapshot? snapshot) {
    if (snapshot == null) return [];
    return List.from(snapshot.consentedCookies);
  }

  /// Check if consent has been given (banner has been interacted with).
  ///
  /// Returns true if a consent snapshot exists, regardless of specific choices.
  static bool hasConsent(ConsentSnapshot? snapshot) {
    return snapshot != null;
  }

  /// Check if all categories have been accepted.
  ///
  /// Returns true if consent exists and all 5 standard categories are set to true.
  static bool hasAcceptedAll(ConsentSnapshot? snapshot) {
    if (snapshot == null) return false;
    
    final choices = snapshot.categoryChoices;
    return choices.necessary &&
           choices.analytics &&
           choices.marketing &&
           choices.functional &&
           choices.performance;
  }

  /// Check if only necessary categories are accepted (equivalent to reject all).
  ///
  /// Returns true if necessary is accepted but all optional categories are denied.
  static bool hasRejectedAll(ConsentSnapshot? snapshot) {
    if (snapshot == null) return false;
    
    final choices = snapshot.categoryChoices;
    return choices.necessary &&
           !choices.analytics &&
           !choices.marketing &&
           !choices.functional &&
           !choices.performance;
  }
}
