import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/elements/basics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/flutter_adaptive_cards.dart';

void main() {
  testWidgets('Basic types return', (tester) async {
    final cardRegistry = CardRegistry();

    final Widget adaptiveElement = cardRegistry.getElement({
      "type": "TextBlock",
      "text": "Adaptive Card design session",
      "size": "large",
      "weight": "bolder",
    });
    expect(adaptiveElement.runtimeType, equals(AdaptiveTextBlock));

    final Widget second = cardRegistry.getElement({
      "type": "Media",
      "poster":
      "https://docs.microsoft.com/en-us/adaptive-cards/content/videoposter.png",
      "sources": [
        {
          "mimeType": "video/mp4",
          "url":
          "https://adaptivecardsblob.blob.core.windows.net/assets/AdaptiveCardsOverviewVideo.mp4"
        }
      ],
    });
    expect(second.runtimeType, equals(AdaptiveMedia));
  });

  testWidgets('Unknown element', (tester) async {
    final cardRegistry = CardRegistry();

    final Widget adaptiveElement = cardRegistry.getElement({'type': "NoType"});
    expect(adaptiveElement.runtimeType, equals(AdaptiveUnknown));

    final AdaptiveUnknown unknown = adaptiveElement as AdaptiveUnknown;
    expect(unknown.type, equals('NoType'));
  });

  testWidgets('Removed element', (tester) async {
    final cardRegistry = CardRegistry(removedElements: const ['TextBlock']);

    final Widget adaptiveElement = cardRegistry.getElement({
      "type": "TextBlock",
      "text": "Adaptive Card design session",
      "size": "large",
      "weight": "bolder",
    });
    expect(adaptiveElement.runtimeType, equals(AdaptiveUnknown));

    final AdaptiveUnknown unknown = adaptiveElement as AdaptiveUnknown;
    expect(unknown.type, equals('TextBlock'));
  });

  testWidgets('Add element', (tester) async {
    final cardRegistry =
    CardRegistry(addedElements: {'Test': (map) => const _TestAddition()});

    final element = cardRegistry.getElement({'type': "Test"});
    expect(element.runtimeType, equals(_TestAddition));

    await tester.pumpWidget(element);
    expect(find.text('Test'), findsOneWidget);
  });
}

class _TestAddition extends StatelessWidget {
  const _TestAddition();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Test')),
      ),
    );
  }
}
