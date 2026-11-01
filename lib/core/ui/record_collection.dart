import 'package:farm_tap/core/theme/theme.dart';
import 'package:flutter/material.dart';

class RecordColumn<T> {
  const new({required this.label, required this.cell, this.flex = 1, this.sortKey});

  final String label;
  final Widget Function(BuildContext context, T item) cell;
  final int flex;

  /// When set, tapping the header sorts by this value.
  final Comparable<Object?> Function(T item)? sortKey;
}

/// A list of records: tiles on phones (width < 700), a sortable table above.
/// Not scrollable itself: put it inside a scroll view.
class RecordCollection<T> extends StatefulWidget {
  const new({required this.items, required this.tileBuilder, required this.columns, super.key, this.onTap, this.empty});

  final List<T> items;
  final Widget Function(BuildContext context, T item) tileBuilder;
  final List<RecordColumn<T>> columns;
  final ValueChanged<T>? onTap;

  /// Shown instead of the list when [items] is empty.
  final Widget? empty;

  @override
  State<RecordCollection<T>> createState() => _RecordCollectionState<T>();
}

class _RecordCollectionState<T> extends State<RecordCollection<T>> {
  int? _sortColumn;
  bool _ascending = true;

  List<T> get _sorted {
    final i = _sortColumn;
    if (i == null) return widget.items;
    final key = widget.columns[i].sortKey;
    if (key == null) return widget.items;
    final list = [...widget.items]..sort((a, b) => key(a).compareTo(key(b)));
    return _ascending ? list : list.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty && widget.empty != null) return widget.empty!;
    return LayoutBuilder(
      builder: (context, constraints) =>
          constraints.maxWidth < FarmTapBreakpoints.table ? _list(context) : _table(context),
    );
  }

  Widget _list(BuildContext context) {
    final items = widget.items;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: context.sizes.divider),
            Semantics(
              button: widget.onTap != null,
              child: InkWell(
                onTap: widget.onTap == null ? null : () => widget.onTap!(items[i]),
                child: widget.tileBuilder(context, items[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _table(BuildContext context) {
    final items = _sorted;
    final header = context.textStyles.sectionLabel;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: context.colors.surfaceContainer,
            padding: context.space.listItem,
            child: Row(
              children: [
                for (var c = 0; c < widget.columns.length; c++)
                  Expanded(
                    flex: widget.columns[c].flex,
                    child: InkWell(
                      onTap: widget.columns[c].sortKey == null
                          ? null
                          : () => setState(() {
                              _ascending = _sortColumn != c || !_ascending;
                              _sortColumn = c;
                            }),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.columns[c].label.toUpperCase(),
                              style: header,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_sortColumn == c)
                            Icon(
                              _ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                              size: context.sizes.iconXs,
                              color: context.colors.onSurfaceVariant,
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: context.sizes.divider),
            InkWell(
              onTap: widget.onTap == null ? null : () => widget.onTap!(items[i]),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: context.sizes.actionTile),
                child: Padding(
                  padding: context.space.listItem,
                  child: Row(
                    children: [
                      for (final col in widget.columns)
                        Expanded(
                          flex: col.flex,
                          child: Align(alignment: Alignment.centerLeft, child: col.cell(context, items[i])),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
