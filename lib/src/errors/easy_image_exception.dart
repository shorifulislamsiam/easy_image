import 'package:flutter/foundation.dart';

/// Base sealed class for all exceptions thrown by the EasyImage package.
@immutable
sealed class EasyImageException implements Exception {
  /// A human-readable description of the error.
  final String message;

  /// The underlying cause or exception, if any.
  final Object? cause;

  /// The stack trace associated with the error, if any.
  final StackTrace? stackTrace;

  const EasyImageException(this.message, {this.cause, this.stackTrace});

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when a network request fails (e.g. non-2xx status code or connection failure).
final class EasyImageNetworkException extends EasyImageException {
  /// The HTTP status code, if available.
  final int? statusCode;

  /// The URL that failed.
  final String? url;

  const EasyImageNetworkException(
    super.message, {
    this.statusCode,
    this.url,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() =>
      'EasyImageNetworkException: $message (status: $statusCode, url: $url)';
}

/// Thrown when an image download or processing operation times out.
final class EasyImageTimeoutException extends EasyImageException {
  /// The duration that was exceeded.
  final Duration? timeout;

  const EasyImageTimeoutException(
    super.message, {
    this.timeout,
    super.cause,
    super.stackTrace,
  });
}

/// Thrown when image bytes fail to decode or are corrupted.
final class EasyImageDecodeException extends EasyImageException {
  const EasyImageDecodeException(
    super.message, {
    super.cause,
    super.stackTrace,
  });
}

/// Thrown when an image format is unsupported or cannot be recognized.
final class EasyImageUnsupportedFormatException extends EasyImageException {
  /// The detected or declared format string (e.g. "image/tiff").
  final String? format;

  const EasyImageUnsupportedFormatException(
    super.message, {
    this.format,
    super.cause,
    super.stackTrace,
  });
}

/// Thrown when an operation is attempted on an unsupported platform
/// (e.g. using `File` or native compression on Flutter Web).
final class EasyImageUnsupportedPlatformException extends EasyImageException {
  /// The name of the platform where the operation failed.
  final String platform;

  const EasyImageUnsupportedPlatformException(
    super.message, {
    required this.platform,
    super.cause,
    super.stackTrace,
  });
}

/// Thrown when an optional dependency required for a feature is missing.
final class EasyImageMissingDependencyException extends EasyImageException {
  /// The name of the missing package or dependency.
  final String dependency;

  const EasyImageMissingDependencyException(
    super.message, {
    required this.dependency,
    super.cause,
    super.stackTrace,
  });
}

/// Thrown when a downloaded image exceeds the configured maximum byte size.
final class EasyImageSizeLimitExceededException extends EasyImageException {
  /// The actual number of bytes received (or declared in Content-Length).
  final int actualBytes;

  /// The maximum allowed byte limit.
  final int maxBytes;

  const EasyImageSizeLimitExceededException(
    super.message, {
    required this.actualBytes,
    required this.maxBytes,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() =>
      'EasyImageSizeLimitExceededException: $message (received: $actualBytes bytes, max: $maxBytes bytes)';
}

/// Thrown when a URL provided is malformed or has an invalid scheme.
final class EasyImageInvalidUrlException extends EasyImageException {
  /// The invalid URL string.
  final String url;

  const EasyImageInvalidUrlException(
    super.message, {
    required this.url,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() => 'EasyImageInvalidUrlException: $message (url: $url)';
}

// Backwards compatibility aliases
typedef SmartImageException = EasyImageException;
typedef SmartImageNetworkException = EasyImageNetworkException;
typedef SmartImageTimeoutException = EasyImageTimeoutException;
typedef SmartImageDecodeException = EasyImageDecodeException;
typedef SmartImageUnsupportedFormatException = EasyImageUnsupportedFormatException;
typedef SmartImageUnsupportedPlatformException = EasyImageUnsupportedPlatformException;
typedef SmartImageMissingDependencyException = EasyImageMissingDependencyException;
typedef SmartImageSizeLimitExceededException = EasyImageSizeLimitExceededException;
typedef SmartImageInvalidUrlException = EasyImageInvalidUrlException;
