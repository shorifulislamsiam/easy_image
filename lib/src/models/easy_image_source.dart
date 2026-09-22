import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../errors/easy_image_exception.dart';

/// The raw type of the resolved image source.
enum EasyImageSourceType {
  /// Remote network image via HTTP/HTTPS.
  network,

  /// Bundled Flutter asset image.
  asset,

  /// Local file system image.
  file,

  /// In-memory raw bytes.
  bytes,
}

/// Represents the resolved image source after applying priority rules.
@immutable
class ResolvedImageSource {
  /// The resolved source type.
  final EasyImageSourceType type;

  /// The string identifier (URL, asset path, or file path).
  final String? stringData;

  /// The in-memory byte data if source is [EasyImageSourceType.bytes].
  final Uint8List? byteData;

  /// The file instance if source is [EasyImageSourceType.file].
  final Object? fileData;

  const ResolvedImageSource._({
    required this.type,
    this.stringData,
    this.byteData,
    this.fileData,
  });

  /// Creates a network resolved source.
  const ResolvedImageSource.network(String url)
      : this._(type: EasyImageSourceType.network, stringData: url);

  /// Creates an asset resolved source.
  const ResolvedImageSource.asset(String assetPath)
      : this._(type: EasyImageSourceType.asset, stringData: assetPath);

  /// Creates a file resolved source.
  ResolvedImageSource.file(Object file)
      : this._(
          type: EasyImageSourceType.file,
          stringData: _extractFilePath(file),
          fileData: file,
        );

  /// Creates an in-memory bytes resolved source.
  const ResolvedImageSource.bytes(Uint8List bytes)
      : this._(type: EasyImageSourceType.bytes, byteData: bytes);

  static String _extractFilePath(Object file) {
    try {
      return (file as dynamic).path as String;
    } catch (_) {
      return file.toString();
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResolvedImageSource &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          stringData == other.stringData &&
          fileData == other.fileData &&
          (byteData == null && other.byteData == null ||
              byteData != null &&
                  other.byteData != null &&
                  listEquals(byteData, other.byteData));

  @override
  int get hashCode => Object.hash(type, stringData, fileData, byteData?.length);
}

/// Helper for resolving image sources based on strict priority.
class EasyImageSourceResolver {
  /// Resolves the effective image source according to priority rules:
  ///
  /// `darkUrl` (if isDarkMode and non-null) → `url` → `asset` → `file` → `bytes` → `base64`
  ///
  /// In debug mode, an assertion checks if multiple sources were provided
  /// and prints a diagnostic warning indicating which source won.
  static ResolvedImageSource? resolve({
    String? url,
    String? darkUrl,
    String? asset,
    Object? file,
    Uint8List? bytes,
    String? base64,
    bool isDarkMode = false,
  }) {
    // 1. Gather all provided sources to check for ambiguity.
    final providedSources = <String, Object?>{};
    if (darkUrl != null && darkUrl.trim().isNotEmpty) {
      providedSources['darkUrl'] = darkUrl;
    }
    if (url != null && url.trim().isNotEmpty) {
      providedSources['url'] = url;
    }
    if (asset != null && asset.trim().isNotEmpty) {
      providedSources['asset'] = asset;
    }
    if (file != null) {
      providedSources['file'] = file;
    }
    if (bytes != null && bytes.isNotEmpty) {
      providedSources['bytes'] = bytes;
    }
    if (base64 != null && base64.trim().isNotEmpty) {
      providedSources['base64'] = base64;
    }

    if (providedSources.isEmpty) {
      return null;
    }

    // Check for ambiguity in debug mode
    assert(() {
      if (providedSources.length > 1) {
        final chosen = isDarkMode && darkUrl != null
            ? 'darkUrl'
            : (url != null
                ? 'url'
                : (asset != null
                    ? 'asset'
                    : (file != null
                        ? 'file'
                        : (bytes != null ? 'bytes' : 'base64'))));
        final ignored = providedSources.keys.where((k) => k != chosen).toList();
        debugPrint(
          '⚠️ [EasyImage Warning] Multiple image sources provided (${providedSources.keys.join(', ')}). '
          'Prioritizing "$chosen" and ignoring: ${ignored.join(', ')}.',
        );
      }
      return true;
    }());

    // 2. Resolve by priority
    if (isDarkMode && darkUrl != null && darkUrl.trim().isNotEmpty) {
      return ResolvedImageSource.network(darkUrl.trim());
    }

    if (url != null && url.trim().isNotEmpty) {
      return ResolvedImageSource.network(url.trim());
    }

    if (asset != null && asset.trim().isNotEmpty) {
      return ResolvedImageSource.asset(asset.trim());
    }

    if (file != null) {
      if (kIsWeb) {
        throw const EasyImageUnsupportedPlatformException(
          'dart:io File is not supported on Flutter Web. Use bytes, asset, or url instead.',
          platform: 'web',
        );
      }
      return ResolvedImageSource.file(file);
    }

    if (bytes != null && bytes.isNotEmpty) {
      return ResolvedImageSource.bytes(bytes);
    }

    if (base64 != null && base64.trim().isNotEmpty) {
      try {
        final cleanBase64 = _stripDataUriPrefix(base64.trim());
        final decodedBytes = base64Decode(cleanBase64);
        return ResolvedImageSource.bytes(decodedBytes);
      } catch (e, st) {
        throw EasyImageDecodeException(
          'Failed to decode Base64 image data: $e',
          cause: e,
          stackTrace: st,
        );
      }
    }

    return null;
  }

  static String _stripDataUriPrefix(String input) {
    if (input.startsWith('data:image/') && input.contains('base64,')) {
      return input.split('base64,').last;
    }
    return input;
  }
}

// Backwards compatibility aliases
typedef SmartImageSourceType = EasyImageSourceType;
typedef SmartImageSourceResolver = EasyImageSourceResolver;
