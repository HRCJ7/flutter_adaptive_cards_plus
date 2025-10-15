library flutter_adaptive_cards;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' show launchUrl, LaunchMode;

import 'elements/base.dart';
import 'registry.dart';
import 'utils.dart';

abstract class AdaptiveCardContentProvider {
  AdaptiveCardContentProvider({required this.hostConfigPath});

  final String hostConfigPath;

  Future<Map<String, dynamic>> loadHostConfig() async {
    final hostConfigString = await rootBundle.loadString(hostConfigPath);
    return Map<String, dynamic>.from(json.decode(hostConfigString));
  }

  Future<Map<String, dynamic>> loadAdaptiveCardContent();
}

class MemoryAdaptiveCardContentProvider extends AdaptiveCardContentProvider {
  MemoryAdaptiveCardContentProvider({
    required this.content,
    required String hostConfigPath,
  }) : super(hostConfigPath: hostConfigPath);

  final Map<String, dynamic> content;

  @override
  Future<Map<String, dynamic>> loadAdaptiveCardContent() {
    return Future.value(content);
  }
}

class AssetAdaptiveCardContentProvider extends AdaptiveCardContentProvider {
  AssetAdaptiveCardContentProvider({
    required this.path,
    required String hostConfigPath,
  }) : super(hostConfigPath: hostConfigPath);

  final String path;

  @override
  Future<Map<String, dynamic>> loadAdaptiveCardContent() async {
    final s = await rootBundle.loadString(path);
    return Map<String, dynamic>.from(json.decode(s));
  }
}

class NetworkAdaptiveCardContentProvider extends AdaptiveCardContentProvider {
  NetworkAdaptiveCardContentProvider({
    required this.url,
    required String hostConfigPath,
  }) : super(hostConfigPath: hostConfigPath);

  final String url;

  @override
  Future<Map<String, dynamic>> loadAdaptiveCardContent() async {
    final resp = await http.get(Uri.parse(url));
    return Map<String, dynamic>.from(json.decode(resp.body));
  }
}

// ignore: must_be_immutable
class AdaptiveCard extends StatefulWidget {
  AdaptiveCard({
    Key? key,
    required this.map,
    required this.hostConfig,
    this.placeholder,
    this.cardRegistry = const CardRegistry(),
    this.onSubmit,
    this.onOpenUrl,
    this.showDebugJson = true,
    this.approximateDarkThemeColors = true,
    this.isAsync = false,
  })  : adaptiveCardContentProvider = null,
        super(key: key);

  AdaptiveCard.network({
    Key? key,
    this.placeholder,
    CardRegistry? cardRegistry,
    required String url,
    required String hostConfigPath,
    this.onSubmit,
    this.onOpenUrl,
    this.showDebugJson = true,
    this.approximateDarkThemeColors = true,
    this.isAsync = true,
  })  : adaptiveCardContentProvider = NetworkAdaptiveCardContentProvider(
    url: url,
    hostConfigPath: hostConfigPath,
  ),
        map = null,
        hostConfig = null,
        cardRegistry = cardRegistry ?? const CardRegistry(),
        super(key: key);

  AdaptiveCard.asset({
    Key? key,
    this.placeholder,
    CardRegistry? cardRegistry,
    required String assetPath,
    required String hostConfigPath,
    this.onSubmit,
    this.onOpenUrl,
    this.showDebugJson = true,
    this.approximateDarkThemeColors = true,
    this.isAsync = true,
  })  : adaptiveCardContentProvider = AssetAdaptiveCardContentProvider(
    path: assetPath,
    hostConfigPath: hostConfigPath,
  ),
        map = null,
        hostConfig = null,
        cardRegistry = cardRegistry ?? const CardRegistry(),
        super(key: key);

  AdaptiveCard.memory({
    Key? key,
    this.placeholder,
    CardRegistry? cardRegistry,
    required Map<String, dynamic> content,
    required String hostConfigPath,
    this.onSubmit,
    this.onOpenUrl,
    this.showDebugJson = true,
    this.approximateDarkThemeColors = true,
    this.isAsync = true,
  })  : adaptiveCardContentProvider = MemoryAdaptiveCardContentProvider(
    content: content,
    hostConfigPath: hostConfigPath,
  ),
        map = null,
        hostConfig = null,
        cardRegistry = cardRegistry ?? const CardRegistry(),
        super(key: key);

  final AdaptiveCardContentProvider? adaptiveCardContentProvider;

  final Widget? placeholder;
  final CardRegistry cardRegistry;

  final void Function(Map<String, dynamic> map)? onSubmit;
  final void Function(String url)? onOpenUrl;

  final bool showDebugJson;
  final bool approximateDarkThemeColors;
  final bool isAsync;

  /// For async sources these start as `null` and are filled after load.
  Map<String, dynamic>? map;
  Map<String, dynamic>? hostConfig;

  @override
  _AdaptiveCardState createState() => _AdaptiveCardState();
}

class _AdaptiveCardState extends State<AdaptiveCard> {
  late CardRegistry cardRegistry;

  void Function(Map<String, dynamic> map)? onSubmit;
  void Function(String url)? onOpenUrl;

  @override
  void initState() {
    super.initState();
    if (widget.isAsync) {
      widget.adaptiveCardContentProvider!.loadHostConfig().then((hostConfigMap) {
        if (!mounted) return;
        setState(() => widget.hostConfig = hostConfigMap);
      });
      widget.adaptiveCardContentProvider!
          .loadAdaptiveCardContent()
          .then((adaptiveMap) {
        if (!mounted) return;
        setState(() => widget.map = adaptiveMap);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    cardRegistry = widget.cardRegistry;
    onSubmit = widget.onSubmit;
    onOpenUrl = widget.onOpenUrl;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isAsync && (widget.hostConfig == null || widget.map == null)) {
      return widget.placeholder ?? const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: RawAdaptiveCard.fromMap(
        widget.map!,
        widget.hostConfig!,
        cardRegistry: cardRegistry,
        onOpenUrl: onOpenUrl ?? (url) async {
          final uri = Uri.tryParse(url);
          if (uri == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Invalid URL: $url')),
            );
            return;
          }
          final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!ok) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not launch $url')),
            );
          }
        },
        onSubmit: onSubmit ?? (payload) {
          // Default feedback; replace with whatever you prefer.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Submitted: ${jsonEncode(payload)}')),
          );
        },
        showDebugJson: widget.showDebugJson,
        approximateDarkThemeColors: widget.approximateDarkThemeColors,
      ),
    );
  }
}

/// Main entry point to adaptive cards.
class RawAdaptiveCard extends StatefulWidget {
  RawAdaptiveCard.fromMap(
      this.map,
      this.hostConfig, {
        this.cardRegistry = const CardRegistry(),
        required this.onSubmit,
        required this.onOpenUrl,
        this.showDebugJson = true,
        this.approximateDarkThemeColors = true,
      });

  final Map<String, dynamic> map;
  final Map<String, dynamic> hostConfig;
  final CardRegistry cardRegistry;

  final void Function(Map<String, dynamic> map) onSubmit;
  final void Function(String url) onOpenUrl;

  final bool showDebugJson;
  final bool approximateDarkThemeColors;

  @override
  RawAdaptiveCardState createState() => RawAdaptiveCardState();
}

class RawAdaptiveCardState extends State<RawAdaptiveCard> {
  // Wrapper around the host config
  late ReferenceResolver _resolver;
  late UUIDGenerator idGenerator;
  late CardRegistry cardRegistry;

  // The root element
  late Widget _adaptiveElement;

  static RawAdaptiveCardState of(BuildContext context) {
    return Provider.of<RawAdaptiveCardState>(context, listen: false);
  }

  @override
  void initState() {
    super.initState();
    _resolver = ReferenceResolver(hostConfig: widget.hostConfig);
    idGenerator = UUIDGenerator();
    cardRegistry = widget.cardRegistry;
    _adaptiveElement = widget.cardRegistry.getElement(widget.map);
  }

  /// Every widget can access method of this class
  void rebuild() => setState(() {});

  /// Submits all the inputs of this adaptive card.
  void submit(Map<String, dynamic> map) {
    void visitor(Element element) {
      if (element is StatefulElement) {
        final st = element.state;
        if (st is AdaptiveInputMixin) {
          (st).appendInput(map);
        }
      }
      element.visitChildren(visitor);
    }

    context.visitChildElements(visitor);
    widget.onSubmit(map);
  }

  void openUrl(String url) => widget.onOpenUrl(url);

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// min and max may be null; defaults applied.
  Future<DateTime?> pickDate(DateTime? min, DateTime? max) {
    final now = DateTime.now();
    final first = min ?? now.subtract(const Duration(days: 10000));
    final last = max ?? now.add(const Duration(days: 10000));
    final initial = now.isBefore(first) ? first : (now.isAfter(last) ? last : now);
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
  }

  Future<TimeOfDay?> pickTime() {
    return showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget child = _adaptiveElement;

    assert(() {
      if (widget.showDebugJson) {
        child = Column(
          children: <Widget>[
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.indigo),
              onPressed: () {
                final encoder = const JsonEncoder.withIndent('  ');
                final pretty = encoder.convert(widget.map);
                showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text(
                      "JSON (only added in debug mode, you can also turn "
                          "it off manually by passing showDebugJson = false)",
                    ),
                    content: SingleChildScrollView(child: Text(pretty)),
                    actions: <Widget>[
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text("Thanks"),
                        ),
                      ),
                    ],
                    contentPadding: const EdgeInsets.all(8.0),
                  ),
                );
              },
              child: const Text("Debug show the JSON"),
            ),
            const Divider(height: 0),
            child,
          ],
        );
      }
      return true;
    }());

    return Provider<RawAdaptiveCardState>.value(
      value: this,
      child: InheritedReferenceResolver(
        key: const ValueKey('AdaptiveCardRootResolver'),
        resolver: _resolver,
        child: Card(
          margin: const EdgeInsets.all(0.0),
          shape: Border.all(color: Colors.transparent),
          elevation: _resolver.resolveElevation(widget.map["elevation"] ?? "default"),
          borderOnForeground: false,
          child: child,
        ),
      ),
    );

  }
}

/// The visitor called for each element in the tree
typedef AdaptiveElementVisitor = void Function(AdaptiveElement element);

/// Base class for every element (widget) drawn on the screen.
abstract class AdaptiveElement {
  AdaptiveElement({
    required this.adaptiveMap,
    required this.widgetState,
  }) {
    loadTree();
  }

  final Map<String, dynamic> adaptiveMap;

  late String id;

  /// Access to Flutter-specific card state.
  final RawAdaptiveCardState widgetState;

  /// Concrete widgets implement this.
  Widget build();

  @mustCallSuper
  Widget generateWidget() => build();

  void loadId() {
    if (adaptiveMap.containsKey("id")) {
      id = adaptiveMap["id"] as String;
    } else {
      id = widgetState.idGenerator.getId();
    }
  }

  @mustCallSuper
  void loadTree() => loadId();

  /// Visits the children
  void visitChildren(AdaptiveElementVisitor visitor) {
    visitor(this);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is AdaptiveElement &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Resolves values based on the host config.
class ReferenceResolver {
  ReferenceResolver({
    required this.hostConfig,
    this.currentStyle,
  });

  final Map<String, dynamic> hostConfig;
  final String? currentStyle;

  dynamic resolve(String key, String value) {
    final dynamic res = hostConfig[key][firstCharacterToLowerCase(value)];
    assert(res != null,
    "Could not find hostConfig[$key][${firstCharacterToLowerCase(value)}]");
    return res;
  }

  dynamic get(String key) {
    final dynamic res = hostConfig[key];
    assert(res != null, "Could not find hostConfig[$key]");
    return res;
  }

  FontWeight resolveFontWeight(String? value) {
    final int weight = resolve("fontWeights", value ?? "default") as int;
    return FontWeight.values
        .firstWhere((w) => w.toString() == "FontWeight.w$weight");
  }

  double resolveFontSize(String? value) {
    final int size = resolve("fontSizes", value ?? "default") as int;
    return size.toDouble();
  }

  /// Resolves a color from the host config
  Color resolveColor(String? color, bool? isSubtle) {
    final String myColor = color ?? "default";
    final String subtleOrDefault = (isSubtle ?? false) ? "subtle" : "default";
    final style = currentStyle ?? "default";
    final String colorValue = hostConfig["containerStyles"][style]
    ["foregroundColors"][firstCharacterToLowerCase(myColor)]
    [subtleOrDefault] as String;
    return parseColor(colorValue);
  }

  double resolveElevation(String? value) {
    final String v = value ?? "default";
    final dynamic group = hostConfig["elevations"];
    if (group is Map) {
      final dynamic raw = group[firstCharacterToLowerCase(v)];
      if (raw is num) return raw.toDouble();
    }
    return 0.0;
  }

  ReferenceResolver copyWith({String? style}) {
    final String myStyle = style ?? "default";
    assert(myStyle == "default" || myStyle == "emphasis");
    return ReferenceResolver(
      hostConfig: hostConfig,
      currentStyle: myStyle,
    );
  }

  double resolveSpacing(String? spacing) {
    final String mySpacing = spacing ?? "default";
    if (mySpacing == "none") return 0.0;
    final int intSpacing =
    hostConfig["spacing"][firstCharacterToLowerCase(mySpacing)] as int;
    return intSpacing.toDouble();
  }
}
