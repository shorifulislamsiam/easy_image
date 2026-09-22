import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_image/easy_image.dart';

// Minimal 1x1 transparent PNG bytes for testing
final Uint8List kTestPngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

void main() {
  setUp(() {
    ImageDownloadQueue.shared.clearQueue();
  });

  tearDown(() {
    ImageDownloadQueue.shared.clearQueue();
  });

  group('EasyImage Widget Tests', () {
    testWidgets('renders placeholder when loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EasyImage(
              url: 'https://example.com/unresponsive.png',
              placeholder: const Text('Custom Loading...'),
            ),
          ),
        ),
      );

      expect(find.text('Custom Loading...'), findsOneWidget);
    });

    testWidgets('renders shimmer loader when shimmer is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EasyImage(
              url: 'https://example.com/image.png',
              shimmer: true,
            ),
          ),
        ),
      );

      expect(find.byType(EasyImageShimmer), findsOneWidget);
    });

    testWidgets('renders static container when disableAnimations is true',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: EasyImage(
                url: 'https://example.com/image.png',
                shimmer: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(EasyImageShimmer), findsOneWidget);
      // Under disableAnimations, AnimatedBuilder inside shimmer does not animate
    });

    testWidgets('renders custom error widget on invalid url', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EasyImage(
              url: 'ftp://bad-url.png',
              retryCount: 0,
              errorWidget: const Text('Failed to load'),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text('Failed to load'), findsOneWidget);
    });

    testWidgets('renders default error UI with retry button', (tester) async {
      bool retryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EasyImage(
              url: '',
              width: 100,
              height: 100,
              onRetry: () {
                retryPressed = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retryPressed, isTrue);
    });

    testWidgets('renders memory bytes image and triggers onLoadComplete',
        (tester) async {
      EasyImageLoadInfo? completedInfo;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EasyImage(
              bytes: kTestPngBytes,
              config: EasyImageConfig(
                onLoadComplete: (info) {
                  completedInfo = info;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(completedInfo, isNotNull);
      expect(completedInfo!.cacheSource, EasyImageCacheSource.memory);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('applies circular clipping for EasyImage.circle',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EasyImage.circle(
              bytes: kTestPngBytes,
              radius: 40,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(ClipOval), findsOneWidget);
    });

    testWidgets('renders semantics with semanticLabel', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EasyImage(
              bytes: kTestPngBytes,
              semanticLabel: 'User avatar thumbnail',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'User avatar thumbnail',
        ),
        findsOneWidget,
      );
    });
  });
}
