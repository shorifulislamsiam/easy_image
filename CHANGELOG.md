# Changelog

All notable changes to `easy_image` will be documented in this file.
This project adheres to [Semantic Versioning](https://semver.org/).

## [1.0.1] - WASM & WebAssembly Compatibility

### Added
- **Full WASM (WebAssembly) Ready**:
  - Replaced direct dart:io imports with conditional platform-safe storage adapters (DiskCacheAdapter).
  - Added full support for Flutter 3.22+ WebAssembly (WASM).
  - Achieved 160/160 (100% full score) compatibility on pub.dev.

## [1.0.0] - Phase 3: Final Production Release

### Added
- **Pure Dart BlurHash Progressive Loading**:
  - Out-of-the-box BlurHash decoding without native C/Rust binaries.
  - Background isolate decoding via `compute()` for zero UI latency.
  - Smooth crossfade transitions from BlurHash placeholder to high-resolution imagery.
- **Pluggable CDN URL Transformation**:
  - `SmartImageCdnTransform` callback support (`SmartImageConfig.cdnTransform`) for on-the-fly resizing with Cloudinary, Imgix, Cloudflare, or AWS CloudFront.
- **Image Compression Service**:
  - `ImageCompressionService` with configurable quality (1-100) and target dimension constraints for local/file images.
- **At-Rest Cache Encryption**:
  - `encryptCache` and `encryptionKey` support in `SmartImageCacheService` for securing cached images on disk.
- **Animated Playback Controls**:
  - `autoPlay` and `loopCount` overrides with automatic static frame fallback when `MediaQuery.disableAnimations` is active.
- **Migration Guide**:
  - Comprehensive migration documentation (`MIGRATION_GUIDE.md`) for transitioning from `cached_network_image` and `extended_image`.
- **Pub.dev Publication Score Checklist**:
  - Full automated checklist and guidelines for pub.dev package publishing.

## [0.2.0] - Phase 2: Advanced Cache & Performance

### Added
- **HTTP Cache Header Validation & 304 Revalidation**:
  - Full `Cache-Control: max-age` evaluation for zero-network instant cache hits.
  - Conditional HTTP revalidation using `If-None-Match: <etag>` and `If-Modified-Since: <lastModified>`.
  - Seamless handling of `304 Not Modified` responses: reuses local cached bytes, updates freshness timestamps, and announces `SmartImageCacheSource.networkNotModified`.
  - `Cache-Control: no-store` detection to completely bypass disk/memory caching for sensitive dynamic endpoints.
- **LRU (Least-Recently-Used) Cache Eviction**:
  - Quota-based eviction for in-memory tier (`maxMemoryCacheBytes`, default 50 MB) and disk tier (`maxDiskCacheBytes`, default 250 MB).
  - Automatically evicts least recently accessed entries when limits are reached.
- **Header-Aware Cache Keys**:
  - `ImageCacheKey` generator that isolates cache entries for requests carrying distinct authentication headers (`Authorization`, tokens), preventing cross-user data leakage.
- **Concurrent Download Queue**:
  - `ImageDownloadQueue` concurrency limiter (`maxConcurrentDownloads: 6`) preventing UI/network thread bottlenecks during fast scrolling in grids and lists.
- **Pluggable Cache Manager Architecture**:
  - `SmartImageCacheManager` interface allowing custom third-party caching backends to be injected via `SmartImageConfig.cacheManager`.
- **Off-Main-Isolate Format Sniffing**:
  - Sniffing for large byte payloads (>50 KB) offloaded to background isolate via `compute()` to eliminate UI jank.
- **Live Download Progress Reporting**:
  - Streaming progress callbacks via `SmartImageConfig.onLoadProgress(received, total)` with graceful fallback when `Content-Length` is omitted.

## [0.1.0] - Phase 1: Core Foundation

### Added
- **Multi-Source Image Widget**: Unified `SmartImage` widget supporting `url`, `darkUrl`, `asset`, `file`, `bytes`, and `base64`.
- **First-Class Vector SVG Support**: Out-of-the-box rendering of SVG vector images via bundled `flutter_svg`.
- **Raster Multi-Format Detection**: Automatic Content-Type header inspection and magic-byte sniffing for PNG, JPEG, WebP, GIF, and BMP.
- **Two-Tier Caching**: In-memory and persistent on-disk caching with configurable TTL.
- **Retry Mechanism**: Exponential backoff with random jitter to prevent retry storms, plus customizable retry delay and count.
- **Request Cancellation & Lifecycle Safety**: Cancellation of in-flight network streams and pending retry timers on widget disposal or source change.
- **Loading UI & Shimmer**: Configurable loading states, customizable placeholders, and accessibility-aware shimmer effect respecting `MediaQuery.disableAnimations`.
- **Error UI**: Clean default broken-image widget with optional retry action and custom `errorWidget` support.
- **Sealed Exception Taxonomy**: Structured error hierarchy (`SmartImageNetworkException`, `SmartImageTimeoutException`, `SmartImageDecodeException`, `SmartImageUnsupportedFormatException`, `SmartImageUnsupportedPlatformException`, `SmartImageMissingDependencyException`, `SmartImageSizeLimitExceededException`, `SmartImageInvalidUrlException`).
- **Memory Optimization**: Target raster resize dimensions (`cacheWidth`, `cacheHeight`).
- **Accessibility**: Semantic label propagation and screen reader support.
- **Security Guard**: Configurable maximum download size guard (`maxBytes`) preventing out-of-memory crashes on oversized responses.
- **Cache Clearing**: `SmartImage.clearCache()`, `SmartImage.clearImageCache(url)`, and `SmartImage.clearCacheOnLogout()`.
- **Repository Setup**: CI workflow, issue/PR templates, CONTRIBUTING guide, and CODEOWNERS.
