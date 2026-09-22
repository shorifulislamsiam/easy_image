import 'dart:typed_data';
import 'disk_cache_io.dart'
    if (dart.library.js_interop) 'disk_cache_web.dart'
    if (dart.library.html) 'disk_cache_web.dart' as impl;

abstract class DiskCacheAdapter {
  Future<Uint8List?> readBytes(String filename);
  Future<String?> readMeta(String filename);
  Future<void> write(String filename, Uint8List bytes, String metaJson);
  Future<void> updateMetaLastAccessed(
      String filename, Map<String, dynamic> meta);
  Future<void> evictLru(int maxDiskBytes);
  Future<int> getDiskByteCount();
  Future<void> delete(String filename);
  Future<void> clearAll();

  factory DiskCacheAdapter() => impl.createDiskCacheAdapter();
}
