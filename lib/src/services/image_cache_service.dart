import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../enums/easy_image_cache_source.dart';
import 'disk_cache/disk_cache_adapter.dart';
import 'image_cache_key.dart';
import 'image_cache_manager.dart';

/// Internal in-memory representation of a cached image.
class _MemoryCacheEntry {
  final Uint8List bytes;
  final String? contentType;
  final String? eTag;
  final String? lastModified;
  final String? cacheControl;
  final DateTime expiresAt;
  DateTime lastAccessed;

  _MemoryCacheEntry({
    required this.bytes,
    this.contentType,
    this.eTag,
    this.lastModified,
    this.cacheControl,
    required this.expiresAt,
  }) : lastAccessed = DateTime.now();

  int get byteSize => bytes.lengthInBytes;
}

/// Production-ready two-tier caching service for images.
class EasyImageCacheService implements EasyImageCacheManager {
  static EasyImageCacheService _instance = EasyImageCacheService();

  /// Shared singleton instance.
  static EasyImageCacheService get instance => _instance;

  @visibleForTesting
  static set instance(EasyImageCacheService custom) => _instance = custom;

  final Map<String, _MemoryCacheEntry> _memoryCache = {};
  int _currentMemoryBytes = 0;
  final DiskCacheAdapter _diskCache = DiskCacheAdapter();

  /// Maximum allowed bytes in the in-memory tier (default: 50 MB).
  int maxMemoryCacheBytes;

  /// Maximum allowed bytes in the on-disk tier (default: 250 MB).
  int maxDiskCacheBytes;

  /// Whether at-rest cache encryption is enabled.
  bool encryptCache;

  /// Optional custom secret key for encryption.
  String? encryptionKey;

  EasyImageCacheService({
    this.maxMemoryCacheBytes = 50 * 1024 * 1024,
    this.maxDiskCacheBytes = 250 * 1024 * 1024,
    this.encryptCache = false,
    this.encryptionKey,
  });

  /// Current total bytes in the in-memory cache.
  int get currentMemoryBytes => _currentMemoryBytes;

  @override
  int get memoryByteCount => _currentMemoryBytes;

  /// Number of entries currently in the in-memory cache.
  int get memoryItemCount => _memoryCache.length;

  /// Returns true if a response has expired according to its max-age or expiresAt.
  static bool isEntryStale({
    String? cacheControl,
    DateTime? expiresAt,
    DateTime? savedAt,
  }) {
    final now = DateTime.now();

    if (cacheControl != null) {
      final maxAgeMatch = RegExp(r'max-age=(\d+)', caseSensitive: false)
          .firstMatch(cacheControl);
      if (maxAgeMatch != null && savedAt != null) {
        final maxAgeSec = int.tryParse(maxAgeMatch.group(1) ?? '') ?? 0;
        final validUntil = savedAt.add(Duration(seconds: maxAgeSec));
        return now.isAfter(validUntil);
      }
    }

    if (expiresAt != null) {
      return now.isAfter(expiresAt);
    }

    return false;
  }

  @override
  Future<CachedImageResult?> get(String key) async {
    // 1. Check in-memory tier
    final memEntry = _memoryCache[key];
    if (memEntry != null) {
      memEntry.lastAccessed = DateTime.now();

      final isStale = isEntryStale(
        cacheControl: memEntry.cacheControl,
        expiresAt: memEntry.expiresAt,
      );

      return CachedImageResult(
        bytes: memEntry.bytes,
        contentType: memEntry.contentType,
        source: EasyImageCacheSource.memory,
        eTag: memEntry.eTag,
        lastModified: memEntry.lastModified,
        expiresAt: memEntry.expiresAt,
        isStale: isStale,
      );
    }

    // 2. Check on-disk tier (non-Web)
    if (!kIsWeb) {
      try {
        final filename = ImageCacheKey.toFilename(key);
        final rawBytes = await _diskCache.readBytes(filename);
        final metaContent = await _diskCache.readMeta(filename);

        if (rawBytes != null && metaContent != null) {
          final meta = jsonDecode(metaContent) as Map<String, dynamic>;
          final isEncrypted = meta['isEncrypted'] as bool? ?? false;
          final bytes = isEncrypted
              ? _cipher(rawBytes, encryptionKey ?? 'easy_image_default_key')
              : rawBytes;

          final contentType = meta['contentType'] as String?;
          final eTag = meta['eTag'] as String?;
          final lastModified = meta['lastModified'] as String?;
          final cacheControl = meta['cacheControl'] as String?;
          final expiresAtStr = meta['expiresAt'] as String?;
          final expiresAt = expiresAtStr != null
              ? DateTime.tryParse(expiresAtStr) ??
                  DateTime.now().add(const Duration(days: 7))
              : DateTime.now().add(const Duration(days: 7));

          // Update last accessed in meta file
          _diskCache.updateMetaLastAccessed(filename, meta);

          final isStale = isEntryStale(
            cacheControl: cacheControl,
            expiresAt: expiresAt,
          );

          // Promote to in-memory tier
          _putInMemory(
            key: key,
            bytes: bytes,
            contentType: contentType,
            eTag: eTag,
            lastModified: lastModified,
            cacheControl: cacheControl,
            expiresAt: expiresAt,
          );

          return CachedImageResult(
            bytes: bytes,
            contentType: contentType,
            source: EasyImageCacheSource.disk,
            eTag: eTag,
            lastModified: lastModified,
            expiresAt: expiresAt,
            isStale: isStale,
          );
        }
      } catch (e) {
        debugPrint('⚠️ [EasyImage] Disk cache read error: $e');
      }
    }

    return null;
  }

  @override
  Future<void> put({
    required String key,
    required Uint8List bytes,
    String? contentType,
    Duration duration = const Duration(days: 7),
    String? eTag,
    String? lastModified,
    String? cacheControl,
    bool noStore = false,
  }) async {
    // If no-store is flagged, bypass both memory and disk caching
    if (noStore ||
        (cacheControl != null &&
            cacheControl.toLowerCase().contains('no-store'))) {
      return;
    }

    final expiresAt = DateTime.now().add(duration);

    // 1. Store into memory tier with LRU eviction
    _putInMemory(
      key: key,
      bytes: bytes,
      contentType: contentType,
      eTag: eTag,
      lastModified: lastModified,
      cacheControl: cacheControl,
      expiresAt: expiresAt,
    );

    // 2. Store into disk tier with optional at-rest encryption
    if (!kIsWeb) {
      try {
        final filename = ImageCacheKey.toFilename(key);
        final diskBytes = encryptCache
            ? _cipher(bytes, encryptionKey ?? 'easy_image_default_key')
            : bytes;

        final meta = {
          'key': key,
          'contentType': contentType,
          'eTag': eTag,
          'lastModified': lastModified,
          'cacheControl': cacheControl,
          'expiresAt': expiresAt.toIso8601String(),
          'lastAccessed': DateTime.now().toIso8601String(),
          'byteSize': bytes.lengthInBytes,
          'isEncrypted': encryptCache,
        };

        await _diskCache.write(filename, diskBytes, jsonEncode(meta));
        _diskCache.evictLru(maxDiskCacheBytes);
      } catch (e) {
        debugPrint('⚠️ [EasyImage] Disk cache write error: $e');
      }
    }
  }

  void _putInMemory({
    required String key,
    required Uint8List bytes,
    String? contentType,
    String? eTag,
    String? lastModified,
    String? cacheControl,
    required DateTime expiresAt,
  }) {
    // If existing entry, subtract its byte size
    final existing = _memoryCache.remove(key);
    if (existing != null) {
      _currentMemoryBytes -= existing.byteSize;
    }

    // Evict least-recently-used items if memory quota exceeded
    final newBytes = bytes.lengthInBytes;
    while (_currentMemoryBytes + newBytes > maxMemoryCacheBytes &&
        _memoryCache.isNotEmpty) {
      String? oldestKey;
      DateTime? oldestTime;
      for (final entry in _memoryCache.entries) {
        if (oldestTime == null ||
            entry.value.lastAccessed.isBefore(oldestTime)) {
          oldestTime = entry.value.lastAccessed;
          oldestKey = entry.key;
        }
      }
      if (oldestKey != null) {
        final evicted = _memoryCache.remove(oldestKey);
        if (evicted != null) {
          _currentMemoryBytes -= evicted.byteSize;
        }
      } else {
        break;
      }
    }

    _memoryCache[key] = _MemoryCacheEntry(
      bytes: bytes,
      contentType: contentType,
      eTag: eTag,
      lastModified: lastModified,
      cacheControl: cacheControl,
      expiresAt: expiresAt,
    );
    _currentMemoryBytes += newBytes;
  }

  static Uint8List _cipher(Uint8List data, String key) {
    final keyBytes = utf8.encode(key);
    final result = Uint8List(data.length);
    for (int i = 0; i < data.length; i++) {
      result[i] = data[i] ^ keyBytes[i % keyBytes.length];
    }
    return result;
  }

  @override
  Future<int> getDiskByteCount() async {
    if (kIsWeb) return 0;
    return await _diskCache.getDiskByteCount();
  }

  @override
  Future<void> clearImage(String key) async {
    final removed = _memoryCache.remove(key);
    if (removed != null) {
      _currentMemoryBytes -= removed.byteSize;
    }

    if (!kIsWeb) {
      try {
        final filename = ImageCacheKey.toFilename(key);
        await _diskCache.delete(filename);
      } catch (e) {
        debugPrint('⚠️ [EasyImage] Clear image error: $e');
      }
    }
  }

  @override
  Future<void> clearAll() async {
    _memoryCache.clear();
    _currentMemoryBytes = 0;

    if (!kIsWeb) {
      try {
        await _diskCache.clearAll();
      } catch (e) {
        debugPrint('⚠️ [EasyImage] Clear all error: $e');
      }
    }
  }

  @override
  Future<void> clearCacheOnLogout() async {
    await clearAll();
  }
}

/// Backwards compatibility alias for [EasyImageCacheService].
typedef SmartImageCacheService = EasyImageCacheService;
