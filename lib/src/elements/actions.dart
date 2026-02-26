import 'package:flutter/material.dart';
import 'base.dart';
import 'basics.dart';

class IconButtonAction extends StatefulWidget with AdaptiveElementWidgetMixin {
  const IconButtonAction({
    Key? key,
    required this.adaptiveMap,
    required this.onTapped,
  }) : super(key: key);

  final Map<String, dynamic> adaptiveMap;
  final VoidCallback onTapped;

  @override
  _IconButtonActionState createState() => _IconButtonActionState();
}

class _IconButtonActionState extends State<IconButtonAction>
    with AdaptiveActionMixin, AdaptiveElementMixin {
  String? iconUrl;

  @override
  void initState() {
    super.initState();
    iconUrl = widget.adaptiveMap["iconUrl"] as String?;
  }

  @override
  Widget build(BuildContext context) {
    final hasIcon = (iconUrl != null && iconUrl!.isNotEmpty);

    if (hasIcon) {
      return ElevatedButton.icon(
        onPressed: onTapped,
        icon: Image.network(
          Uri.encodeFull(iconUrl!),
          height: 36.0,
          errorBuilder: (context, error, stackTrace) => const SizedBox(width: 0, height: 0),
        ),
        label: Text(title),
      );
    }
    return ElevatedButton(
      onPressed: onTapped,
      child: Text(title),
    );
  }

  @override
  void onTapped() => widget.onTapped();
}

class AdaptiveActionShowCard extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  const AdaptiveActionShowCard({
    Key? key,
    required this.adaptiveMap,
  }) : super(key: key);

  final Map<String, dynamic> adaptiveMap;

  @override
  _AdaptiveActionShowCardState createState() => _AdaptiveActionShowCardState();
}

class _AdaptiveActionShowCardState extends State<AdaptiveActionShowCard>
    with AdaptiveActionMixin, AdaptiveElementMixin {
  @override
  void initState() {
    super.initState();
    final Widget card =
    widgetState.cardRegistry.getElement(widget.adaptiveMap["card"]);
    final _adaptiveCardElement = AdaptiveCardElementState.of(context);
    _adaptiveCardElement.registerCard(id, card);
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTapped,
      child: Row(
        children: <Widget>[
          Text(title),
          AdaptiveCardElementState.of(context).currentCardId == id
              ? const Icon(Icons.keyboard_arrow_up)
              : const Icon(Icons.keyboard_arrow_down),
        ],
      ),
    );
  }

  @override
  void onTapped() {
    final _adaptiveCardElement = AdaptiveCardElementState.of(context);
    _adaptiveCardElement.showCard(id);
  }
}

class AdaptiveActionSubmit extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  const AdaptiveActionSubmit({
    Key? key,
    required this.adaptiveMap,
    required this.color,
  }) : super(key: key);

  final Map<String, dynamic> adaptiveMap;

  // Native styling
  final Color color;

  @override
  _AdaptiveActionSubmitState createState() => _AdaptiveActionSubmitState();
}

class _AdaptiveActionSubmitState extends State<AdaptiveActionSubmit>
    with AdaptiveActionMixin, AdaptiveElementMixin {
  late GenericSubmitAction action;

  @override
  void initState() {
    super.initState();
    action = GenericSubmitAction(widget.adaptiveMap, widgetState);
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1b4f80),
        foregroundColor: Colors.white, // text/icon color
      ),
      onPressed: onTapped,
      child: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  @override
  void onTapped() {
    action.tap();
  }
}

class AdaptiveActionOpenUrl extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  const AdaptiveActionOpenUrl({
    Key? key,
    required this.adaptiveMap,
  }) : super(key: key);

  final Map<String, dynamic> adaptiveMap;

  @override
  _AdaptiveActionOpenUrlState createState() => _AdaptiveActionOpenUrlState();
}

class _AdaptiveActionOpenUrlState extends State<AdaptiveActionOpenUrl>
    with AdaptiveActionMixin, AdaptiveElementMixin {
  late GenericActionOpenUrl action;
  String? iconUrl;

  @override
  void initState() {
    super.initState();
    action = GenericActionOpenUrl(widget.adaptiveMap, widgetState);
    iconUrl = widget.adaptiveMap["iconUrl"] as String?;
  }

  @override
  Widget build(BuildContext context) {
    return IconButtonAction(
      adaptiveMap: widget.adaptiveMap,
      onTapped: onTapped,
    );
  }

  @override
  void onTapped() {
    action.tap();
  }
}

// --- Execute button widget ---
class AdaptiveActionExecute extends StatefulWidget with AdaptiveElementWidgetMixin {
  const AdaptiveActionExecute({Key? key, required this.adaptiveMap}) : super(key: key);
  final Map<String, dynamic> adaptiveMap;

  @override
  _AdaptiveActionExecuteState createState() => _AdaptiveActionExecuteState();
}

class _AdaptiveActionExecuteState extends State<AdaptiveActionExecute> with AdaptiveElementMixin {
  @override
  Widget build(BuildContext context) {
    final title = (adaptiveMap["title"] as String?) ?? "Execute";
    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      child: ElevatedButton(
        onPressed: () {
          // Seed the submission with verb/data; RawAdaptiveCardState.submit()
          // will visit inputs and merge their values into this map.
          final payload = <String, dynamic>{};
          if (adaptiveMap["verb"] != null)  payload["verb"]  = adaptiveMap["verb"];
          if (adaptiveMap["data"] != null)  payload["data"]  = adaptiveMap["data"];
          widgetState.submit(payload);
        },
        child: Text(title),
      ),
    );
  }
}

