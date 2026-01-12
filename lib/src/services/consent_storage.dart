import '../models/consent_snapshot.dart';

/// Abstract interface for consent storage.
///
/// Provides methods to load, save, and clear consent data.
/// Implementations can use SharedPreferences (mobile), browser cookies (web),
/// or other storage mechanisms.
abstract class ConsentStorage {
  /// Load the consent snapshot from storage.
  /// Returns null if no consent has been stored yet.
  Future<ConsentSnapshot?> loadConsent();

  /// Save the consent snapshot to storage.
  Future<void> saveConsent(ConsentSnapshot snapshot);

  /// Clear all stored consent data.
  Future<void> clearConsent();

  /// Check if consent exists in storage.
  Future<bool> hasConsent();
}
