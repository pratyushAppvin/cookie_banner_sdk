import 'package:flutter_test/flutter_test.dart';
import 'package:cookie_banner_sdk/src/utils/uuid_helper.dart';

void main() {
  group('UUID Helper Tests', () {
    test('generateV4 creates valid UUID v4 format', () {
      final uuid = UuidHelper.generateV4();
      
      // UUID v4 format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      );
      
      expect(uuid, matches(uuidRegex));
      expect(uuid.length, 36);
      expect(uuid[14], '4'); // Version nibble
    });

    test('generateV4 creates unique UUIDs', () {
      final uuid1 = UuidHelper.generateV4();
      final uuid2 = UuidHelper.generateV4();
      final uuid3 = UuidHelper.generateV4();
      
      expect(uuid1, isNot(equals(uuid2)));
      expect(uuid2, isNot(equals(uuid3)));
      expect(uuid1, isNot(equals(uuid3)));
    });
  });
}

