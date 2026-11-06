import 'dart:async';

import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/sectors/cattle/operations/data/operations_repository.dart';
import 'package:farm_tap/sectors/cattle/operations/domain/operations_models.dart';
import 'package:farm_tap/sectors/cattle/operations/presentation/pages/operations_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Feeds store (decision 0024): the farm's own feeds (feedTypes), what is in
/// the store, how many days it lasts and what runs low. Counting the store
/// here is the same record as "Count stock" on the web.
class FeedStorePage extends StatefulWidget {
  const new({required this.repo, required this.canEdit, super.key, this.onRecordFeeding});

  final OperationsRepository repo;
  final bool canEdit;

  /// Opens the existing feeding page (buy / feed).
  final VoidCallback? onRecordFeeding;

  @override
  State<FeedStorePage> createState() => _FeedStorePageState();
}

class _FeedStorePageState extends State<FeedStorePage> {
  @override
  void initState() {
    super.initState();
    if (!widget.repo.loaded) unawaited(widget.repo.restore());
  }

  String _amount(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: widget.repo,
      builder: (context, _) {
        final stock = widget.repo.stock;
        final low = stock.where((s) => s.low || (s.daysLeft != null && s.daysLeft! <= 7)).toList();
        return AdaptiveScaffold(
          title: l10n.opsFeedStore,
          showBack: true,
          floatingActionButton: widget.canEdit
              ? FarmTapFab(label: l10n.opsAddFeed, icon: Symbols.add_rounded, onPressed: () => _editType(null))
              : null,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (low.isNotEmpty) ...[
                FarmTapBanner(
                  tone: FarmTapTone.warning,
                  icon: Symbols.inventory_2_rounded,
                  title: l10n.opsRunningLow(low.length),
                  message: low.map((s) => s.type.name).join(', '),
                ),
                context.space.gapMd,
              ],
              if (widget.onRecordFeeding != null) ...[
                FarmTapButton(
                  label: l10n.opsBuyOrFeed,
                  icon: Symbols.grass_rounded,
                  kind: ButtonKind.tonal,
                  onPressed: widget.onRecordFeeding,
                ),
                context.space.gapMd,
              ],
              if (!widget.repo.loaded)
                const FarmTapPageLoader()
              else if (stock.isEmpty)
                EmptyState(
                  title: l10n.opsNoFeeds,
                  message: l10n.opsNoFeedsBody,
                  animation: FarmTapAnimations.feeding,
                  actionLabel: widget.canEdit ? l10n.opsAddFeed : null,
                  onAction: widget.canEdit ? () => _editType(null) : null,
                )
              else
                ListCard(
                  title: l10n.opsInStore,
                  children: [
                    for (final s in stock)
                      RecordTile(
                        leading: IconBubble(
                          icon: Symbols.inventory_2_rounded,
                          tone: s.low ? FarmTapTone.danger : FarmTapTone.gold,
                          size: context.sizes.bubbleMd,
                        ),
                        title: s.type.name,
                        subtitle: s.daysLeft == null ? l10n.opsNoUseYet : l10n.opsLastsDays(s.daysLeft!),
                        trailingValue: '${_amount(s.amount)} ${s.type.unit}',
                        badge: s.low ? StatusBadge(label: l10n.opsLow, tone: FarmTapTone.danger) : null,
                        onTap: widget.canEdit ? () => _actions(s) : null,
                        showChevron: widget.canEdit,
                      ),
                  ],
                ),
              if (!widget.canEdit) const ViewOnlyNote(),
            ],
          ),
        );
      },
    );
  }

  Future<void> _actions(FeedStock s) async {
    final l10n = AppLocalizations.of(context);
    final pick = await showAdaptiveSheet<String>(
      context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetTitle(s.type.name),
          ActionTile(
            icon: Symbols.checklist_rounded,
            label: l10n.opsCountStore,
            subtitle: l10n.opsCountStoreSub,
            onTap: () => Navigator.of(sheet).pop('count'),
          ),
          context.space.gapSm,
          ActionTile(
            icon: Symbols.edit_rounded,
            label: l10n.opsEditFeed,
            tone: FarmTapTone.neutral,
            onTap: () => Navigator.of(sheet).pop('edit'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (pick == 'edit') await _editType(s.type);
    if (pick == 'count') await _count(s);
  }

  Future<void> _count(FeedStock s) => showAdaptiveSheet<void>(
    context,
    builder: (_) => _CountForm(repo: widget.repo, stock: s),
  );

  Future<void> _editType(FeedType? t) => showAdaptiveSheet<void>(
    context,
    builder: (_) => _FeedTypeForm(repo: widget.repo, type: t),
  );
}

final _number = FilteringTextInputFormatter.allow(RegExp('[0-9.]'));

class _CountForm extends StatefulWidget {
  const new({required this.repo, required this.stock});

  final OperationsRepository repo;
  final FeedStock stock;

  @override
  State<_CountForm> createState() => _CountFormState();
}

class _CountFormState extends State<_CountForm> {
  final _amount = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final v = double.tryParse(_amount.text);
    return FormSheet(
      title: l10n.opsCountStore,
      saving: _saving,
      onSave: v == null || v < 0
          ? null
          : () async {
              setState(() => _saving = true);
              await widget.repo.countFeed(widget.stock.type.id, v);
              if (context.mounted) Navigator.of(context).pop();
            },
      children: [
        FarmTapTextField(
          label: l10n.opsHowMuchLeft(widget.stock.type.unit),
          controller: _amount,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [_number],
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}

class _FeedTypeForm extends StatefulWidget {
  const new({required this.repo, this.type});

  final OperationsRepository repo;
  final FeedType? type;

  @override
  State<_FeedTypeForm> createState() => _FeedTypeFormState();
}

class _FeedTypeFormState extends State<_FeedTypeForm> {
  late final _name = TextEditingController(text: widget.type?.name);
  late final _unit = TextEditingController(text: widget.type?.unit ?? 'kg');
  late final _low = TextEditingController(text: widget.type?.lowAt?.toString());
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _unit, _low]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FormSheet(
      title: widget.type == null ? l10n.opsAddFeed : l10n.opsEditFeed,
      saving: _saving,
      onSave: () async {
        if (_name.text.trim().isEmpty) return;
        setState(() => _saving = true);
        await widget.repo.saveFeedType(
          FeedType(
            id: widget.type?.id ?? '',
            name: _name.text.trim(),
            unit: _unit.text.trim().isEmpty ? 'kg' : _unit.text.trim(),
            lowAt: double.tryParse(_low.text),
          ),
        );
        if (context.mounted) Navigator.of(context).pop();
      },
      onDelete: widget.type == null
          ? null
          : () async {
              setState(() => _saving = true);
              await widget.repo.removeFeedType(widget.type!.id);
              if (context.mounted) Navigator.of(context).pop();
            },
      children: [
        FarmTapTextField(label: l10n.opsFeedName, controller: _name, hint: l10n.opsFeedNameHint),
        FarmTapTextField(label: l10n.opsUnit, controller: _unit, hint: l10n.opsUnitHint),
        FarmTapTextField(
          label: l10n.opsLowAt,
          controller: _low,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [_number],
        ),
      ],
    );
  }
}
