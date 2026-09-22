import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:easy_image/smart_image.dart';
import 'package:easy_image/src/services/image_downloader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HTTP Revalidation & Headers', () {
    test('ImageDownloader parses max-age and attaches ETag revalidation',
        () async {
      final mockClient = MockClient((request) async {
        if (request.headers['if-none-match'] == '"12345"') {
          return http.Response('', 304, headers: {
            'etag': '"12345"',
            'cache-control': 'max-age=3600',
          });
        }

        return http.Response(
          'fresh_bytes',
          200,
          headers: {
            'content-type': 'image/png',
            'etag': '"12345"',
            'last-modified': 'Wed, 21 Oct 2025 07:28:00 GMT',
            'cache-control': 'public, max-age=86400',
          },
        );
      });

      final downloader = ImageDownloader(client: mockClient);

      // 1. Initial 200 Download
      final initial = await downloader.download(
        url: 'https://example.com/photo.png',
      );
      expect(initial.statusCode, 200);
      expect(initial.isNotModified, isFalse);
      expect(initial.eTag, '"12345"');
      expect(initial.maxAgeSeconds, 86400);
      expect(initial.noStore, isFalse);
      expect(utf8.decode(initial.bytes), 'fresh_bytes');

      // 2. Conditional 304 Revalidation
      final revalidated = await downloader.download(
        url: 'https://example.com/photo.png',
        cachedETag: '"12345"',
      );
      expect(revalidated.statusCode, 304);
      expect(revalidated.isNotModified, isTrue);
      expect(revalidated.maxAgeSeconds, 3600);
    });

    test('flags noStore when Cache-Control contains no-store', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          'sensitive_bytes',
          200,
          headers: {
            'content-type': 'image/png',
            'cache-control': 'no-store, no-cache, must-revalidate',
          },
        );
      });

      final downloader = ImageDownloader(client: mockClient);
      final result = await downloader.download(
        url: 'https://example.com/secure.png',
      );

      expect(result.noStore, isTrue);
    });

    test('SmartImageCacheService bypasses storage when noStore is true',
        () async {
      final cacheService = SmartImageCacheService(maxMemoryCacheBytes: 1000);
      const key = 'https://example.com/bypass.png';

      await cacheService.put(
        key: key,
        bytes: Uint8List(20),
        noStore: true,
      );

      expect(await cacheService.get(key), isNull);
      expect(cacheService.memoryByteCount, 0);
    });
  });
}
