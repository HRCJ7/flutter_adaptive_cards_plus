import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class FadeAnimation extends StatefulWidget {
  const FadeAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
  }) : super(key: key);

  final Widget child;
  final Duration duration;

  @override
  _FadeAnimationState createState() => _FadeAnimationState();
}

class _FadeAnimationState extends State<FadeAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController animationController;

  @override
  void initState() {
    super.initState();
    animationController =
    AnimationController(duration: widget.duration, vsync: this)
      ..addListener(() {
        if (mounted) setState(() {});
      })
      ..forward(from: 0.0);
  }

  @override
  void deactivate() {
    animationController.stop();
    super.deactivate();
  }

  @override
  void didUpdateWidget(FadeAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child) {
      animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return animationController.isAnimating
        ? Opacity(
      opacity: 1.0 - animationController.value,
      child: widget.child,
    )
        : const SizedBox.shrink();
  }
}

String firstCharacterToLowerCase(String s) =>
    s.isNotEmpty ? s[0].toLowerCase() + s.substring(1) : "";

class Tuple<A, B> {
  final A a;
  final B b;
  const Tuple(this.a, this.b);
}

class FullCircleClipper extends CustomClipper<Rect> {
  const FullCircleClipper();

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0.0, 0.0, size.width, size.height);

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => false;
}

Color parseColor(String colorValue) {
  // #RRGGBB
  if (colorValue.length == 7) {
    return Color(int.parse(colorValue.substring(1, 7), radix: 16) + 0xFF000000);
  }
  // #AARRGGBB
  if (colorValue.length == 9) {
    return Color(int.parse(colorValue.substring(1, 9), radix: 16));
  }
  throw StateError("$colorValue is not a valid color");
}

String getDayOfMonthSuffix(final int n) {
  assert(n >= 1 && n <= 31, "illegal day of month: $n");
  if (n >= 11 && n <= 13) return "th";
  switch (n % 10) {
    case 1:
      return "st";
    case 2:
      return "nd";
    case 3:
      return "rd";
    default:
      return "th";
  }
}

/// Lighten very dark colors for dark themes (no tinycolor dependency).
Color adjustColorToFitDarkTheme(Color color, Brightness brightness) {
  if (brightness == Brightness.light) return color;

  // If the color is already light, leave it alone.
  final isDark =
      ThemeData.estimateBrightnessForColor(color) == Brightness.dark;
  if (!isDark) return color;

  // Lighten based on luminance via HSL.
  final double luminance = color.computeLuminance(); // 0..1
  final hsl = HSLColor.fromColor(color);
  final double delta = ((1 - luminance) * 0.5).clamp(0.0, 0.6);
  final double newLightness = (hsl.lightness + delta).clamp(0.0, 1.0);
  return hsl.withLightness(newLightness).toColor();
}

/// Parses a given text string to properly handle DATE() and TIME()
/// Examples:
///   {{DATE(2020-06-01, COMPACT)}}
///   {{DATE(2020-06-01, SHORT)}}
///   {{TIME(2020-06-01T15:10:00)}}
String parseTextString(String text) {
  return text.replaceAllMapped(RegExp(r'{{.*}}'), (match) {
    final String res = match.group(0)!;
    String input = res.substring(2, res.length - 2).replaceAll(" ", "");

    final String type = input.substring(0, 4);
    if (type == "DATE") {
      final String dateFunction = input.substring(5, input.length - 1);
      final List<String> items = dateFunction.split(",");
      if (items.length == 1) items.add("COMPACT");
      if (items.length != 2) return res;

      final DateTime? dateTime = DateTime.tryParse(items[0]);
      if (dateTime == null) return res;

      // TODO: use locale if needed
      if (items[1] == "COMPACT") {
        return DateFormat.yMd().format(dateTime);
      } else if (items[1] == "SHORT") {
        final df = DateFormat("E, MMM d{n}, y");
        return df
            .format(dateTime)
            .replaceFirst('{n}', getDayOfMonthSuffix(dateTime.day));
      } else if (items[1] == "LONG") {
        final df = DateFormat("EEEE, MMMM d{n}, y");
        return df
            .format(dateTime)
            .replaceFirst('{n}', getDayOfMonthSuffix(dateTime.day));
      } else {
        return res;
      }
    } else if (type == "TIME") {
      final String time = input.substring(5, input.length - 1);
      final DateTime? dateTime = DateTime.tryParse(time);
      if (dateTime == null) return res;
      return DateFormat("jm").format(dateTime);
    } else {
      return res;
    }
  });
}

class UUIDGenerator {
  UUIDGenerator() : uuid = const Uuid();

  final Uuid uuid;

  String getId() => uuid.v1();
}
