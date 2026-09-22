/// Generates deterministic, collision-resistant cache keys with header-isolation support.
class ImageCacheKey {
  /// Generates a composite cache key from the given URL and optional request headers.
  static String generate({
    required String url,
    Map<String, String>? headers,
    bool includeHeaders = true,
  }) {
    final cleanUrl = url.trim();

    if (!includeHeaders || headers == null || headers.isEmpty) {
      return cleanUrl;
    }

    // Sort headers alphabetically for deterministic key generation
    final sortedKeys = headers.keys.toList()..sort();
    final headerComponents = <String>[];

    for (final key in sortedKeys) {
      final val = headers[key]?.trim();
      if (val != null && val.isNotEmpty) {
        headerComponents.add('${key.toLowerCase()}=$val');
      }
    }

    if (headerComponents.isEmpty) {
      return cleanUrl;
    }

    return '$cleanUrl|headers:${headerComponents.join('&')}';
  }

  /// Converts any cache key string into a safe filesystem-friendly filename.
  static String toFilename(String key) {
    var hash = 5381;
    for (int i = 0; i < key.length; i++) {
      hash = ((hash << 5) + hash) + key.codeUnitAt(i);
    }

    final sanitized = key
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
        .substring(0, key.length > 30 ? 30 : key.length);

    return '${sanitized}_${hash.toRadixString(16)}';
  }
}
