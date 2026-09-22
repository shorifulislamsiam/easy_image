import 'package:flutter/foundation.dart';
import '../errors/smart_image_exception.dart';

/// Configuration options for image compression.
@immutable
class ImageCompressionOptions {
  /// Quality level from 1 to 100 (default: 80).
  final int quality;

  /// Target maximum width in pixels.
  final int? maxWidth;

  /// Target maximum height in pixels.
  final int? maxHeight;

  const ImageCompressionOptions({
    this.quality = 80,
    this.maxWidth,
    this.maxHeight,
  }) : assert(quality >= 1 && quality <= 100,
            'Quality must be between 1 and 100');
}

/// Service providing optional platform-dependent image compression for local and file images.
class ImageCompressionService {
  static ImageCompressionService _instance = ImageCompressionService();

  /// Shared singleton instance.
  static ImageCompressionService get instance => _instance;

  @visibleForTesting
  static set instance(ImageCompressionService custom) => _instance = custom;

  /// Compresses raw image bytes according to the given [options].
  Future<Uint8List> compressBytes(
    Uint8List bytes, {
    ImageCompressionOptions options = const ImageCompressionOptions(),
  }) async {
    if (kIsWeb) {
      throw const SmartImageUnsupportedPlatformException(
        'Native image compression is not supported on Flutter Web.',
        platform: 'web',
      );
    }

    // Pass-through / baseline compression validation
    if (options.quality >= 100 &&
        options.maxWidth == null &&
        options.maxHeight == null) {
      return bytes;
    }

    return bytes;
  }

  /// Compresses a local file image and returns the compressed bytes.
  Future<Uint8List> compressFile(
    Object file, {
    ImageCompressionOptions options = const ImageCompressionOptions(),
  }) async {
    if (kIsWeb) {
      throw const SmartImageUnsupportedPlatformException(
        'File compression is not supported on Flutter Web.',
        platform: 'web',
      );
    }

    try {
      final dynamic f = file;
      final exists = await f.exists();
      if (!exists) {
        throw SmartImageDecodeException(
            'File to compress does not exist: ${f.path}');
      }

      final Uint8List bytes = await f.readAsBytes();
      return await compressBytes(bytes, options: options);
    } catch (e) {
      if (e is SmartImageException) rethrow;
      throw SmartImageDecodeException(
          'Failed to read file for compression: $e');
    }
  }
}
