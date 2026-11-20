import 'package:flutter/material.dart';

/// Keeps the scoresheet available while the visual keyboard scrolls below it.
/// Numeric entry retains the usual single scrolling form.
class GameEntryViewport extends StatelessWidget {
  final bool pinMode;
  final ScrollController controller;
  final EdgeInsets padding;
  final List<Widget> header;
  final List<Widget> children;

  const GameEntryViewport({
    super.key,
    required this.pinMode,
    required this.controller,
    required this.header,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 16),
  });

  Widget _scroll(List<Widget> widgets, EdgeInsets insets) =>
      SingleChildScrollView(
        controller: controller,
        padding: insets,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: widgets,
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (!pinMode) return _scroll([...header, ...children], padding);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: padding.copyWith(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: header,
          ),
        ),
        Expanded(child: _scroll(children, padding.copyWith(top: 0))),
      ],
    );
  }
}
