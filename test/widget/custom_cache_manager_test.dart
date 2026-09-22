import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_image/smart_image.dart';

final Uint8List kTestPngCustom = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

class _MockCustomCacheManager implements SmartImageCacheManager {
  final Map<String, CachedImageResult> storage = {};
  int getCallCount = 0;
  int putCallCount = 0;

  @override
  Future<CachedImageResult?> get(String key) async {
    getCallCount++;
    return storage[key];
  }

  @override
  Future<void> put({
    required String key,
    required Uint8List bytes,
    String? contentType,
    Duration duration = const Duration(days: 7),
    String? eTag,
    String? lastModified,
    String? cacheControl,
    bool noStore = false,
  }) async {
    putCallCount++;
    storage[key] = CachedImageResult(
      bytes: bytes,
      contentType: contentType ?? 'image/png',
      source: SmartImageCacheSource.memory,
      eTag: eTag,
      lastModified: lastModified,
    );
  }

  @override
  Future<void> clearAll() async => storage.clear();

  @override
  Future<void> clearCacheOnLogout() async => storage.clear();

  @override
  Future<void> clearImage(String key) async => storage.remove(key);

  @override
  Future<int> getDiskByteCount() async => 0;

  @override
  int get memoryByteCount => storage.length * 100;
}

void main() {
  group('Custom Cache Manager Injection', () {
    testWidgets('uses injected custom cache manager', (tester) async {
      final customManager = _MockCustomCacheManager();

      // Pre-seed mock manager
      const testUrl = 'https://example.com/custom_cached.png';
      await customManager.put(
        key: testUrl,
        bytes: kTestPngCustom,
        contentType: 'image/png',
      );

      SmartImageCacheSource? hitSource;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartImage(
              url: testUrl,
              config: SmartImageConfig(
                cacheManager: customManager,
                onCacheHit: (source) {
                  hitSource = source;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(customManager.getCallCount, greaterThanOrEqualTo(1));
      expect(hitSource, SmartImageCacheSource.memory);
      expect(find.byType(Image), findsOneWidget);
    });
  });
}
