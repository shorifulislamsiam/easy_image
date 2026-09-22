# Migration Guide: Moving to Smart Image

`smart_image` is designed to be a modern, lightweight, all-in-one replacement for existing Flutter image libraries like `cached_network_image` and `extended_image`.

This guide outlines how to migrate your existing code to `SmartImage`.

---

## 1. Migrating from `cached_network_image`

### Basic Cached Network Image

**Before (`cached_network_image`):**
```dart
CachedNetworkImage(
  imageUrl: 'https://example.com/avatar.jpg',
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
)
```

**After (`smart_image`):**
```dart
SmartImage(
  url: 'https://example.com/avatar.jpg',
  placeholder: CircularProgressIndicator(),
  errorWidget: Icon(Icons.error),
  shimmer: true, // or built-in shimmer
)
```

---

### Custom Cache Manager & Headers

**Before (`cached_network_image`):**
```dart
CachedNetworkImage(
  imageUrl: 'https://api.example.com/photo.jpg',
  httpHeaders: {'Authorization': 'Bearer $token'},
  cacheManager: customCacheManager,
)
```

**After (`smart_image`):**
```dart
SmartImage(
  url: 'https://api.example.com/photo.jpg',
  headers: {'Authorization': 'Bearer $token'},
  config: SmartImageConfig(
    cacheManager: customCacheManager,
    includeHeadersInCacheKey: true, // Isolates cache per user token
  ),
)
```

---

### Clearing the Cache

**Before (`cached_network_image`):**
```dart
await DefaultCacheManager().emptyCache();
await DefaultCacheManager().removeFile('https://example.com/image.jpg');
```

**After (`smart_image`):**
```dart
// Clear both memory and disk caches across the entire app
await SmartImage.clearCache();

// Clear specific image
await SmartImage.clearImageCache('https://example.com/image.jpg');

// Purge cache on account logout
await SmartImage.clearCacheOnLogout();
```

---

## 2. Migrating from `extended_image`

### Border Radius & Circular Image

**Before (`extended_image`):**
```dart
ExtendedImage.network(
  'https://example.com/avatar.jpg',
  shape: BoxShape.circle,
  borderRadius: BorderRadius.circular(20),
)
```

**After (`smart_image`):**
```dart
// Circular avatar:
SmartImage.circle(
  url: 'https://example.com/avatar.jpg',
  radius: 30,
)

// Rounded corners:
SmartImage(
  url: 'https://example.com/avatar.jpg',
  radius: 20, // or borderRadius: BorderRadius.circular(20)
)
```

---

### Multiple Image Sources (Network, Asset, File, Memory, SVG)

**Before (`extended_image`):**
```dart
ExtendedImage.network('https://example.com/img.jpg');
ExtendedImage.asset('assets/img.png');
ExtendedImage.file(File('/path/img.jpg'));
ExtendedImage.memory(bytes);
// Required separate flutter_svg setup for SVG
```

**After (`smart_image`):**
```dart
// All sources handled by ONE unified widget with zero extra setup:
SmartImage(url: 'https://example.com/img.jpg');
SmartImage(asset: 'assets/img.png');
SmartImage(file: File('/path/img.jpg'));
SmartImage(bytes: bytes);
SmartImage(base64: base64DataString);
// SVG vectors work automatically out of the box!
```

---

### Progressive / BlurHash Loading

**Before (`extended_image` / `octo_image`):**
```dart
// Required multiple wrapper packages
```

**After (`smart_image`):**
```dart
SmartImage(
  url: 'https://example.com/photo.jpg',
  blurHash: 'L6PZfSi_.AyE_3t7t7R**0o#DgR4',
)
```
