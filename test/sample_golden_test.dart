import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_utils.dart';

Widget getSampleForGoldenTest(Key key, String sampleName) {
  final Widget sample = getWidthDefaultHostConfig(sampleName);

  return MaterialApp(
    home: RepaintBoundary(
      key: key,
      child: Scaffold(
        appBar: AppBar(),
        body: Center(child: sample),
      ),
    ),
  );
}

void main() {
  // Deliver actual images + fonts
  setUp(() async {
    HttpOverrides.global = MyTestHttpOverrides();
    WidgetsBinding.instance.renderView.configuration =
    TestViewConfiguration(size: Size(500, 700));

    Future<ByteData> _font(String path) async {
      final bytes = await File(path).readAsBytes();
      return ByteData.view(Uint8List.fromList(bytes).buffer);
    }

    final fontLoader = FontLoader('Roboto')
      ..addFont(_font('assets/fonts/Roboto/Roboto-Regular.ttf'))
      ..addFont(_font('assets/fonts/Roboto/Roboto-Bold.ttf'))
      ..addFont(_font('assets/fonts/Roboto/Roboto-Light.ttf'))
      ..addFont(_font('assets/fonts/Roboto/Roboto-Medium.ttf'))
      ..addFont(_font('assets/fonts/Roboto/Roboto-Thin.ttf'));
    await fontLoader.load();
  });

  testWidgets('Golden Sample 1', (tester) async {
    const key = ValueKey('paint');
    final sample1 = getSampleForGoldenTest(key, 'example1');

    await tester.pumpWidget(sample1);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/sample1-base.png'),
    );

    expect(find.widgetWithText(ElevatedButton, 'Set due date'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Set due date'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/sample1_set_due_date.png'),
    );

    // Date/time picker actions are TextButtons in Material
    expect(find.widgetWithText(TextButton, 'OK'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Comment'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/sample1_comment.png'),
    );
  });

  testWidgets('Golden Sample 2', (tester) async {
    const key = ValueKey('paint');
    final sample1 = getSampleForGoldenTest(key, 'example2');

    await tester.pumpWidget(sample1);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/sample2-base.png'),
    );

    expect(find.widgetWithText(ElevatedButton, "I'll be late"), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, "I'll be late"));
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/sample2_ill_be_late.png'),
    );

    expect(find.widgetWithText(ElevatedButton, 'Snooze'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Snooze'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/sample2_snooze.png'),
    );
  });

  testWidgets('Golden Sample 3', (tester) async {
    const key = ValueKey('paint');
    final sample1 = getSampleForGoldenTest(key, 'example3');

    await tester.pumpWidget(sample1);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/sample3-base.png'),
    );
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Golden Sample 4', (tester) async {
    const key = ValueKey('paint');
    final sample1 = getSampleForGoldenTest(key, 'example4');

    await tester.pumpWidget(sample1);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/sample4-base.png'),
    );
  });

  testWidgets('Golden Sample 5', (tester) async {
    const key = ValueKey('paint');
    final sample1 = getSampleForGoldenTest(key, 'example5');

    await tester.pumpWidget(sample1);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/sample5-base.png'),
    );

    expect(find.widgetWithText(ElevatedButton, 'Steak'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Chicken'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Tofu'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Steak'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/sample5-steak.png'),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Chicken'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/sample5-chicken.png'),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Tofu'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/sample5-tofu.png'),
    );
  });

  testWidgets('Golden Sample 14', (tester) async {
    const key = ValueKey('paint');
    final sample1 = getSampleForGoldenTest(key, 'example14');

    await tester.pumpWidget(sample1);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/sample14-base.png'),
    );

    await tester.pump(const Duration(seconds: 1));
  });
}
