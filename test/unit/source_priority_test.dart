import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_image/src/errors/easy_image_exception.dart';
import 'package:easy_image/src/models/easy_image_source.dart';

void main() {
  group('EasyImageSourceResolver', () {
    test('returns null when no sources are provided', () {
      final source = EasyImageSourceResolver.resolve();
      expect(source, isNull);
    });

    test('resolves url as network source', () {
      final source = EasyImageSourceResolver.resolve(
        url: 'https://example.com/image.png',
      );
      expect(source, isNotNull);
      expect(source!.type, EasyImageSourceType.network);
      expect(source.stringData, 'https://example.com/image.png');
    });

    test('resolves asset as asset source', () {
      final source = EasyImageSourceResolver.resolve(
        asset: 'assets/images/logo.png',
      );
      expect(source, isNotNull);
      expect(source!.type, EasyImageSourceType.asset);
      expect(source.stringData, 'assets/images/logo.png');
    });

    test('resolves bytes as bytes source', () {
      final testBytes = Uint8List.fromList([1, 2, 3, 4]);
      final source = EasyImageSourceResolver.resolve(
        bytes: testBytes,
      );
      expect(source, isNotNull);
      expect(source!.type, EasyImageSourceType.bytes);
      expect(source.byteData, testBytes);
    });

    test('resolves base64 data URI string to bytes source', () {
      final raw = 'Hello Image Bytes';
      final encoded = base64Encode(utf8.encode(raw));
      final dataUri = 'data:image/png;base64,$encoded';

      final source = EasyImageSourceResolver.resolve(base64: dataUri);
      expect(source, isNotNull);
      expect(source!.type, EasyImageSourceType.bytes);
      expect(utf8.decode(source.byteData!), raw);
    });

    test('throws EasyImageDecodeException on invalid base64 string', () {
      expect(
        () => EasyImageSourceResolver.resolve(base64: '%%%invalid-base64%%%'),
        throwsA(isA<EasyImageDecodeException>()),
      );
    });

    test('prioritizes darkUrl when isDarkMode is true', () {
      final source = EasyImageSourceResolver.resolve(
        url: 'https://example.com/light.png',
        darkUrl: 'https://example.com/dark.png',
        isDarkMode: true,
      );
      expect(source!.stringData, 'https://example.com/dark.png');
    });

    test('uses url when isDarkMode is false even if darkUrl is provided', () {
      final source = EasyImageSourceResolver.resolve(
        url: 'https://example.com/light.png',
        darkUrl: 'https://example.com/dark.png',
        isDarkMode: false,
      );
      expect(source!.stringData, 'https://example.com/light.png');
    });

    test('prioritizes url over asset, file, bytes, and base64', () {
      final source = EasyImageSourceResolver.resolve(
        url: 'https://example.com/primary.png',
        asset: 'assets/ignored.png',
        bytes: Uint8List.fromList([1, 2]),
      );
      expect(source!.type, EasyImageSourceType.network);
      expect(source.stringData, 'https://example.com/primary.png');
    });

    test('prioritizes asset over bytes and base64', () {
      final source = EasyImageSourceResolver.resolve(
        asset: 'assets/primary.png',
        bytes: Uint8List.fromList([1, 2]),
      );
      expect(source!.type, EasyImageSourceType.asset);
      expect(source.stringData, 'assets/primary.png');
    });
  });
}
