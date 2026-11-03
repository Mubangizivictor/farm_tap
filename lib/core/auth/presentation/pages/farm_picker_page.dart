import 'dart:async';

import 'package:farm_tap/core/auth/domain/entities/account_user.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/onboarding/presentation/pages/choice_steps.dart';
import 'package:farm_tap/core/tenancy/domain/farm_membership.dart';
import 'package:farm_tap/core/tenancy/domain/farm_membership_repository.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

/// A07 — the farm this account works on (decision 0018).
///
/// One account runs one farm, so for most people this is a short "Welcome
/// back, Victor · Opening Rwemera Dairy Farm" on the way in: with
/// [autoOpen] (after the splash or a sign-in) the farm opened last on this
/// phone, or the only farm, opens by itself. The list shows when the person
/// came here on purpose ("Switch farm") or is a member of several farms.
/// No farm yet: a personal "Let's set up your farm". "Add another farm" is
/// only there on a multi-farm plan ([FarmMembershipRepository.farmLimit]).
class FarmPickerPage extends StatefulWidget {
  const new({
    required this.places,
    required this.onOpened,
    super.key,
    this.account,
    this.autoOpen = false,
    this.onAddFarm,
    this.onSignOut,
    this.prepare,
  });

  final FarmMembershipRepository places;

  /// The signed-in person: their name for the greeting, email for "Signed in as".
  final AccountUser? account;

  /// Open the remembered (or only) farm without waiting for a tap.
  final bool autoOpen;

  /// Loads the farm's records (downloads them on a new or reinstalled
  /// phone) before it opens.
  final Future<void> Function(String tenantId)? prepare;
  final ValueChanged<FarmMembership> onOpened;

  /// Set up a farm: the first one, or another on a multi-farm plan.
  final VoidCallback? onAddFarm;

  /// Back to sign-in, e.g. to use another account.
  final VoidCallback? onSignOut;

  @override
  State<FarmPickerPage> createState() => _FarmPickerPageState();
}

/// What the account can open, loaded once.
typedef _Places = ({List<FarmMembership>? places, int limit, String? last});

class _FarmPickerPageState extends State<FarmPickerPage> {
  late Future<_Places> _load = _fetch();

  FarmMembership? _opening;

  Future<_Places> _fetch() async {
    final result = await widget.places.myPlaces();
    final limit = await widget.places.farmLimit();
    final last = await widget.places.lastOpened();
    final places = result.data;
    if (widget.autoOpen && places != null) {
      final remembered = places.where((p) => p.tenantId == last).firstOrNull;
      final target = remembered ?? (places.length == 1 ? places.single : null);
      if (target != null) unawaited(Future.microtask(() => _open(target)));
    }
    return (places: places, limit: limit, last: last);
  }

  Future<void> _open(FarmMembership m) async {
    if (_opening != null || !mounted) return;
    setState(() => _opening = m);
    final result = await widget.places.open(m.tenantId);
    if (result.isSuccess) await widget.prepare?.call(m.tenantId);
    if (!mounted) return;
    setState(() => _opening = null);
    if (result.isSuccess) widget.onOpened(m);
  }

  String? get _firstName {
    final name = widget.account?.name.trim() ?? '';
    return name.isEmpty ? null : name.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    final opening = _opening;
    if (opening != null) return _OpeningView(place: opening, firstName: _firstName);
    return FutureBuilder<_Places>(
      future: _load,
      builder: (context, snapshot) {
        final data = snapshot.data;
        // Waiting, or about to open the remembered farm: the opening view
        // takes over in a moment, so show only the greeting and loader.
        if (data == null) return _OpeningView(firstName: _firstName);
        final places = data.places;
        if (places == null) return _offline(context);
        if (places.isEmpty) return _noFarm(context);
        return _list(context, places, data.limit);
      },
    );
  }

  void _retry() => setState(() => _load = _fetch());

  Widget _page(BuildContext context, List<Widget> children) => CenteredLayout(
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: context.space.xl),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: children),
    ),
  );

  Widget _accountFooter(BuildContext context, String signOutLabel) {
    final l10n = AppLocalizations.of(context);
    final email = widget.account?.email ?? '';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (email.isNotEmpty)
          Text(
            l10n.signedInAsEmail(email),
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        if (widget.onSignOut != null)
          FarmTapButton(
            label: signOutLabel,
            icon: Symbols.logout_rounded,
            kind: ButtonKind.text,
            onPressed: widget.onSignOut,
          ),
      ],
    );
  }

  Widget _heading(BuildContext context, String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(title, style: context.text.headlineSmall),
      context.space.gapXs,
      Text(subtitle, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
    ],
  );

  Widget _list(BuildContext context, List<FarmMembership> places, int limit) {
    final l10n = AppLocalizations.of(context);
    final name = _firstName;
    final owned = places.where((p) => p.owned).length;
    return _page(context, [
      _heading(
        context,
        name == null ? l10n.welcomeBackPlain : l10n.welcomeBackName(name),
        places.length == 1 ? l10n.farmPickerOneSub : l10n.farmPickerManySub(places.length),
      ),
      context.space.gapLg,
      for (final p in places) ...[FarmPlaceCard(place: p, onOpen: () => _open(p)), context.space.gapMd],
      // Multi-farm plan only (decision 0018): never offered on the free path.
      if (owned < limit && widget.onAddFarm != null) ...[
        FarmTapButton(
          label: l10n.addAnotherFarm,
          icon: Symbols.add_rounded,
          kind: ButtonKind.outlined,
          onPressed: widget.onAddFarm,
        ),
        context.space.gapMd,
      ],
      _accountFooter(context, l10n.signOutLabel),
    ]);
  }

  Widget _noFarm(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = _firstName;
    return _page(context, [
      Center(
        child: FarmTapAnimationView(animation: FarmTapAnimations.welcome, size: context.sizes.animationCelebration),
      ),
      context.space.gapLg,
      Text(
        name == null ? l10n.noFarmTitle : l10n.welcomeName(name),
        textAlign: TextAlign.center,
        style: context.text.headlineSmall,
      ),
      context.space.gapXs,
      Text(
        '${name == null ? '' : '${l10n.noFarmTitle}. '}${l10n.noFarmBody(freeTrialDays)}',
        textAlign: TextAlign.center,
        style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
      ),
      context.space.gapXl,
      FarmTapButton(
        label: l10n.setUpMyFarm,
        icon: Symbols.arrow_forward_rounded,
        large: true,
        onPressed: widget.onAddFarm,
      ),
      context.space.gapLg,
      Text(
        l10n.joinFarmHint,
        textAlign: TextAlign.center,
        style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
      ),
      FarmTapButton(label: l10n.checkAgain, icon: Symbols.refresh_rounded, kind: ButtonKind.text, onPressed: _retry),
      context.space.gapSm,
      _accountFooter(context, l10n.useAnotherAccount),
    ]);
  }

  Widget _offline(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _page(context, [
      Center(
        child: IconBubble(icon: Symbols.wifi_off_rounded, tone: FarmTapTone.warning, size: context.sizes.bubbleXl),
      ),
      context.space.gapLg,
      Text(l10n.placesOfflineTitle, textAlign: TextAlign.center, style: context.text.headlineSmall),
      context.space.gapXs,
      Text(
        l10n.placesOfflineBody,
        textAlign: TextAlign.center,
        style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
      ),
      context.space.gapXl,
      FarmTapButton(label: l10n.tryAgain, icon: Symbols.refresh_rounded, large: true, onPressed: _retry),
      context.space.gapSm,
      _accountFooter(context, l10n.signOutLabel),
    ]);
  }
}

/// "Welcome back, Victor · Opening Rwemera Dairy Farm" while the farm loads
/// (or, with no [place], while the farm list loads).
class _OpeningView extends StatelessWidget {
  const new({this.place, this.firstName});

  final FarmMembership? place;
  final String? firstName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = firstName;
    final p = place;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(context.space.xl),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.sizes.centeredMaxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (p != null) ...[FarmPlaceAvatar(place: p, size: context.sizes.avatarXl), context.space.gapLg],
                  Text(
                    name == null ? l10n.welcomeBackPlain : l10n.welcomeBackName(name),
                    textAlign: TextAlign.center,
                    style: context.text.titleLarge,
                  ),
                  if (p != null) ...[
                    context.space.gapXs,
                    Text(
                      l10n.openingFarmTitle(p.name),
                      textAlign: TextAlign.center,
                      style: context.text.bodyLarge?.copyWith(fontWeight: FarmTapWeights.semiBold),
                    ),
                    Text(
                      placeKindLabel(l10n, p),
                      textAlign: TextAlign.center,
                      style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                  ],
                  context.space.gapXl,
                  FarmTapLoader(size: context.sizes.loaderSize),
                  if (p != null) ...[
                    context.space.gapLg,
                    Text(
                      l10n.gettingFarmReadySub,
                      textAlign: TextAlign.center,
                      style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Dairy farm", "Milk collection centre", "Poultry"...
String placeKindLabel(AppLocalizations l10n, FarmMembership p) {
  if (p.kind == PlaceKind.collectionCentre) return l10n.placeCentre;
  if (p.sector != Sector.dairy) return sectorInfo(l10n, p.sector).$1;
  return p.withCentre ? l10n.placeDairyAndCentre : l10n.placeDairyFarm;
}

/// "42 cows", "300 birds", "18 pigs".
String herdLabel(AppLocalizations l10n, Sector sector, int count) => switch (sector) {
  Sector.dairy => l10n.herdCows(count),
  Sector.poultry => l10n.herdBirds(count),
  Sector.piggery => l10n.herdPigs(count),
  _ => l10n.herdAnimals(count),
};

/// The farm's picture: a cow for a dairy farm, the shop for a centre, the
/// sector's icon for poultry, pigs and the rest.
class FarmPlaceAvatar extends StatelessWidget {
  const new({required this.place, super.key, this.size});

  final FarmMembership place;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dimension = size ?? context.sizes.avatarLg;
    if (place.kind == PlaceKind.collectionCentre) {
      return IconBubble(icon: Symbols.storefront_rounded, tone: FarmTapTone.gold, size: dimension);
    }
    if (place.sector == Sector.dairy) return CowAvatar(avatarIndex: place.avatarIndex, size: dimension);
    return IconBubble(icon: sectorInfo(l10n, place.sector).$3, size: dimension);
  }
}

/// One farm on A07: picture, name, what it is, where, herd, your role, and
/// where its trial or payment stands, with an Open button.
class FarmPlaceCard extends StatelessWidget {
  const new({required this.place, required this.onOpen, super.key});

  final FarmMembership place;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final today = context.clock.today();
    final sub = place.subscription;
    final role = switch (place.role) {
      PlaceRole.owner => l10n.roleOwner,
      PlaceRole.manager => l10n.roleManager,
      PlaceRole.clerk => l10n.roleClerk,
      PlaceRole.worker => l10n.roleWorker,
    };
    final state = sub.state(today);
    final (badge, tone) = switch (state) {
      SubscriptionState.active => (l10n.statusActive, FarmTapTone.success),
      SubscriptionState.grace => (l10n.statusActive, FarmTapTone.warning),
      SubscriptionState.trial => (l10n.statusTrial, FarmTapTone.gold),
      SubscriptionState.readOnly => (l10n.statusReadOnly, FarmTapTone.neutral),
    };
    final where = [place.village, place.place].whereType<String>().where((s) => s.isNotEmpty).toSet().join(', ');
    final herd = place.herdSize;
    final muted = context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant);
    Widget fact(IconData icon, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: context.sizes.iconSm, color: context.colors.onSurfaceVariant),
        SizedBox(width: context.space.xs),
        Flexible(
          child: Text(text, style: muted, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
    final locale = Localizations.localeOf(context).toLanguageTag();
    final Widget standing = switch (state) {
      SubscriptionState.trial => FarmTapProgress(
        value: sub.trialLength == 0 ? 1 : sub.trialDaysUsed(today) / sub.trialLength,
        thin: true,
        label: l10n.freeTrialLabel,
        trailingLabel: l10n.trialDaysLeftOf(sub.trialDaysLeft(today), sub.trialLength),
        color: FarmTapTone.gold.of(context).accent,
      ),
      SubscriptionState.active => Text(
        l10n.paidUntilDate(DateFormat('d MMM y', locale).format(sub.paidUntil!)),
        style: muted,
      ),
      SubscriptionState.grace => Text(
        l10n.graceDaysToPay(sub.graceDaysLeft(today)),
        style: context.text.bodySmall?.copyWith(color: FarmTapTone.warning.of(context).accent),
      ),
      SubscriptionState.readOnly => Text(l10n.readOnlyPickerHint, style: muted),
    };
    return Semantics(
      container: true,
      label: '${place.name}, ${placeKindLabel(l10n, place)}',
      child: FarmTapCard(
        onTap: onOpen,
        children: [
          Row(
            children: [
              FarmPlaceAvatar(place: place),
              SizedBox(width: context.space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(place.name, style: context.text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(placeKindLabel(l10n, place), style: muted),
                  ],
                ),
              ),
              StatusBadge(label: badge, tone: tone),
            ],
          ),
          Wrap(
            spacing: context.space.lg,
            runSpacing: context.space.xs,
            children: [
              if (where.isNotEmpty) fact(Symbols.location_on_rounded, where),
              if (herd != null && herd > 0 && place.kind != PlaceKind.collectionCentre)
                fact(Symbols.pets_rounded, herdLabel(l10n, place.sector, herd)),
              fact(Symbols.person_rounded, l10n.youAreRole(role)),
            ],
          ),
          standing,
          FarmTapButton(label: l10n.openFarmButton, trailingIcon: Symbols.arrow_forward_rounded, onPressed: onOpen),
        ],
      ),
    );
  }
}
