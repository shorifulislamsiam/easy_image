import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_image/src/enums/easy_image_format.dart';
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
          ImageFormatDetector.detectFromBytes(pngBytes), EasyImageFormat.png);
      expect(
        ImageFormatDetector.detect(bytes: pngBytes),
        EasyImageFormat.png,
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
          EasyImageFormat.jpeg);
      expect(
        ImageFormatDetector.detect(bytes: jpegBytes),
        EasyImageFormat.jpeg,
      );
    });

    test('detects WebP from magic bytes', () {
      final webpBytes = Uint8List.fromList([
        0x52, 0x49, 0x46, 0x46, // RIFF
        0x00, 0x00, 0x00, 0x00, // Size
        0x57, 0x45, 0x42, 0x50, // WEBP
      ]);
      expect(ImageFormatDetector.detectFromBytes(webpBytes),
          EasyImageFormat.webp);
      expect(
        ImageFormatDetector.detect(bytes: webpBytes),
        EasyImageFormat.webp,
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
          EasyImageFormat.gif);
      expect(ImageFormatDetector.detectFromBytes(gif89Bytes),
          EasyImageFormat.gif);
    });

    test('detects BMP from magic bytes', () {
      final bmpBytes = Uint8List.fromList([
        0x42,
        0x4D,
        0x00,
        0x00,
      ]);
      expect(
          ImageFormatDetector.detectFromBytes(bmpBytes), EasyImageFormat.bmp);
    });

    test('detects SVG from XML text bytes', () {
      final svgBytes = Uint8List.fromList(
        utf8.encode('<svg viewBox="0 0 100 100"><circle r="50"/></svg>'),
      );
      final xmlSvgBytes = Uint8List.fromList(
        utf8.encode('<?xml version="1.0"?><svg width="100"></svg>'),
      );
      expect(
          ImageFormatDetector.detectFromBytes(svgBytes), EasyImageFormat.svg);
      expect(ImageFormatDetector.detectFromBytes(xmlSvgBytes),
          EasyImageFormat.svg);
    });

    test('prioritizes Content-Type header when valid', () {
      expect(
        ImageFormatDetector.detect(contentType: 'image/svg+xml'),
        EasyImageFormat.svg,
      );
      expect(
        ImageFormatDetector.detect(contentType: 'image/png; charset=utf-8'),
        EasyImageFormat.png,
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
        EasyImageFormat.png,
      );
    });

    test('falls back to extension as last resort', () {
      expect(
        ImageFormatDetector.detect(
            pathOrUrl: 'https://example.com/photo.jpg?v=1'),
        EasyImageFormat.jpeg,
      );
      expect(
        ImageFormatDetector.detect(pathOrUrl: 'assets/icon.svg#layer1'),
        EasyImageFormat.svg,
      );
      expect(
        ImageFormatDetector.detect(pathOrUrl: '/var/data/image.webp'),
        EasyImageFormat.webp,
      );
    });
  });
}
