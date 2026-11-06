// K08 — My page (decision 0016 §7): what a worker sees about themselves:
// their ID card, today's clock-in, days this month, pay (wage, advances,
// paid, balance), their tasks and Change PIN.
import 'dart:async';

import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/people/domain/card_registry.dart';
import 'package:farm_tap/core/people/domain/staff_directory.dart';
import 'package:farm_tap/core/people/domain/staff_member.dart';
import 'package:farm_tap/core/people/presentation/widgets/choose_pin_sheet.dart';
import 'package:farm_tap/core/people/presentation/widgets/id_card.dart';
import 'package:farm_tap/core/people/presentation/widgets/staff_form_fields.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/core/utils/formats.dart';
import 'package:farm_tap/sectors/cattle/workers/domain/workers_models.dart';
import 'package:farm_tap/sectors/cattle/workers/domain/workers_repository.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// The ID card of a worker.
IdCardData staffIdCard(
  AppLocalizations l10n,
  StaffMember s, {
  required String tenantId,
  required String farmName,
  String? farmPlace,
  String? farmPhone,
  IdCardRecord? card,
}) => IdCardData(
  kind: CardHolderKind.staff,
  tenantId: tenantId,
  farmName: farmName,
  farmPlace: farmPlace,
  farmPhone: farmPhone,
  name: s.name,
  personCode: s.staffCode,
  cardNumber: s.cardNumber,
  job: staffTitle(l10n, s),
  department: s.department,
  phone: s.phone == null ? null : '0${s.phone!.replaceAll(' ', '')}',
  emergencyName: s.emergencyName,
  emergencyPhone: s.emergencyPhone == null ? null : '0${s.emergencyPhone!.replaceAll(' ', '')}',
  village: s.village,
  nationalId: s.nationalId,
  issued: card?.issuedAt,
  since: s.since,
  photo: s.photo,
);

class MyPage extends StatefulWidget {
  const new({
    required this.staff,
    required this.directory,
    required this.workers,
    required this.card,
    required this.onCard,
    super.key,
    this.onChangePin,
    this.onSignOut,
  });

  final StaffMember staff;
  final StaffDirectory directory;
  final WorkersRepository workers;

  /// Their ID card as printed.
  final IdCardData card;

  /// Opens the full card (print / download).
  final VoidCallback onCard;

  /// Also changes the phone sign-in PIN (when they signed in with phone).
  final Future<void> Function(String pin)? onChangePin;
  final VoidCallback? onSignOut;

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyData {
  const new({
    required this.today,
    required this.days,
    required this.attendance,
    required this.wage,
    required this.payments,
    required this.tasks,
  });

  final StaffToday? today;
  final int days;
  final List<AttendanceRecord> attendance;
  final WageLine? wage;
  final List<StaffPayment> payments;
  final List<FarmTask> tasks;
}

class _MyPageState extends State<MyPage> {
  late Future<_MyData> _load = _fetch();

  Future<_MyData> _fetch() async {
    final id = widget.staff.id;
    final w = widget.workers;
    return _MyData(
      today: ((await w.today()).data ?? const <StaffToday>[]).where((t) => t.staff.id == id).firstOrNull,
      days: (await w.daysThisMonth(id)).data ?? 0,
      attendance: (await w.attendanceThisMonth(id)).data ?? const [],
      wage: (await w.wages()).data?.lines.where((l) => l.staff.id == id).firstOrNull,
      payments: (await w.paymentsOf(id)).data ?? const [],
      tasks: ((await w.tasks()).data ?? const <FarmTask>[]).where((t) => t.staffId == id).toList(),
    );
  }

  void _reload() => setState(() {
    _load = _fetch();
  });

  Future<void> _changePin() async {
    final l10n = AppLocalizations.of(context);
    final pin = await showChooseNewPin(context, name: widget.staff.greetingName);
    if (pin == null || !mounted) return;
    await widget.directory.setOwnPin(widget.staff.id, pin);
    await widget.onChangePin?.call(pin);
    if (mounted) FarmTapToast.show(context, message: l10n.pinChangedToast);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = FarmTapFormat(Localizations.localeOf(context).toLanguageTag());
    final now = context.clock.now();
    return AdaptiveScaffold(
      title: l10n.myPageTitle,
      subtitle: widget.staff.name,
      body: FutureBuilder<_MyData>(
        future: _load,
        builder: (context, snapshot) {
          final d = snapshot.data;
          if (d == null) return const FarmTapPageLoader();
          final r = d.today?.record;
          final status = switch (r) {
            null => l10n.statusNotInToday,
            AttendanceRecord(outAt: null) => l10n.statusPresentSince(f.time(r.inAt)),
            AttendanceRecord(:final outAt?) => l10n.statusLeftAt(f.time(outAt)),
          };
          final w = d.wage;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  onTap: widget.onCard,
                  child: IdCardView(data: widget.card),
                ),
              ),
              Center(
                child: TextAction(label: l10n.openMyCard, icon: Symbols.badge_rounded, onPressed: widget.onCard),
              ),
              context.space.gapLg,
              MetricStrip(
                children: [
                  MetricCard(
                    icon: r == null ? Symbols.schedule_rounded : Symbols.login_rounded,
                    label: l10n.todayLabel,
                    value: status,
                    tone: r?.outAt == null && r != null ? FarmTapTone.success : FarmTapTone.gold,
                  ),
                  MetricCard(icon: Symbols.event_available_rounded, label: l10n.daysThisMonth, value: f.count(d.days)),
                ],
              ),
              if (w != null) ...[
                context.space.gapLg,
                ListCard(
                  title: l10n.myPayTitle(f.monthLong(now)),
                  children: [
                    RecordTile(title: l10n.wageLabel, trailingValue: f.money(w.wage), showChevron: false),
                    RecordTile(title: l10n.advancesLabel, trailingValue: f.money(w.advances), showChevron: false),
                    RecordTile(title: l10n.paidLabel, trailingValue: f.money(w.paid), showChevron: false),
                    RecordTile(
                      title: l10n.balanceOwed,
                      trailingValue: f.money(w.toPay),
                      showChevron: false,
                      badge: w.toPay <= 0
                          ? StatusBadge(label: l10n.paidInFull, tone: FarmTapTone.success, icon: Symbols.check_rounded)
                          : null,
                    ),
                  ],
                ),
              ],
              if (d.payments.isNotEmpty) ...[
                context.space.gapLg,
                ListCard(
                  title: l10n.paymentsTitle,
                  children: [
                    for (final p in d.payments.take(6))
                      RecordTile(
                        leading: IconBubble(
                          icon: p.kind == PayKind.advance ? Symbols.request_quote_rounded : Symbols.payments_rounded,
                          tone: FarmTapTone.gold,
                          size: context.sizes.bubbleMd,
                        ),
                        title: p.kind == PayKind.advance ? l10n.advanceWord : l10n.wageWord,
                        subtitle: f.day(p.at),
                        trailingValue: f.money(p.amount),
                        showChevron: false,
                      ),
                  ],
                ),
              ],
              context.space.gapLg,
              ListCard(
                title: l10n.myTasksTitle,
                children: [
                  if (d.tasks.isEmpty) RecordTile(title: l10n.noTasksForYou, showChevron: false),
                  for (final t in d.tasks)
                    CheckboxListTile(
                      value: t.done,
                      title: Text(t.title),
                      subtitle: Text(t.when),
                      onChanged: (v) async {
                        await widget.workers.setTaskDone(t.id, done: v ?? false);
                        if (mounted) _reload();
                      },
                    ),
                ],
              ),
              context.space.gapLg,
              ListCard(
                title: l10n.myAttendanceTitle,
                children: [
                  if (d.attendance.isEmpty) RecordTile(title: l10n.statusNotInToday, showChevron: false),
                  for (final a in d.attendance.take(10))
                    RecordTile(
                      title: f.day(a.inAt),
                      trailingValue: '${f.clock24(a.inAt)} – ${a.outAt == null ? '…' : f.clock24(a.outAt!)}',
                      showChevron: false,
                    ),
                ],
              ),
              context.space.gapLg,
              ListCard(
                children: [
                  RecordTile(
                    leading: IconBubble(
                      icon: Symbols.pin_rounded,
                      tone: FarmTapTone.neutral,
                      size: context.sizes.bubbleMd,
                    ),
                    title: l10n.changeMyPin,
                    subtitle: l10n.pinWhatFor,
                    onTap: () => unawaited(_changePin()),
                  ),
                  if (widget.onSignOut != null)
                    RecordTile(
                      leading: IconBubble(
                        icon: Symbols.logout_rounded,
                        tone: FarmTapTone.danger,
                        size: context.sizes.bubbleMd,
                      ),
                      title: l10n.signOutLabel,
                      onTap: widget.onSignOut,
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
