import 'package:flutter/material.dart';

import 'elements/actions.dart';
import 'elements/base.dart';
import 'elements/basics.dart';
import 'elements/input.dart';
import 'flutter_adaptive_cards.dart';

typedef ElementCreator = Widget Function(Map<String, dynamic> map);

class CardRegistry {
  const CardRegistry({
    this.removedElements = const <String>[],
    this.addedElements = const <String, ElementCreator>{},
    this.addedActions = const <String, ElementCreator>{},
  });

  final Map<String, ElementCreator> addedElements;
  final Map<String, ElementCreator> addedActions;
  final List<String> removedElements;

  Widget getElement(Map<String, dynamic> map) {
    final String stringType = map["type"] as String;

    if (removedElements.contains(stringType)) {
      return AdaptiveUnknown(type: stringType, adaptiveMap: map);
    }

    final ElementCreator? creator = addedElements[stringType];
    if (creator != null) {
      return creator(map);
    }
    return getBaseElement(map);
  }

  GenericAction getGenericAction(
      Map<String, dynamic> map,
      RawAdaptiveCardState state,
      ) {
    final String stringType = map["type"] as String;

    switch (stringType) {
      case "Action.ShowCard":
      // Only used by the root card; treat as an error here.
        throw StateError(
          "Action.ShowCard can only be used directly by the root card",
        );
      case "Action.OpenUrl":
        return GenericActionOpenUrl(map, state);
      case "Action.Submit":
        return GenericSubmitAction(map, state);
      case "Action.Execute":
      case "Execute":
        return GenericActionExecute(map, state);
      default:
        throw StateError("No action found with type $stringType");
    }
  }

  Widget getAction(Map<String, dynamic> map) {
    final String stringType = map["type"] as String;

    if (removedElements.contains(stringType)) {
      return AdaptiveUnknown(adaptiveMap: map, type: stringType);
    }

    final ElementCreator? creator = addedActions[stringType];
    if (creator != null) {
      return creator(map);
    }
    return _getBaseAction(map);
  }

  /// Returns the correct element widget from its `"type"`.
  Widget getBaseElement(Map<String, dynamic> map) {
    final String stringType = map["type"] as String;

    switch (stringType) {
      case "Media":
        return AdaptiveMedia(adaptiveMap: map);
      case "Container":
        return AdaptiveContainer(adaptiveMap: map);
      case "TextBlock":
        return AdaptiveTextBlock(adaptiveMap: map);
      case "AdaptiveCard":
        return AdaptiveCardElement(adaptiveMap: map);
      case "ColumnSet":
        return AdaptiveColumnSet(adaptiveMap: map);
      case "Image":
        return AdaptiveImage(adaptiveMap: map);
      case "FactSet":
        return AdaptiveFactSet(adaptiveMap: map);
      case "ImageSet":
        return AdaptiveImageSet(adaptiveMap: map);
      case "Input.Text":
        return AdaptiveTextInput(adaptiveMap: map);
      case "Input.Number":
        return AdaptiveNumberInput(adaptiveMap: map);
      case "Input.Date":
        return AdaptiveDateInput(adaptiveMap: map);
      case "Input.Time":
        return AdaptiveTimeInput(adaptiveMap: map);
      case "Input.Toggle":
        return AdaptiveToggle(adaptiveMap: map);
      case "Input.ChoiceSet":
        return AdaptiveChoiceSet(adaptiveMap: map);
      default:
        return AdaptiveUnknown(adaptiveMap: map, type: stringType);
    }
  }

  Widget _getBaseAction(Map<String, dynamic> map) {
    final String stringType = map["type"] as String;

    switch (stringType) {
      case "Action.ShowCard":
        return AdaptiveActionShowCard(
          key: UniqueKey(),
          adaptiveMap: map,
        );
      case "Action.OpenUrl":
        return AdaptiveActionOpenUrl(
          key: UniqueKey(),
          adaptiveMap: map,
        );
      case "Action.Submit":
        return AdaptiveActionSubmit(
          key: UniqueKey(),
          adaptiveMap: map,
          color: const Color(0xFF1B4F80), // adjust if your constructor differs
        );
      case "Action.Execute":
      case "Execute":
        return AdaptiveActionExecute(adaptiveMap: map);
      default:
        return AdaptiveUnknown(adaptiveMap: map, type: stringType);
    }
  }
}

class DefaultCardRegistry extends InheritedWidget {
  const DefaultCardRegistry({
    Key? key,
    required this.cardRegistry,
    required Widget child,
  }) : super(key: key, child: child);

  final CardRegistry cardRegistry;

  static CardRegistry of(BuildContext context) {
    final reg =
    context.dependOnInheritedWidgetOfExactType<DefaultCardRegistry>();
    assert(
    reg != null,
    'DefaultCardRegistry not found in the widget tree. '
        'Wrap your subtree with DefaultCardRegistry.',
    );
    return reg!.cardRegistry;
  }

  @override
  bool updateShouldNotify(covariant DefaultCardRegistry oldWidget) {
    return oldWidget.cardRegistry != cardRegistry;
    // If your registry is immutable (const), you could safely return false.
  }
}
