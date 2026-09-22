import 'package:flutter_test/flutter_test.dart';
import 'package:easy_image/smart_image.dart';

void main() {
  test('SmartImage package public exports are accessible', () {
    const config = SmartImageConfig(
      maxBytes: 1024,
      defaultCacheDuration: Duration(days: 1),
    );
    expect(config.maxBytes, 1024);

    expect(SmartImageLoadingType.values.length, 5);
    expect(SmartImageCacheSource.values.length, 4);
    expect(SmartImageFormat.values.length, 7);
  });
}
