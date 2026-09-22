import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_image/easy_image.dart';

final Uint8List kTestPng1 = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

void main() {
  group('Cancellation & Lifecycle Tests', () {
    testWidgets('cancels in-flight load on widget disposal without crashing',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EasyImage(
              url: 'https://example.com/slow_response.png',
              shimmer: true,
            ),
          ),
        ),
      );

      // Verify widget mounted and loading
      expect(find.byType(EasyImage), findsOneWidget);

      // Immediately unmount/replace widget while request is pending
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(EasyImage), findsNothing);
      // No unhandled exceptions or setState after dispose
    });

    testWidgets('rapid url changes cancel previous request and load latest',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EasyImage(
              url: 'https://example.com/image1.png',
            ),
          ),
        ),
      );

      // Switch URL to direct bytes
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EasyImage(
              bytes: kTestPng1,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
    });
  });
}
