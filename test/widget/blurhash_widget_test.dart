import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_image/easy_image.dart';

void main() {
  group('BlurHash & Progressive Widget Tests', () {
    testWidgets('renders BlurHash decoded placeholder during loading',
        (tester) async {
      const validBlurHash = 'L6PZfSi_.AyE_3t7t7R**0o#DgR4';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EasyImage(
              url: 'https://example.com/unresponsive_image.png',
              blurHash: validBlurHash,
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      // Pump microtasks for async BlurHash decoding
      await tester.pump();

      expect(find.byType(EasyImageLoader), findsOneWidget);
    });

    testWidgets('transforms network URL using cdnTransform', (tester) async {
      String? requestedUrl;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EasyImage(
              url: 'https://cdn.example.com/image.jpg',
              width: 150,
              height: 150,
              config: EasyImageConfig(
                cdnTransform: (url, {width, height}) {
                  requestedUrl = '$url?w=$width&h=$height';
                  return requestedUrl!;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(requestedUrl, 'https://cdn.example.com/image.jpg?w=150&h=150');
    });
  });
}
