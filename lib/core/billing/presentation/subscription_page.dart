import 'dart:async';

import 'package:farm_tap/core/billing/billing_repository.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/settings/presentation/pages/help_page.dart';
import 'package:farm_tap/core/tenancy/domain/farm_membership.dart';
import 'package:farm_tap/core/theme/print/billing_pdf.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/core/utils/formats.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

/// M02 Plan and payment (decisions 0023, 0024): the farm's plan, choosing a
/// plan, paying with Mobile Money or card through FarmTap's server, or by
/// hand (bank, pay code) with the transaction ID, and the farm's receipts.
/// Plans, prices and ways to pay come from the control panel, as on the web.
class SubscriptionPage extends StatefulWidget {
  const new({
    required this.repo,
    required this.tenantId,
    required this.farmName,
    required this.subscription,
    required this.canPay,
    required this.onPaid,
    super.key,
    this.phone,
    this.pollEvery = const Duration(seconds: 5), // theme-guard: ignore
    this.pollTimes = 24,
  });

  final BillingRepository repo;
  final String tenantId;
  final String farmName;
  final Subscription subscription;

  /// Owners and managers pay; others see the plan only.
  final bool canPay;

  /// The new dates once a payment is confirmed (unlocks the farm).
  final ValueChanged<Subscription> onPaid;

  /// The account's phone number, filled in for Mobile Money.
  final String? phone;
  final Duration pollEvery;
  final int pollTimes;

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

enum _Stage { choose, waiting, paid, failed, claimed }

class _SubscriptionPageState extends State<SubscriptionPage> {
  PayOptions? _options;
  List<BillingDocument>? _docs;
  PlanOption? _plan;
  PayGateway? _gateway;
  late final _phone = TextEditingController(text: widget.phone);
  final _reference = TextEditingController();
  _Stage _stage = _Stage.choose;
  bool _busy = false;
  String? _error;
  String? _paymentId;
  Timer? _poll;
  int _polls = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _phone.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    PayOptions o;
    try {
      o = await widget.repo.options();
    } on Object {
      o = const PayOptions(plans: samplePlans, gateways: []);
    }
    List<BillingDocument> docs;
    try {
      docs = await widget.repo.documents(widget.tenantId);
    } on Object {
      docs = const [];
    }
    if (!mounted) return;
    final ways = o.gateways.where((g) => g.enabled).toList();
    setState(() {
      _options = o;
      _docs = docs;
      _plan ??= o.plans.where((p) => p.badge.isNotEmpty).firstOrNull ?? o.plans.firstOrNull;
      _gateway ??= ways.firstOrNull;
    });
  }

  FarmTapFormat get _fmt => FarmTapFormat(Localizations.localeOf(context).toLanguageTag());

  Future<void> _pay() async {
    final l10n = AppLocalizations.of(context);
    final plan = _plan;
    final g = _gateway;
    if (plan == null || g == null) return;
    String? phone;
    if (g.mobile) {
      phone = msisdn(_phone.text);
      if (phone == null) {
        setState(() => _error = l10n.payPhoneNeeded);
        return;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await widget.repo.start(tenantId: widget.tenantId, plan: plan, periods: 1, method: g.id, phone: phone);
      _paymentId = r.paymentId;
      final link = r.redirectUrl;
      if (link != null) await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _stage = _Stage.waiting;
      });
      _startPolling();
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e is PayProblem ? e.message : l10n.payNotStarted;
      });
    }
  }

  void _startPolling() {
    _poll?.cancel();
    _polls = 0;
    _poll = Timer.periodic(widget.pollEvery, (_) => unawaited(_check()));
  }

  Future<void> _check() async {
    final id = _paymentId;
    if (id == null) return;
    _polls++;
    PayResult r;
    try {
      r = await widget.repo.check(tenantId: widget.tenantId, paymentId: id);
    } on Object {
      if (_polls >= widget.pollTimes) _stopWith(_Stage.failed);
      return;
    }
    if (!mounted) return;
    switch (r.status) {
      case PayStatus.paid:
        _poll?.cancel();
        final dates = await widget.repo
            .subscription(widget.tenantId)
            .catchError((_) => (trialEndsAt: widget.subscription.trialEndsAt, paidUntil: r.paidUntil));
        widget.onPaid(
          Subscription(
            trialStartedAt: widget.subscription.trialStartedAt,
            trialEndsAt: dates.trialEndsAt ?? widget.subscription.trialEndsAt,
            paidUntil: dates.paidUntil ?? r.paidUntil,
          ),
        );
        _stopWith(_Stage.paid);
        unawaited(_load());
      case PayStatus.failed || PayStatus.cancelled || PayStatus.expired:
        _error = r.message;
        _stopWith(_Stage.failed);
      case PayStatus.pending:
        if (_polls >= widget.pollTimes) _stopWith(_Stage.failed);
    }
  }

  void _stopWith(_Stage s) {
    _poll?.cancel();
    if (mounted) setState(() => _stage = s);
  }

  Future<void> _claim() async {
    final l10n = AppLocalizations.of(context);
    final plan = _plan;
    final g = _gateway;
    if (plan == null || g == null) return;
    if (_reference.text.trim().length < 4) {
      setState(() => _error = l10n.payReferenceNeeded);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repo.claim(plan: plan, periods: 1, method: g.id, reference: _reference.text);
      if (mounted) {
        setState(() {
          _busy = false;
          _stage = _Stage.claimed;
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = l10n.payNotStarted;
        });
      }
    }
  }

  Future<void> _share(BillingDocument d) async {
    final l10n = AppLocalizations.of(context);
    final view = d.isRefund ? DocView.refund : DocView.receipt;
    try {
      final brand = await widget.repo.brand();
      final bytes = await buildBillingPdf(d, view, brand);
      await Printing.sharePdf(bytes: bytes, filename: '${docNumberFor(d, view)}.pdf');
    } on Object {
      if (mounted) FarmTapToast.show(context, message: l10n.payReceiptFailed, tone: FarmTapTone.danger);
    }
  }

  Future<void> _invoice(BillingDocument d) async {
    try {
      final brand = await widget.repo.brand();
      final bytes = await buildBillingPdf(d, DocView.invoice, brand);
      await Printing.sharePdf(bytes: bytes, filename: '${docNumberFor(d, DocView.invoice)}.pdf');
    } on Object {
      if (mounted) {
        FarmTapToast.show(context, message: AppLocalizations.of(context).payReceiptFailed, tone: FarmTapTone.danger);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final o = _options;
    return AdaptiveScaffold(
      title: l10n.subscriptionLabel,
      showBack: true,
      onRefresh: _load,
      body: o == null
          ? const FarmTapPageLoader()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _status(context, l10n),
                context.space.gapLg,
                if (!widget.canPay)
                  FarmTapBanner(
                    tone: FarmTapTone.info,
                    icon: Symbols.info_rounded,
                    title: l10n.payAskOwner,
                    message: l10n.payAskOwnerBody,
                  )
                else
                  ..._payArea(context, l10n, o),
                context.space.gapLg,
                _receipts(context, l10n),
                context.space.gapMd,
                FarmTapButton(
                  label: l10n.payHelp,
                  icon: Symbols.support_agent_rounded,
                  kind: ButtonKind.text,
                  onPressed: () => unawaited(openSupportWhatsApp(l10n.payHelpMessage(widget.farmName))),
                ),
              ],
            ),
    );
  }

  Widget _status(BuildContext context, AppLocalizations l10n) {
    final today = context.clock.today();
    final sub = widget.subscription;
    final fmt = MaterialLocalizations.of(context);
    final (title, message, tone, icon) = switch (sub.state(today)) {
      SubscriptionState.trial => (
        l10n.trialDaysLeft(sub.trialDaysLeft(today)),
        sub.trialEndsAt == null ? null : l10n.payTrialEnds(fmt.formatMediumDate(sub.trialEndsAt!)),
        FarmTapTone.gold,
        Symbols.savings_rounded,
      ),
      SubscriptionState.active || SubscriptionState.grace => (
        l10n.payActive,
        sub.paidUntil == null ? null : l10n.payPaidUntil(fmt.formatMediumDate(sub.paidUntil!)),
        FarmTapTone.primary,
        Symbols.verified_rounded,
      ),
      SubscriptionState.readOnly => (
        sub.paidUntil == null ? l10n.lockedTrialTitle : l10n.lockedPlanTitle,
        l10n.payLockedBody,
        FarmTapTone.danger,
        Symbols.lock_rounded,
      ),
    };
    return FarmTapBanner(tone: tone, icon: icon, title: title, message: message);
  }

  List<Widget> _payArea(BuildContext context, AppLocalizations l10n, PayOptions o) {
    if (_stage == _Stage.waiting) {
      return [
        FarmTapCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: FarmTapLoader()),
              context.space.gapMd,
              Text(l10n.payWaiting, textAlign: TextAlign.center, style: context.text.titleMedium),
              context.space.gapXs,
              Text(
                _gateway?.id == 'card' ? l10n.payWaitingCard : l10n.payWaitingPhone,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
              ),
              context.space.gapMd,
              FarmTapButton(label: l10n.payCheckNow, kind: ButtonKind.outlined, onPressed: () => unawaited(_check())),
            ],
          ),
        ),
      ];
    }
    if (_stage == _Stage.paid || _stage == _Stage.claimed || _stage == _Stage.failed) {
      final paid = _stage == _Stage.paid;
      final claimed = _stage == _Stage.claimed;
      return [
        FarmTapBanner(
          tone: paid
              ? FarmTapTone.primary
              : claimed
              ? FarmTapTone.info
              : FarmTapTone.danger,
          icon: paid
              ? Symbols.check_circle_rounded
              : claimed
              ? Symbols.schedule_rounded
              : Symbols.error_rounded,
          title: paid
              ? l10n.payDone
              : claimed
              ? l10n.payClaimSent
              : l10n.payFailed,
          message: paid
              ? l10n.payDoneBody
              : claimed
              ? l10n.payClaimSentBody
              : (_error ?? l10n.payFailedBody),
        ),
        if (!paid) ...[
          context.space.gapMd,
          FarmTapButton(
            label: l10n.payTryAgain,
            kind: ButtonKind.outlined,
            onPressed: () => setState(() {
              _stage = _Stage.choose;
              _error = null;
            }),
          ),
        ],
      ];
    }
    final ways = o.gateways.where((g) => g.enabled).toList();
    final plan = _plan;
    final g = _gateway;
    return [
      SectionLabel(l10n.payChoosePlan),
      context.space.gapSm,
      ListCard(
        children: [
          for (final p in o.plans)
            RecordTile(
              leading: Icon(
                p.id == plan?.id ? Symbols.radio_button_checked_rounded : Symbols.radio_button_unchecked_rounded,
                color: p.id == plan?.id ? context.colors.primary : context.colors.onSurfaceVariant,
              ),
              title: p.name,
              subtitle: p.months > 1 ? l10n.payPerMonth(_fmt.money(p.perMonth)) : p.description,
              badge: p.badge.isEmpty ? null : StatusBadge(label: p.badge, tone: FarmTapTone.gold),
              trailingValue: _fmt.money(p.priceUgx),
              showChevron: false,
              onTap: () => setState(() => _plan = p),
            ),
        ],
      ),
      context.space.gapLg,
      if (ways.isEmpty)
        FarmTapBanner(
          tone: FarmTapTone.info,
          icon: Symbols.support_agent_rounded,
          title: l10n.paySoon,
          message: l10n.paySoonBody(supportPhoneDisplay),
          actionLabel: l10n.helpWhatsapp,
          onAction: () => unawaited(openSupportWhatsApp(l10n.payHelpMessage(widget.farmName))),
        )
      else ...[
        FarmTapSelectField<PayGateway>(
          label: l10n.payHow,
          icon: Symbols.payments_rounded,
          options: ways,
          value: g,
          labelOf: (x) => x.name,
          onChanged: (x) => setState(() {
            _gateway = x;
            _error = null;
          }),
        ),
        context.space.gapMd,
        if (g != null && g.api) ...[
          if (g.mobile) ...[
            FarmTapTextField(
              label: l10n.payPhone,
              controller: _phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9+ ]'))],
              hint: '07XX XXX XXX',
              error: _error,
            ),
            context.space.gapMd,
          ] else if (_error != null) ...[
            Text(_error!, style: context.text.bodySmall?.copyWith(color: context.colors.error)),
            context.space.gapMd,
          ],
          FarmTapButton(
            label: plan == null ? l10n.payNow : l10n.payAmount(_fmt.money(plan.priceUgx)),
            icon: g.id == 'card' ? Symbols.credit_card_rounded : Symbols.phone_iphone_rounded,
            large: true,
            loading: _busy,
            onPressed: _busy || plan == null ? null : _pay,
          ),
          context.space.gapSm,
          Text(
            g.mobile ? l10n.payMobileNote : l10n.payCardNote,
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ] else if (g != null) ...[
          FarmTapCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.payByHand, style: context.text.titleSmall),
                context.space.gapXs,
                if (plan != null) Text(l10n.payByHandAmount(_fmt.money(plan.priceUgx)), style: context.text.bodyMedium),
                if (g.accountName.isNotEmpty)
                  Text('${l10n.payAccountName}: ${g.accountName}', style: context.text.bodyMedium),
                if (g.payCode.isNotEmpty)
                  SelectableText('${l10n.payCode}: ${g.payCode}', style: context.text.bodyMedium),
                if (g.instructions.isNotEmpty) ...[
                  context.space.gapXs,
                  Text(g.instructions, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
                ],
              ],
            ),
          ),
          context.space.gapMd,
          FarmTapTextField(
            label: l10n.payReference,
            controller: _reference,
            hint: l10n.payReferenceHint,
            error: _error,
          ),
          context.space.gapMd,
          FarmTapButton(
            label: l10n.paySendDetails,
            icon: Symbols.send_rounded,
            loading: _busy,
            onPressed: _busy || plan == null ? null : _claim,
          ),
        ],
      ],
    ];
  }

  Widget _receipts(BuildContext context, AppLocalizations l10n) {
    final docs = _docs ?? const <BillingDocument>[];
    final fmt = MaterialLocalizations.of(context);
    return ListCard(
      title: l10n.payReceipts,
      children: [
        if (docs.isEmpty)
          Padding(
            padding: context.space.listItem,
            child: Text(
              l10n.payNoReceipts,
              style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          )
        else
          for (final d in docs)
            RecordTile(
              leading: IconBubble(
                icon: d.isRefund ? Symbols.undo_rounded : Symbols.receipt_long_rounded,
                tone: d.isRefund ? FarmTapTone.warning : FarmTapTone.primary,
                size: context.sizes.bubbleMd,
              ),
              title: d.isRefund ? (d.refundNo ?? d.receiptNo) : d.receiptNo,
              subtitle: '${fmt.formatMediumDate(d.paidAt)} · ${methodNames[d.method] ?? d.method}',
              trailingValue: _fmt.money(d.totalUgx),
              onTap: () => _docActions(d),
            ),
      ],
    );
  }

  Future<void> _docActions(BillingDocument d) async {
    final l10n = AppLocalizations.of(context);
    final pick = await showAdaptiveSheet<String>(
      context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetTitle(d.isRefund ? (d.refundNo ?? d.receiptNo) : d.receiptNo),
          ActionTile(
            icon: Symbols.receipt_long_rounded,
            label: d.isRefund ? l10n.payRefundNote : l10n.payReceipt,
            onTap: () => Navigator.of(sheet).pop('receipt'),
          ),
          if (!d.isRefund) ...[
            sheet.space.gapSm,
            ActionTile(
              icon: Symbols.description_rounded,
              label: l10n.payInvoice,
              tone: FarmTapTone.neutral,
              onTap: () => Navigator.of(sheet).pop('invoice'),
            ),
          ],
        ],
      ),
    );
    if (!mounted) return;
    if (pick == 'receipt') await _share(d);
    if (pick == 'invoice') await _invoice(d);
  }
}
