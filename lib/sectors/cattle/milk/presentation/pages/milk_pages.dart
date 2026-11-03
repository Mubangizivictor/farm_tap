// Milk: F01 today, F02 pick cow (+ F06 treated warning), F03 keypad (+ F04
// read-back, F05 saved), F07 quick total, F08 use split, F09 sales, F10 trends.
import 'dart:async';

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
  const new({required this.repo, required this.onRecord, required this.onTool, super.key, this.today});

  final MilkRepository repo;
  final VoidCallback onRecord;

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

  Future<(MilkSessionSummary?, MilkSessionSummary?)> _load() async =>
      ((await widget.repo.session(MilkSession.morning)).data, (await widget.repo.session(MilkSession.evening)).data);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    final today = widget.today ?? context.clock.now();
    return AdaptiveScaffold(
      title: l10n.milk,
      subtitle: f.longDay(today),
      actions: [BarAction(icon: Symbols.calendar_month_rounded, tooltip: l10n.pickDay, onPressed: () {})],
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
                spacing: context.space.lg,
                children: [
                  ListCard(
                    title: l10n.justRecorded,
                    actionLabel: l10n.seeAll,
                    onAction: widget.onRecord,
                    children: [for (final c in recent.reversed.take(3)) _RecordedTile(cow: c)],
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
                spacing: context.space.lg,
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
  const new({required this.cow});

  final MilkCow cow;

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

  @override
  void initState() {
    super.initState();
    unawaited(widget.repo.use().then((r) => mounted ? setState(() => _lines = r.data) : null));
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
    const produced = 312.0;
    return AdaptiveScaffold(
      title: l10n.milkUse,
      subtitle: l10n.todayLitres(f.litresValue(produced)),
      showNavigation: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FarmTapProgress(
            value: total / produced,
            label: l10n.accountedFor,
            trailingLabel: '${f.litresValue(total)} / ${f.litres(produced)}',
            color: total == produced ? context.status.success : null,
          ),
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

class MilkSalesPage extends StatelessWidget {
  const new({required this.repo, super.key, this.onAddSale});

  final MilkRepository repo;
  final VoidCallback? onAddSale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    return FutureBuilder<MilkSalesSummary?>(
      future: repo.sales().then((r) => r.data),
      builder: (context, snapshot) {
        final summary = snapshot.data;
        final sales = summary?.sales ?? const <MilkSale>[];
        IconData icon(BuyerKind k) => switch (k) {
          BuyerKind.centre => Symbols.storefront_rounded,
          BuyerKind.shop => Symbols.storefront_rounded,
          BuyerKind.neighbours => Symbols.groups_rounded,
        };
        FarmTapTone tone(BuyerKind k) => switch (k) {
          BuyerKind.centre => FarmTapTone.primary,
          BuyerKind.shop => FarmTapTone.gold,
          BuyerKind.neighbours => FarmTapTone.info,
        };
        Widget status(MilkSale s) => StatusBadge(
          label: s.paid ? l10n.paid : l10n.unpaid,
          tone: s.paid ? FarmTapTone.success : FarmTapTone.warning,
        );
        return AdaptiveScaffold(
          title: l10n.milkSales,
          actions: [BarAction(icon: Symbols.download_rounded, tooltip: l10n.download, onPressed: () {})],
          floatingActionButton: FarmTapFab(label: l10n.addSale, icon: Symbols.add_rounded, onPressed: onAddSale),
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
              RecordCollection<MilkSale>(
                items: sales,
                tileBuilder: (context, s) => RecordTile(
                  leading: IconBubble(icon: icon(s.kind), tone: tone(s.kind)),
                  title: s.buyer,
                  subtitle: l10n.litresTimesPrice(f.litresValue(s.litres), f.money(s.pricePerLitre)),
                  trailingValue: f.count(s.amount),
                  trailingSub: s.paid ? l10n.paid : l10n.unpaid,
                  onTap: () {},
                ),
                columns: [
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

// ---------------------------------------------------------------- F10

class MilkTrendsPage extends StatefulWidget {
  const new({required this.repo, super.key, this.today});

  final MilkRepository repo;
  final DateTime? today;

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
        return AdaptiveScaffold(
          title: l10n.milkTrends,
          actions: [BarAction(icon: Symbols.download_rounded, tooltip: l10n.download, onPressed: () {})],
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
                          label: l10n.vsPrevious('${t.changePercent >= 0 ? '+' : ''}${t.changePercent}%', previous),
                          tone: FarmTapTone.success,
                          icon: Symbols.trending_up_rounded,
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
                  spacing: context.space.lg,
                  children: [
                    ListCard(
                      title: l10n.topCows,
                      children: [
                        for (final c in t.top)
                          RecordTile(
                            leading: CowAvatar(avatarIndex: c.cow.avatarIndex, animalId: c.cow.id),
                            title: c.cow.name,
                            subtitle: l10n.averagePerDay(f.litresValue(c.average, trim: false)),
                            trailingValue: '+${c.changePercent}%',
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
                            onTap: () {},
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
