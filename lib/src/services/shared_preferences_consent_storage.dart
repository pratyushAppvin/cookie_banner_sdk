import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/consent_snapshot.dart';
import 'consent_storage.dart';

/// SharedPreferences-based implementation of ConsentStorage.
///
/// Stores consent data in mobile-friendly persistent storage.
/// Uses the same key ('gotrust_pb_ydt') as the web cookie for consistency.
class SharedPreferencesConsentStorage implements ConsentStorage {
  static const String _consentKey = 'gotrust_pb_ydt';

  @override
  Future<ConsentSnapshot?> loadConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_consentKey);

      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return ConsentSnapshot.fromJson(json);
    } catch (e) {
      // Log error but don't crash - treat as no consent
      print('Error loading consent: $e');
      return null;
    }
  }

  @override
  Future<void> saveConsent(ConsentSnapshot snapshot) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(snapshot.toJson());
      await prefs.setString(_consentKey, jsonString);
    } catch (e) {
      print('Error saving consent: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_consentKey);
    } catch (e) {
      print('Error clearing consent: $e');
      rethrow;
    }
  }

  @override
  Future<bool> hasConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_consentKey);
    } catch (e) {
      print('Error checking consent: $e');
      return false;
    }
  }
}
