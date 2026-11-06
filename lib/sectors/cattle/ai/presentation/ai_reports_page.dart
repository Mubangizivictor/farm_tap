// Smart Farm Reports (decision 0025): ask in your own words, or pick a
// report and a period. The table is made only from the farm's records and
// can be shared as PDF or a spreadsheet, like the other reports.
import 'dart:async';

import 'package:farm_tap/core/ai/ai_assistant.dart';
import 'package:farm_tap/core/ai/ai_core.dart';
import 'package:farm_tap/core/ai/ai_data.dart';
import 'package:farm_tap/core/ai/ai_reports.dart';
import 'package:farm_tap/core/ai/ai_repository.dart';
import 'package:farm_tap/core/export/table_export.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/sectors/cattle/ai/presentation/ai_widgets.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class AiReportsPage extends StatefulWidget {
  const new({required this.ctx, super.key});

  final AiPageContext ctx;

  @override
  State<AiReportsPage> createState() => _AiReportsPageState();
}

class _AiReportsPageState extends State<AiReportsPage> {
  static const _periods = ['this month', 'last month', 'last 7 days', 'last 30 days'];

  final _request = TextEditingController();
  String _kind = 'overall';
  String _period = 'this month';
  Report? _report;
  bool _notFound = false;

  @override
  void dispose() {
    _request.dispose();
    super.dispose();
  }

  String _periodLabel(AppLocalizations l10n, String p) => switch (p) {
    'last month' => l10n.aiPeriodLastMonth,
    'last 7 days' => l10n.aiPeriod7,
    'last 30 days' => l10n.aiPeriod30,
    _ => l10n.aiPeriodThisMonth,
  };

  void _build(AiFarm farm, String kind, Period period) {
    final started = context.clock.now();
    final r = buildReport(kind, period, farm.data);
    unawaited(
      widget.ctx.repo.log(
        'reports',
        ok: true,
        ms: context.clock.now().difference(started).inMilliseconds,
        method: Method.calculated,
      ),
    );
    setState(() {
      _report = r;
      _notFound = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ctx = widget.ctx;
    return AiBody(
      repo: ctx.repo,
      role: ctx.role,
      title: aiModuleLabel('reports'),
      builder: (context, farm, reload) {
        final day = today(farm.data);
        final kinds = [
          for (final k in reportKinds)
            if (canBuild(k.key, ctx.role)) k,
        ];
        final r = _report;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FarmTapTextField(
              label: l10n.aiReportAsk,
              hint: l10n.aiReportAskHint,
              controller: _request,
              icon: Symbols.search_rounded,
              textInputAction: TextInputAction.go,
              onSubmitted: (t) {
                final req = parseReportRequest(t, day, ctx.role);
                if (req == null) {
                  setState(() => _notFound = true);
                } else {
                  setState(() => _kind = req.kind);
                  _build(farm, req.kind, req.period);
                }
              },
            ),
            if (_notFound) ...[
              context.space.gapSm,
              AiNote(l10n.aiReportNotFound, icon: Symbols.search_off_rounded, tone: FarmTapTone.warning),
            ],
            context.space.gapLg,
            SectionLabel(l10n.aiReportKind),
            context.space.gapSm,
            Wrap(
              spacing: context.space.sm,
              runSpacing: context.space.sm,
              children: [
                for (final k in kinds)
                  FarmTapChip(label: k.label, selected: _kind == k.key, onTap: () => setState(() => _kind = k.key)),
              ],
            ),
            context.space.gapLg,
            SectionLabel(l10n.aiReportPeriod),
            context.space.gapSm,
            Wrap(
              spacing: context.space.sm,
              runSpacing: context.space.sm,
              children: [
                for (final p in _periods)
                  FarmTapChip(
                    label: _periodLabel(l10n, p),
                    selected: _period == p,
                    onTap: () => setState(() => _period = p),
                  ),
              ],
            ),
            context.space.gapLg,
            FarmTapButton(
              label: l10n.aiShowReport,
              icon: Symbols.bar_chart_rounded,
              onPressed: () => _build(farm, _kind, periodOf(_period, day, 'month')),
            ),
            if (r != null) ...[
              context.space.gapLg,
              FarmTapCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(r.title, style: context.text.titleMedium),
                    Text(
                      r.period.label,
                      style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                    context.space.gapSm,
                    for (final s in r.summary) Text(s, style: context.text.bodyLarge),
                    context.space.gapSm,
                    const MethodBadge(Method.calculated),
                  ],
                ),
              ),
              context.space.gapMd,
              if (r.rows.isEmpty)
                EmptyState(title: l10n.aiReportEmpty)
              else
                AiTable(columns: r.columns, rows: [for (final row in r.rows) row.map(cellText).toList()]),
              context.space.gapMd,
              FarmTapButton(
                label: l10n.aiExportReport,
                icon: Symbols.download_rounded,
                kind: ButtonKind.tonal,
                onPressed: () => unawaited(
                  exportTable(
                    context,
                    ExportTable(
                      title: r.title,
                      subtitle: r.period.label,
                      headers: r.columns,
                      rows: [for (final row in r.rows) row.map(cellText).toList()],
                    ),
                    farmName: ctx.farmName,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
