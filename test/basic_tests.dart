import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'utils/test_utils.dart';

void main() {
  // Deliver actual images
  setUp(() {
    HttpOverrides.global = MyTestHttpOverrides();
  });

  testWidgets('Activity Update test', (tester) async {
    // no addTime
    final widget = getWidthDefaultHostConfig('example1');
    await tester.pumpWidget(widget);

    // advance fake time (animations, timers) as needed
    await tester.pump(const Duration(seconds: 10));

    // At the top and at "assigned to:"
    expect(find.text('Matt Hidinger'), findsNWidgets(2));

    expect(
      find.text(
        'Now that we have defined the main rules and features of'
            ' the format, we need to produce a schema and publish it to GitHub. '
            'The schema will be the starting point of our reference documentation.',
      ),
      findsOneWidget,
    );

    expect(find.byType(Image), findsOneWidget);

    // Two action buttons: "Set due date" and "Comment"
    expect(find.byType(ElevatedButton), findsNWidgets(2));
    expect(find.widgetWithText(ElevatedButton, 'Set due date'), findsOneWidget);

    // Open the date picker and expect an OK button (TextButton in Material)
    await tester.tap(find.widgetWithText(ElevatedButton, 'Set due date'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextButton, 'OK'), findsOneWidget);

    final Widget firstOk =
    tester.firstWidget(find.widgetWithText(TextButton, 'OK'));

    // Tap "Comment" and ensure an OK button still exists but is a new instance
    await tester.tap(find.widgetWithText(ElevatedButton, 'Comment'));
    await tester.pumpAndSettle();

    // You may still have only two ElevatedButtons (actions on the card).
    // The OK belongs to a dialog/sheet and is a TextButton.
    expect(find.widgetWithText(TextButton, 'OK'), findsOneWidget);

    // The prior OK should not be the same widget instance anymore.
    expect(find.byWidget(firstOk), findsNothing);
  });
}
