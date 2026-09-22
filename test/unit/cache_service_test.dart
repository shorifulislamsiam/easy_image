import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_image/src/enums/easy_image_cache_source.dart';
import 'package:easy_image/src/services/image_cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EasyImageCacheService', () {
    late EasyImageCacheService cacheService;

    setUp(() {
      cacheService = EasyImageCacheService.instance;
    });

    tearDown(() async {
      await cacheService.clearAll();
    });

    test('stores and retrieves items from in-memory cache', () async {
      final key = 'https://example.com/test.png';
      final bytes = Uint8List.fromList([10, 20, 30, 40]);

      await cacheService.put(
        key: key,
        bytes: bytes,
        contentType: 'image/png',
      );

      final result = await cacheService.get(key);
      expect(result, isNotNull);
      expect(result!.bytes, bytes);
      expect(result.contentType, 'image/png');
      expect(result.source, EasyImageCacheSource.memory);
      expect(result.isStale, isFalse);
    });

    test('expires in-memory items after TTL duration (marks isStale true)',
        () async {
      final key = 'https://example.com/short_lived.png';
      final bytes = Uint8List.fromList([1, 2, 3]);

      await cacheService.put(
        key: key,
        bytes: bytes,
        duration: const Duration(milliseconds: 50),
      );

      // Verify immediate hit is fresh
      final hit = await cacheService.get(key);
      expect(hit, isNotNull);
      expect(hit!.isStale, isFalse);

      // Wait for expiration
      await Future<void>.delayed(const Duration(milliseconds: 60));

      final expired = await cacheService.get(key);
      expect(expired, isNotNull);
      expect(expired!.isStale, isTrue);
    });

    test('clears individual image from cache', () async {
      final key1 = 'https://example.com/item1.png';
      final key2 = 'https://example.com/item2.png';

      await cacheService.put(key: key1, bytes: Uint8List.fromList([1]));
      await cacheService.put(key: key2, bytes: Uint8List.fromList([2]));

      await cacheService.clearImage(key1);

      expect(await cacheService.get(key1), isNull);
      expect(await cacheService.get(key2), isNotNull);
    });

    test('clears all entries with clearAll and clearCacheOnLogout', () async {
      final key = 'https://example.com/user_data.png';
      await cacheService.put(key: key, bytes: Uint8List.fromList([99]));

      await cacheService.clearCacheOnLogout();
      expect(await cacheService.get(key), isNull);
    });
  });
}
