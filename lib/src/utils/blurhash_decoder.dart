import 'dart:math';
import 'package:flutter/foundation.dart';

/// Pure Dart implementation of the BlurHash decoding algorithm.
///
/// Decodes compact BlurHash strings into renderable BMP image bytes
/// without requiring any native C/Rust binaries or external dependencies.
class BlurHashDecoder {
  static const String _base83Characters =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#\$%*+,-.:;=?@[]^_{|}~';

  /// Decodes a BlurHash string into BMP image bytes.
  ///
  /// [width] and [height] are the target pixel resolution (typically 32x32 for high quality blur).
  /// [punch] adjusts the contrast of the generated image (default: 1.0).
  static Uint8List? decode({
    required String blurHash,
    int width = 32,
    int height = 32,
    double punch = 1.0,
  }) {
    if (blurHash.length < 6) return null;

    try {
      final sizeFlag = _decodeBase83(blurHash.substring(0, 1));
      final numY = (sizeFlag / 9).floor() + 1;
      final numX = (sizeFlag % 9) + 1;

      final quantisedMaxAc = _decodeBase83(blurHash.substring(1, 2));
      final maxValue = (quantisedMaxAc + 1) / 166.0;

      final colors = List<List<double>>.filled(numX * numY, [0.0, 0.0, 0.0]);

      for (int i = 0; i < colors.length; i++) {
        if (i == 0) {
          final value = _decodeBase83(blurHash.substring(2, 6));
          colors[i] = _decodeDc(value);
        } else {
          final value = _decodeBase83(blurHash.substring(4 + i * 2, 6 + i * 2));
          colors[i] = _decodeAc(value, maxValue * punch);
        }
      }

      final rgbaPixels = Uint8List(width * height * 4);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          double r = 0.0;
          double g = 0.0;
          double b = 0.0;

          for (int j = 0; j < numY; j++) {
            for (int i = 0; i < numX; i++) {
              final basis =
                  cos((pi * x * i) / width) * cos((pi * y * j) / height);
              final color = colors[i + j * numX];
              r += color[0] * basis;
              g += color[1] * basis;
              b += color[2] * basis;
            }
          }

          final pixelIndex = (y * width + x) * 4;
          rgbaPixels[pixelIndex] = _linearToSrgb(r);
          rgbaPixels[pixelIndex + 1] = _linearToSrgb(g);
          rgbaPixels[pixelIndex + 2] = _linearToSrgb(b);
          rgbaPixels[pixelIndex + 3] = 255;
        }
      }

      return _rgbaToBmp(rgbaPixels, width, height);
    } catch (_) {
      return null;
    }
  }

  /// Asynchronously decodes BlurHash on a background isolate using [compute()].
  static Future<Uint8List?> decodeAsync({
    required String blurHash,
    int width = 32,
    int height = 32,
    double punch = 1.0,
  }) async {
    if (kIsWeb) {
      return decode(
          blurHash: blurHash, width: width, height: height, punch: punch);
    }
    return compute(
      _decodeWrapper,
      _BlurHashParams(blurHash, width, height, punch),
    );
  }

  static Uint8List? _decodeWrapper(_BlurHashParams params) {
    return decode(
      blurHash: params.blurHash,
      width: params.width,
      height: params.height,
      punch: params.punch,
    );
  }

  static int _decodeBase83(String str) {
    int value = 0;
    for (int i = 0; i < str.length; i++) {
      final code = _base83Characters.indexOf(str[i]);
      if (code == -1) return 0;
      value = value * 83 + code;
    }
    return value;
  }

  static List<double> _decodeDc(int value) {
    final int r = value >> 16;
    final int g = (value >> 8) & 255;
    final int b = value & 255;
    return [_srgbToLinear(r), _srgbToLinear(g), _srgbToLinear(b)];
  }

  static List<double> _decodeAc(int value, double maxValue) {
    final int quantR = (value / (19 * 19)).floor();
    final int quantG = ((value / 19).floor()) % 19;
    final int quantB = value % 19;

    return [
      _signPow((quantR - 9) / 9.0, 2.0) * maxValue,
      _signPow((quantG - 9) / 9.0, 2.0) * maxValue,
      _signPow((quantB - 9) / 9.0, 2.0) * maxValue,
    ];
  }

  static double _signPow(double val, double exp) {
    return val.sign * pow(val.abs(), exp);
  }

  static double _srgbToLinear(int value) {
    final double v = value / 255.0;
    return v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
  }

  static int _linearToSrgb(double value) {
    final double v = value.clamp(0.0, 1.0);
    final double s =
        v <= 0.0031308 ? v * 12.92 : 1.055 * pow(v, 1.0 / 2.4) - 0.055;
    return (s * 255.0).round().clamp(0, 255);
  }

  /// Converts RGBA pixels into standard Windows BMP file bytes.
  static Uint8List _rgbaToBmp(Uint8List rgba, int width, int height) {
    final rowSize = (width * 3 + 3) & ~3; // 4-byte row alignment
    final pixelArraySize = rowSize * height;
    final fileSize = 54 + pixelArraySize;

    final bmp = Uint8List(fileSize);
    final buffer = ByteData.view(bmp.buffer);

    // Bitmap File Header (14 bytes)
    bmp[0] = 0x42; // 'B'
    bmp[1] = 0x4D; // 'M'
    buffer.setUint32(2, fileSize, Endian.little);
    buffer.setUint32(10, 54, Endian.little); // Offset to pixel array

    // DIB Header (BITMAPINFOHEADER - 40 bytes)
    buffer.setUint32(14, 40, Endian.little);
    buffer.setInt32(18, width, Endian.little);
    buffer.setInt32(22, height, Endian.little); // Bottom-up bitmap
    buffer.setUint16(26, 1, Endian.little); // Color planes
    buffer.setUint16(28, 24, Endian.little); // 24 bits per pixel (BGR)
    buffer.setUint32(34, pixelArraySize, Endian.little);

    // Write BGR pixels (bottom to top)
    for (int y = 0; y < height; y++) {
      final srcRow = height - 1 - y;
      final destOffset = 54 + y * rowSize;

      for (int x = 0; x < width; x++) {
        final srcOffset = (srcRow * width + x) * 4;
        final r = rgba[srcOffset];
        final g = rgba[srcOffset + 1];
        final b = rgba[srcOffset + 2];

        final pixelPos = destOffset + x * 3;
        bmp[pixelPos] = b;
        bmp[pixelPos + 1] = g;
        bmp[pixelPos + 2] = r;
      }
    }

    return bmp;
  }
}

class _BlurHashParams {
  final String blurHash;
  final int width;
  final int height;
  final double punch;

  _BlurHashParams(this.blurHash, this.width, this.height, this.punch);
}
