import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../flutter_adaptive_cards.dart';

class InheritedReferenceResolver extends StatelessWidget {
  final Widget child;
  final ReferenceResolver resolver;

  const InheritedReferenceResolver({required Key key, required this.resolver, required this.child})
      : super(key: key);

  static ReferenceResolver of(BuildContext context) {
    return Provider.of<ReferenceResolver>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Provider<ReferenceResolver>.value(value: resolver, child: child);
  }
}

mixin AdaptiveElementWidgetMixin on StatefulWidget {
  Map get adaptiveMap;
}

mixin AdaptiveElementMixin<T extends AdaptiveElementWidgetMixin> on State<T> {
  late String id;

  late RawAdaptiveCardState widgetState;

  Map get adaptiveMap => widget.adaptiveMap;

  ReferenceResolver get resolver => InheritedReferenceResolver.of(context);

  @override
  void initState() {
    super.initState();

    widgetState = Provider.of<RawAdaptiveCardState>(context, listen: false);
    if (widget.adaptiveMap.containsKey("id")) {
      id = widget.adaptiveMap["id"];
    } else {
      id = widgetState.idGenerator.getId();
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdaptiveElementMixin &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

mixin AdaptiveActionMixin<T extends AdaptiveElementWidgetMixin> on State<T>
    implements AdaptiveElementMixin<T> {
  String get title => widget.adaptiveMap["title"];

  void onTapped();
}

mixin AdaptiveInputMixin<T extends AdaptiveElementWidgetMixin> on State<T>
    implements AdaptiveElementMixin<T> {
  late String value;

  @override
  void initState() {
    super.initState();
    value = adaptiveMap["value"].toString() == "null"
        ? ""
        : adaptiveMap["value"].toString();
  }

  void appendInput(Map map);
}

mixin AdaptiveTextualInputMixin<T extends AdaptiveElementWidgetMixin>
    on State<T> implements AdaptiveInputMixin<T> {
  late String placeholder;

  @override
  void initState() {
    super.initState();

    placeholder = widget.adaptiveMap["placeholder"] ?? "";
  }
}

abstract class GenericAction {
  GenericAction(this.adaptiveMap, this.rawAdaptiveCardState);

  String get title => adaptiveMap["title"];
  final Map adaptiveMap;
  final RawAdaptiveCardState rawAdaptiveCardState;

  void tap();
}

class GenericSubmitAction extends GenericAction {
  GenericSubmitAction(
      Map<String, dynamic> adaptiveMap,
      RawAdaptiveCardState rawAdaptiveCardState,
      ) : data = (adaptiveMap['data'] as Map?)
      ?.cast<String, dynamic>() ??
      const <String, dynamic>{},
        super(adaptiveMap, rawAdaptiveCardState);

  final Map<String, dynamic> data;

  @override
  void tap() {
    rawAdaptiveCardState.submit(data);
  }
}

class GenericActionOpenUrl extends GenericAction {
  GenericActionOpenUrl(
      Map<String, dynamic> adaptiveMap,
      RawAdaptiveCardState rawAdaptiveCardState,
      ) : url = (adaptiveMap['url'] as String?)?.trim() ?? '',
        super(adaptiveMap, rawAdaptiveCardState);

  final String url;

  @override
  void tap() {
    if (url.isEmpty) return; // or handle error/log
    rawAdaptiveCardState.openUrl(url);
  }
}

class GenericActionExecute extends GenericAction {
  GenericActionExecute(
      Map<String, dynamic> adaptiveMap,
      RawAdaptiveCardState rawAdaptiveCardState,
      )   : verb = (adaptiveMap['verb'] as String?)?.trim() ?? '',
        data = (adaptiveMap['data'] as Map?)
            ?.cast<String, dynamic>() ??
            const <String, dynamic>{},
        super(adaptiveMap, rawAdaptiveCardState);

  /// Execute verb, e.g. "vote"
  final String verb;

  /// Extra data to send with the action
  final Map<String, dynamic> data;

  @override
  void tap() {
    // Build the payload expected by Action.Execute handlers.
    final payload = <String, dynamic>{};
    if (verb.isNotEmpty) payload['verb'] = verb;
    if (data.isNotEmpty) payload['data'] = Map<String, dynamic>.from(data);

    // Let the card collect inputs (if any) and submit the final map.
    rawAdaptiveCardState.submit(payload);
  }
}




