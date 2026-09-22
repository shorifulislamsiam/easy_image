import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_image/smart_image.dart';

void main() {
  group('ImageCompressionService', () {
    test('compressBytes returns compressed byte payload', () async {
      final service = ImageCompressionService.instance;
      final rawBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      final result = await service.compressBytes(
        rawBytes,
        options: const ImageCompressionOptions(quality: 80),
      );

      expect(result, isNotNull);
      expect(result.length, rawBytes.length);
    });

    test('validates quality bounds on ImageCompressionOptions', () {
      expect(
        () => ImageCompressionOptions(quality: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => ImageCompressionOptions(quality: 101),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
