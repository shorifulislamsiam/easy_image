import 'package:flutter_test/flutter_test.dart';
import 'package:easy_image/smart_image.dart';

void main() {
  group('ImageCacheKey Generation', () {
    test('produces distinct cache keys for different authorization headers',
        () {
      const url = 'https://api.example.com/user/avatar.png';

      final keyUser1 = ImageCacheKey.generate(
        url: url,
        headers: {'Authorization': 'Bearer token_user_1'},
      );

      final keyUser2 = ImageCacheKey.generate(
        url: url,
        headers: {'Authorization': 'Bearer token_user_2'},
      );

      final keyNoAuth = ImageCacheKey.generate(
        url: url,
        headers: null,
      );

      expect(keyUser1, isNot(equals(keyUser2)));
      expect(keyUser1, isNot(equals(keyNoAuth)));
      expect(keyNoAuth, url);
    });

    test('is deterministic regardless of header insertion order', () {
      const url = 'https://api.example.com/data.png';

      final key1 = ImageCacheKey.generate(
        url: url,
        headers: {
          'X-Api-Key': '12345',
          'Authorization': 'Bearer xyz',
        },
      );

      final key2 = ImageCacheKey.generate(
        url: url,
        headers: {
          'Authorization': 'Bearer xyz',
          'X-Api-Key': '12345',
        },
      );

      expect(key1, key2);
    });
  });
}
