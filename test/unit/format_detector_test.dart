import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_image/src/enums/smart_image_format.dart';
import 'package:easy_image/src/services/image_format_detector.dart';

void main() {
  group('ImageFormatDetector', () {
    test('detects PNG from magic bytes', () {
      final pngBytes = Uint8List.fromList([
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x00,
        0x00,
      ]);
      expect(
          ImageFormatDetector.detectFromBytes(pngBytes), SmartImageFormat.png);
      expect(
        ImageFormatDetector.detect(bytes: pngBytes),
        SmartImageFormat.png,
      );
    });

    test('detects JPEG from magic bytes', () {
      final jpegBytes = Uint8List.fromList([
        0xFF,
        0xD8,
        0xFF,
        0xE0,
        0x00,
        0x10,
      ]);
      expect(ImageFormatDetector.detectFromBytes(jpegBytes),
          SmartImageFormat.jpeg);
      expect(
        ImageFormatDetector.detect(bytes: jpegBytes),
        SmartImageFormat.jpeg,
      );
    });

    test('detects WebP from magic bytes', () {
      final webpBytes = Uint8List.fromList([
        0x52, 0x49, 0x46, 0x46, // RIFF
        0x00, 0x00, 0x00, 0x00, // Size
        0x57, 0x45, 0x42, 0x50, // WEBP
      ]);
      expect(ImageFormatDetector.detectFromBytes(webpBytes),
          SmartImageFormat.webp);
      expect(
        ImageFormatDetector.detect(bytes: webpBytes),
        SmartImageFormat.webp,
      );
    });

    test('detects GIF87a and GIF89a from magic bytes', () {
      final gif87Bytes = Uint8List.fromList([
        0x47,
        0x49,
        0x46,
        0x38,
        0x37,
        0x61,
      ]);
      final gif89Bytes = Uint8List.fromList([
        0x47,
        0x49,
        0x46,
        0x38,
        0x39,
        0x61,
      ]);
      expect(ImageFormatDetector.detectFromBytes(gif87Bytes),
          SmartImageFormat.gif);
      expect(ImageFormatDetector.detectFromBytes(gif89Bytes),
          SmartImageFormat.gif);
    });

    test('detects BMP from magic bytes', () {
      final bmpBytes = Uint8List.fromList([
        0x42,
        0x4D,
        0x00,
        0x00,
      ]);
      expect(
          ImageFormatDetector.detectFromBytes(bmpBytes), SmartImageFormat.bmp);
    });

    test('detects SVG from XML text bytes', () {
      final svgBytes = Uint8List.fromList(
        utf8.encode('<svg viewBox="0 0 100 100"><circle r="50"/></svg>'),
      );
      final xmlSvgBytes = Uint8List.fromList(
        utf8.encode('<?xml version="1.0"?><svg width="100"></svg>'),
      );
      expect(
          ImageFormatDetector.detectFromBytes(svgBytes), SmartImageFormat.svg);
      expect(ImageFormatDetector.detectFromBytes(xmlSvgBytes),
          SmartImageFormat.svg);
    });

    test('prioritizes Content-Type header when valid', () {
      expect(
        ImageFormatDetector.detect(contentType: 'image/svg+xml'),
        SmartImageFormat.svg,
      );
      expect(
        ImageFormatDetector.detect(contentType: 'image/png; charset=utf-8'),
        SmartImageFormat.png,
      );
    });

    test('falls back to magic bytes if Content-Type is generic or octet-stream',
        () {
      final pngBytes = Uint8List.fromList([
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
      ]);
      expect(
        ImageFormatDetector.detect(
          contentType: 'application/octet-stream',
          bytes: pngBytes,
        ),
        SmartImageFormat.png,
      );
    });

    test('falls back to extension as last resort', () {
      expect(
        ImageFormatDetector.detect(
            pathOrUrl: 'https://example.com/photo.jpg?v=1'),
        SmartImageFormat.jpeg,
      );
      expect(
        ImageFormatDetector.detect(pathOrUrl: 'assets/icon.svg#layer1'),
        SmartImageFormat.svg,
      );
      expect(
        ImageFormatDetector.detect(pathOrUrl: '/var/data/image.webp'),
        SmartImageFormat.webp,
      );
    });
  });
}
