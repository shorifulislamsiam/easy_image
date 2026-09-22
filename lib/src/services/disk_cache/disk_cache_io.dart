import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'disk_cache_adapter.dart';

class DiskCacheIo implements DiskCacheAdapter {
  io.Directory? _diskCacheDir;
  bool _initAttempted = false;

  Future<io.Directory?> _getDiskCacheDir() async {
    if (_initAttempted) return _diskCacheDir;
    _initAttempted = true;
    try {
      final base = await getApplicationCacheDirectory();
      final dir = io.Directory('${base.path}/smart_image_cache');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _diskCacheDir = dir;
      return _diskCacheDir;
    } catch (e) {
      debugPrint('⚠️ [SmartImage] Unable to initialize disk cache: $e');
      return null;
    }
  }

  @override
  Future<Uint8List?> readBytes(String filename) async {
    final dir = await _getDiskCacheDir();
    if (dir == null) return null;
    final file = io.File('${dir.path}/$filename.cache');
    if (await file.exists()) {
      return await file.readAsBytes();
    }
    return null;
  }

  @override
  Future<String?> readMeta(String filename) async {
    final dir = await _getDiskCacheDir();
    if (dir == null) return null;
    final metaFile = io.File('${dir.path}/$filename.meta');
    if (await metaFile.exists()) {
      return await metaFile.readAsString();
    }
    return null;
  }

  @override
  Future<void> write(String filename, Uint8List bytes, String metaJson) async {
    final dir = await _getDiskCacheDir();
    if (dir == null) return;
    final file = io.File('${dir.path}/$filename.cache');
    final metaFile = io.File('${dir.path}/$filename.meta');
    await file.writeAsBytes(bytes);
    await metaFile.writeAsString(metaJson);
  }

  @override
  Future<void> updateMetaLastAccessed(
      String filename, Map<String, dynamic> meta) async {
    final dir = await _getDiskCacheDir();
    if (dir == null) return;
    final metaFile = io.File('${dir.path}/$filename.meta');
    meta['lastAccessed'] = DateTime.now().toIso8601String();
    await metaFile.writeAsString(jsonEncode(meta)).catchError((_) => metaFile);
  }

  @override
  Future<void> evictLru(int maxDiskBytes) async {
    final dir = await _getDiskCacheDir();
    if (dir == null) return;
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

      if (totalDiskBytes > maxDiskBytes) {
        entries.sort((a, b) => a.lastAccessed.compareTo(b.lastAccessed));

        for (final entry in entries) {
          if (totalDiskBytes <= maxDiskBytes) break;
          if (await entry.cacheFile.exists()) await entry.cacheFile.delete();
          if (await entry.metaFile.exists()) await entry.metaFile.delete();
          totalDiskBytes -= entry.byteSize;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [SmartImage] Disk LRU eviction error: $e');
    }
  }

  @override
  Future<int> getDiskByteCount() async {
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
    return 0;
  }

  @override
  Future<void> delete(String filename) async {
    final dir = await _getDiskCacheDir();
    if (dir == null) return;
    final file = io.File('${dir.path}/$filename.cache');
    final metaFile = io.File('${dir.path}/$filename.meta');
    if (await file.exists()) await file.delete();
    if (await metaFile.exists()) await metaFile.delete();
  }

  @override
  Future<void> clearAll() async {
    final dir = await _getDiskCacheDir();
    if (dir != null && await dir.exists()) {
      final entities = await dir.list().toList();
      for (final entity in entities) {
        await entity.delete().catchError((_) => entity);
      }
    }
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

DiskCacheAdapter createDiskCacheAdapter() => DiskCacheIo();
