import 'package:flutter_test/flutter_test.dart';
import 'package:easy_image/src/errors/easy_image_exception.dart';
import 'package:easy_image/src/services/image_downloader.dart';

void main() {
  group('ImageDownloader URL Validation', () {
    test('throws EasyImageInvalidUrlException on empty URL', () {
      expect(
        () => ImageDownloader.validateUrl(''),
        throwsA(isA<EasyImageInvalidUrlException>()),
      );
      expect(
        () => ImageDownloader.validateUrl('   '),
        throwsA(isA<EasyImageInvalidUrlException>()),
      );
    });

    test('throws EasyImageInvalidUrlException on non-http/https schemes', () {
      expect(
        () => ImageDownloader.validateUrl('ftp://example.com/image.png'),
        throwsA(isA<EasyImageInvalidUrlException>()),
      );
      expect(
        () => ImageDownloader.validateUrl('file:///Users/image.png'),
        throwsA(isA<EasyImageInvalidUrlException>()),
      );
    });

    test('validates valid http and https URLs successfully', () {
      final uri1 = ImageDownloader.validateUrl('http://example.com/test.png');
      expect(uri1.scheme, 'http');
      expect(uri1.host, 'example.com');

      final uri2 = ImageDownloader.validateUrl(
          'https://cdn.example.com/path/img.jpg?v=2');
      expect(uri2.scheme, 'https');
      expect(uri2.host, 'cdn.example.com');
    });
  });
}
