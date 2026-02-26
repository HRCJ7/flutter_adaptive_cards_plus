import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils.dart';
import 'actions.dart';
import 'base.dart';

class AdaptiveCardElement extends StatefulWidget with AdaptiveElementWidgetMixin {
  const AdaptiveCardElement({
    Key? key,
    required this.adaptiveMap,
  }) : super(key: key);

  final Map<String, dynamic> adaptiveMap;

  @override
  AdaptiveCardElementState createState() => AdaptiveCardElementState();
}

class AdaptiveCardElementState extends State<AdaptiveCardElement>
    with AdaptiveElementMixin {
  String? currentCardId;

  late List<Widget> children;

  List<Widget> allActions = [];
  List<AdaptiveActionShowCard> showCardActions = [];
  List<Widget> cards = [];

  Axis? actionsOrientation;
  String? backgroundImage;

  final Map<String, Widget> _registeredCards = <String, Widget>{};

  void registerCard(String id, Widget it) => _registeredCards[id] = it;

  static AdaptiveCardElementState of(BuildContext context) {
    return Provider.of<AdaptiveCardElementState>(context, listen: false);
  }

  @override
  void initState() {
    super.initState();

    final String? stringAxis = resolver.resolve("actions", "actionsOrientation");
    if (stringAxis == "Horizontal") {
      actionsOrientation = Axis.horizontal;
    } else if (stringAxis == "Vertical") {
      actionsOrientation = Axis.vertical;
    }

    final List<Map<String, dynamic>> body =
    List<Map<String, dynamic>>.from(
      (adaptiveMap["body"] ?? const <Map<String, dynamic>>[]) as List,
    );

    children = body.map((map) => widgetState.cardRegistry.getElement(map)).toList();

    backgroundImage = adaptiveMap['backgroundImage'] as String?;
  }

  void loadChildren() {
    if (widget.adaptiveMap.containsKey("actions")) {
      final List<Map<String, dynamic>> acts =
      List<Map<String, dynamic>>.from(widget.adaptiveMap["actions"] as List);

      allActions = acts.map((m) => widgetState.cardRegistry.getAction(m)).toList();

      showCardActions = List<AdaptiveActionShowCard>.from(
        allActions.where((a) => a is AdaptiveActionShowCard),
      );

      cards = List<Widget>.from(
        showCardActions.map((action) {
          final Map<String, dynamic> cardMap =
          (action.adaptiveMap["card"] as Map).cast<String, dynamic>();
          return widgetState.cardRegistry.getElement(cardMap);
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    loadChildren();

    final List<Widget> widgetChildren = <Widget>[...children];

    // ── ACTIONS (safe: never overflows) ───────────────────────────────────────────
    final List<Widget> actionWidgets = allActions
        .map((action) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: action,
    ))
        .toList();

    final Widget actionsView = (actionsOrientation == Axis.vertical)
        ? Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: actionWidgets,
    )
    // Horizontal: use Wrap so items go to a new line instead of overflowing
        : Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.start,
      children: actionWidgets,
    );

    if (actionWidgets.isNotEmpty) {
      widgetChildren.add(actionsView);
    }
    // ─────────────────────────────────────────────────────────────────────────────

    if (currentCardId != null && _registeredCards[currentCardId!] != null) {
      widgetChildren.add(_registeredCards[currentCardId!]!);
    }

    Widget result = Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgetChildren,
      ),
    );

    if (backgroundImage != null && backgroundImage!.isNotEmpty) {
      result = Stack(
        children: <Widget>[
          Positioned.fill(
            child: Image.network(
              Uri.encodeFull(backgroundImage!),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
          result,
        ],
      );
    }

    return Provider<AdaptiveCardElementState>.value(
      value: this,
      child: result,
    );
  }

  void showCard(String id) {
    currentCardId = (currentCardId == id) ? null : id;
    setState(() {});
  }
}

class AdaptiveTextBlock extends StatefulWidget with AdaptiveElementWidgetMixin {
  const AdaptiveTextBlock({
    Key? key,
    required this.adaptiveMap,
  }) : super(key: key);

  final Map<String, dynamic> adaptiveMap;

  @override
  _AdaptiveTextBlockState createState() => _AdaptiveTextBlockState();
}

class _AdaptiveTextBlockState extends State<AdaptiveTextBlock>
    with AdaptiveElementMixin {
  late FontWeight fontWeight;
  late double fontSize;
  late Alignment horizontalAlignment;
  late int maxLines;
  late String text;

  @override
  void initState() {
    super.initState();
    fontSize = resolver.resolveFontSize(adaptiveMap["size"]);
    fontWeight = resolver.resolveFontWeight(adaptiveMap["weight"]);
    horizontalAlignment = loadAlignment();
    maxLines = loadMaxLines();
    text = (adaptiveMap['text'] as String?) ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      child: Align(
        alignment: horizontalAlignment,
        child: MarkdownBody(
          data: text,
          styleSheet: loadMarkdownStyleSheet(),
          onTapLink: (t, href, title) => _launchURL(href),

          sizedImageBuilder: (MarkdownImageConfig config) {
            final uri = config.uri;
            final url = uri.toString();
            if (url.isEmpty) return const SizedBox.shrink();

            return Image.network(
              Uri.encodeFull(url),
              width: config.width,
              height: config.height,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            );
          },
        )
      ),
    );
  }

  Future<void> _launchURL(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) throw 'Could not launch $url';
  }

  Color getColor(Brightness brightness) {
    final Color color =
    resolver.resolveColor(adaptiveMap["color"], adaptiveMap["isSubtle"]);
    if (!widgetState.widget.approximateDarkThemeColors) return color;
    return adjustColorToFitDarkTheme(color, brightness);
  }

  Alignment loadAlignment() {
    final String alignmentString =
        (widget.adaptiveMap["horizontalAlignment"] as String?) ?? "left";
    switch (alignmentString) {
      case "left":
        return Alignment.centerLeft;
      case "center":
        return Alignment.center;
      case "right":
        return Alignment.centerRight;
      default:
        return Alignment.centerLeft;
    }
  }

  int loadMaxLines() {
    final bool wrap = widget.adaptiveMap["wrap"] as bool? ?? false;
    if (!wrap) return 1;
    return widget.adaptiveMap["maxLines"] as int? ?? 999999;
  }

  MarkdownStyleSheet loadMarkdownStyleSheet() {
    final TextStyle base = TextStyle(
      fontWeight: fontWeight,
      fontSize: fontSize,
      color: getColor(Theme.of(context).brightness),
    );
    return MarkdownStyleSheet(
      a: base.copyWith(color: const Color.fromRGBO(4, 164, 255, 1)),
      blockquote: base,
      code: base,
      em: base,
      strong: base.copyWith(fontWeight: FontWeight.bold),
      p: base,
    );
  }
}

class AdaptiveContainer extends StatefulWidget with AdaptiveElementWidgetMixin {
  const AdaptiveContainer({
    Key? key,
    required this.adaptiveMap,
  }) : super(key: key);

  final Map<String, dynamic> adaptiveMap;

  @override
  _AdaptiveContainerState createState() => _AdaptiveContainerState();
}

class _AdaptiveContainerState extends State<AdaptiveContainer>
    with AdaptiveElementMixin {
  late List<Widget> children;
  late Color? backgroundColor;

  @override
  void initState() {
    super.initState();
    if (adaptiveMap["items"] != null) {
      children = List<Map<String, dynamic>>.from(adaptiveMap["items"] as List)
          .map((child) => widgetState.cardRegistry.getElement(child))
          .toList();
    } else {
      children = <Widget>[];
    }

    final String styleKey = (adaptiveMap["style"] as String?) ?? "default";
    final String colorString =
    resolver.hostConfig["containerStyles"][styleKey]["backgroundColor"];
    backgroundColor = parseColor(colorString);
  }

  @override
  Widget build(BuildContext context) {
    return ChildStyler(
      adaptiveMap: adaptiveMap,
      child: AdaptiveTappable(
        adaptiveMap: adaptiveMap,
        child: SeparatorElement(
          adaptiveMap: adaptiveMap,
          child: Container(
            color: Theme.of(context).brightness == Brightness.dark &&
                adaptiveMap["style"] == null
                ? null
                : backgroundColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(children: children),
            ),
          ),
        ),
      ),
    );
  }
}

class AdaptiveColumnSet extends StatefulWidget with AdaptiveElementWidgetMixin {
  const AdaptiveColumnSet({
    Key? key,
    required this.adaptiveMap,
  }) : super(key: key);

  final Map<String, dynamic> adaptiveMap;

  @override
  _AdaptiveColumnSetState createState() => _AdaptiveColumnSetState();
}

class _AdaptiveColumnSetState extends State<AdaptiveColumnSet>
    with AdaptiveElementMixin {
  late List<AdaptiveColumn> columns;

  @override
  void initState() {
    super.initState();
    final List<Map<String, dynamic>> cols =
    List<Map<String, dynamic>>.from(
      adaptiveMap["columns"] ?? const <Map<String, dynamic>>[],
    );

    // IMPORTANT: pass useFlex: false because we will put the Row inside a
    // horizontal SingleChildScrollView (Row gets unbounded width there).
    columns = cols
        .map((child) => AdaptiveColumn(adaptiveMap: child, useFlex: false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      child: AdaptiveTappable(
        adaptiveMap: adaptiveMap,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: columns,
          ),
        ),
      ),
    );
  }
}


class AdaptiveColumn extends StatefulWidget with AdaptiveElementWidgetMixin {
  const AdaptiveColumn({
    Key? key,
    required this.adaptiveMap,
    this.useFlex = true, // <— NEW
  }) : super(key: key);

  final Map<String, dynamic> adaptiveMap;
  final bool useFlex; // <— NEW

  @override
  _AdaptiveColumnState createState() => _AdaptiveColumnState();
}

class _AdaptiveColumnState extends State<AdaptiveColumn>
    with AdaptiveElementMixin {
  late List<Widget> items;

  late String mode; // "auto" | "stretch" | "manual"
  int? width;

  GenericAction? action;

  late double precedingSpacing;
  late bool separator;

  @override
  void initState() {
    super.initState();

    if (adaptiveMap.containsKey("selectAction")) {
      action = widgetState.cardRegistry
          .getGenericAction(adaptiveMap["selectAction"], widgetState);
    }
    precedingSpacing = resolver.resolveSpacing(adaptiveMap["spacing"]);
    separator = adaptiveMap["separator"] as bool? ?? false;

    items = adaptiveMap["items"] != null
        ? List<Map<String, dynamic>>.from(adaptiveMap["items"] as List)
        .map((child) => widgetState.cardRegistry.getElement(child))
        .toList()
        : <Widget>[];

    final toParseWidth = adaptiveMap["width"];
    if (toParseWidth != null) {
      if (toParseWidth == "auto") {
        mode = "auto";
      } else if (toParseWidth == "stretch") {
        mode = "stretch";
      } else if (toParseWidth is int) {
        width = toParseWidth; // “star” weight in AC schema
        mode = "manual";
      } else {
        mode = "auto";
      }
    } else {
      mode = "auto";
    }
  }

  @override
  Widget build(BuildContext context) {
    final inner = InkWell(
      onTap: action?.tap,
      child: Padding(
        padding: EdgeInsets.only(left: precedingSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            if (separator) const Divider(),
            ...items,
          ],
        ),
      ),
    );

    final styled = ChildStyler(adaptiveMap: adaptiveMap, child: inner);

    // If we're inside a horizontal scroller, DO NOT use Flexible/Expanded.
    if (!widget.useFlex) {
      return Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: styled,
      );
    }

    switch (mode) {
      case "stretch":
        return Expanded(child: styled);
      case "manual":
        return Flexible(flex: width ?? 1, fit: FlexFit.tight, child: styled);
      case "auto":
      default:
        return Flexible(fit: FlexFit.loose, child: styled);
    }
  }
}


class AdaptiveFactSet extends StatefulWidget with AdaptiveElementWidgetMixin {
  const AdaptiveFactSet({
    Key? key,
    required this.adaptiveMap,
  }) : super(key: key);

  final Map<String, dynamic> adaptiveMap;

  @override
  _AdaptiveFactSetState createState() => _AdaptiveFactSetState();
}

class _AdaptiveFactSetState extends State<AdaptiveFactSet>
    with AdaptiveElementMixin {
  late List<Map> facts;

  @override
  void initState() {
    super.initState();
    facts = List<Map>.from(adaptiveMap["facts"] ?? const <Map>[]).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Left titles: size to content (flex: 0). Right values: take remaining width (Expanded) and wrap.
    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Flexible(
            flex: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: facts
                  .map((fact) => Text(
                (fact["title"] ?? '') as String,
                style: const TextStyle(fontWeight: FontWeight.bold),
                softWrap: true,
              ))
                  .toList(),
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: facts
                  .map((fact) => Text(
                (fact["value"] ?? '') as String,
                softWrap: true,
              ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

}

class AdaptiveImage extends StatefulWidget with AdaptiveElementWidgetMixin {
  const AdaptiveImage({
    Key? key,
    required this.adaptiveMap,
  }) : super(key: key);

  final Map<String, dynamic> adaptiveMap;

  @override
  _AdaptiveImageState createState() => _AdaptiveImageState();
}

class _AdaptiveImageState extends State<AdaptiveImage>
    with AdaptiveElementMixin {
  late Alignment horizontalAlignment;
  late bool isPerson;
  Tuple<double, double>? size;

  @override
  void initState() {
    super.initState();
    horizontalAlignment = loadAlignment();
    isPerson = loadIsPerson();
    size = loadSize();
  }

  @override
  Widget build(BuildContext context) {
    final String urlStr = url ?? '';
    Widget image = Image.network(
      Uri.encodeFull(urlStr),
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const SizedBox.shrink();
      },
    );

    if (isPerson) {
      image = ClipOval(clipper: FullCircleClipper(), child: image);
    }

    image = Align(alignment: horizontalAlignment, child: image);

    if (size != null) {
      image = ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: size!.a,
          minHeight: size!.a,
          maxHeight: size!.b,
          maxWidth: size!.b,
        ),
        child: image,
      );
    }

    return SeparatorElement(adaptiveMap: adaptiveMap, child: image);
  }

  Alignment loadAlignment() {
    final String alignmentString =
        adaptiveMap["horizontalAlignment"] as String? ?? "left";
    switch (alignmentString) {
      case "left":
        return Alignment.centerLeft;
      case "center":
        return Alignment.center;
      case "right":
        return Alignment.centerRight;
      default:
        return Alignment.centerLeft;
    }
  }

  bool loadIsPerson() {
    final style = adaptiveMap["style"];
    if (style == null || style == "default") return false;
    return true;
  }

  String? get url => adaptiveMap["url"] as String?;

  Tuple<double, double>? loadSize() {
    String sizeDescription =
    (adaptiveMap["size"] as String? ?? "auto").toLowerCase();
    if (sizeDescription == "auto" || sizeDescription == "stretch") return null;
    final int s = resolver.resolve("imageSizes", sizeDescription);
    return Tuple(s.toDouble(), s.toDouble());
  }
}

class AdaptiveImageSet extends StatefulWidget with AdaptiveElementWidgetMixin {
  const AdaptiveImageSet({
    Key? key,
    required this.adaptiveMap,
  }) : super(key: key);

  final Map<String, dynamic> adaptiveMap;

  @override
  _AdaptiveImageSetState createState() => _AdaptiveImageSetState();
}

class _AdaptiveImageSetState extends State<AdaptiveImageSet>
    with AdaptiveElementMixin {
  late List<AdaptiveImage> images;

  String? imageSize;
  double? maybeSize;

  @override
  void initState() {
    super.initState();

    final List<Map<String, dynamic>> imgs =
    List<Map<String, dynamic>>.from(
      adaptiveMap["images"] ?? const <Map<String, dynamic>>[],
    );
    images = imgs.map((m) => AdaptiveImage(adaptiveMap: m)).toList();

    loadSize();
  }

  @override
  Widget build(BuildContext context) {
    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Wrap(
            children: images
                .map((img) => SizedBox(
              width: calculateSize(constraints),
              child: img,
            ))
                .toList(),
          );
        },
      ),
    );
  }

  double calculateSize(BoxConstraints constraints) {
    if (maybeSize != null) return maybeSize!;
    if (imageSize == "stretch") return constraints.maxWidth;
    final count = images.length;
    if (count >= 5) {
      return constraints.maxWidth / 5;
    } else if (count == 0) {
      return 0.0;
    } else {
      return constraints.maxWidth / count;
    }
  }

  void loadSize() {
    final String sizeDescription =
        adaptiveMap["imageSize"] as String? ?? "auto";
    if (sizeDescription == "auto") {
      imageSize = "auto";
      return;
    }
    if (sizeDescription == "stretch") {
      imageSize = "stretch";
      return;
    }
    final int s = resolver.resolve("imageSizes", sizeDescription);
    maybeSize = s.toDouble();
  }
}

class AdaptiveMedia extends StatefulWidget with AdaptiveElementWidgetMixin {
  const AdaptiveMedia({
    Key? key,
    required this.adaptiveMap,
  }) : super(key: key);

  final Map<String, dynamic> adaptiveMap;

  @override
  _AdaptiveMediaState createState() => _AdaptiveMediaState();
}

class _AdaptiveMediaState extends State<AdaptiveMedia>
    with AdaptiveElementMixin {
  late VideoPlayerController videoPlayerController;
  late ChewieController controller;

  late String sourceUrl;
  String? postUrl;
  String? altText;

  final FadeAnimation imageFadeAnim =
  FadeAnimation(child: const Icon(Icons.play_arrow, size: 100.0));

  @override
  void initState() {
    super.initState();

    postUrl = adaptiveMap["poster"] as String?;
    sourceUrl = (adaptiveMap["sources"] as List).first["url"] as String;

    videoPlayerController =
        VideoPlayerController.networkUrl(Uri.parse(sourceUrl));

    controller = ChewieController(
      aspectRatio: 3 / 2,
      autoPlay: false,
      looping: true,
      autoInitialize: true,
      placeholder: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (postUrl != null && postUrl!.isNotEmpty)
              Image.network(
                Uri.encodeFull(postUrl!),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            const Icon(Icons.play_circle_fill, size: 64),
          ],
        ),
      ),
      videoPlayerController: videoPlayerController,
    );
  }

  @override
  void dispose() {
    controller.pause();
    controller.dispose();
    videoPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      child: Chewie(controller: controller),
    );
  }
}

class AdaptiveUnknown extends StatefulWidget with AdaptiveElementWidgetMixin {
  const AdaptiveUnknown({
    Key? key,
    required this.adaptiveMap,
    required this.type,
  }) : super(key: key);

  final Map<String, dynamic> adaptiveMap;
  final String type;

  @override
  _AdaptiveUnknownState createState() => _AdaptiveUnknownState();
}

class _AdaptiveUnknownState extends State<AdaptiveUnknown>
    with AdaptiveElementMixin {
  @override
  Widget build(BuildContext context) {
    Widget result = const SizedBox();

    assert(() {
      result = ErrorWidget(
        "Type ${widget.type} not found. \n\n"
            "Because of this, a portion of the tree was dropped: \n"
            "$adaptiveMap",
      );
      return true;
    }());

    return result;
  }
}

// ======= helpers (ensure these are not duplicated in other files) =======

class SeparatorElement extends StatefulWidget with AdaptiveElementWidgetMixin {
  const SeparatorElement({
    Key? key,
    required this.adaptiveMap,
    required this.child,
  }) : super(key: key);

  final Map adaptiveMap; // keep flexible to match mixin
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
  final Map adaptiveMap; // flexible

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
    return InkWell(onTap: action?.tap, child: widget.child);
  }
}

class ChildStyler extends StatelessWidget {
  ChildStyler({
    Key? key,
    required this.child,
    required this.adaptiveMap,
  })  : _resolverKey = key ?? UniqueKey(),
        super(key: key);

  final Widget child;
  final Map adaptiveMap; // flexible
  final Key _resolverKey;

  @override
  Widget build(BuildContext context) {
    return InheritedReferenceResolver(
      key: _resolverKey,
      resolver:
      InheritedReferenceResolver.of(context).copyWith(style: adaptiveMap['style']),
      child: child,
    );
  }
}
