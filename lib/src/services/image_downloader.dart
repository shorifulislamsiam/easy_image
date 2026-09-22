import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../errors/easy_image_exception.dart';
import '../models/easy_image_config.dart';

/// Represents downloaded image payload and HTTP cache metadata.
class DownloadedImage {
  final Uint8List bytes;
  final String? contentType;
  final int statusCode;
  final String? eTag;
  final String? lastModified;
  final String? cacheControl;
  final int? maxAgeSeconds;
  final bool noStore;
  final bool isNotModified;

  const DownloadedImage({
    required this.bytes,
    this.contentType,
    required this.statusCode,
    this.eTag,
    this.lastModified,
    this.cacheControl,
    this.maxAgeSeconds,
    this.noStore = false,
    this.isNotModified = false,
  });
}

/// Downloader with streaming byte limits, cancellation, conditional revalidation, and progress updates.
class ImageDownloader {
  final http.Client _client;

  ImageDownloader({http.Client? client}) : _client = client ?? http.Client();

  /// Validates a URL string and returns a parsed [Uri].
  static Uri validateUrl(String url) {
    if (url.trim().isEmpty) {
      throw const EasyImageInvalidUrlException(
        'Image URL cannot be empty.',
        url: '',
      );
    }

    final uri = Uri.tryParse(url.trim());
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw EasyImageInvalidUrlException(
        'Invalid or unsupported URL scheme (must be http or https): $url',
        url: url,
      );
    }

    return uri;
  }

  /// Downloads an image from the given [url] with optional conditional HTTP revalidation.
  Future<DownloadedImage> download({
    required String url,
    Map<String, String>? headers,
    String? cachedETag,
    String? cachedLastModified,
    Duration timeout = const Duration(seconds: 15),
    int maxBytes = 20 * 1024 * 1024,
    EasyImageProgressCallback? onProgress,
    bool Function()? isCancelled,
  }) async {
    final uri = validateUrl(url);

    if (isCancelled?.call() == true) {
      throw const EasyImageTimeoutException(
          'Download cancelled before start.');
    }

    final request = http.Request('GET', uri);
    if (headers != null && headers.isNotEmpty) {
      request.headers.addAll(headers);
    }

    // Attach conditional headers for HTTP 304 revalidation
    if (cachedETag != null && cachedETag.isNotEmpty) {
      request.headers['if-none-match'] = cachedETag;
    }
    if (cachedLastModified != null && cachedLastModified.isNotEmpty) {
      request.headers['if-modified-since'] = cachedLastModified;
    }

    http.StreamedResponse streamedResponse;
    try {
      final futureResponse = _client.send(request);
      streamedResponse = await futureResponse.timeout(
        timeout,
        onTimeout: () {
          throw EasyImageTimeoutException(
            'Connection timed out after ${timeout.inSeconds} seconds for: $url',
            timeout: timeout,
          );
        },
      );
    } on EasyImageException {
      rethrow;
    } catch (e, st) {
      throw EasyImageNetworkException(
        'Failed to establish connection to $url: $e',
        url: url,
        cause: e,
        stackTrace: st,
      );
    }

    // Handle 304 Not Modified response
    if (streamedResponse.statusCode == 304) {
      final eTag = streamedResponse.headers['etag'] ?? cachedETag;
      final lastModified =
          streamedResponse.headers['last-modified'] ?? cachedLastModified;
      final cacheControl = streamedResponse.headers['cache-control'];
      final maxAge = _parseMaxAge(cacheControl);

      return DownloadedImage(
        bytes: Uint8List(0),
        statusCode: 304,
        isNotModified: true,
        eTag: eTag,
        lastModified: lastModified,
        cacheControl: cacheControl,
        maxAgeSeconds: maxAge,
      );
    }

    if (streamedResponse.statusCode < 200 ||
        streamedResponse.statusCode >= 300) {
      throw EasyImageNetworkException(
        'Server returned HTTP status ${streamedResponse.statusCode} for $url',
        statusCode: streamedResponse.statusCode,
        url: url,
      );
    }

    // Parse caching headers
    final cacheControl = streamedResponse.headers['cache-control'];
    final eTag = streamedResponse.headers['etag'];
    final lastModified = streamedResponse.headers['last-modified'];
    final noStore =
        cacheControl != null && cacheControl.toLowerCase().contains('no-store');
    final maxAgeSeconds = _parseMaxAge(cacheControl);

    // Check declared Content-Length header against maxBytes guard
    final contentLength = streamedResponse.contentLength ?? -1;
    if (contentLength > maxBytes) {
      throw EasyImageSizeLimitExceededException(
        'Image declared Content-Length ($contentLength bytes) exceeds maximum limit ($maxBytes bytes).',
        actualBytes: contentLength,
        maxBytes: maxBytes,
      );
    }

    final bytesBuilder = BytesBuilder(copy: false);
    int receivedBytes = 0;

    final completer = Completer<Uint8List>();
    StreamSubscription<List<int>>? subscription;

    void cleanup() {
      subscription?.cancel();
    }

    subscription = streamedResponse.stream.listen(
      (chunk) {
        if (isCancelled?.call() == true) {
          cleanup();
          if (!completer.isCompleted) {
            completer.completeError(
              const EasyImageTimeoutException(
                  'Download cancelled during stream.'),
            );
          }
          return;
        }

        receivedBytes += chunk.length;
        if (receivedBytes > maxBytes) {
          cleanup();
          if (!completer.isCompleted) {
            completer.completeError(
              EasyImageSizeLimitExceededException(
                'Streamed download exceeded maximum limit of $maxBytes bytes.',
                actualBytes: receivedBytes,
                maxBytes: maxBytes,
              ),
            );
          }
          return;
        }

        bytesBuilder.add(chunk);
        onProgress?.call(receivedBytes, contentLength);
      },
      onError: (Object error, StackTrace st) {
        cleanup();
        if (!completer.isCompleted) {
          completer.completeError(
            EasyImageNetworkException(
              'Error while streaming image response: $error',
              url: url,
              cause: error,
              stackTrace: st,
            ),
          );
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete(bytesBuilder.takeBytes());
        }
      },
      cancelOnError: true,
    );

    final bytes = await completer.future.timeout(
      timeout,
      onTimeout: () {
        cleanup();
        throw EasyImageTimeoutException(
          'Streaming response timed out after ${timeout.inSeconds} seconds for $url',
          timeout: timeout,
        );
      },
    );

    final contentType = streamedResponse.headers['content-type'];
    return DownloadedImage(
      bytes: bytes,
      contentType: contentType,
      statusCode: streamedResponse.statusCode,
      eTag: eTag,
      lastModified: lastModified,
      cacheControl: cacheControl,
      maxAgeSeconds: maxAgeSeconds,
      noStore: noStore,
      isNotModified: false,
    );
  }

  static int? _parseMaxAge(String? cacheControl) {
    if (cacheControl == null || cacheControl.isEmpty) return null;
    final match =
        RegExp(r'max-age=(\d+)', caseSensitive: false).firstMatch(cacheControl);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }
}
