// Feeding: I01 feed stock (+ I03 buy feed sheet), I02 record feeding.
// Stock, days left and the month's feed cost are calculated from the
// purchase and feeding records.
import 'dart:async';

import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/core/utils/formats.dart';
import 'package:farm_tap/sectors/cattle/feeding/domain/feeding_models.dart';
import 'package:farm_tap/sectors/cattle/feeding/domain/feeding_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

FarmTapFormat _fmt(BuildContext context) => FarmTapFormat(Localizations.localeOf(context).toLanguageTag());

String feedLabel(AppLocalizations l10n, FeedKind f) => switch (f) {
  FeedKind.dairyMeal => l10n.feedDairyMeal,
  FeedKind.maizeBran => l10n.feedMaizeBran,
  FeedKind.mineralLick => l10n.feedMineralLick,
  FeedKind.silage => l10n.feedSilage,
};

String groupLabel(AppLocalizations l10n, FeedGroup g) => switch (g) {
  FeedGroup.milkingCows => l10n.groupMilkingCows,
  FeedGroup.dryCows => l10n.groupDryCows,
  FeedGroup.heifers => l10n.groupHeifers,
  FeedGroup.calves => l10n.groupCalves,
};

/// "2 bags", "6 blocks", "about 3 tonnes".
String _stockLong(AppLocalizations l10n, FarmTapFormat f, FeedKind feed, double v) => switch (feed.unit) {
  FeedUnit.bags => l10n.feedBags(f.litresValue(v)),
  FeedUnit.blocks => l10n.feedBlocks(f.litresValue(v)),
  FeedUnit.kg => l10n.feedTonnes(f.litresValue(v / 1000)),
};

/// "2 bags" / "6 blocks" / "3 t" for tables.
String _stockShort(AppLocalizations l10n, FarmTapFormat f, FeedKind feed, double v) => switch (feed.unit) {
  FeedUnit.kg => '${f.litresValue(v / 1000)} t',
  _ => _stockLong(l10n, f, feed, v),
};

/// "0.7 bags", "1 bag", "0.2", "250 kg" as on the I01 table.
String _perDay(AppLocalizations l10n, FarmTapFormat f, FeedKind feed, double v) => switch (feed.unit) {
  FeedUnit.bags => '${f.litresValue(v)} ${v == 1 ? l10n.unitBagsLabel.toLowerCase().substring(0, 3) : l10n.unitBags}',
  FeedUnit.blocks => f.litresValue(v),
  FeedUnit.kg => '${f.count(v)} ${l10n.unitKg}',
};

FarmTapTone _tone(FeedKind feed) => switch (feed) {
  FeedKind.mineralLick => FarmTapTone.info,
  FeedKind.silage => FarmTapTone.primary,
  _ => FarmTapTone.gold,
};

IconData _icon(FeedKind feed) => feed == FeedKind.silage ? Symbols.grass_rounded : Symbols.inventory_2_rounded;

// ---------------------------------------------------------------- I01 / I03

class FeedStockPage extends StatefulWidget {
  const new({required this.repo, required this.onRecord, super.key, this.openBuy = false});

  final FeedRepository repo;
  final VoidCallback onRecord;

  /// Golden / deep link: open the I03 sheet on first frame.
  final bool openBuy;

  @override
  State<FeedStockPage> createState() => _FeedStockPageState();
}

class _FeedStockPageState extends State<FeedStockPage> {
  late Future<FeedSummary?> _load = _fetch();

  Future<FeedSummary?> _fetch() async => (await widget.repo.summary()).data;

  @override
  void initState() {
    super.initState();
    if (widget.openBuy) WidgetsBinding.instance.addPostFrameCallback((_) => _buy(FeedKind.dairyMeal));
  }

  Future<void> _buy([FeedKind? feed]) async {
    final saved = await showAdaptiveSheet<FeedPurchase>(
      context,
      builder: (_) => _BuyFeedSheet(repo: widget.repo, feed: feed ?? FeedKind.dairyMeal),
    );
    if (saved == null || !mounted) return;
    setState(() {
      _load = _fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    return AdaptiveScaffold(
      title: l10n.feeding,
      actions: [BarAction(icon: Symbols.add_rounded, tooltip: l10n.buyFeed, onPressed: _buy)],
      floatingActionButton: FarmTapFab(
        label: l10n.recordFeeding,
        icon: Symbols.grass_rounded,
        onPressed: widget.onRecord,
      ),
      body: FutureBuilder<FeedSummary?>(
        future: _load,
        builder: (context, snapshot) {
          final s = snapshot.data;
          if (s == null) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HeroCard(
                label: l10n.feedCostThisMonth,
                value: f.moneyShort(s.costThisMonth),
                sub: s.costPerLitre == null ? null : l10n.perLitreOfMilk(f.money(s.costPerLitre!)),
                tone: FarmTapTone.gold,
                animation: FarmTapAnimations.feeding,
              ),
              context.space.gapLg,
              RecordCollection<FeedStock>(
                items: s.stock,
                tileBuilder: (context, st) => RecordTile(
                  leading: IconBubble(icon: _icon(st.feed), tone: _tone(st.feed), size: context.sizes.bubbleMd),
                  title: feedLabel(l10n, st.feed),
                  subtitle: st.reorder
                      ? l10n.feedLeftDays(_stockLong(l10n, f, st.feed, st.left), st.daysLeft!)
                      : _stockLong(l10n, f, st.feed, st.left),
                  badge: st.reorder ? StatusBadge(label: l10n.reorder, tone: FarmTapTone.gold) : null,
                  trailingValue: st.reorder
                      ? _stockShort(l10n, f, st.feed, st.left)
                      : st.feed.unit == FeedUnit.kg
                      ? _stockShort(l10n, f, st.feed, st.left)
                      : f.litresValue(st.left),
                  onTap: () => _buy(st.feed),
                ),
                columns: [
                  RecordColumn(
                    label: l10n.colFeed,
                    flex: 2,
                    sortKey: (st) => feedLabel(l10n, st.feed),
                    cell: (c, st) => Text(feedLabel(l10n, st.feed), style: c.text.titleSmall),
                  ),
                  RecordColumn(label: l10n.colInStock, cell: (c, st) => Text(_stockShort(l10n, f, st.feed, st.left))),
                  RecordColumn(label: l10n.colUsedPerDay, cell: (c, st) => Text(_perDay(l10n, f, st.feed, st.perDay))),
                  RecordColumn(
                    label: l10n.colDaysLeft,
                    sortKey: (st) => st.daysLeft ?? 0,
                    cell: (c, st) => Text(st.daysLeft == null ? '—' : f.count(st.daysLeft!)),
                  ),
                  RecordColumn(
                    label: l10n.colStatus,
                    cell: (c, st) => Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: st.reorder
                          ? StatusBadge(label: l10n.reorder, tone: FarmTapTone.gold)
                          : StatusBadge(label: l10n.okBadge, tone: FarmTapTone.success),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BuyFeedSheet extends StatefulWidget {
  const new({required this.repo, required this.feed});

  final FeedRepository repo;
  final FeedKind feed;

  @override
  State<_BuyFeedSheet> createState() => _BuyFeedSheetState();
}

class _BuyFeedSheetState extends State<_BuyFeedSheet> {
  late FeedKind _feed = widget.feed;
  static const _defaultAmount = '10';
  static const _defaultPrice = '52,000';
  final _amount = TextEditingController(text: _defaultAmount);
  final _price = TextEditingController(text: _defaultPrice);
  late final _supplier = TextEditingController(text: widget.repo.suppliers.first);

  @override
  void dispose() {
    for (final c in [_amount, _price, _supplier]) {
      c.dispose();
    }
    super.dispose();
  }

  double get _qty => double.tryParse(_amount.text.replaceAll(',', '')) ?? 0;
  int get _unitPrice => int.tryParse(_price.text.replaceAll(',', '')) ?? 0;
  int get _total => (_qty * _unitPrice).round();

  /// Changed from the suggested purchase (I03 opens pre-filled).
  bool get _dirty =>
      _feed != widget.feed ||
      _amount.text != _defaultAmount ||
      _price.text != _defaultPrice ||
      _supplier.text != widget.repo.suppliers.first;

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    // Money: read back before saving.
    final ok = await showReadBack(
      context,
      leading: IconBubble(icon: _icon(_feed), tone: _tone(_feed), size: context.sizes.bubbleXl),
      subject: '${feedLabel(l10n, _feed)} · ${_qty == _qty.roundToDouble() ? f.count(_qty) : f.litresValue(_qty)}',
      valueText: f.money(_total),
      detail: _supplier.text.trim().isEmpty ? null : _supplier.text.trim(),
    );
    if (!ok || !mounted) return;
    final p = (await widget.repo.addPurchase(
      feed: _feed,
      amount: _feed.unit == FeedUnit.kg ? _qty * 1000 : _qty,
      pricePerUnit: _unitPrice,
      supplier: _supplier.text.trim().isEmpty ? null : _supplier.text.trim(),
    )).data;
    if (!mounted || p == null) return;
    FarmTapToast.show(context, message: l10n.purchaseSaved(f.money(p.total)));
    Navigator.of(context).pop(p);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    final (amountLabel, priceLabel) = switch (_feed.unit) {
      FeedUnit.bags => (l10n.unitBagsLabel, l10n.pricePerBag),
      FeedUnit.blocks => (l10n.unitBlocksLabel, l10n.pricePerBlock),
      FeedUnit.kg => (l10n.unitTonnes, l10n.pricePerTonne),
    };
    return DiscardGuard(
      dirty: _dirty,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetTitle(l10n.buyFeed, subtitle: l10n.buyFeedSub),
          context.space.gapLg,
          FarmTapSelectField<FeedKind>(
            label: l10n.colFeed,
            icon: Symbols.inventory_2_rounded,
            options: FeedKind.values,
            value: _feed,
            labelOf: (k) => feedLabel(l10n, k),
            onChanged: (k) => setState(() => _feed = k),
          ),
          context.space.gapLg,
          FarmTapTextField(
            label: amountLabel,
            icon: Symbols.inventory_2_rounded,
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
          ),
          context.space.gapLg,
          FarmTapTextField(
            label: priceLabel,
            prefixText: 'UGX ',
            controller: _price,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9,]'))],
            onChanged: (_) => setState(() {}),
          ),
          context.space.gapLg,
          FarmTapTextField(
            label: l10n.supplier,
            icon: Symbols.storefront_rounded,
            controller: _supplier,
            onChanged: (_) => setState(() {}),
          ),
          context.space.gapLg,
          FarmTapCard(
            child: Column(
              children: [
                const Divider(height: 0),
                context.space.gapLg,
                SummaryRow(label: l10n.total, value: f.money(_total), emphasis: true),
              ],
            ),
          ),
          context.space.gapXl,
          FarmTapButton(label: l10n.savePurchase, icon: Symbols.check_rounded, onPressed: _total > 0 ? _save : null),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- I02

class RecordFeedingPage extends StatefulWidget {
  const new({required this.repo, required this.onSaved, super.key, this.initialAmount});

  final FeedRepository repo;
  final VoidCallback onSaved;

  /// Goldens: the mockup shows 1.5 typed.
  final String? initialAmount;

  @override
  State<RecordFeedingPage> createState() => _RecordFeedingPageState();
}

class _RecordFeedingPageState extends State<RecordFeedingPage> {
  static const List<FeedKind> _chipOrder = [
    FeedKind.dairyMeal,
    FeedKind.maizeBran,
    FeedKind.silage,
    FeedKind.mineralLick,
  ];

  FeedGroup _group = FeedGroup.milkingCows;
  FeedKind _feed = FeedKind.dairyMeal;
  late DecimalEntry _entry = DecimalEntry(text: widget.initialAmount ?? '', maxIntegerDigits: 4);
  List<FeedStock> _stock = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_loadStock());
  }

  Future<void> _loadStock() async {
    final r = await widget.repo.summary();
    if (mounted) setState(() => _stock = r.data?.stock ?? const []);
  }

  String _unit(AppLocalizations l10n) => switch (_feed.unit) {
    FeedUnit.bags => l10n.unitBags,
    FeedUnit.blocks => l10n.unitBlocks,
    FeedUnit.kg => l10n.unitKg,
  };

  double? get _left => _stock.where((s) => s.feed == _feed).firstOrNull?.left;

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    final amount = '${f.litresValue(_entry.value)} ${_unit(l10n)}';
    await widget.repo.recordFeeding(feed: _feed, group: _group, amount: _entry.value);
    if (!mounted) return;
    FarmTapToast.show(context, message: l10n.feedingSaved(amount));
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    final unit = _unit(l10n);
    final left = _left;
    final over = left != null && _entry.value > left;
    return DiscardGuard(
      dirty: !_entry.isEmpty && _entry.text != widget.initialAmount,
      child: AdaptiveScaffold(
        title: l10n.recordFeeding,
        showNavigation: false,
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: context.sizes.keypadMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FarmTapAnimationView(
                  animation: FarmTapAnimations.feeding,
                  size: context.sizes.animationSm,
                  semanticLabel: l10n.recordFeeding,
                ),
                context.space.gapLg,
                Text(l10n.whichGroup, style: context.text.titleSmall),
                context.space.gapSm,
                FilterChips<FeedGroup>(
                  wrap: true,
                  options: [for (final g in FeedGroup.values) FilterOption(value: g, label: groupLabel(l10n, g))],
                  selected: _group,
                  onSelected: (g) => setState(() => _group = g),
                ),
                context.space.gapLg,
                Text(l10n.whichFeed, style: context.text.titleSmall),
                context.space.gapSm,
                FilterChips<FeedKind>(
                  wrap: true,
                  options: [for (final k in _chipOrder) FilterOption(value: k, label: feedLabel(l10n, k))],
                  selected: _feed,
                  onSelected: (k) => setState(() => _feed = k),
                ),
                context.space.gapLg,
                KeypadDisplay(
                  text: _entry.text,
                  unit: unit,
                  caption: over
                      ? l10n.moreThanInStock(_stockLong(l10n, f, _feed, left))
                      : l10n.feedAmountCaption(
                          '${unit[0].toUpperCase()}${unit.substring(1)}',
                          feedLabel(l10n, _feed).toLowerCase(),
                        ),
                ),
                context.space.gapLg,
                BigNumberKeypad(
                  showDecimal: true,
                  onDigit: (d) => setState(() => _entry = _entry.press(d)),
                  onBackspace: () => setState(() => _entry = _entry.backspace()),
                ),
                context.space.gapSm,
                FarmTapButton(
                  label: l10n.saveFeeding,
                  icon: Symbols.check_rounded,
                  large: true,
                  onPressed: _entry.value > 0 && !over ? _save : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
