import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'utils/test_utils.dart';

void main() {
  // Deliver actual images
  setUp(() {
    HttpOverrides.global = MyTestHttpOverrides();
  });

  for (int i = 1; i <= 15; i++) {
    final idx = i; // snapshot the index for this test

    testWidgets('sample$idx smoke test', (tester) async {
      Widget widget = getWidget('example$idx', 'host_config');

      // This one's pretty big; wrap it in a scrollable
      if (idx == 8) {
        widget = SingleChildScrollView(
          child: IntrinsicHeight(child: widget),
        );
      }

      await tester.pumpWidget(widget);

      // Advance fake time so any initial animations/timers complete
      await tester.pumpAndSettle(const Duration(seconds: 10));
      // If your UI never "settles", use a plain timed pump instead:
      // await tester.pump(const Duration(seconds: 10));
    });
  }
}
