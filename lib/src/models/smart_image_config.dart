import 'package:flutter/foundation.dart';
import '../enums/smart_image_cache_source.dart';
import '../errors/smart_image_exception.dart';
import '../services/image_cache_manager.dart';

/// Callback signature for image load start.
typedef SmartImageLoadStartCallback = void Function();

/// Callback signature for cache hit notification.
typedef SmartImageCacheHitCallback = void Function(
    SmartImageCacheSource source);

/// Callback signature for image load completion.
typedef SmartImageLoadCompleteCallback = void Function(SmartImageLoadInfo info);

/// Callback signature for image load failure.
typedef SmartImageErrorCallback = void Function(SmartImageException error);

/// Callback signature for download progress reporting.
typedef SmartImageProgressCallback = void Function(
    int receivedBytes, int totalBytes);

/// Callback signature for custom retry backoff strategy.
typedef SmartImageRetryBackoff = Duration Function(
    int attempt, Duration baseDelay);

/// Callback signature for transforming URLs for CDN / dynamic image resizing services.
typedef SmartImageCdnTransform = String Function(String url,
    {int? width, int? height});

/// Information provided when an image completes loading.
@immutable
class SmartImageLoadInfo {
  /// The resolved source that was loaded.
  final String source;

  /// The cache source that served the image.
  final SmartImageCacheSource cacheSource;

  /// The size in bytes of the loaded image, if known.
  final int? byteLength;

  /// The time taken to fetch/decode the image.
  final Duration? duration;

  const SmartImageLoadInfo({
    required this.source,
    required this.cacheSource,
    this.byteLength,
    this.duration,
  });
}

/// Advanced configuration object for [SmartImage].
@immutable
class SmartImageConfig {
  /// The maximum allowed download size in bytes. Defaults to 20 MB (20,971,520 bytes).
  final int maxBytes;

  /// Default fallback cache validity duration for network images.
  final Duration defaultCacheDuration;

  /// Network request timeout. Defaults to 15 seconds.
  final Duration timeout;

  /// Custom HTTP request headers attached to network calls.
  final Map<String, String>? headers;

  /// Optional fallback asset path to display if the primary source fails.
  final String? fallbackAsset;

  /// Optional dark mode URL variant.
  final String? darkUrl;

  /// Custom retry backoff function. If null, exponential backoff with jitter is used.
  final SmartImageRetryBackoff? retryBackoff;

  /// Custom cache manager instance. Defaults to built-in [SmartImageCacheService.instance].
  final SmartImageCacheManager? cacheManager;

  /// Maximum concurrent network downloads allowed simultaneously. Defaults to 6.
  final int maxConcurrentDownloads;

  /// Whether custom request headers should be included in the cache key. Defaults to true.
  final bool includeHeadersInCacheKey;

  /// Pluggable CDN URL transformation function.
  final SmartImageCdnTransform? cdnTransform;

  /// Optional BlurHash string decoded as a progressive placeholder gradient.
  final String? blurHash;

  /// Optional low-resolution preview image URL for progressive blur-up loading.
  final String? lowResUrl;

  /// Whether to encrypt cached image files at rest on disk. Defaults to false.
  final bool encryptCache;

  /// Secret key used when [encryptCache] is enabled.
  final String? encryptionKey;

  /// Whether animated formats (GIF, WebP) should auto-play. Defaults to true.
  final bool autoPlay;

  /// Number of times to loop animated images. If null, loops continuously.
  final int? loopCount;

  /// Called when an image loading operation begins.
  final SmartImageLoadStartCallback? onLoadStart;

  /// Called when an image is retrieved from cache or network.
  final SmartImageCacheHitCallback? onCacheHit;

  /// Called when an image successfully completes loading.
  final SmartImageLoadCompleteCallback? onLoadComplete;

  /// Called when an image fails to load.
  final SmartImageErrorCallback? onError;

  /// Called as network image bytes are downloaded.
  final SmartImageProgressCallback? onLoadProgress;

  const SmartImageConfig({
    this.maxBytes = 20 * 1024 * 1024, // 20 MB
    this.defaultCacheDuration = const Duration(days: 7),
    this.timeout = const Duration(seconds: 15),
    this.headers,
    this.fallbackAsset,
    this.darkUrl,
    this.retryBackoff,
    this.cacheManager,
    this.maxConcurrentDownloads = 6,
    this.includeHeadersInCacheKey = true,
    this.cdnTransform,
    this.blurHash,
    this.lowResUrl,
    this.encryptCache = false,
    this.encryptionKey,
    this.autoPlay = true,
    this.loopCount,
    this.onLoadStart,
    this.onCacheHit,
    this.onLoadComplete,
    this.onError,
    this.onLoadProgress,
  });

  /// Default global config instance.
  static const SmartImageConfig defaultConfig = SmartImageConfig();

  /// Creates a copy with specified fields replaced.
  SmartImageConfig copyWith({
    int? maxBytes,
    Duration? defaultCacheDuration,
    Duration? timeout,
    Map<String, String>? headers,
    String? fallbackAsset,
    String? darkUrl,
    SmartImageRetryBackoff? retryBackoff,
    SmartImageCacheManager? cacheManager,
    int? maxConcurrentDownloads,
    bool? includeHeadersInCacheKey,
    SmartImageCdnTransform? cdnTransform,
    String? blurHash,
    String? lowResUrl,
    bool? encryptCache,
    String? encryptionKey,
    bool? autoPlay,
    int? loopCount,
    SmartImageLoadStartCallback? onLoadStart,
    SmartImageCacheHitCallback? onCacheHit,
    SmartImageLoadCompleteCallback? onLoadComplete,
    SmartImageErrorCallback? onError,
    SmartImageProgressCallback? onLoadProgress,
  }) {
    return SmartImageConfig(
      maxBytes: maxBytes ?? this.maxBytes,
      defaultCacheDuration: defaultCacheDuration ?? this.defaultCacheDuration,
      timeout: timeout ?? this.timeout,
      headers: headers ?? this.headers,
      fallbackAsset: fallbackAsset ?? this.fallbackAsset,
      darkUrl: darkUrl ?? this.darkUrl,
      retryBackoff: retryBackoff ?? this.retryBackoff,
      cacheManager: cacheManager ?? this.cacheManager,
      maxConcurrentDownloads:
          maxConcurrentDownloads ?? this.maxConcurrentDownloads,
      includeHeadersInCacheKey:
          includeHeadersInCacheKey ?? this.includeHeadersInCacheKey,
      cdnTransform: cdnTransform ?? this.cdnTransform,
      blurHash: blurHash ?? this.blurHash,
      lowResUrl: lowResUrl ?? this.lowResUrl,
      encryptCache: encryptCache ?? this.encryptCache,
      encryptionKey: encryptionKey ?? this.encryptionKey,
      autoPlay: autoPlay ?? this.autoPlay,
      loopCount: loopCount ?? this.loopCount,
      onLoadStart: onLoadStart ?? this.onLoadStart,
      onCacheHit: onCacheHit ?? this.onCacheHit,
      onLoadComplete: onLoadComplete ?? this.onLoadComplete,
      onError: onError ?? this.onError,
      onLoadProgress: onLoadProgress ?? this.onLoadProgress,
    );
  }
}

/// Type alias for [SmartImageConfig].
typedef EasyImageConfig = SmartImageConfig;
