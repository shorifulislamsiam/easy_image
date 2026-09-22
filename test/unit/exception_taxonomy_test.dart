import 'package:flutter_test/flutter_test.dart';
import 'package:easy_image/src/errors/easy_image_exception.dart';

void main() {
  group('EasyImageException Taxonomy', () {
    test('EasyImageNetworkException has status and url', () {
      const exc = EasyImageNetworkException(
        'Not Found',
        statusCode: 404,
        url: 'https://example.com/404.png',
      );
      expect(exc.statusCode, 404);
      expect(exc.url, 'https://example.com/404.png');
      expect(exc.toString(), contains('404'));
    });

    test('EasyImageSizeLimitExceededException contains actual and max bytes',
        () {
      const exc = EasyImageSizeLimitExceededException(
        'Too large',
        actualBytes: 25000000,
        maxBytes: 20000000,
      );
      expect(exc.actualBytes, 25000000);
      expect(exc.maxBytes, 20000000);
      expect(exc.toString(), contains('25000000'));
    });

    test('EasyImageUnsupportedPlatformException contains platform name', () {
      const exc = EasyImageUnsupportedPlatformException(
        'Unsupported',
        platform: 'web',
      );
      expect(exc.platform, 'web');
    });

    test('EasyImageMissingDependencyException contains dependency name', () {
      const exc = EasyImageMissingDependencyException(
        'Missing decoder',
        dependency: 'blurhash_dart',
      );
      expect(exc.dependency, 'blurhash_dart');
    });

    test('EasyImageInvalidUrlException contains bad url', () {
      const exc = EasyImageInvalidUrlException(
        'Bad scheme',
        url: 'ftp://example.com/image.png',
      );
      expect(exc.url, 'ftp://example.com/image.png');
    });
  });
}
