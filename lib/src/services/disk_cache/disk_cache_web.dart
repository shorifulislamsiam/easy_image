import 'dart:typed_data';
import 'disk_cache_adapter.dart';

class DiskCacheWeb implements DiskCacheAdapter {
  @override
  Future<Uint8List?> readBytes(String filename) async => null;

  @override
  Future<String?> readMeta(String filename) async => null;

  @override
  Future<void> write(String filename, Uint8List bytes, String metaJson) async {}

  @override
  Future<void> updateMetaLastAccessed(
      String filename, Map<String, dynamic> meta) async {}

  @override
  Future<void> evictLru(int maxDiskBytes) async {}

  @override
  Future<int> getDiskByteCount() async => 0;

  @override
  Future<void> delete(String filename) async {}

  @override
  Future<void> clearAll() async {}
}

DiskCacheAdapter createDiskCacheAdapter() => DiskCacheWeb();
