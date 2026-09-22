import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../enums/smart_image_format.dart';

/// Detects the image format using Content-Type headers, magic byte signatures,
/// and URL/path file extensions as a last resort.
class ImageFormatDetector {
  /// Payload threshold above which byte sniffing is offloaded to a background isolate.
  static const int kComputeThresholdBytes = 50 * 1024; // 50 KB

  /// Detects the [SmartImageFormat] using the priority:
  /// 1. Content-Type header (if non-generic)
  /// 2. Magic bytes file signature
  /// 3. File extension fallback
  static SmartImageFormat detect({
    String? contentType,
    Uint8List? bytes,
    String? pathOrUrl,
  }) {
    // 1. Content-Type check
    if (contentType != null && contentType.trim().isNotEmpty) {
      final normalized = contentType.split(';').first.trim().toLowerCase();
      switch (normalized) {
        case 'image/png':
          return SmartImageFormat.png;
        case 'image/jpeg':
        case 'image/jpg':
          return SmartImageFormat.jpeg;
        case 'image/webp':
          return SmartImageFormat.webp;
        case 'image/gif':
          return SmartImageFormat.gif;
        case 'image/bmp':
        case 'image/x-ms-bmp':
          return SmartImageFormat.bmp;
        case 'image/svg+xml':
        case 'image/svg':
          return SmartImageFormat.svg;
        default:
          // If generic or octet-stream, fall through to magic bytes
          break;
      }
    }

    // 2. Magic bytes inspection
    if (bytes != null && bytes.isNotEmpty) {
      final magicFormat = detectFromBytes(bytes);
      if (magicFormat != SmartImageFormat.unknown) {
        return magicFormat;
      }
    }

    // 3. Fallback to extension
    if (pathOrUrl != null && pathOrUrl.trim().isNotEmpty) {
      final extFormat = detectFromExtension(pathOrUrl);
      if (extFormat != SmartImageFormat.unknown) {
        return extFormat;
      }
    }

    return SmartImageFormat.unknown;
  }

  /// Asynchronously detects format, offloading to an isolate if bytes exceed [kComputeThresholdBytes].
  static Future<SmartImageFormat> detectAsync({
    String? contentType,
    Uint8List? bytes,
    String? pathOrUrl,
  }) async {
    // If format is already obvious from Content-Type, resolve synchronously
    if (contentType != null && contentType.trim().isNotEmpty) {
      final syncResult = detect(contentType: contentType);
      if (syncResult != SmartImageFormat.unknown) {
        return syncResult;
      }
    }

    // If large byte array and not Web, run off-main-isolate
    if (bytes != null && bytes.length > kComputeThresholdBytes && !kIsWeb) {
      return compute(detectFromBytes, bytes);
    }

    return detect(
      contentType: contentType,
      bytes: bytes,
      pathOrUrl: pathOrUrl,
    );
  }

  /// Sniffs the image format solely from raw bytes.
  static SmartImageFormat detectFromBytes(Uint8List bytes) {
    if (bytes.length >= 8) {
      // PNG: 89 50 4E 47 0D 0A 1A 0A
      if (bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47 &&
          bytes[4] == 0x0D &&
          bytes[5] == 0x0A &&
          bytes[6] == 0x1A &&
          bytes[7] == 0x0A) {
        return SmartImageFormat.png;
      }
    }

    if (bytes.length >= 3) {
      // JPEG: FF D8 FF
      if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
        return SmartImageFormat.jpeg;
      }
    }

    if (bytes.length >= 12) {
      // WebP: RIFF ... WEBP
      if (bytes[0] == 0x52 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x46 &&
          bytes[8] == 0x57 &&
          bytes[9] == 0x45 &&
          bytes[10] == 0x42 &&
          bytes[11] == 0x50) {
        return SmartImageFormat.webp;
      }
    }

    if (bytes.length >= 6) {
      // GIF: GIF87a or GIF89a
      if (bytes[0] == 0x47 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x38 &&
          (bytes[4] == 0x37 || bytes[4] == 0x39) &&
          bytes[5] == 0x61) {
        return SmartImageFormat.gif;
      }
    }

    if (bytes.length >= 2) {
      // BMP: BM (0x42 0x4D)
      if (bytes[0] == 0x42 && bytes[1] == 0x4D) {
        return SmartImageFormat.bmp;
      }
    }

    // SVG: Text XML containing '<svg' or '<?xml'
    if (bytes.length >= 4) {
      final sampleLen = bytes.length > 512 ? 512 : bytes.length;
      final sampleString = utf8
          .decode(bytes.sublist(0, sampleLen), allowMalformed: true)
          .trim()
          .toLowerCase();
      if (sampleString.startsWith('<svg') ||
          (sampleString.startsWith('<?xml') && sampleString.contains('<svg')) ||
          (sampleString.startsWith('<!doctype svg') ||
              sampleString.contains('<svg xmlns'))) {
        return SmartImageFormat.svg;
      }
    }

    return SmartImageFormat.unknown;
  }

  /// Detects format from the URL or path string extension.
  static SmartImageFormat detectFromExtension(String pathOrUrl) {
    final cleanPath = pathOrUrl.split('?').first.split('#').first.toLowerCase();

    if (cleanPath.endsWith('.png')) return SmartImageFormat.png;
    if (cleanPath.endsWith('.jpg') || cleanPath.endsWith('.jpeg')) {
      return SmartImageFormat.jpeg;
    }
    if (cleanPath.endsWith('.webp')) return SmartImageFormat.webp;
    if (cleanPath.endsWith('.gif')) return SmartImageFormat.gif;
    if (cleanPath.endsWith('.bmp')) return SmartImageFormat.bmp;
    if (cleanPath.endsWith('.svg')) return SmartImageFormat.svg;

    return SmartImageFormat.unknown;
  }
}
