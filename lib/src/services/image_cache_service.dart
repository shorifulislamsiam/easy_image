import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../enums/smart_image_cache_source.dart';
import 'image_cache_key.dart';
import 'image_cache_manager.dart';

/// Entry stored in the in-memory cache tier.
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
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// A production two-tier (Memory + Disk) image caching service with LRU eviction,
/// HTTP revalidation metadata, and optional at-rest encryption.
class SmartImageCacheService implements SmartImageCacheManager {
  static SmartImageCacheService _instance = SmartImageCacheService._internal();

  /// Singleton accessor.
  static SmartImageCacheService get instance => _instance;

  @visibleForTesting
  static set instance(SmartImageCacheService custom) => _instance = custom;

  /// Maximum allowed memory cache size (default: 50 MB).
  int maxMemoryCacheBytes;

  /// Maximum allowed disk cache size (default: 250 MB).
  int maxDiskCacheBytes;

  /// Whether disk cache should be encrypted at rest.
  bool encryptCache;

  /// Secret key used when [encryptCache] is enabled.
  String? encryptionKey;

  final Map<String, _MemoryCacheEntry> _memoryCache = {};
  int _currentMemoryBytes = 0;

  io.Directory? _diskCacheDir;
  bool _isDiskInitStarted = false;

  SmartImageCacheService._internal({
    this.maxMemoryCacheBytes = 50 * 1024 * 1024,
    this.maxDiskCacheBytes = 250 * 1024 * 1024,
    this.encryptCache = false,
    this.encryptionKey,
  });

  /// Factory constructor allowing custom cache size limits and encryption settings.
  factory SmartImageCacheService({
    int maxMemoryCacheBytes = 50 * 1024 * 1024,
    int maxDiskCacheBytes = 250 * 1024 * 1024,
    bool encryptCache = false,
    String? encryptionKey,
  }) {
    return SmartImageCacheService._internal(
      maxMemoryCacheBytes: maxMemoryCacheBytes,
      maxDiskCacheBytes: maxDiskCacheBytes,
      encryptCache: encryptCache,
      encryptionKey: encryptionKey,
    );
  }

  @override
  int get memoryByteCount => _currentMemoryBytes;

  /// Initializes the disk cache directory if supported on this platform.
  Future<io.Directory?> _getDiskCacheDir() async {
    if (kIsWeb) return null;
    if (_diskCacheDir != null) return _diskCacheDir;

    if (!_isDiskInitStarted) {
      _isDiskInitStarted = true;
      try {
        final base = await getApplicationCacheDirectory();
        final dir = io.Directory('${base.path}/smart_image_cache');
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        _diskCacheDir = dir;
      } catch (e) {
        debugPrint('⚠️ [SmartImage] Unable to initialize disk cache: $e');
      }
    }
    return _diskCacheDir;
  }

  @override
  Future<CachedImageResult?> get(String key) async {
    final now = DateTime.now();

    // 1. Check memory cache tier
    final memEntry = _memoryCache[key];
    if (memEntry != null) {
      memEntry.lastAccessed = now;
      return CachedImageResult(
        bytes: memEntry.bytes,
        contentType: memEntry.contentType,
        source: SmartImageCacheSource.memory,
        eTag: memEntry.eTag,
        lastModified: memEntry.lastModified,
        expiresAt: memEntry.expiresAt,
        isStale: memEntry.isExpired,
      );
    }

    // 2. Check disk cache tier
    if (!kIsWeb) {
      try {
        final dir = await _getDiskCacheDir();
        if (dir != null) {
          final filename = ImageCacheKey.toFilename(key);
          final file = io.File('${dir.path}/$filename.cache');
          final metaFile = io.File('${dir.path}/$filename.meta');

          if (await file.exists() && await metaFile.exists()) {
            final metaStr = await metaFile.readAsString();
            final meta = jsonDecode(metaStr) as Map<String, dynamic>;
            final expiresAt = DateTime.parse(meta['expiresAt'] as String);
            final eTag = meta['eTag'] as String?;
            final lastModified = meta['lastModified'] as String?;
            final contentType = meta['contentType'] as String?;
            final cacheControl = meta['cacheControl'] as String?;
            final isEncrypted = meta['isEncrypted'] as bool? ?? false;

            Uint8List bytes = await file.readAsBytes();
            if (isEncrypted) {
              bytes =
                  _cipher(bytes, encryptionKey ?? 'smart_image_default_key');
            }

            final isStale = now.isAfter(expiresAt);

            // Update disk access timestamp for LRU
            meta['lastAccessed'] = now.toIso8601String();
            await metaFile
                .writeAsString(jsonEncode(meta))
                .catchError((_) => metaFile);

            // Promote into memory tier
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
              source: SmartImageCacheSource.disk,
              eTag: eTag,
              lastModified: lastModified,
              expiresAt: expiresAt,
              isStale: isStale,
            );
          }
        }
      } catch (e) {
        debugPrint('⚠️ [SmartImage] Disk cache read error: $e');
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
        final dir = await _getDiskCacheDir();
        if (dir != null) {
          final filename = ImageCacheKey.toFilename(key);
          final file = io.File('${dir.path}/$filename.cache');
          final metaFile = io.File('${dir.path}/$filename.meta');

          final diskBytes = encryptCache
              ? _cipher(bytes, encryptionKey ?? 'smart_image_default_key')
              : bytes;

          await file.writeAsBytes(diskBytes);

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
          await metaFile.writeAsString(jsonEncode(meta));

          // Run disk LRU check asynchronously
          _evictDiskLru(dir);
        }
      } catch (e) {
        debugPrint('⚠️ [SmartImage] Disk cache write error: $e');
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

  Future<void> _evictDiskLru(io.Directory dir) async {
    try {
      final metaFiles = dir
          .listSync()
          .whereType<io.File>()
          .where((f) => f.path.endsWith('.meta'))
          .toList();

      int totalDiskBytes = 0;
      final entries = <_DiskEntryInfo>[];

      for (final mf in metaFiles) {
        try {
          final content = await mf.readAsString();
          final data = jsonDecode(content) as Map<String, dynamic>;
          final byteSize = data['byteSize'] as int? ?? 0;
          final lastAccessed =
              DateTime.tryParse(data['lastAccessed'] as String? ?? '') ??
                  DateTime.now();
          final cacheFilePath = mf.path.replaceAll('.meta', '.cache');

          totalDiskBytes += byteSize;
          entries.add(_DiskEntryInfo(
            metaFile: mf,
            cacheFile: io.File(cacheFilePath),
            lastAccessed: lastAccessed,
            byteSize: byteSize,
          ));
        } catch (_) {}
      }

      if (totalDiskBytes > maxDiskCacheBytes) {
        entries.sort((a, b) => a.lastAccessed.compareTo(b.lastAccessed));

        for (final entry in entries) {
          if (totalDiskBytes <= maxDiskCacheBytes) break;
          if (await entry.cacheFile.exists()) await entry.cacheFile.delete();
          if (await entry.metaFile.exists()) await entry.metaFile.delete();
          totalDiskBytes -= entry.byteSize;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [SmartImage] Disk LRU eviction error: $e');
    }
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
    try {
      final dir = await _getDiskCacheDir();
      if (dir != null && await dir.exists()) {
        int total = 0;
        final files = await dir
            .list()
            .where((e) => e is io.File && e.path.endsWith('.cache'))
            .toList();
        for (final file in files) {
          total += await (file as io.File).length();
        }
        return total;
      }
    } catch (_) {}
    return 0;
  }

  @override
  Future<void> clearImage(String key) async {
    final removed = _memoryCache.remove(key);
    if (removed != null) {
      _currentMemoryBytes -= removed.byteSize;
    }

    if (!kIsWeb) {
      try {
        final dir = await _getDiskCacheDir();
        if (dir != null) {
          final filename = ImageCacheKey.toFilename(key);
          final file = io.File('${dir.path}/$filename.cache');
          final metaFile = io.File('${dir.path}/$filename.meta');
          if (await file.exists()) await file.delete();
          if (await metaFile.exists()) await metaFile.delete();
        }
      } catch (e) {
        debugPrint('⚠️ [SmartImage] Clear image error: $e');
      }
    }
  }

  @override
  Future<void> clearAll() async {
    _memoryCache.clear();
    _currentMemoryBytes = 0;

    if (!kIsWeb) {
      try {
        final dir = await _getDiskCacheDir();
        if (dir != null && await dir.exists()) {
          final entities = await dir.list().toList();
          for (final entity in entities) {
            await entity.delete().catchError((_) => entity);
          }
        }
      } catch (e) {
        debugPrint('⚠️ [SmartImage] Clear all error: $e');
      }
    }
  }

  @override
  Future<void> clearCacheOnLogout() async {
    await clearAll();
  }
}

class _DiskEntryInfo {
  final io.File metaFile;
  final io.File cacheFile;
  final DateTime lastAccessed;
  final int byteSize;

  _DiskEntryInfo({
    required this.metaFile,
    required this.cacheFile,
    required this.lastAccessed,
    required this.byteSize,
  });
}
