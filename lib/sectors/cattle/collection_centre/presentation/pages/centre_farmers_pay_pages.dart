// Collection centre farmers and pay: G06 farmers, G07 farmer detail, G09
// payments, G10 pay farmers, G11 SMS statements.
import 'dart:async';

import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/core/utils/formats.dart';
import 'package:farm_tap/sectors/cattle/collection_centre/domain/centre_models.dart';
import 'package:farm_tap/sectors/cattle/collection_centre/domain/centre_repository.dart';
import 'package:farm_tap/sectors/cattle/collection_centre/presentation/pages/centre_collect_pages.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

FarmTapFormat _fmt(BuildContext context) => FarmTapFormat(Localizations.localeOf(context).toLanguageTag());

/// "UGX 538k" under a million, "UGX 18.4M" above.
String _short(FarmTapFormat f, num ugx) => ugx < 1000000 ? 'UGX ${f.compact(ugx)}' : f.moneyShort(ugx);

String _network(AppLocalizations l10n, MobileNetwork n) =>
    n == MobileNetwork.mtn ? l10n.networkMtn : l10n.networkAirtel;

// ---------------------------------------------------------------- G06

class CentreFarmersPage extends StatefulWidget {
  const new({required this.repo, required this.onFarmer, required this.onAdd, super.key});

  final CentreRepository repo;
  final ValueChanged<CentreFarmer> onFarmer;
  final VoidCallback onAdd;

  @override
  State<CentreFarmersPage> createState() => _CentreFarmersPageState();
}

class _CentreFarmersPageState extends State<CentreFarmersPage> {
  late final Future<(List<CentreFarmer>, FarmerCounts?)> _load = _fetch();
  FarmerFilter _filter = FarmerFilter.all;
  String _query = '';

  Future<(List<CentreFarmer>, FarmerCounts?)> _fetch() async =>
      ((await widget.repo.farmers()).data ?? const <CentreFarmer>[], (await widget.repo.counts()).data);

  List<CentreFarmer> _shown(List<CentreFarmer> all) {
    final q = _query.trim().toLowerCase();
    return all.where((x) {
      final keep = switch (_filter) {
        FarmerFilter.all => true,
        FarmerFilter.deliveredToday => x.deliveredToday,
        FarmerFilter.notToday => !x.deliveredToday,
        FarmerFilter.noCard => x.card == null,
      };
      return keep && (q.isEmpty || x.name.toLowerCase().contains(q) || (x.card ?? '').contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    return FutureBuilder<(List<CentreFarmer>, FarmerCounts?)>(
      future: _load,
      builder: (context, snapshot) {
        final (all, counts) = snapshot.data ?? (const <CentreFarmer>[], null);
        final shown = _shown(all);
        return AdaptiveScaffold(
          title: l10n.farmers,
          subtitle: counts == null ? null : l10n.suppliersCount(counts.total),
          actions: [BarAction(icon: Symbols.download_rounded, tooltip: l10n.download, onPressed: () {})],
          floatingActionButton: FarmTapFab(
            label: l10n.addFarmer,
            icon: Symbols.person_add_rounded,
            onPressed: widget.onAdd,
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SearchField(hint: l10n.searchFarmers, onChanged: (v) => setState(() => _query = v)),
              context.space.gapMd,
              FilterChips<FarmerFilter>(
                wrap: true,
                options: [
                  FilterOption(value: FarmerFilter.all, label: l10n.filterAll),
                  if (counts != null) ...[
                    FilterOption(value: FarmerFilter.deliveredToday, label: l10n.deliveredToday(counts.deliveredToday)),
                    FilterOption(value: FarmerFilter.notToday, label: l10n.notToday(counts.notToday)),
                    FilterOption(value: FarmerFilter.noCard, label: l10n.noCard(counts.noCard)),
                  ],
                ],
                selected: _filter,
                onSelected: (v) => setState(() => _filter = v),
              ),
              context.space.gapSm,
              if (snapshot.hasData && shown.isEmpty)
                Padding(
                  padding: EdgeInsets.all(context.space.xl),
                  child: Text(l10n.noMatches, textAlign: TextAlign.center, style: context.text.bodyMedium),
                )
              else
                RecordCollection<CentreFarmer>(
                  items: shown,
                  onTap: widget.onFarmer,
                  tileBuilder: (context, x) => RecordTile(
                    leading: FarmerAvatar(farmer: x),
                    title: x.name,
                    subtitle: l10n.cardThisPeriod(x.card ?? '—', f.count(x.periodLitres)),
                    trailingValue: x.todayLitres == null ? '—' : f.litres(x.todayLitres!),
                    trailingSub: l10n.today,
                    onTap: () => widget.onFarmer(x),
                  ),
                  columns: [
                    RecordColumn(
                      label: l10n.colFarmer,
                      flex: 3,
                      sortKey: (x) => x.name,
                      cell: (context, x) => Row(
                        children: [
                          FarmerAvatar(farmer: x, size: context.sizes.avatarSm),
                          context.space.gapMd,
                          Flexible(child: Text(x.name, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                    RecordColumn(
                      label: l10n.colCard,
                      sortKey: (x) => x.card ?? '',
                      cell: (context, x) => Text(x.card ?? '—'),
                    ),
                    RecordColumn(
                      label: l10n.colToday,
                      sortKey: (x) => x.todayLitres ?? -1,
                      cell: (context, x) => Text(x.todayLitres == null ? '—' : f.litres(x.todayLitres!)),
                    ),
                    RecordColumn(
                      label: l10n.colThisPeriod,
                      flex: 2,
                      sortKey: (x) => x.periodLitres,
                      cell: (context, x) => Text(f.litres(x.periodLitres)),
                    ),
                    RecordColumn(
                      label: l10n.colOwed,
                      flex: 2,
                      sortKey: (x) => x.owed,
                      cell: (context, x) => Text(f.money(x.owed)),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Add a supplier from the G06 FAB: name, Mobile Money phone, village, card.
Future<CentreFarmer?> showAddFarmerSheet(BuildContext context, CentreRepository repo) =>
    showAdaptiveSheet<CentreFarmer>(context, builder: (_) => _AddFarmerSheet(repo: repo));

class _AddFarmerSheet extends StatefulWidget {
  const new({required this.repo});

  final CentreRepository repo;

  @override
  State<_AddFarmerSheet> createState() => _AddFarmerSheetState();
}

class _AddFarmerSheetState extends State<_AddFarmerSheet> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _village = TextEditingController();
  final _card = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _phone, _village, _card]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _ready => _name.text.trim().isNotEmpty && _phone.text.replaceAll(' ', '').length >= 9;

  Future<void> _save() async {
    final farmer = (await widget.repo.addFarmer(
      name: _name.text.trim(),
      phone: '+256 ${_phone.text.trim()}',
      village: _village.text.trim(),
      card: _card.text.trim(),
    )).data;
    if (!mounted || farmer == null) return;
    FarmTapToast.show(context, message: AppLocalizations.of(context).farmerSaved(farmer.name));
    Navigator.of(context).pop(farmer);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    void changed(String _) => setState(() {});
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(l10n.addFarmer),
        context.space.gapLg,
        FarmTapTextField(
          label: l10n.farmerName,
          icon: Symbols.person_rounded,
          controller: _name,
          textInputAction: TextInputAction.next,
          onChanged: changed,
        ),
        context.space.gapLg,
        FarmTapTextField(
          label: l10n.farmerPhone,
          icon: Symbols.call_rounded,
          prefixText: '+256 ',
          controller: _phone,
          keyboardType: TextInputType.phone,
          inputFormatters: [UgPhoneFormatter()],
          textInputAction: TextInputAction.next,
          onChanged: changed,
        ),
        context.space.gapLg,
        FarmTapTextField(
          label: l10n.villageLabel,
          icon: Symbols.location_on_rounded,
          controller: _village,
          textInputAction: TextInputAction.next,
        ),
        context.space.gapLg,
        FarmTapTextField(
          label: l10n.cardOptional,
          icon: Symbols.contactless_rounded,
          controller: _card,
          keyboardType: TextInputType.number,
        ),
        context.space.gapXl,
        FarmTapButton(label: l10n.saveFarmer, icon: Symbols.check_rounded, onPressed: _ready ? _save : null),
      ],
    );
  }
}

// ---------------------------------------------------------------- G07

class CentreFarmerPage extends StatefulWidget {
  const new({required this.repo, required this.farmerId, super.key});

  final CentreRepository repo;
  final String farmerId;

  @override
  State<CentreFarmerPage> createState() => _CentreFarmerPageState();
}

class _CentreFarmerPageState extends State<CentreFarmerPage> {
  late final Future<(CentreFarmer?, FarmerStatement?)> _load = _fetch();

  Future<(CentreFarmer?, FarmerStatement?)> _fetch() async =>
      ((await widget.repo.farmer(widget.farmerId)).data, (await widget.repo.statement(widget.farmerId)).data);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    return FutureBuilder<(CentreFarmer?, FarmerStatement?)>(
      future: _load,
      builder: (context, snapshot) {
        final (farmer, st) = snapshot.data ?? (null, null);
        return AdaptiveScaffold(
          title: l10n.farmerTitle,
          actions: [
            BarAction(icon: Symbols.call_rounded, tooltip: l10n.call, onPressed: () {}),
            BarAction(icon: Symbols.edit_rounded, tooltip: l10n.edit, onPressed: () {}),
          ],
          body: farmer == null || st == null
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FarmTapCard(
                      child: Row(
                        children: [
                          FarmerAvatar(farmer: farmer, size: context.sizes.avatarXl, plain: true),
                          context.space.gapLg,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(farmer.name, style: context.text.headlineSmall),
                                context.space.gapXs,
                                Text(
                                  farmer.card == null ? farmer.phone : l10n.cardAndPhone(farmer.card!, farmer.phone),
                                  style: context.text.bodyLarge?.copyWith(color: context.colors.onSurfaceVariant),
                                ),
                                if (farmer.smsReceipts) ...[
                                  context.space.gapSm,
                                  StatusBadge(
                                    label: l10n.smsReceiptsOn,
                                    tone: FarmTapTone.success,
                                    icon: Symbols.sms_rounded,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    context.space.gapLg,
                    ResponsiveGrid(
                      minItemWidth: context.sizes.gridMetric,
                      maxColumns: 3,
                      spacing: context.space.lg,
                      children: [
                        MetricCard(
                          icon: Symbols.water_drop_rounded,
                          label: l10n.thisPeriod,
                          value: f.count(st.litres),
                          unit: l10n.litreUnit,
                        ),
                        MetricCard(
                          icon: Symbols.payments_rounded,
                          label: l10n.toBePaid,
                          value: _short(f, st.net),
                          caption: l10n.payDay(f.day(st.payDay)),
                          tone: FarmTapTone.gold,
                        ),
                        MetricCard(
                          icon: Symbols.science_rounded,
                          label: l10n.rejected,
                          value: f.count(farmer.rejectedLitres),
                          unit: l10n.litreUnit,
                          tone: FarmTapTone.info,
                        ),
                      ],
                    ),
                    context.space.gapLg,
                    FarmTapCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CardHeader(
                            title: l10n.statementPeriod(f.period(st.start, st.end)),
                            actionLabel: l10n.share,
                            onAction: () {},
                          ),
                          context.space.gapSm,
                          SummaryRow(label: l10n.litresDelivered, value: f.litres(st.litres)),
                          SummaryRow(label: l10n.pricePerLitre, value: f.money(st.pricePerLitre)),
                          SummaryRow(label: l10n.gross, value: f.money(st.gross)),
                          for (final d in st.deductions)
                            SummaryRow(
                              label: switch (d.kind) {
                                DeductionKind.advance => l10n.advanceOn(d.date == null ? '' : f.dayMonth(d.date!)),
                                DeductionKind.feedsOnCredit => l10n.feedsOnCredit,
                              },
                              value: '− ${f.money(d.amount)}',
                            ),
                          const Divider(),
                          SummaryRow(label: l10n.toPay, value: f.money(st.net), emphasis: true),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------- G09

class CentrePaymentsPage extends StatelessWidget {
  const new({
    required this.repo,
    required this.onSendSms,
    required this.onPaymentSheet,
    required this.onFarmer,
    super.key,
  });

  final CentreRepository repo;
  final VoidCallback onSendSms;
  final VoidCallback onPaymentSheet;
  final ValueChanged<CentreFarmer> onFarmer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    return FutureBuilder<PaymentPeriod?>(
      future: repo.payments().then((r) => r.data),
      builder: (context, snapshot) {
        final p = snapshot.data;
        return AdaptiveScaffold(
          title: l10n.payments,
          subtitle: p == null ? null : l10n.periodLabel(f.period(p.start, p.end)),
          actions: [BarAction(icon: Symbols.download_rounded, tooltip: l10n.download, onPressed: () {})],
          body: p == null
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HeroCard(
                      label: l10n.toPayOn(f.day(p.payDay)),
                      value: f.moneyShort(p.amount),
                      sub: l10n.payHeroSub(p.farmers, f.count(p.litres), f.money(p.pricePerLitre)),
                      tone: FarmTapTone.gold,
                      animation: FarmTapAnimations.paymentReceived,
                    ),
                    context.space.gapLg,
                    ButtonPair(
                      first: FarmTapButton(
                        label: l10n.sendSmsStatements,
                        icon: Symbols.sms_rounded,
                        kind: ButtonKind.tonal,
                        onPressed: onSendSms,
                      ),
                      second: FarmTapButton(
                        label: l10n.paymentSheet,
                        icon: Symbols.receipt_long_rounded,
                        onPressed: onPaymentSheet,
                      ),
                    ),
                    context.space.gapLg,
                    RecordCollection<PaymentLine>(
                      items: p.lines,
                      onTap: (line) => onFarmer(line.farmer),
                      tileBuilder: (context, line) => RecordTile(
                        leading: FarmerAvatar(farmer: line.farmer, plain: true),
                        title: line.farmer.name,
                        subtitle: l10n.litresAndCard(f.count(line.litres), line.farmer.card ?? '—'),
                        trailingValue: f.compact(line.gross),
                        trailingSub: l10n.ugxUnit,
                        onTap: () => onFarmer(line.farmer),
                      ),
                      columns: [
                        RecordColumn(
                          label: l10n.colFarmer,
                          flex: 3,
                          sortKey: (line) => line.farmer.name,
                          cell: (context, line) => Row(
                            children: [
                              FarmerAvatar(farmer: line.farmer, size: context.sizes.avatarSm, plain: true),
                              context.space.gapMd,
                              Flexible(child: Text(line.farmer.name, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ),
                        RecordColumn(
                          label: l10n.litreUnit,
                          sortKey: (line) => line.litres,
                          cell: (context, line) => Text(f.count(line.litres)),
                        ),
                        RecordColumn(
                          label: l10n.colGross,
                          flex: 2,
                          sortKey: (line) => line.gross,
                          cell: (context, line) => Text(f.money(line.gross)),
                        ),
                        RecordColumn(
                          label: l10n.colDeductions,
                          flex: 2,
                          cell: (context, line) => Text(line.deductions == 0 ? '—' : '− ${f.money(line.deductions)}'),
                        ),
                        RecordColumn(
                          label: l10n.colNet,
                          flex: 2,
                          sortKey: (line) => line.net,
                          cell: (context, line) => Text(f.money(line.net)),
                        ),
                        RecordColumn(
                          label: l10n.colStatus,
                          flex: 2,
                          cell: (context, line) =>
                              StatusBadge(label: l10n.ready, tone: FarmTapTone.info, icon: Symbols.schedule_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------- G10

class PayFarmersPage extends StatefulWidget {
  const new({required this.repo, required this.onDone, super.key});

  final CentreRepository repo;
  final VoidCallback onDone;

  @override
  State<PayFarmersPage> createState() => _PayFarmersPageState();
}

class _PayFarmersPageState extends State<PayFarmersPage> {
  late final Future<PaymentPeriod?> _load = widget.repo.payments().then((r) => r.data);
  PayMethod _method = PayMethod.mobileMoney;

  Future<void> _confirm(PaymentPeriod p) async {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    final ok = await showReadBack(
      context,
      leading: IconBubble(icon: Symbols.payments_rounded, tone: FarmTapTone.gold, size: context.sizes.bubbleXl),
      subject: l10n.farmersAndAmount(p.farmers, f.moneyShort(p.amount)),
      valueText: f.money(_method == PayMethod.mobileMoney ? p.total : p.amount),
      detail: _method == PayMethod.mobileMoney ? l10n.mobileMoney : l10n.cashSheet,
    );
    if (!ok || !mounted) return;
    await widget.repo.payOut(_method);
    if (!mounted) return;
    await showCelebration(
      context,
      animation: FarmTapAnimations.paymentReceived,
      sound: FarmTapSound.coin,
      title: l10n.payoutStarted,
      message: l10n.farmersAndAmount(p.farmers, f.money(p.amount)),
      primaryLabel: l10n.done,
    );
    if (mounted) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    return FutureBuilder<PaymentPeriod?>(
      future: _load,
      builder: (context, snapshot) {
        final p = snapshot.data;
        final mobile = _method == PayMethod.mobileMoney;
        return AdaptiveScaffold(
          title: l10n.payFarmers,
          subtitle: p == null ? null : l10n.farmersAndAmount(p.farmers, f.moneyShort(p.amount)),
          body: p == null
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedTabs<PayMethod>(
                      options: [
                        TabOption(value: PayMethod.mobileMoney, label: l10n.mobileMoney),
                        TabOption(value: PayMethod.cashSheet, label: l10n.cashSheet),
                      ],
                      selected: _method,
                      onChanged: (v) => setState(() => _method = v),
                    ),
                    context.space.gapLg,
                    FarmTapBanner(
                      tone: FarmTapTone.info,
                      icon: Symbols.info_rounded,
                      title: mobile ? l10n.mobileMoneyPayouts : l10n.cashSheetInfo,
                      message: mobile ? l10n.mobileMoneyBody : l10n.cashSheetBody,
                    ),
                    context.space.gapLg,
                    ListCard(
                      children: [
                        for (final line in p.lines.take(3))
                          RecordTile(
                            leading: FarmerAvatar(farmer: line.farmer),
                            title: line.farmer.name,
                            subtitle: l10n.networkPhone(_network(l10n, line.farmer.network), line.farmer.localPhone),
                            badge: mobile ? _PayoutBadge(status: line.status) : null,
                            trailingValue: f.count(line.net),
                            showChevron: false,
                            onTap: line.status == PayoutStatus.failed ? () {} : null,
                          ),
                      ],
                    ),
                    context.space.gapLg,
                    FarmTapCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SummaryRow(label: l10n.farmersLabel, value: f.count(p.farmers)),
                          SummaryRow(label: l10n.amount, value: f.money(p.amount)),
                          if (mobile) SummaryRow(label: l10n.estimatedFees, value: f.money(p.fees)),
                          const Divider(),
                          SummaryRow(label: l10n.total, value: f.money(mobile ? p.total : p.amount), emphasis: true),
                        ],
                      ),
                    ),
                    context.space.gapLg,
                    FarmTapButton(
                      label: mobile ? l10n.confirmAndPay : l10n.printCashSheet,
                      icon: mobile ? Symbols.payments_rounded : Symbols.print_rounded,
                      onPressed: () => unawaited(_confirm(p)),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _PayoutBadge extends StatelessWidget {
  const new({required this.status});

  final PayoutStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (status) {
      PayoutStatus.sent => StatusBadge(label: l10n.sent, tone: FarmTapTone.success, icon: Symbols.check_circle_rounded),
      PayoutStatus.sending => StatusBadge(label: l10n.sending, tone: FarmTapTone.gold, icon: Symbols.schedule_rounded),
      PayoutStatus.failed => StatusBadge(
        label: l10n.failedRetry,
        tone: FarmTapTone.danger,
        icon: Symbols.error_rounded,
      ),
      PayoutStatus.ready => StatusBadge(label: l10n.ready, tone: FarmTapTone.info, icon: Symbols.schedule_rounded),
    };
  }
}

// ---------------------------------------------------------------- G11

class SmsStatementsPage extends StatelessWidget {
  const new({required this.repo, required this.onSent, super.key});

  final CentreRepository repo;
  final VoidCallback onSent;

  Future<void> _send(BuildContext context, SmsPreview p) async {
    final l10n = AppLocalizations.of(context);
    await repo.sendStatements();
    if (!context.mounted) return;
    await showCelebration(
      context,
      animation: FarmTapAnimations.smsSent,
      sound: FarmTapSound.success,
      title: l10n.smsSent,
      message: l10n.sendToFarmers(p.messages),
      primaryLabel: l10n.done,
    );
    onSent();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    return FutureBuilder<SmsPreview?>(
      future: repo.smsPreview().then((r) => r.data),
      builder: (context, snapshot) {
        final p = snapshot.data;
        return AdaptiveScaffold(
          title: l10n.smsStatements,
          body: p == null
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.previewWhatFarmersGet,
                      style: context.text.bodyLarge?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                    context.space.gapLg,
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: context.colors.surfaceContainerLow,
                        borderRadius: context.radii.card,
                        border: Border.all(color: context.colors.outlineVariant),
                      ),
                      child: Padding(
                        padding: context.space.card,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SmsBubble(
                              sender: p.centreSender,
                              text: l10n.smsStatementText(
                                p.sample.name,
                                f.period(p.weekStart, p.weekEnd),
                                f.litresValue(p.weekLitres, trim: false),
                                f.money(p.weekAmount),
                                f.day(p.payDay),
                              ),
                              time: l10n.dateAt(f.dayMonth(p.sentAt), f.time(p.sentAt)),
                            ),
                            context.space.gapLg,
                            _SmsBubble(
                              sender: p.centreSender,
                              text: l10n.smsReceiptText(
                                f.litresValue(p.lastDelivery.litres, trim: false),
                                f.time(p.lastDelivery.at),
                                p.lastDelivery.card,
                              ),
                              time: l10n.smsTodayAt(f.time(p.lastDelivery.at)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    context.space.gapLg,
                    FarmTapCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SummaryRow(label: l10n.messages, value: f.count(p.messages)),
                          SummaryRow(label: l10n.smsLeftThisMonth, value: l10n.countOfTotal(p.smsLeft, p.smsMonthly)),
                          SummaryRow(label: l10n.extraSmsNeeded, value: f.count(p.extraNeeded)),
                        ],
                      ),
                    ),
                    context.space.gapLg,
                    FarmTapButton(
                      label: l10n.sendToFarmers(p.messages),
                      icon: Symbols.sms_rounded,
                      onPressed: () => unawaited(_send(context, p)),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _SmsBubble extends StatelessWidget {
  const new({required this.sender, required this.text, required this.time});

  final String sender;
  final String text;
  final String time;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(sender, style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant)),
          context.space.gapSm,
          DecoratedBox(
            decoration: BoxDecoration(color: context.colors.surfaceContainerHigh, borderRadius: context.radii.card),
            child: Padding(
              padding: context.space.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(text, style: context.text.bodyMedium),
                  context.space.gapXs,
                  Text(
                    time,
                    textAlign: TextAlign.end,
                    style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant),
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
