import 'dart:math';

/// UUID generation utilities mirroring the React `generateUUID` function.
class UuidHelper {
  static final Random _random = Random.secure();

  /// Generate a UUID v4 string.
  ///
  /// Mirrors the JavaScript implementation from cookie-banner.tsx.
  /// Uses secure random number generation and RFC-4122 v4 formatting.
  static String generateV4() {
    // Generate 16 random bytes
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));

    // RFC-4122 version 4 formatting
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 10

    // Convert to hex string with dashes
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');

    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  /// Validate if a string is a valid UUID format.
  static bool isValid(String uuid) {
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegex.hasMatch(uuid);
  }
}
