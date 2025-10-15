import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class BasicMarkdown extends MarkdownWidget {
  /// Non-scrolling Markdown renderer.
  const BasicMarkdown({
    Key? key,
    required String data,
    MarkdownStyleSheet? styleSheet,
    SyntaxHighlighter? syntaxHighlighter,
    MarkdownTapLinkCallback? onTapLink,
    this.maxLines,
  }) : super(
    key: key,
    data: data,
    styleSheet: styleSheet,
    syntaxHighlighter: syntaxHighlighter,
    onTapLink: onTapLink,
  );

  final int? maxLines;

  @override
  Widget build(BuildContext context, List<Widget>? children) {
    final list = children ?? const <Widget>[];
    if (list.length == 1) return list.single;

    final visible =
    (maxLines != null && maxLines! < list.length)
        ? list.take(maxLines!).toList()
        : list;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: visible,
    );
  }
}
