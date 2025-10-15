import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'base.dart';

/// ===== Separator / Tappable / Styler helpers =====

class SeparatorElement extends StatefulWidget with AdaptiveElementWidgetMixin {
  const SeparatorElement({
    Key? key,
    required this.adaptiveMap,
    required this.child,
  }) : super(key: key);

  final Map adaptiveMap;
  final Widget child;

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
        separator ? Divider(height: topSpacing) : SizedBox(height: topSpacing),
        widget.child,
        SizedBox(height: bottomSpacing),
      ],
    );
  }
}

class AdaptiveTappable extends StatefulWidget with AdaptiveElementWidgetMixin {
  const AdaptiveTappable({
    Key? key,
    required this.child,
    required this.adaptiveMap,
  }) : super(key: key);

  final Widget child;
  final Map adaptiveMap;

  @override
  _AdaptiveTappableState createState() => _AdaptiveTappableState();
}

class _AdaptiveTappableState extends State<AdaptiveTappable>
    with AdaptiveElementMixin {
  GenericAction? action;

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
      onTap: action?.tap,
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

/// ======================= AdaptiveTextInput =======================

class AdaptiveTextInput extends StatefulWidget with AdaptiveElementWidgetMixin {
  const AdaptiveTextInput({
    Key? key,
    required this.adaptiveMap,
  }) : super(key: key);

  final Map<String, dynamic> adaptiveMap;

  @override
  _AdaptiveTextInputState createState() => _AdaptiveTextInputState();
}

class _AdaptiveTextInputState extends State<AdaptiveTextInput>
    with AdaptiveTextualInputMixin, AdaptiveInputMixin, AdaptiveElementMixin {
  final TextEditingController controller = TextEditingController();
  late bool isMultiline;
  int? maxLength;
  late TextInputType keyboardType;

  @override
  void initState() {
    super.initState();
    isMultiline = adaptiveMap["isMultiline"] as bool? ?? false;
    maxLength = adaptiveMap["maxLength"] as int?;
    keyboardType = _loadTextInputType();
    controller.text = value;
  }

  @override
  Widget build(BuildContext context) {
    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      child: TextField(
        controller: controller,
        maxLength: maxLength,
        keyboardType: keyboardType,
        maxLines: isMultiline ? null : 1,
        decoration: InputDecoration(labelText: placeholder),
      ),
    );
  }

  @override
  void appendInput(Map map) {
    map[id] = controller.text;
  }

  TextInputType _loadTextInputType() {
    final String styleStr = adaptiveMap["style"] as String? ?? "text";
    switch (styleStr) {
      case "tel":
        return TextInputType.phone;
      case "url":
        return TextInputType.url;
      case "email":
        return TextInputType.emailAddress;
      case "text":
      default:
        return TextInputType.text;
    }
  }
}

/// ======================= AdaptiveNumberInput =======================

class AdaptiveNumberInput extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  const AdaptiveNumberInput({
    Key? key,
    required this.adaptiveMap,
  }) : super(key: key);

  final Map<String, dynamic> adaptiveMap;

  @override
  _AdaptiveNumberInputState createState() => _AdaptiveNumberInputState();
}

class _AdaptiveNumberInputState extends State<AdaptiveNumberInput>
    with AdaptiveTextualInputMixin, AdaptiveInputMixin, AdaptiveElementMixin {
  final TextEditingController controller = TextEditingController();

  int? min;
  int? max;

  @override
  void initState() {
    super.initState();
    controller.text = value;
    final m = adaptiveMap["min"];
    final x = adaptiveMap["max"];
    min = (m is num) ? m.toInt() : int.tryParse(m?.toString() ?? "");
    max = (x is num) ? x.toInt() : int.tryParse(x?.toString() ?? "");
  }

  @override
  Widget build(BuildContext context) {
    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      child: TextField(
        keyboardType: TextInputType.number,
        inputFormatters: [
          TextInputFormatter.withFunction((oldVal, newVal) {
            if (newVal.text.isEmpty) return newVal;
            final int? newNumber = int.tryParse(newVal.text);
            if (newNumber == null) return oldVal;

            final bool aboveMin = (min == null) || newNumber >= min!;
            final bool belowMax = (max == null) || newNumber <= max!;
            return (aboveMin && belowMax) ? newVal : oldVal;
          }),
        ],
        controller: controller,
        decoration: InputDecoration(labelText: placeholder),
      ),
    );
  }

  @override
  void appendInput(Map map) {
    map[id] = controller.text;
  }
}

/// ======================= AdaptiveDateInput =======================

class AdaptiveDateInput extends StatefulWidget with AdaptiveElementWidgetMixin {
  const AdaptiveDateInput({
    Key? key,
    required this.adaptiveMap,
  }) : super(key: key);

  final Map<String, dynamic> adaptiveMap;

  @override
  _AdaptiveDateInputState createState() => _AdaptiveDateInputState();
}

class _AdaptiveDateInputState extends State<AdaptiveDateInput>
    with AdaptiveTextualInputMixin, AdaptiveElementMixin, AdaptiveInputMixin {
  DateTime? selectedDateTime;
  DateTime? min;
  DateTime? max;

  @override
  void initState() {
    super.initState();
    try {
      selectedDateTime = DateTime.tryParse(value);
      min = (adaptiveMap["min"] as String?) != null
          ? DateTime.tryParse(adaptiveMap["min"] as String)
          : null;
      max = (adaptiveMap["max"] as String?) != null
          ? DateTime.tryParse(adaptiveMap["max"] as String)
          : null;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final String label =
        selectedDateTime?.toIso8601String() ?? placeholder; // avoid ?? "Pick date" (placeholder likely non-null)

    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      child: ElevatedButton(
        onPressed: () async {
          // pickDate expects non-null DateTime bounds; provide sensible defaults
          final DateTime lower =
              min ?? DateTime(1900, 1, 1);
          final DateTime upper =
              max ?? DateTime(2100, 12, 31);

          final DateTime? picked = await widgetState.pickDate(lower, upper);
          if (picked != null) {
            setState(() => selectedDateTime = picked);
          }
        },
        child: Text(label),
      ),
    );
  }

  @override
  void appendInput(Map map) {
    if (selectedDateTime != null) {
      map[id] = selectedDateTime!.toIso8601String();
    }
  }
}

/// ======================= AdaptiveTimeInput =======================

class AdaptiveTimeInput extends StatefulWidget with AdaptiveElementWidgetMixin {
  const AdaptiveTimeInput({
    Key? key,
    required this.adaptiveMap,
  }) : super(key: key);

  final Map<String, dynamic> adaptiveMap;

  @override
  _AdaptiveTimeInputState createState() => _AdaptiveTimeInputState();
}

class _AdaptiveTimeInputState extends State<AdaptiveTimeInput>
    with AdaptiveTextualInputMixin, AdaptiveElementMixin, AdaptiveInputMixin {
  late TimeOfDay selectedTime;
  late TimeOfDay min;
  late TimeOfDay max;

  @override
  void initState() {
    super.initState();

    selectedTime =
        _parseTime(value) ?? TimeOfDay.now();
    min = _parseTime(adaptiveMap["min"] as String?) ??
        const TimeOfDay(hour: 0, minute: 0);
    max = _parseTime(adaptiveMap["max"] as String?) ??
        const TimeOfDay(hour: 23, minute: 59);
  }

  TimeOfDay? _parseTime(String? time) {
    if (time == null || time.isEmpty) return null;
    final parts = time.split(":");
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  bool _withinRange(TimeOfDay t) {
    if (t.hour < min.hour) return false;
    if (t.hour > max.hour) return false;
    if (t.hour == min.hour && t.minute < min.minute) return false;
    if (t.hour == max.hour && t.minute > max.minute) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      child: ElevatedButton(
        onPressed: () async {
          final TimeOfDay? result = await widgetState.pickTime();
          if (result == null) return;
          if (!_withinRange(result)) {
            widgetState.showError(
              "Time must be between ${min.format(widgetState.context)} and ${max.format(widgetState.context)}",
            );
            return;
          }
          setState(() {
            selectedTime = result;
          });
        },
        child: Text(selectedTime.format(widgetState.context)),
      ),
    );
  }

  @override
  void appendInput(Map map) {
    map[id] = selectedTime.format(widgetState.context);
  }
}

/// ======================= AdaptiveToggle =======================

class AdaptiveToggle extends StatefulWidget with AdaptiveElementWidgetMixin {
  const AdaptiveToggle({
    Key? key,
    required this.adaptiveMap,
  }) : super(key: key);

  final Map<String, dynamic> adaptiveMap;

  @override
  _AdaptiveToggleState createState() => _AdaptiveToggleState();
}

class _AdaptiveToggleState extends State<AdaptiveToggle>
    with AdaptiveInputMixin, AdaptiveElementMixin {
  bool boolValue = false;

  late String valueOff;
  late String valueOn;
  late String title;

  @override
  void initState() {
    super.initState();
    valueOff = adaptiveMap["valueOff"] as String? ?? "false";
    valueOn = adaptiveMap["valueOn"] as String? ?? "true";
    boolValue = value == valueOn;
    title = adaptiveMap["title"] as String? ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      child: Row(
        children: <Widget>[
          Switch(
            value: boolValue,
            onChanged: (newValue) => setState(() => boolValue = newValue),
          ),
          Expanded(child: Text(title)),
        ],
      ),
    );
  }

  @override
  void appendInput(Map map) {
    map[id] = boolValue ? valueOn : valueOff;
  }
}

/// ======================= AdaptiveChoiceSet =======================

class AdaptiveChoiceSet extends StatefulWidget with AdaptiveElementWidgetMixin {
  const AdaptiveChoiceSet({
    Key? key,
    required this.adaptiveMap,
  }) : super(key: key);

  final Map<String, dynamic> adaptiveMap;

  @override
  _AdaptiveChoiceSetState createState() => _AdaptiveChoiceSetState();
}

class _AdaptiveChoiceSetState extends State<AdaptiveChoiceSet>
    with AdaptiveInputMixin, AdaptiveElementMixin {
  // Map from title to value
  final Map<String, String> choices = <String, String>{};
  // Contains the values (the things to send as request)
  final Set<String> _selectedChoice = <String>{};

  late bool isCompact;
  late bool isMultiSelect;

  @override
  void initState() {
    super.initState();
    for (final Map m in (adaptiveMap["choices"] as List? ?? const <Map>[])) {
      final map = m.cast<String, dynamic>();
      choices[map["title"] as String] = (map["value"]).toString();
    }
    isCompact = _loadCompact();
    isMultiSelect = adaptiveMap["isMultiSelect"] as bool? ?? false;
    final seed = (value).toString();
    if (seed.isNotEmpty) {
      _selectedChoice.addAll(seed.split(",").where((e) => e.isNotEmpty));
    }
  }

  @override
  void appendInput(Map map) {
    map[id] = _selectedChoice;
  }

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (isCompact) {
      content = isMultiSelect ? _buildExpandedMultiSelect() : _buildCompact();
    } else {
      content =
      isMultiSelect ? _buildExpandedMultiSelect() : _buildExpandedSingleSelect();
    }

    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      child: content,
    );
  }

  /// multiSelect == false && isCompact == true
  Widget _buildCompact() {
    return DropdownButton<String>(
      items: choices.keys
          .map((choiceTitle) => DropdownMenuItem<String>(
        value: choices[choiceTitle],
        child: Text(choiceTitle),
      ))
          .toList(),
      onChanged: (String? v) => _select(v),
      value: _selectedChoice.isEmpty ? null : _selectedChoice.single,
    );
  }

  Widget _buildExpandedSingleSelect() {
    return Column(
      children: choices.keys.map((title) {
        final String valueForTitle = choices[title]!;
        // RadioListTile still works; Flutter warns about new RadioGroup API on very new versions.
        return RadioListTile<String>(
          value: valueForTitle,
          // ignore: deprecated_member_use
          onChanged: (v) => _select(v),
          // ignore: deprecated_member_use
          groupValue:
          _selectedChoice.contains(valueForTitle) ? valueForTitle : null,
          title: Text(title),
        );
      }).toList(),
    );
  }

  Widget _buildExpandedMultiSelect() {
    return Column(
      children: choices.keys.map((title) {
        final String valueForTitle = choices[title]!;
        final bool checked = _selectedChoice.contains(valueForTitle);
        return CheckboxListTile(
          controlAffinity: ListTileControlAffinity.leading,
          value: checked,
          onChanged: (_) => _select(valueForTitle),
          title: Text(title),
        );
      }).toList(),
    );
  }

  void _select(String? choice) {
    if (choice == null) return;
    if (!isMultiSelect) {
      _selectedChoice
        ..clear()
        ..add(choice);
    } else {
      if (_selectedChoice.contains(choice)) {
        _selectedChoice.remove(choice);
      } else {
        _selectedChoice.add(choice);
      }
    }
    setState(() {});
  }

  bool _loadCompact() {
    final style = adaptiveMap["style"];
    if (style == null) return false;
    if (style == "compact") return true;
    if (style == "expanded") return false;
    throw StateError(
      "The style of the ChoiceSet needs to be either compact or expanded",
    );
  }
}
