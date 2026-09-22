# Easy Image for Flutter

A production-ready Flutter package providing a unified widget for displaying images with built-in two-tier caching, HTTP 304 revalidation, LRU eviction, BlurHash progressive loading, CDN transformations, concurrency limiting, loading shimmer, error retry with backoff, local file/asset/memory support, and first-class SVG rendering.

[![CI](https://github.com/flutter_packages/easy_image/actions/workflows/ci.yml/badge.svg)](https://github.com/flutter_packages/easy_image/actions/workflows/ci.yml)
[![pub package](https://img.shields.io/badge/pub.dev-1.0.0-blue.svg)](https://pub.dev/packages/easy_image)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## 1. Introduction

`SmartImage` replaces all image-related boilerplate in Flutter apps with a single, highly-optimized widget:

```dart
SmartImage(
  url: user.profileImageUrl,
)
```

Whether you are loading remote HTTP/HTTPS images, bundled assets, local files, in-memory bytes, Base64 strings, animated GIFs, or vector SVGs, `SmartImage` automatically detects the format, applies two-tier caching with HTTP 304 revalidation, limits concurrent connections, handles progressive BlurHash loading, and recovers from transient network drops with jittered backoff retries.

---

## 2. Installation

Add `easy_image` to your `pubspec.yaml`:

```yaml
dependencies:
  easy_image: ^1.0.0
```

Then run:

```bash
flutter pub get
```

> **Note on SVG Support**: `flutter_svg` is a standard, required dependency bundled transitively with `easy_image`. You do not need to install or configure any extra package to render SVGs.

---

## 3. Basic Usage

```dart
import 'package:easy_image/easy_image.dart';

// Display a network image with default shimmer loading and error recovery
SmartImage(
  url: 'https://example.com/avatar.jpg',
  width: 120,
  height: 120,
  radius: 12,
  shimmer: true,
)
```

---

## 4. Network Images

```dart
SmartImage(
  url: 'https://images.unsplash.com/photo-1579783902614-a3fb3927b675',
  width: 300,
  height: 200,
  fit: BoxFit.cover,
  headers: {'Authorization': 'Bearer $token'},
)
```

---

## 5. Asset Images

```dart
SmartImage(
  asset: 'assets/images/logo.png',
  width: 150,
  height: 150,
)
```

---

## 6. File Images (Desktop & Mobile)

```dart
import 'dart:io';

SmartImage(
  file: File('/path/to/local/storage/photo.jpg'),
  width: 200,
  height: 200,
)
```

> ⚠️ **Web Limitation**: `dart:io` `File` is not supported on Flutter Web. For Web platforms, provide `bytes`, `asset`, or `url` instead.

---

## 7. Memory & Base64 Images

```dart
// Raw byte Uint8List (e.g. from camera picker)
SmartImage(
  bytes: capturedImageBytes,
  width: 200,
  height: 200,
)

// Base64 string / Data URI
SmartImage(
  base64: 'data:image/png;base64,iVBORw0KGgo...',
  width: 100,
  height: 100,
)
```

---

## 8. SVG & Animated Format Support

`SmartImage` automatically inspects Content-Type headers and sniffs magic byte signatures to detect vector SVGs, animated GIFs, and WebP:

```dart
// Remote or bundled SVG vector
SmartImage(
  url: 'https://example.com/vector_icon.svg',
  width: 48,
  height: 48,
)

// Animated GIF with loop count control
SmartImage(
  url: 'https://example.com/animation.gif',
  autoPlay: true,
  loopCount: 3,
  width: 120,
  height: 120,
)
```

---

## 9. Placeholders, Shimmer & BlurHash Progressive Loading

`SmartImage` includes a built-in pure Dart BlurHash decoder that decodes compact BlurHash strings off the main isolate:

```dart
// BlurHash progressive placeholder
SmartImage(
  url: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=500',
  blurHash: 'L6PZfSi_.AyE_3t7t7R**0o#DgR4',
  width: 260,
  height: 150,
  radius: 12,
)

// Shimmer effect
SmartImage(
  url: imageUrl,
  shimmer: true,
  loadingType: SmartImageLoadingType.shimmer,
)
```

> **Accessibility Note**: When the user enables the OS-level "Reduce Motion" accessibility setting (`MediaQuery.disableAnimations`), shimmer, fade-in, and autoplay animations automatically degrade to instant, static visual states.

---

## 10. Error Handling & Exception Taxonomy

All errors thrown and passed to `onError` conform to the sealed `SmartImageException` hierarchy:

```dart
SmartImage(
  url: imageUrl,
  errorWidget: Container(
    color: Colors.red.shade50,
    child: const Icon(Icons.error, color: Colors.red),
  ),
  config: SmartImageConfig(
    onError: (error) {
      switch (error) {
        case SmartImageNetworkException(:final statusCode, :final url):
          debugPrint('Network failure ($statusCode) on $url');
        case SmartImageTimeoutException():
          debugPrint('Request timed out');
        case SmartImageSizeLimitExceededException(:final actualBytes, :final maxBytes):
          debugPrint('Image exceeded $maxBytes bytes (was $actualBytes bytes)');
        case SmartImageDecodeException():
          debugPrint('Corrupted image payload');
        case SmartImageUnsupportedFormatException(:final format):
          debugPrint('Unsupported format: $format');
        case SmartImageUnsupportedPlatformException(:final platform):
          debugPrint('Platform $platform does not support this operation');
        case SmartImageMissingDependencyException(:final dependency):
          debugPrint('Missing optional dependency: $dependency');
        case SmartImageInvalidUrlException(:final url):
          debugPrint('Invalid URL scheme: $url');
      }
    },
  ),
)
```

---

## 11. Automatic Retry with Exponential Backoff & Jitter

When a network image fails due to a transient connection error or 5xx server status, `SmartImage` can automatically retry using exponential backoff with randomized jitter to prevent server retry storms:

```dart
SmartImage(
  url: imageUrl,
  retryCount: 3,
  retryDelay: Duration(seconds: 2), // Base delay (exponential backoff applied)
)
```

---

## 12. Circular Images & Box Styling

```dart
// Circular Avatar shortcut
SmartImage.circle(
  url: userAvatarUrl,
  radius: 32,
  shimmer: true,
)

// Rounded rectangle with custom background
SmartImage(
  url: imageUrl,
  width: 140,
  height: 140,
  radius: 16,
  backgroundColor: Colors.grey.shade200,
  fit: BoxFit.cover,
)
```

---

## 13. Two-Tier Cache & HTTP 304 Revalidation

`SmartImage` implements an intelligent two-tier (In-Memory + Disk) caching layer with automatic HTTP revalidation:

1. **`Cache-Control: no-store`**: If response contains `no-store`, caching is completely bypassed (0 disk/memory footprint).
2. **Freshness (`max-age`)**: If cached entry is within its `max-age` window, it is served immediately from memory/disk with 0 network calls.
3. **Revalidation (`ETag` / `Last-Modified`)**: If cached entry is stale, a conditional request (`If-None-Match`, `If-Modified-Since`) is made. An HTTP `304 Not Modified` reuses local cached bytes, updates freshness, and notifies `SmartImageCacheSource.networkNotModified`.
4. **LRU Eviction**: In-memory and disk caches strictly respect size quotas (e.g. `maxMemoryCacheBytes: 50MB`, `maxDiskCacheBytes: 250MB`), automatically evicting least-recently-used items when limits are reached.

```dart
// Clear entire cache (Memory + Disk)
await SmartImage.clearCache();

// Clear specific URL
await SmartImage.clearImageCache('https://example.com/photo.png');

// Clear all user cache on account logout
await SmartImage.clearCacheOnLogout();
```

---

## 14. Image Compression

Support optional compression for local/file images:

```dart
SmartImage(
  bytes: cameraBytes,
  compress: true,
  quality: 80, // Quality from 1 to 100
)
```

---

## 15. Concurrent Download Limiter

To avoid saturating network connections and UI isolates when scrolling long image feeds or grids, `SmartImage` processes downloads through a concurrent queue (`ImageDownloadQueue`):

```dart
SmartImage(
  url: imageUrl,
  config: SmartImageConfig(
    maxConcurrentDownloads: 6, // Up to 6 simultaneous downloads
  ),
)
```

---

## 16. CDN URL Transformation

Pluggable dynamic resizing using Cloudinary, Imgix, Cloudflare Images, or custom image resizing gateways:

```dart
SmartImage(
  url: 'https://images.example.com/original.jpg',
  width: 200,
  height: 150,
  config: SmartImageConfig(
    cdnTransform: (url, {width, height}) {
      return '$url?w=$width&h=$height&fit=crop';
    },
  ),
)
```

---

## 17. Lifecycle & Observability Hooks

```dart
SmartImage(
  url: imageUrl,
  config: SmartImageConfig(
    onLoadStart: () => debugPrint('Image loading started'),
    onCacheHit: (source) {
      // SmartImageCacheSource.memory
      // SmartImageCacheSource.disk
      // SmartImageCacheSource.networkNotModified (HTTP 304)
      // SmartImageCacheSource.network (Fresh download)
      debugPrint('Cache source: $source');
    },
    onLoadProgress: (received, total) {
      debugPrint('Progress: $received / $total bytes');
    },
    onLoadComplete: (info) => debugPrint('Loaded ${info.byteLength} bytes in ${info.duration}'),
    onError: (error) => debugPrint('Error: $error'),
  ),
)
```

---

## 21. Platform Support Matrix

| Feature | Android | iOS | Web | macOS | Windows | Linux |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Network Image (HTTP/HTTPS)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Asset Image** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **File Image (`dart:io`)** | ✅ | ✅ | ❌ (No `dart:io`) | ✅ | ✅ | ✅ |
| **Memory / Bytes / Base64** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Vector SVG (`flutter_svg`)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Raster (PNG, JPEG, WebP, GIF, BMP)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Two-Tier Cache (Memory + Disk)** | ✅ | ✅ | In-Memory | ✅ | ✅ | ✅ |
| **HTTP 304 Revalidation & No-Store** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **BlurHash Progressive Loading** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **LRU Cache Eviction** | ✅ | ✅ | Memory LRU | ✅ | ✅ | ✅ |
| **Concurrent Download Limiter** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **CDN Transformations** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Authenticated Cache Isolation** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Accessibility & Reduced Motion** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## 24. Migration Guide

Moving from `cached_network_image` or `extended_image`? See our detailed [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) for step-by-step mapping of common APIs.

---

## 25. Pub.dev Pre-Publish Checklist

Before publishing to pub.dev, verify:
- [x] All platforms declared in `pubspec.yaml`.
- [x] Zero analyzer errors or warnings (`flutter analyze --fatal-infos`).
- [x] Clean formatting (`dart format --output=none --set-exit-if-changed .`).
- [x] Full test suite passing (`flutter test --coverage`).
- [x] Functional `example/` project with runnable web/desktop/mobile support.
- [x] Complete documentation with code samples.

---

## 27. License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
