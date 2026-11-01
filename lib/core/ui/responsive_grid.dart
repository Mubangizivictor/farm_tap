import 'package:farm_tap/core/theme/theme.dart';
import 'package:flutter/material.dart';

/// Lays children out in equal-width columns:
/// columns = floor((width + gap) / (minItemWidth + gap)), at most [maxColumns].
/// Rows have equal height. Not scrollable: put it inside a scroll view.
/// Metric / action tiles: minItemWidth 150-180. Paired cards: 420-460.
class ResponsiveGrid extends StatelessWidget {
  const new({required this.minItemWidth, required this.children, super.key, this.maxColumns = 4, this.spacing});

  final double minItemWidth;
  final List<Widget> children;
  final int maxColumns;
  final double? spacing;

  static int columnsFor(double width, double minItemWidth, double gap, {int maxColumns = 4}) {
    final cols = ((width + gap) / (minItemWidth + gap)).floor();
    return cols.clamp(1, maxColumns);
  }

  @override
  Widget build(BuildContext context) {
    final gap = spacing ?? context.space.md;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = columnsFor(constraints.maxWidth, minItemWidth, gap, maxColumns: maxColumns);
        final rows = <Widget>[];
        for (var start = 0; start < children.length; start += cols) {
          final slice = children.sublist(start, (start + cols).clamp(0, children.length));
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < cols; i++) ...[
                    if (i > 0) SizedBox(width: gap),
                    Expanded(child: i < slice.length ? slice[i] : const SizedBox.shrink()),
                  ],
                ],
              ),
            ),
          );
          if (start + cols < children.length) rows.add(SizedBox(height: gap));
        }
        return Column(mainAxisSize: MainAxisSize.min, children: rows);
      },
    );
  }
}
