import 'dart:async';
import 'dart:math';
import '../errors/smart_image_exception.dart';
import '../models/smart_image_config.dart';

/// Handles retry attempts with exponential backoff and jitter.
class ImageRetryService {
  static final Random _random = Random();

  /// Calculates the backoff duration for a given attempt.
  static Duration calculateDelay({
    required int attempt,
    required Duration baseDelay,
    SmartImageRetryBackoff? customBackoff,
    Random? random,
  }) {
    if (customBackoff != null) {
      return customBackoff(attempt, baseDelay);
    }

    // Exponential backoff: baseDelay * 2^attempt
    final factor = pow(2, attempt).toDouble();
    final baseMillis = baseDelay.inMilliseconds * factor;

    // Apply ±25% jitter to prevent thundering herd / retry storm
    final rng = random ?? _random;
    final jitterFraction = (rng.nextDouble() * 0.5) - 0.25; // [-0.25, +0.25]
    final jitterMillis = (baseMillis * (1.0 + jitterFraction)).round();

    // Ensure delay is at least 0 ms
    final finalMillis = max(0, jitterMillis);
    return Duration(milliseconds: finalMillis);
  }

  /// Determines whether a given exception is eligible for retry.
  static bool shouldRetry(SmartImageException exception) {
    return switch (exception) {
      SmartImageNetworkException() => true,
      SmartImageTimeoutException() => true,
      SmartImageDecodeException() => false,
      SmartImageUnsupportedFormatException() => false,
      SmartImageUnsupportedPlatformException() => false,
      SmartImageMissingDependencyException() => false,
      SmartImageSizeLimitExceededException() => false,
      SmartImageInvalidUrlException() => false,
    };
  }

  /// Executes an asynchronous operation with retry logic and cancellation support.
  static Future<T> retry<T>({
    required Future<T> Function() operation,
    required int retryCount,
    required Duration baseDelay,
    SmartImageRetryBackoff? customBackoff,
    bool Function()? isCancelled,
    void Function(SmartImageException error, int attempt, Duration nextDelay)?
        onRetry,
  }) async {
    int attempts = 0;

    while (true) {
      if (isCancelled?.call() == true) {
        throw const SmartImageTimeoutException('Operation cancelled.');
      }

      try {
        return await operation();
      } on SmartImageException catch (e) {
        if (!shouldRetry(e) || attempts >= retryCount) {
          rethrow;
        }

        attempts++;
        final delay = calculateDelay(
          attempt: attempts - 1,
          baseDelay: baseDelay,
          customBackoff: customBackoff,
        );

        onRetry?.call(e, attempts, delay);

        if (delay > Duration.zero) {
          await Future<void>.delayed(delay);
        }

        if (isCancelled?.call() == true) {
          throw const SmartImageTimeoutException(
              'Operation cancelled during retry wait.');
        }
      } catch (e, st) {
        final wrapped = SmartImageNetworkException(
          'Unexpected error during image fetch: $e',
          cause: e,
          stackTrace: st,
        );
        if (attempts >= retryCount) {
          throw wrapped;
        }
        attempts++;
        final delay = calculateDelay(
          attempt: attempts - 1,
          baseDelay: baseDelay,
          customBackoff: customBackoff,
        );
        onRetry?.call(wrapped, attempts, delay);
        if (delay > Duration.zero) {
          await Future<void>.delayed(delay);
        }
      }
    }
  }
}
