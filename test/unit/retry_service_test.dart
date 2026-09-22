import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_image/src/errors/smart_image_exception.dart';
import 'package:easy_image/src/services/image_retry_service.dart';

void main() {
  group('ImageRetryService', () {
    test('calculates exponential delay with jitter bounds', () {
      final baseDelay = const Duration(seconds: 1);

      // Deterministic Random returning 0.0 -> jitter is -25%
      final rngMin = _MockRandom(0.0);
      final delayMin = ImageRetryService.calculateDelay(
        attempt: 0,
        baseDelay: baseDelay,
        random: rngMin,
      );
      expect(delayMin.inMilliseconds, 750); // 1000 * (1 - 0.25)

      // Deterministic Random returning 1.0 -> jitter is +25%
      final rngMax = _MockRandom(1.0);
      final delayMax = ImageRetryService.calculateDelay(
        attempt: 0,
        baseDelay: baseDelay,
        random: rngMax,
      );
      expect(delayMax.inMilliseconds, 1250); // 1000 * (1 + 0.25)

      // Attempt 2 (factor 4)
      final delayAttempt2 = ImageRetryService.calculateDelay(
        attempt: 2,
        baseDelay: baseDelay,
        random: _MockRandom(0.5), // jitter is 0%
      );
      expect(delayAttempt2.inMilliseconds, 4000);
    });

    test('supports custom backoff strategy override', () {
      final delay = ImageRetryService.calculateDelay(
        attempt: 3,
        baseDelay: const Duration(seconds: 1),
        customBackoff: (attempt, base) => Duration(seconds: attempt * 5),
      );
      expect(delay, const Duration(seconds: 15));
    });

    test('shouldRetry returns true for network and timeout errors only', () {
      expect(
        ImageRetryService.shouldRetry(
          const SmartImageNetworkException('500 Server Error'),
        ),
        isTrue,
      );
      expect(
        ImageRetryService.shouldRetry(
          const SmartImageTimeoutException('Timeout'),
        ),
        isTrue,
      );
      expect(
        ImageRetryService.shouldRetry(
          const SmartImageDecodeException('Corrupt bytes'),
        ),
        isFalse,
      );
      expect(
        ImageRetryService.shouldRetry(
          const SmartImageUnsupportedFormatException('tiff'),
        ),
        isFalse,
      );
      expect(
        ImageRetryService.shouldRetry(
          const SmartImageSizeLimitExceededException(
            'Too big',
            actualBytes: 100,
            maxBytes: 50,
          ),
        ),
        isFalse,
      );
    });

    test('retries up to retryCount and succeeds', () async {
      int attempts = 0;
      final result = await ImageRetryService.retry<String>(
        retryCount: 3,
        baseDelay: const Duration(milliseconds: 10),
        operation: () async {
          attempts++;
          if (attempts < 3) {
            throw const SmartImageNetworkException('Temporary network drop');
          }
          return 'success!';
        },
      );
      expect(result, 'success!');
      expect(attempts, 3);
    });

    test('throws when retries are exhausted', () async {
      int attempts = 0;
      await expectLater(
        () => ImageRetryService.retry<String>(
          retryCount: 2,
          baseDelay: const Duration(milliseconds: 10),
          operation: () async {
            attempts++;
            throw const SmartImageNetworkException('Persistent error');
          },
        ),
        throwsA(isA<SmartImageNetworkException>()),
      );
      expect(attempts, 3); // initial attempt + 2 retries
    });
  });
}

class _MockRandom implements Random {
  final double value;
  _MockRandom(this.value);

  @override
  double nextDouble() => value;

  @override
  bool nextBool() => true;

  @override
  int nextInt(int max) => 0;
}
