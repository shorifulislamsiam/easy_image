import 'package:flutter/foundation.dart';

/// Base sealed class for all exceptions thrown by the SmartImage package.
@immutable
sealed class SmartImageException implements Exception {
  /// A human-readable description of the error.
  final String message;

  /// The underlying cause or exception, if any.
  final Object? cause;

  /// The stack trace associated with the error, if any.
  final StackTrace? stackTrace;

  const SmartImageException(this.message, {this.cause, this.stackTrace});

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when a network request fails (e.g. non-2xx status code or connection failure).
final class SmartImageNetworkException extends SmartImageException {
  /// The HTTP status code, if available.
  final int? statusCode;

  /// The URL that failed.
  final String? url;

  const SmartImageNetworkException(
    super.message, {
    this.statusCode,
    this.url,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() =>
      'SmartImageNetworkException: $message (status: $statusCode, url: $url)';
}

/// Thrown when an image download or processing operation times out.
final class SmartImageTimeoutException extends SmartImageException {
  /// The duration that was exceeded.
  final Duration? timeout;

  const SmartImageTimeoutException(
    super.message, {
    this.timeout,
    super.cause,
    super.stackTrace,
  });
}

/// Thrown when image bytes fail to decode or are corrupted.
final class SmartImageDecodeException extends SmartImageException {
  const SmartImageDecodeException(
    super.message, {
    super.cause,
    super.stackTrace,
  });
}

/// Thrown when an image format is unsupported or cannot be recognized.
final class SmartImageUnsupportedFormatException extends SmartImageException {
  /// The detected or declared format string (e.g. "image/tiff").
  final String? format;

  const SmartImageUnsupportedFormatException(
    super.message, {
    this.format,
    super.cause,
    super.stackTrace,
  });
}

/// Thrown when an operation is attempted on an unsupported platform
/// (e.g. using `File` or native compression on Flutter Web).
final class SmartImageUnsupportedPlatformException extends SmartImageException {
  /// The name of the platform where the operation failed.
  final String platform;

  const SmartImageUnsupportedPlatformException(
    super.message, {
    required this.platform,
    super.cause,
    super.stackTrace,
  });
}

/// Thrown when an optional dependency required for a feature is missing.
final class SmartImageMissingDependencyException extends SmartImageException {
  /// The name of the missing package or dependency.
  final String dependency;

  const SmartImageMissingDependencyException(
    super.message, {
    required this.dependency,
    super.cause,
    super.stackTrace,
  });
}

/// Thrown when a downloaded image exceeds the configured maximum byte size.
final class SmartImageSizeLimitExceededException extends SmartImageException {
  /// The actual number of bytes received (or declared in Content-Length).
  final int actualBytes;

  /// The maximum allowed byte limit.
  final int maxBytes;

  const SmartImageSizeLimitExceededException(
    super.message, {
    required this.actualBytes,
    required this.maxBytes,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() =>
      'SmartImageSizeLimitExceededException: $message (received: $actualBytes bytes, max: $maxBytes bytes)';
}

/// Thrown when a URL provided is malformed or has an invalid scheme.
final class SmartImageInvalidUrlException extends SmartImageException {
  /// The invalid URL string.
  final String url;

  const SmartImageInvalidUrlException(
    super.message, {
    required this.url,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() => 'SmartImageInvalidUrlException: $message (url: $url)';
}
