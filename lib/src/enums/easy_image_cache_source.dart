/// Identifies where an image was retrieved from.
enum EasyImageCacheSource {
  /// Served directly from the fast in-memory cache.
  memory,

  /// Served from persistent local disk cache.
  disk,

  /// Revalidated via HTTP 304 (Not Modified); existing cached bytes reused.
  networkNotModified,

  /// Freshly downloaded over the network.
  network,
}

/// Backwards compatibility alias for [EasyImageCacheSource].
typedef SmartImageCacheSource = EasyImageCacheSource;
