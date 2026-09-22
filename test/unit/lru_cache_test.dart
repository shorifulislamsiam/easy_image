import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_image/easy_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EasyImageCacheService LRU Eviction', () {
    test('evicts oldest accessed items when memory quota is exceeded',
        () async {
      // Create cache service with a tight 100-byte memory limit
      final lruCache = EasyImageCacheService(
        maxMemoryCacheBytes: 100,
        maxDiskCacheBytes: 500,
      );

      final bytesA = Uint8List(40); // 40 bytes
      final bytesB = Uint8List(40); // 40 bytes
      final bytesC =
          Uint8List(40); // 40 bytes -> total would be 120 bytes > 100 limit

      await lruCache.put(key: 'item_a', bytes: bytesA);
      await lruCache.put(key: 'item_b', bytes: bytesB);

      expect(lruCache.memoryByteCount, 80);

      // Access item_a to make item_b the least recently used
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await lruCache.get('item_a');

      // Now insert item_c -> item_b should be evicted
      await lruCache.put(key: 'item_c', bytes: bytesC);

      // item_a and item_c should exist, item_b evicted from memory
      final resA = await lruCache.get('item_a');
      final resB = await lruCache.get('item_b');
      final resC = await lruCache.get('item_c');

      expect(resA, isNotNull);
      expect(resB, isNull);
      expect(resC, isNotNull);
      expect(lruCache.memoryByteCount, lessThanOrEqualTo(100));
    });

    test('updates memory byte size on key overwrite', () async {
      final lruCache = EasyImageCacheService(maxMemoryCacheBytes: 200);

      await lruCache.put(key: 'key1', bytes: Uint8List(50));
      expect(lruCache.memoryByteCount, 50);

      // Overwrite key1 with 70 bytes
      await lruCache.put(key: 'key1', bytes: Uint8List(70));
      expect(lruCache.memoryByteCount, 70);

      await lruCache.clearImage('key1');
      expect(lruCache.memoryByteCount, 0);
    });
  });
}
