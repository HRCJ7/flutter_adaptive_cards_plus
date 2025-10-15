import 'package:flutter/material.dart';

class DefaultAdaptiveCardHandlers extends InheritedWidget {
  const DefaultAdaptiveCardHandlers({
    Key? key,
    required this.onSubmit,
    required this.onOpenUrl,
    required Widget child,
  }) : super(key: key, child: child);

  /// Called when an Adaptive Card submits a payload.
  final void Function(Map<String, dynamic> map) onSubmit;

  /// Called when an Adaptive Card requests to open a URL.
  final void Function(String url) onOpenUrl;

  /// Obtain the nearest handlers in the widget tree.
  static DefaultAdaptiveCardHandlers of(BuildContext context) {
    final handlers = context
        .dependOnInheritedWidgetOfExactType<DefaultAdaptiveCardHandlers>();
    assert(
    handlers != null,
    'DefaultAdaptiveCardHandlers not found in context. '
        'Wrap your subtree with DefaultAdaptiveCardHandlers.',
    );
    return handlers!;
  }

  @override
  bool updateShouldNotify(covariant DefaultAdaptiveCardHandlers oldWidget) {
    // Notify dependents only if the callbacks change.
    return oldWidget.onSubmit != onSubmit || oldWidget.onOpenUrl != onOpenUrl;
  }
}
