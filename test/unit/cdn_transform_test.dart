import 'package:flutter_test/flutter_test.dart';
import 'package:easy_image/easy_image.dart';

void main() {
  group('CDN URL Transformation', () {
    test('applies custom cdnTransform function to resize URL', () {
      final config = EasyImageConfig(
        cdnTransform: (url, {width, height}) {
          final uri = Uri.parse(url);
          final params = Map<String, String>.from(uri.queryParameters);
          if (width != null) params['w'] = width.toString();
          if (height != null) params['h'] = height.toString();
          return uri.replace(queryParameters: params).toString();
        },
      );

      final originalUrl = 'https://images.example.com/item.jpg';
      final transformed = config.cdnTransform!(
        originalUrl,
        width: 300,
        height: 200,
      );

      expect(transformed, contains('w=300'));
      expect(transformed, contains('h=200'));
    });
  });
}
