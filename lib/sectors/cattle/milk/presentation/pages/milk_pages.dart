// Milk: F01 today, F02 pick cow (+ F06 treated warning), F03 keypad (+ F04
// read-back, F05 saved), F07 quick total, F08 use split, F09 sales, F10 trends.
import 'dart:async';

import 'package:farm_tap/core/export/table_export.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/core/utils/formats.dart';
import 'package:farm_tap/sectors/cattle/milk/domain/milk_models.dart';
import 'package:farm_tap/sectors/cattle/milk/domain/milk_repository.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Litres above this ask "Are you sure?" (UX_SPEC F03).
const double bigMilkLitres = 30;

String sessionName(AppLocalizations l10n, MilkSession s) => s == MilkSession.morning ? l10n.morning : l10n.evening;

/// Morning before noon, evening after.
MilkSession sessionAt(DateTime t) => t.hour < 12 ? MilkSession.morning : MilkSession.evening;

FarmTapFormat _fmt(BuildContext context) => FarmTapFormat(Localizations.localeOf(context).toLanguageTag());

// ---------------------------------------------------------------- F01

enum _DayView { morning, evening, total }

class MilkTodayPage extends StatefulWidget {
  const new({required this.repo, required this.onRecord, required this.onTool, super.key, this.today, this.onCow});

  final MilkRepository repo;
  final VoidCallback onRecord;

  /// Opens a cow's page (tap on a recorded or "check these" cow).
  final ValueChanged<String>? onCow;

  /// 0 quick total, 1 use, 2 sales, 3 trends.
  final ValueChanged<int> onTool;
  final DateTime? today;

  @override
  State<MilkTodayPage> createState() => _MilkTodayPageState();
}

class _MilkTodayPageState extends State<MilkTodayPage> {
  late _DayView _view = sessionAt(widget.today ?? context.clock.now()) == MilkSession.morning
      ? _DayView.morning
      : _DayView.evening;

  /// A past day picked from the calendar (null = today).
  DateTime? _picked;

  Future<(MilkSessionSummary?, MilkSessionSummary?)> _load() async => (
    (await widget.repo.session(MilkSession.morning, day: _picked)).data,
    (await widget.repo.session(MilkSession.evening, day: _picked)).data,
  );

  Future<void> _pickDay(DateTime today) async {
    final first = DateTime(today.year - 2, today.month, today.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _picked ?? today,
      firstDate: first,
      lastDate: today,
      helpText: AppLocalizations.of(context).pickDay,
    );
    if (picked == null || !mounted) return;
    final isToday = picked.year == today.year && picked.month == today.month && picked.day == today.day;
    setState(() {
      _picked = isToday ? null : picked;
      if (!isToday) _view = _DayView.total;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    final now = widget.today ?? context.clock.now();
    final today = _picked ?? now;
    return AdaptiveScaffold(
      title: l10n.milk,
      subtitle: _picked == null ? f.longDay(today) : l10n.viewingDay(f.longDay(today)),
      actions: [
        if (_picked != null)
          BarAction(
            icon: Symbols.today_rounded,
            tooltip: l10n.backToToday,
            onPressed: () => setState(() => _picked = null),
          ),
        BarAction(icon: Symbols.calendar_month_rounded, tooltip: l10n.pickDay, onPressed: () => _pickDay(now)),
      ],
      floatingActionButton: FarmTapFab(label: l10n.recordMilk, icon: Symbols.add_rounded, onPressed: widget.onRecord),
      body: FutureBuilder<(MilkSessionSummary?, MilkSessionSummary?)>(
        future: _load(),
        builder: (context, snapshot) {
          final (morning, evening) = snapshot.data ?? (null, null);
          final s = _view == _DayView.evening ? evening : morning;
          final litres = _view == _DayView.total ? (morning?.litres ?? 0) + (evening?.litres ?? 0) : s?.litres ?? 0;
          final label = switch (_view) {
            _DayView.morning => l10n.sessionLabel(l10n.morning),
            _DayView.evening => l10n.sessionLabel(l10n.evening),
            _DayView.total => l10n.dayTotal,
          };
          final cows = s?.cows ?? const <MilkCow>[];
          final recent = [
            for (final c in cows)
              if (c.recorded && c.treatment == null) c,
          ]..sort((a, b) => (a.recordedAt ?? today).compareTo(b.recordedAt ?? today));
          final check = [
            for (final c in cows)
              if (c.treatment != null || !c.recorded) c,
          ].take(2).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedTabs<_DayView>(
                options: [
                  TabOption(value: _DayView.morning, label: l10n.morning),
                  TabOption(value: _DayView.evening, label: l10n.evening),
                  TabOption(value: _DayView.total, label: l10n.dayTotal),
                ],
                selected: _view,
                onChanged: (v) => setState(() => _view = v),
              ),
              context.space.gapLg,
              HeroCard(
                label: label,
                value: f.litresValue(litres, trim: false),
                unit: l10n.litreUnit,
                sub: s == null ? null : l10n.fromCows(s.recordedCount, s.totalCows),
                animation: FarmTapAnimations.milking,
              ),
              if (s != null) ...[
                context.space.gapLg,
                FarmTapProgress(
                  value: s.totalCows == 0 ? 0 : s.recordedCount / s.totalCows,
                  thin: true,
                  label: l10n.cowsRecorded,
                  trailingLabel: l10n.countOf(s.recordedCount, s.totalCows),
                ),
              ],
              context.space.gapLg,
              ResponsiveGrid(
                minItemWidth: context.sizes.gridPaired,
                maxColumns: 2,
                spacing: context.space.md,
                children: [
                  ListCard(
                    title: l10n.justRecorded,
                    actionLabel: l10n.seeAll,
                    onAction: widget.onRecord,
                    children: [
                      for (final c in recent.reversed.take(3))
                        _RecordedTile(cow: c, onTap: widget.onCow == null ? null : () => widget.onCow!(c.id)),
                    ],
                  ),
                  ListCard(
                    title: l10n.checkThese,
                    children: [
                      for (final c in check)
                        RecordTile(
                          leading: CowAvatar(avatarIndex: c.avatarIndex, animalId: c.id),
                          title: c.name,
                          subtitle: c.treatment != null
                              ? l10n.notForSaleUntilShort(f.dayMonth(c.treatment!.until))
                              : l10n.notRecordedYet,
                          badge: c.treatment != null
                              ? StatusBadge(label: l10n.statusTreated, tone: FarmTapTone.danger)
                              : StatusBadge(label: l10n.statusMilking, tone: FarmTapTone.success),
                          trailingValue: c.recorded ? f.litres(c.recordedLitres!) : '—',
                          onTap: widget.onCow == null ? null : () => widget.onCow!(c.id),
                        ),
                    ],
                  ),
                ],
              ),
              context.space.gapLg,
              SectionLabel(l10n.milkTools),
              context.space.gapSm,
              ResponsiveGrid(
                minItemWidth: context.sizes.gridAction,
                spacing: context.space.md,
                children: [
                  ActionTile(icon: Symbols.functions_rounded, label: l10n.quickTotal, onTap: () => widget.onTool(0)),
                  ActionTile(
                    icon: Symbols.pie_chart_rounded,
                    label: l10n.milkUse,
                    tone: FarmTapTone.info,
                    onTap: () => widget.onTool(1),
                  ),
                  ActionTile(
                    icon: Symbols.sell_rounded,
                    label: l10n.milkSales,
                    tone: FarmTapTone.gold,
                    onTap: () => widget.onTool(2),
                  ),
                  ActionTile(
                    icon: Symbols.show_chart_rounded,
                    label: l10n.milkTrends,
                    tone: FarmTapTone.success,
                    onTap: () => widget.onTool(3),
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

class _RecordedTile extends StatelessWidget {
  const new({required this.cow, this.onTap});

  final MilkCow cow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    return RecordTile(
      leading: CowAvatar(avatarIndex: cow.avatarIndex, animalId: cow.id),
      title: cow.name,
      subtitle: '${cow.tag} · ${l10n.breedAge(cow.breed, cow.ageYears)}',
      badge: StatusBadge(label: l10n.statusMilking, tone: FarmTapTone.success),
      trailingValue: f.litres(cow.recordedLitres!),
      trailingSub: cow.recordedAt == null ? null : f.clock24(cow.recordedAt!),
      onTap: onTap,
    );
  }
}

// ---------------------------------------------------------------- F02

class PickCowPage extends StatefulWidget {
  const new({required this.repo, required this.onCow, super.key, this.onScan, this.now});

  final MilkRepository repo;

  /// A cow was picked (`notForSale` after the F06 warning).
  final void Function(MilkCow cow, {required bool notForSale}) onCow;
  final VoidCallback? onScan;
  final DateTime? now;

  @override
  State<PickCowPage> createState() => _PickCowPageState();
}

class _PickCowPageState extends State<PickCowPage> {
  bool _onlyMissing = false;
  String _query = '';

  MilkSession get _session => sessionAt(widget.now ?? context.clock.now());

  Future<void> _pick(MilkCow cow) async {
    final t = cow.treatment;
    if (t == null) {
      widget.onCow(cow, notForSale: false);
      return;
    }
    final ok = await showTreatedCowWarning(context, cow);
    if (ok && mounted) widget.onCow(cow, notForSale: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<MilkSessionSummary?>(
      future: widget.repo.session(_session).then((r) => r.data),
      builder: (context, snapshot) {
        final cows = snapshot.data?.cows ?? const <MilkCow>[];
        final missing = cows.where((c) => !c.recorded).length;
        final q = _query.trim().toLowerCase();
        final shown = [
          for (final c in cows)
            if ((!_onlyMissing || !c.recorded) &&
                (q.isEmpty || c.name.toLowerCase().contains(q) || c.tag.toLowerCase().contains(q)))
              c,
        ];
        return AdaptiveScaffold(
          title: l10n.recordMilk,
          subtitle: l10n.sessionLabel(sessionName(l10n, _session)),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SearchField(hint: l10n.searchCow, onChanged: (v) => setState(() => _query = v)),
              context.space.gapMd,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: FilterChips<bool>(
                      wrap: true,
                      options: [
                        FilterOption(value: true, label: l10n.notRecordedCount(missing)),
                        FilterOption(value: false, label: l10n.allCount(snapshot.data?.totalCows ?? cows.length)),
                      ],
                      selected: _onlyMissing,
                      onSelected: (v) => setState(() => _onlyMissing = v),
                    ),
                  ),
                  FarmTapButton(
                    label: l10n.scan,
                    icon: Symbols.qr_code_scanner_rounded,
                    kind: ButtonKind.tonal,
                    expand: false,
                    onPressed: widget.onScan,
                  ),
                ],
              ),
              context.space.gapMd,
              ResponsiveGrid(
                minItemWidth: context.sizes.avatarHero + context.space.sm,
                maxColumns: 8,
                fillLastRow: false,
                spacing: context.space.md,
                children: [for (final c in shown) _CowTile(cow: c, onTap: () => _pick(c))],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Big photo tile: green tick = recorded; red = under treatment.
class _CowTile extends StatelessWidget {
  const new({required this.cow, required this.onTap});

  final MilkCow cow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final treated = cow.treatment != null;
    final c = context.colors;
    final bg = treated
        ? context.status.dangerContainer
        : cow.recorded
        ? c.primaryContainer
        : context.status.card;
    final border = treated
        ? BorderSide(color: context.status.danger, width: context.sizes.borderThick)
        : BorderSide(color: c.outlineVariant, width: context.sizes.borderThin);
    return Semantics(
      button: true,
      label: [cow.name, cow.tag, if (cow.recorded) l10n.recorded, if (treated) l10n.statusTreated].join(', '),
      excludeSemantics: true,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(borderRadius: context.radii.card, side: border),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: context.space.md, horizontal: context.space.xs),
            child: Stack(
              children: [
                Column(
                  children: [
                    CowAvatar(avatarIndex: cow.avatarIndex, animalId: cow.id, size: context.sizes.avatarLg),
                    context.space.gapSm,
                    Text(cow.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleSmall),
                    Text(cow.tag, style: context.text.bodySmall),
                  ],
                ),
                if (cow.recorded || treated)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Icon(
                      treated ? Symbols.medication_rounded : Symbols.check_circle_rounded,
                      fill: 1,
                      size: context.sizes.iconMd,
                      color: treated ? context.status.danger : context.status.success,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// F06 — milk from a treated cow. True = record it as not for sale.
Future<bool> showTreatedCowWarning(BuildContext context, MilkCow cow) {
  final l10n = AppLocalizations.of(context);
  final f = _fmt(context);
  final t = cow.treatment!;
  return showFarmTapDialog(
    context,
    icon: Symbols.medication_rounded,
    tone: FarmTapTone.danger,
    title: l10n.underTreatmentTitle(cow.name),
    message: l10n.underTreatmentBody(t.drug, f.dayMonth(t.given), '${f.weekday(t.until)} ${f.dayMonth(t.until)}'),
    primaryLabel: l10n.recordNotForSale,
    primaryKind: ButtonKind.danger,
    secondaryLabel: l10n.cancel,
    secondaryKind: ButtonKind.text,
  );
}

// ---------------------------------------------------------------- F03-F05

/// What happened after the celebration (F05).
enum MilkSaveNext { nextCow, finish }

class MilkKeypadPage extends StatefulWidget {
  const new({
    required this.repo,
    required this.cowId,
    required this.recorderName,
    required this.recordedBy,
    required this.onDone,
    super.key,
    this.notForSale = false,
    this.now,
  });

  final MilkRepository repo;
  final String cowId;
  final String recorderName;

  /// Staff id (or "owner") saved on the record for the audit trail.
  final String recordedBy;
  final bool notForSale;

  /// After the save: the next cow to record (null when all are done).
  final void Function(MilkSaveNext next, MilkCow? nextCow) onDone;
  final DateTime? now;

  @override
  State<MilkKeypadPage> createState() => _MilkKeypadPageState();
}

class _MilkKeypadPageState extends State<MilkKeypadPage> {
  late final Future<MilkCow?> _cow = widget.repo.cow(widget.cowId).then((r) => r.data);
  DecimalEntry _entry = const DecimalEntry(maxIntegerDigits: 2);

  MilkSession get _session => sessionAt(widget.now ?? context.clock.now());

  Future<void> _next(MilkCow cow) async {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    final litres = _entry.value;
    if (litres <= 0) return;
    if (litres > bigMilkLitres) {
      final sure = await showFarmTapDialog(
        context,
        icon: Symbols.help_rounded,
        title: l10n.areYouSure,
        message: l10n.bigMilkBody(f.litresValue(litres, trim: false)),
        primaryLabel: l10n.yesCorrect,
        secondaryLabel: l10n.noChangeIt,
      );
      if (!sure || !mounted) return;
    }
    final ok = await showReadBack(
      context,
      leading: CowAvatar(
        avatarIndex: cow.avatarIndex,
        animalId: cow.id,
        size: context.sizes.avatarReadBack,
        ring: true,
      ),
      subject: '${cow.name} · ${cow.tag}',
      valueText: l10n.litresValue(f.litresValue(litres, trim: false)),
      detail: l10n.recordedBy(sessionName(l10n, _session), widget.recorderName),
    );
    if (!ok || !mounted) return;
    await widget.repo.recordCow(cow.id, _session, litres, notForSale: widget.notForSale, recordedBy: widget.recordedBy);
    final summary = (await widget.repo.session(_session)).data;
    if (!mounted) return;
    final nextCow = summary?.cows.where((c) => !c.recorded && c.treatment == null).firstOrNull;
    final action = await showCelebration(
      context,
      animation: FarmTapAnimations.milkSaved,
      sound: FarmTapSound.pop,
      autoAdvance: nextCow != null,
      title: l10n.savedMilk(f.litresValue(litres, trim: false), cow.name),
      message: summary == null
          ? null
          : l10n.cowsDoneThisSession(
              summary.recordedCount,
              summary.totalCows,
              sessionName(l10n, _session).toLowerCase(),
            ),
      primaryLabel: nextCow == null ? l10n.allCowsDone : l10n.nextCow(nextCow.name),
      primaryIcon: Symbols.arrow_forward_rounded,
      secondaryLabel: l10n.finishSession,
      secondaryKind: ButtonKind.text,
    );
    if (!mounted) return;
    widget.onDone(
      action == CelebrationAction.secondary || nextCow == null ? MilkSaveNext.finish : MilkSaveNext.nextCow,
      nextCow,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    return FutureBuilder<MilkCow?>(
      future: _cow,
      builder: (context, snapshot) {
        final cow = snapshot.data;
        return AdaptiveScaffold(
          title: cow == null ? '' : '${cow.name} · ${cow.tag}',
          subtitle: l10n.sessionLabel(sessionName(l10n, _session)),
          showNavigation: false,
          body: cow == null
              ? const SizedBox.shrink()
              : Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: context.sizes.keypadMaxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            CowAvatar(avatarIndex: cow.avatarIndex, animalId: cow.id, size: context.sizes.avatarMl),
                            context.space.gapMd,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.howManyLitres, style: context.text.titleMedium),
                                if (cow.lastLitres != null)
                                  Text(
                                    l10n.lastTime(f.litresValue(cow.lastLitres!, trim: false)),
                                    style: context.text.bodySmall,
                                  ),
                              ],
                            ),
                          ],
                        ),
                        context.space.gapMd,
                        KeypadDisplay(text: _entry.text, unit: l10n.litreUnit),
                        context.space.gapMd,
                        BigNumberKeypad(
                          showDecimal: true,
                          onDigit: (d) => setState(() => _entry = _entry.press(d)),
                          onBackspace: () => setState(() => _entry = _entry.backspace()),
                        ),
                        context.space.gapSm,
                        FarmTapButton(
                          label: l10n.next,
                          icon: Symbols.check_rounded,
                          large: true,
                          onPressed: _entry.value > 0 ? () => _next(cow) : null,
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------- F07

class QuickTotalPage extends StatefulWidget {
  const new({required this.repo, required this.onSaved, required this.recordedBy, super.key, this.now});

  final MilkRepository repo;
  final VoidCallback onSaved;

  /// Staff id (or "owner") saved on the record.
  final String recordedBy;
  final DateTime? now;

  @override
  State<QuickTotalPage> createState() => _QuickTotalPageState();
}

class _QuickTotalPageState extends State<QuickTotalPage> {
  DecimalEntry _entry = const DecimalEntry(maxIntegerDigits: 4);

  MilkSession get _session => sessionAt(widget.now ?? context.clock.now());

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    final ok = await showReadBack(
      context,
      leading: IconBubble(icon: Symbols.water_drop_rounded, size: context.sizes.bubbleXl),
      subject: l10n.wholeHerd,
      valueText: l10n.litresValue(f.litresValue(_entry.value)),
      detail: l10n.sessionLabel(sessionName(l10n, _session)),
    );
    if (!ok || !mounted) return;
    await widget.repo.recordTotal(_session, _entry.value, recordedBy: widget.recordedBy);
    if (!mounted) return;
    FarmTapToast.show(context, message: l10n.totalSaved(f.litresValue(_entry.value)));
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = sessionName(l10n, _session);
    return AdaptiveScaffold(
      title: l10n.quickTotal,
      subtitle: l10n.wholeHerdSession(session),
      showNavigation: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FarmTapBanner(
            tone: FarmTapTone.info,
            icon: Symbols.info_rounded,
            title: l10n.quickMode,
            message: l10n.quickModeBody,
          ),
          context.space.gapLg,
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.sizes.keypadMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  KeypadDisplay(
                    text: _entry.text,
                    unit: l10n.litreUnit,
                    caption: l10n.totalFromAllCows(session.toLowerCase()),
                  ),
                  context.space.gapLg,
                  BigNumberKeypad(
                    showDecimal: true,
                    onDigit: (d) => setState(() => _entry = _entry.press(d)),
                    onBackspace: () => setState(() => _entry = _entry.backspace()),
                  ),
                  context.space.gapSm,
                  FarmTapButton(
                    label: l10n.saveTotal,
                    icon: Symbols.check_rounded,
                    large: true,
                    onPressed: _entry.value > 0 ? _save : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- F08

class MilkUsePage extends StatefulWidget {
  const new({required this.repo, required this.onSaved, super.key});

  final MilkRepository repo;
  final VoidCallback onSaved;

  @override
  State<MilkUsePage> createState() => _MilkUsePageState();
}

class _MilkUsePageState extends State<MilkUsePage> {
  List<MilkUseLine>? _lines;

  /// Today's milk from the milk records.
  double _produced = 0;

  @override
  void initState() {
    super.initState();
    unawaited(widget.repo.use().then((r) => mounted ? setState(() => _lines = r.data) : null));
    unawaited(widget.repo.litresOn().then((r) => mounted ? setState(() => _produced = r.data ?? 0) : null));
  }

  Future<void> _edit(int i) async {
    final l10n = AppLocalizations.of(context);
    final line = _lines![i];
    var entry = DecimalEntry(text: line.litres == 0 ? '' : _fmt(context).litresValue(line.litres), maxIntegerDigits: 4);
    final value = await showAdaptiveSheet<double>(
      context,
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, set) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetTitle(_useLabel(l10n, line.kind)),
            sheet.space.gapLg,
            KeypadDisplay(text: entry.text, unit: l10n.litreUnit),
            sheet.space.gapLg,
            Center(
              child: BigNumberKeypad(
                showDecimal: true,
                onDigit: (d) => set(() => entry = entry.press(d)),
                onBackspace: () => set(() => entry = entry.backspace()),
              ),
            ),
            sheet.space.gapSm,
            FarmTapButton(
              label: l10n.done,
              icon: Symbols.check_rounded,
              onPressed: () => Navigator.of(sheet).pop(entry.value),
            ),
          ],
        ),
      ),
    );
    if (value == null) return;
    setState(() => _lines![i] = MilkUseLine(kind: line.kind, litres: value, detail: line.detail));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    final lines = _lines ?? const <MilkUseLine>[];
    final total = lines.fold<double>(0, (s, l) => s + l.litres);
    final produced = _produced;
    final balanced = (total - produced).abs() < 0.05;
    return AdaptiveScaffold(
      title: l10n.milkUse,
      subtitle: l10n.todayLitres(f.litresValue(produced)),
      showNavigation: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FarmTapProgress(
            value: produced <= 0 ? 0 : (total / produced).clamp(0, 1).toDouble(),
            label: l10n.accountedFor,
            trailingLabel: '${f.litresValue(total)} / ${f.litres(produced)}',
            color: balanced ? context.status.success : null,
          ),
          if (produced <= 0) ...[
            context.space.gapSm,
            Text(l10n.noMilkRecordedToday, style: context.text.bodySmall),
          ] else if (total > produced + 0.05) ...[
            context.space.gapSm,
            Text(
              l10n.useMoreThanMilked(f.litres(total - produced)),
              style: context.text.bodySmall?.copyWith(color: context.colors.error),
            ),
          ],
          context.space.gapLg,
          ListCard(
            children: [
              for (var i = 0; i < lines.length; i++)
                RecordTile(
                  leading: IconBubble(icon: _useIcon(lines[i].kind), tone: _useTone(lines[i].kind)),
                  title: _useLabel(l10n, lines[i].kind),
                  subtitle: lines[i].detail,
                  trailingValue: f.litres(lines[i].litres),
                  showChevron: false,
                  onTap: () => _edit(i),
                ),
            ],
          ),
          context.space.gapLg,
          FarmTapButton(
            label: l10n.save,
            icon: Symbols.check_rounded,
            onPressed: _lines == null
                ? null
                : () async {
                    await widget.repo.saveUse(lines);
                    if (!context.mounted) return;
                    FarmTapToast.show(context, message: l10n.useSaved);
                    widget.onSaved();
                  },
          ),
        ],
      ),
    );
  }

  static String _useLabel(AppLocalizations l10n, MilkUseKind k) => switch (k) {
    MilkUseKind.sold => l10n.useSold,
    MilkUseKind.home => l10n.useHome,
    MilkUseKind.calves => l10n.useCalves,
    MilkUseKind.notForSale => l10n.useNotForSale,
    MilkUseKind.spoiled => l10n.useSpoiled,
  };

  static IconData _useIcon(MilkUseKind k) => switch (k) {
    MilkUseKind.sold => Symbols.sell_rounded,
    MilkUseKind.home => Symbols.home_rounded,
    MilkUseKind.calves => Symbols.pets_rounded,
    MilkUseKind.notForSale => Symbols.medication_rounded,
    MilkUseKind.spoiled => Symbols.delete_rounded,
  };

  static FarmTapTone _useTone(MilkUseKind k) => switch (k) {
    MilkUseKind.sold => FarmTapTone.primary,
    MilkUseKind.home => FarmTapTone.gold,
    MilkUseKind.calves => FarmTapTone.info,
    MilkUseKind.notForSale => FarmTapTone.danger,
    MilkUseKind.spoiled => FarmTapTone.neutral,
  };
}

// ---------------------------------------------------------------- F09

IconData _buyerIcon(BuyerKind k) => switch (k) {
  BuyerKind.centre => Symbols.storefront_rounded,
  BuyerKind.shop => Symbols.store_rounded,
  BuyerKind.neighbours => Symbols.groups_rounded,
};

FarmTapTone _buyerTone(BuyerKind k) => switch (k) {
  BuyerKind.centre => FarmTapTone.primary,
  BuyerKind.shop => FarmTapTone.gold,
  BuyerKind.neighbours => FarmTapTone.info,
};

String _buyerKindLabel(AppLocalizations l10n, BuyerKind k) => switch (k) {
  BuyerKind.centre => l10n.buyerCentre,
  BuyerKind.shop => l10n.buyerShop,
  BuyerKind.neighbours => l10n.buyerNeighbours,
};

class MilkSalesPage extends StatefulWidget {
  const new({required this.repo, super.key, this.farmName = ''});

  final MilkRepository repo;

  /// Printed at the top of an exported list.
  final String farmName;

  @override
  State<MilkSalesPage> createState() => _MilkSalesPageState();
}

class _MilkSalesPageState extends State<MilkSalesPage> {
  late Future<MilkSalesSummary?> _future = _load();

  Future<MilkSalesSummary?> _load() => widget.repo.sales().then((r) => r.data);

  void _reload() => setState(() => _future = _load());

  Future<void> _add() async {
    final l10n = AppLocalizations.of(context);
    final buyers = (await widget.repo.recentBuyers()).data ?? const <MilkSale>[];
    if (!mounted) return;
    final saved = await showAdaptiveSheet<MilkSale>(
      context,
      builder: (sheet) => _AddSaleSheet(repo: widget.repo, recent: buyers),
    );
    if (saved == null || !mounted) return;
    FarmTapToast.show(context, message: l10n.saleSaved);
    _reload();
  }

  Future<void> _open(MilkSale sale) async {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    final mark = await showAdaptiveSheet<bool>(
      context,
      builder: (sheet) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetTitle(sale.buyer, subtitle: sale.at == null ? null : f.day(sale.at!)),
          sheet.space.gapMd,
          SummaryRow(label: l10n.colLitres, value: f.litres(sale.litres)),
          SummaryRow(label: l10n.colPricePerL, value: f.money(sale.pricePerLitre)),
          SummaryRow(label: l10n.colAmount, value: f.money(sale.amount)),
          SummaryRow(
            label: l10n.colStatus,
            value: !sale.paid
                ? l10n.unpaid
                : sale.paidAt == null
                ? l10n.paid
                : l10n.paidOn(f.dayMonth(sale.paidAt!)),
          ),
          sheet.space.gapLg,
          if (!sale.paid)
            FarmTapButton(
              label: l10n.markPaid,
              icon: Symbols.payments_rounded,
              onPressed: () => Navigator.of(sheet).pop(true),
            )
          else
            FarmTapButton(
              label: l10n.markUnpaid,
              icon: Symbols.undo_rounded,
              kind: ButtonKind.outlined,
              onPressed: () => Navigator.of(sheet).pop(false),
            ),
        ],
      ),
    );
    if (mark == null || sale.id.isEmpty) return;
    await widget.repo.setSalePaid(sale.id, paid: mark);
    if (!mounted) return;
    FarmTapToast.show(context, message: mark ? l10n.salePaidSaved : l10n.saleUnpaidSaved);
    _reload();
  }

  Future<void> _export(List<MilkSale> sales) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    final total = sales.fold<int>(0, (t, x) => t + x.amount);
    final owed = sales.where((x) => !x.paid).fold<int>(0, (t, x) => t + x.amount);
    return exportTable(
      context,
      ExportTable(
        title: l10n.milkSales,
        subtitle: f.longDay(context.clock.now()),
        headers: [l10n.colDate, l10n.colBuyer, l10n.colLitres, l10n.colPricePerL, l10n.colAmount, l10n.colStatus],
        rows: [
          for (final x in sales)
            [
              if (x.at == null) '' else f.day(x.at!),
              x.buyer,
              f.litresValue(x.litres),
              f.count(x.pricePerLitre),
              f.count(x.amount),
              if (x.paid) l10n.paid else l10n.unpaid,
            ],
        ],
        footer: [
          [l10n.total, f.money(total)],
          [l10n.owedToYou, f.money(owed)],
        ],
      ),
      farmName: widget.farmName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    return FutureBuilder<MilkSalesSummary?>(
      future: _future,
      builder: (context, snapshot) {
        final summary = snapshot.data;
        final sales = summary?.sales ?? const <MilkSale>[];
        Widget status(MilkSale s) => StatusBadge(
          label: s.paid ? l10n.paid : l10n.unpaid,
          tone: s.paid ? FarmTapTone.success : FarmTapTone.warning,
        );
        return AdaptiveScaffold(
          title: l10n.milkSales,
          actions: [BarAction(icon: Symbols.download_rounded, tooltip: l10n.download, onPressed: () => _export(sales))],
          floatingActionButton: FarmTapFab(label: l10n.addSale, icon: Symbols.add_rounded, onPressed: _add),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MetricStrip(
                children: [
                  MetricCard(
                    icon: Symbols.local_shipping_rounded,
                    label: l10n.soldThisWeek,
                    value: f.count(summary?.soldThisWeek ?? 0),
                    unit: l10n.litreUnit,
                  ),
                  MetricCard(
                    icon: Symbols.receipt_long_rounded,
                    label: l10n.owedToYou,
                    value: f.moneyShort(summary?.owed ?? 0),
                    caption: l10n.buyersCount(summary?.buyersOwing ?? 0),
                    tone: FarmTapTone.gold,
                  ),
                ],
              ),
              context.space.gapLg,
              if (snapshot.connectionState == ConnectionState.done && sales.isEmpty)
                EmptyState(
                  title: l10n.noSalesYet,
                  actionIcon: Symbols.add_rounded,
                  message: l10n.noSalesYetBody,
                  actionLabel: l10n.addSale,
                  onAction: _add,
                )
              else
                RecordCollection<MilkSale>(
                  items: sales,
                  tileBuilder: (context, s) => RecordTile(
                    leading: IconBubble(icon: _buyerIcon(s.kind), tone: _buyerTone(s.kind)),
                    title: s.buyer,
                    subtitle: [
                      if (s.at != null) f.dayMonth(s.at!),
                      l10n.litresTimesPrice(f.litresValue(s.litres), f.money(s.pricePerLitre)),
                    ].join(' · '),
                    trailingValue: f.count(s.amount),
                    trailingSub: s.paid ? l10n.paid : l10n.unpaid,
                    onTap: () => _open(s),
                  ),
                  onTap: _open,
                  columns: [
                    RecordColumn(
                      label: l10n.colDate,
                      sortKey: (s) => s.at ?? DateTime(0),
                      cell: (c, s) => Text(s.at == null ? '' : f.dayMonth(s.at!)),
                    ),
                    RecordColumn(label: l10n.colBuyer, flex: 3, sortKey: (s) => s.buyer, cell: (c, s) => Text(s.buyer)),
                    RecordColumn(label: l10n.colLitres, cell: (c, s) => Text(f.litresValue(s.litres))),
                    RecordColumn(label: l10n.colPricePerL, cell: (c, s) => Text(f.count(s.pricePerLitre))),
                    RecordColumn(
                      label: l10n.colAmount,
                      sortKey: (s) => s.amount,
                      cell: (c, s) => Text(f.count(s.amount)),
                    ),
                    RecordColumn(label: l10n.colStatus, cell: (c, s) => status(s)),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

/// F09 "Add sale": who bought, how much, the price and whether they paid.
class _AddSaleSheet extends StatefulWidget {
  const new({required this.repo, required this.recent});

  final MilkRepository repo;
  final List<MilkSale> recent;

  @override
  State<_AddSaleSheet> createState() => _AddSaleSheetState();
}

class _AddSaleSheetState extends State<_AddSaleSheet> {
  final _buyer = TextEditingController();
  final _litres = TextEditingController();
  final _price = TextEditingController();
  BuyerKind _kind = BuyerKind.centre;
  bool _paid = false;
  bool _saving = false;
  bool _tried = false;

  @override
  void initState() {
    super.initState();
    final last = widget.recent.firstOrNull;
    if (last != null) _use(last);
  }

  @override
  void dispose() {
    _buyer.dispose();
    _litres.dispose();
    _price.dispose();
    super.dispose();
  }

  void _use(MilkSale s) {
    _buyer.text = s.buyer;
    _price.text = s.pricePerLitre.toString();
    _kind = s.kind;
  }

  double? get _l => double.tryParse(_litres.text.replaceAll(',', '.').trim());
  int? get _p => int.tryParse(_price.text.replaceAll(RegExp('[^0-9]'), ''));

  Future<void> _save() async {
    setState(() => _tried = true);
    final litres = _l;
    final price = _p;
    if (_buyer.text.trim().isEmpty || litres == null || litres <= 0 || price == null || price <= 0) return;
    setState(() => _saving = true);
    final r = await widget.repo.addSale(
      buyer: _buyer.text,
      kind: _kind,
      litres: litres,
      pricePerLitre: price,
      paid: _paid,
    );
    if (!mounted) return;
    Navigator.of(context).pop(r.data);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    final litres = _l ?? 0;
    final price = _p ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetTitle(l10n.addSale),
        context.space.gapMd,
        SegmentedTabs<BuyerKind>(
          options: [for (final k in BuyerKind.values) TabOption(value: k, label: _buyerKindLabel(l10n, k))],
          selected: _kind,
          onChanged: (k) => setState(() => _kind = k),
        ),
        context.space.gapMd,
        FarmTapTextField(
          label: l10n.colBuyer,
          controller: _buyer,
          icon: _buyerIcon(_kind),
          textInputAction: TextInputAction.next,
          error: _tried && _buyer.text.trim().isEmpty ? l10n.enterBuyer : null,
          onChanged: (_) => setState(() {}),
        ),
        if (widget.recent.length > 1) ...[
          context.space.gapSm,
          Wrap(
            spacing: context.space.chipRun,
            runSpacing: context.space.xs,
            children: [
              for (final s in widget.recent.take(6))
                FarmTapChip(
                  label: s.buyer,
                  selected: _buyer.text.trim().toLowerCase() == s.buyer.toLowerCase(),
                  onTap: () => setState(() => _use(s)),
                ),
            ],
          ),
        ],
        context.space.gapMd,
        Row(
          children: [
            Expanded(
              child: FarmTapTextField(
                label: l10n.colLitres,
                controller: _litres,
                icon: Symbols.water_drop_rounded,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                error: _tried && (_l == null || _l! <= 0) ? l10n.enterLitres : null,
                onChanged: (_) => setState(() {}),
              ),
            ),
            context.space.gapMd,
            Expanded(
              child: FarmTapTextField(
                label: l10n.pricePerLitre,
                controller: _price,
                prefixText: 'UGX ',
                keyboardType: TextInputType.number,
                error: _tried && (_p == null || _p! <= 0) ? l10n.enterPrice : null,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        context.space.gapMd,
        SummaryRow(label: l10n.total, value: f.money(litres * price), emphasis: true),
        context.space.gapSm,
        SegmentedTabs<bool>(
          options: [
            TabOption(value: false, label: l10n.notPaidYet),
            TabOption(value: true, label: l10n.paidNow),
          ],
          selected: _paid,
          onChanged: (v) => setState(() => _paid = v),
        ),
        context.space.gapLg,
        FarmTapButton(
          label: l10n.saveSale,
          icon: Symbols.check_rounded,
          loading: _saving,
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- F10

class MilkTrendsPage extends StatefulWidget {
  const new({required this.repo, super.key, this.today, this.onCow, this.farmName = ''});

  final MilkRepository repo;
  final DateTime? today;

  /// Opens a cow's page (to check her health when her milk drops).
  final ValueChanged<String>? onCow;
  final String farmName;

  @override
  State<MilkTrendsPage> createState() => _MilkTrendsPageState();
}

class _MilkTrendsPageState extends State<MilkTrendsPage> {
  TrendRange _range = TrendRange.month;

  DateTime get _now => widget.today ?? context.clock.now();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    return FutureBuilder<MilkTrend?>(
      future: widget.repo.trend(_range).then((r) => r.data),
      builder: (context, snapshot) {
        final t = snapshot.data;
        final (totalLabel, previous) = switch (_range) {
          TrendRange.week => (l10n.totalThisWeek, l10n.week),
          TrendRange.month => (l10n.totalThisMonth, f.monthShort(DateTime(_now.year, _now.month - 1))),
          TrendRange.year => (l10n.totalThisYear, l10n.year),
        };
        String pct(int p) => '${p >= 0 ? '+' : ''}$p%';
        return AdaptiveScaffold(
          title: l10n.milkTrends,
          actions: [
            BarAction(
              icon: Symbols.download_rounded,
              tooltip: l10n.download,
              onPressed: t == null
                  ? null
                  : () => exportTable(
                      context,
                      ExportTable(
                        title: '${l10n.milkTrends} · $totalLabel',
                        subtitle: f.longDay(_now),
                        headers: [l10n.colDate, l10n.colLitres],
                        rows: [
                          for (var i = 0; i < t.points.length; i++) [t.labels[i], f.litresValue(t.points[i])],
                        ],
                        footer: [
                          [l10n.total, f.litres(t.total)],
                        ],
                      ),
                      farmName: widget.farmName,
                    ),
            ),
          ],
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedTabs<TrendRange>(
                options: [
                  TabOption(value: TrendRange.week, label: l10n.week),
                  TabOption(value: TrendRange.month, label: l10n.month),
                  TabOption(value: TrendRange.year, label: l10n.year),
                ],
                selected: _range,
                onChanged: (r) => setState(() => _range = r),
              ),
              context.space.gapLg,
              if (t != null) ...[
                FarmTapCard(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(totalLabel, style: context.textStyles.metricLabel),
                              Text(f.litres(t.total).replaceAll('.0 L', ' L'), style: context.text.headlineMedium),
                            ],
                          ),
                        ),
                        StatusBadge(
                          label: l10n.vsPrevious(pct(t.changePercent), previous),
                          tone: t.changePercent >= 0 ? FarmTapTone.success : FarmTapTone.warning,
                          icon: t.changePercent >= 0 ? Symbols.trending_up_rounded : Symbols.trending_down_rounded,
                        ),
                      ],
                    ),
                    MilkLineChart(values: t.points, labels: t.labels, target: t.target),
                  ],
                ),
                context.space.gapLg,
                ResponsiveGrid(
                  minItemWidth: context.sizes.gridPaired,
                  maxColumns: 2,
                  spacing: context.space.md,
                  children: [
                    ListCard(
                      title: l10n.topCows,
                      children: [
                        for (final c in t.top)
                          RecordTile(
                            leading: CowAvatar(avatarIndex: c.cow.avatarIndex, animalId: c.cow.id),
                            title: c.cow.name,
                            subtitle: l10n.averagePerDay(f.litresValue(c.average, trim: false)),
                            trailingValue: pct(c.changePercent),
                            onTap: widget.onCow == null ? null : () => widget.onCow!(c.cow.id),
                          ),
                      ],
                    ),
                    ListCard(
                      title: l10n.droppingCheckHealth,
                      children: [
                        for (final c in t.dropping)
                          RecordTile(
                            leading: CowAvatar(avatarIndex: c.cow.avatarIndex, animalId: c.cow.id),
                            title: c.cow.name,
                            subtitle: l10n.todayVsAvg(
                              f.litresValue(c.today ?? 0, trim: false),
                              f.litresValue(c.average, trim: false),
                            ),
                            trailingValue: '${c.changePercent}%',
                            onTap: widget.onCow == null ? null : () => widget.onCow!(c.cow.id),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
