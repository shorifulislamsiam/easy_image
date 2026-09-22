import 'package:flutter_test/flutter_test.dart';
import 'package:easy_image/easy_image.dart';

void main() {
  test('EasyImage package public exports are accessible', () {
    const config = EasyImageConfig(
      maxBytes: 1024,
      defaultCacheDuration: Duration(days: 1),
    );
    expect(config.maxBytes, 1024);

    expect(EasyImageLoadingType.values.length, 5);
    expect(EasyImageCacheSource.values.length, 4);
    expect(EasyImageFormat.values.length, 7);
  });
}
