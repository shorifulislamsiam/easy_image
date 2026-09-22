import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_image/smart_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Cache At-Rest Encryption', () {
    test('stores and retrieves encrypted entries seamlessly', () async {
      final cacheService = SmartImageCacheService(
        encryptCache: true,
        encryptionKey: 'my_secret_user_key',
      );

      const key = 'https://example.com/sensitive_id.png';
      final originalBytes = Uint8List.fromList([10, 20, 30, 40, 50, 60]);

      await cacheService.put(
        key: key,
        bytes: originalBytes,
        contentType: 'image/png',
      );

      final result = await cacheService.get(key);
      expect(result, isNotNull);
      expect(result!.bytes, originalBytes);
    });
  });
}
