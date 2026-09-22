import 'package:flutter_test/flutter_test.dart';
import 'package:easy_image/src/errors/smart_image_exception.dart';

void main() {
  group('SmartImageException Taxonomy', () {
    test('SmartImageNetworkException has status and url', () {
      const exc = SmartImageNetworkException(
        'Not Found',
        statusCode: 404,
        url: 'https://example.com/404.png',
      );
      expect(exc.statusCode, 404);
      expect(exc.url, 'https://example.com/404.png');
      expect(exc.toString(), contains('404'));
    });

    test('SmartImageSizeLimitExceededException contains actual and max bytes',
        () {
      const exc = SmartImageSizeLimitExceededException(
        'Too large',
        actualBytes: 25000000,
        maxBytes: 20000000,
      );
      expect(exc.actualBytes, 25000000);
      expect(exc.maxBytes, 20000000);
      expect(exc.toString(), contains('25000000'));
    });

    test('SmartImageUnsupportedPlatformException contains platform name', () {
      const exc = SmartImageUnsupportedPlatformException(
        'Unsupported',
        platform: 'web',
      );
      expect(exc.platform, 'web');
    });

    test('SmartImageMissingDependencyException contains dependency name', () {
      const exc = SmartImageMissingDependencyException(
        'Missing decoder',
        dependency: 'blurhash_dart',
      );
      expect(exc.dependency, 'blurhash_dart');
    });

    test('SmartImageInvalidUrlException contains bad url', () {
      const exc = SmartImageInvalidUrlException(
        'Bad scheme',
        url: 'ftp://example.com/image.png',
      );
      expect(exc.url, 'ftp://example.com/image.png');
    });
  });
}
