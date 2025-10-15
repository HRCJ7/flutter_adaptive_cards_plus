import 'package:flutter/material.dart';

import 'base.dart';

class SeparatorElement extends StatefulWidget with AdaptiveElementWidgetMixin {
  final Map adaptiveMap;
  final Widget child;

  SeparatorElement({required Key key, required this.adaptiveMap, required this.child}) : super(key: key);

  @override
  _SeparatorElementState createState() => _SeparatorElementState();
}

class _SeparatorElementState extends State<SeparatorElement>
    with AdaptiveElementMixin {
  late double topSpacing;
  late double bottomSpacing;
  late bool separator;

  @override
  void initState() {
    super.initState();
    topSpacing = resolver.resolveSpacing(adaptiveMap["spacing"]);
    bottomSpacing = resolver.resolveSpacing(adaptiveMap["bottomSpacing"]);
    separator = adaptiveMap["separator"] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        separator
            ? Divider(
                height: topSpacing,
              )
            : SizedBox(
                height: topSpacing,
              ),
        widget.child,
        SizedBox(
          height: bottomSpacing,
        ),
      ],
    );
  }
}

class AdaptiveTappable extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveTappable({required Key key, required this.child, required this.adaptiveMap}) : super(key: key);

  final Widget child;

  final Map adaptiveMap;

  @override
  _AdaptiveTappableState createState() => _AdaptiveTappableState();
}

class _AdaptiveTappableState extends State<AdaptiveTappable>
    with AdaptiveElementMixin {
  late GenericAction action;

  @override
  void initState() {
    super.initState();
    if (adaptiveMap.containsKey("selectAction")) {
      action = widgetState.cardRegistry
          .getGenericAction(adaptiveMap["selectAction"], widgetState);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: action.tap,
      child: widget.child,
    );
  }
}

class ChildStyler extends StatelessWidget {
  ChildStyler({
    Key? key,
    required this.child,
    required this.adaptiveMap,
  })  : _resolverKey = key ?? UniqueKey(), // stable for this instance
        super(key: key);

  final Widget child;
  final Map<String, dynamic> adaptiveMap;
  final Key _resolverKey;

  @override
  Widget build(BuildContext context) {
    return InheritedReferenceResolver(
      key: _resolverKey,
      resolver: InheritedReferenceResolver.of(context)
          .copyWith(style: adaptiveMap['style']),
      child: child,
    );
  }
}


