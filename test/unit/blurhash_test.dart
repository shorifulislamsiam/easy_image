import 'package:flutter_test/flutter_test.dart';
import 'package:easy_image/easy_image.dart';

void main() {
  group('BlurHashDecoder', () {
    test('decodes valid BlurHash string into BMP bytes', () {
      // Standard valid BlurHash string
      const blurHash = 'L6PZfSi_.AyE_3t7t7R**0o#DgR4';

      final bytes = BlurHashDecoder.decode(
        blurHash: blurHash,
        width: 16,
        height: 16,
      );

      expect(bytes, isNotNull);
      expect(bytes!.length, greaterThan(54)); // 54 header + pixels
      expect(bytes[0], 0x42); // 'B'
      expect(bytes[1], 0x4D); // 'M'
    });

    test('returns null gracefully on invalid BlurHash string', () {
      expect(BlurHashDecoder.decode(blurHash: 'bad'), isNull);
      expect(BlurHashDecoder.decode(blurHash: ''), isNull);
    });
  });
}
