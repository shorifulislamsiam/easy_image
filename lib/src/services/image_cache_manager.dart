import 'package:flutter/foundation.dart';
import '../enums/smart_image_cache_source.dart';

/// Result returned from a cache lookup, containing image bytes and metadata.
@immutable
class CachedImageResult {
  /// The raw image bytes retrieved from cache.
  final Uint8List bytes;

  /// The MIME content-type of the cached image (e.g. "image/png").
  final String? contentType;

  /// Where the image was retrieved from (Memory, Disk, etc.).
  final SmartImageCacheSource source;

  /// HTTP ETag validator string stored with the entry.
  final String? eTag;

  /// HTTP Last-Modified validator string stored with the entry.
  final String? lastModified;

  /// Expiration timestamp of the cached entry.
  final DateTime? expiresAt;

  /// Whether the entry is currently considered expired/stale based on its expiration timestamp.
  final bool isStale;

  const CachedImageResult({
    required this.bytes,
    this.contentType,
    required this.source,
    this.eTag,
    this.lastModified,
    this.expiresAt,
    this.isStale = false,
  });
}

/// Abstract contract for custom cache managers in SmartImage.
abstract class SmartImageCacheManager {
  /// Retrieves a cached image entry by key.
  Future<CachedImageResult?> get(String key);

  /// Persists an image entry with optional HTTP validation headers and TTL.
  Future<void> put({
    required String key,
    required Uint8List bytes,
    String? contentType,
    Duration duration = const Duration(days: 7),
    String? eTag,
    String? lastModified,
    String? cacheControl,
    bool noStore = false,
  });

  /// Removes an individual key from the cache.
  Future<void> clearImage(String key);

  /// Clears all entries from all tiers of the cache.
  Future<void> clearAll();

  /// Clears cached data on user logout.
  Future<void> clearCacheOnLogout();

  /// Total approximate bytes currently occupied in the in-memory cache.
  int get memoryByteCount;

  /// Total approximate bytes currently occupied in the disk cache.
  Future<int> getDiskByteCount();
}
