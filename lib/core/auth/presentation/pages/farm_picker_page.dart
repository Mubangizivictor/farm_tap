import 'package:farm_tap/core/auth/presentation/widgets/auth_widgets.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/tenancy/domain/farm_membership.dart';
import 'package:farm_tap/core/tenancy/domain/farm_membership_repository.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// A07 — choose which farm or collection centre to open.
class FarmPickerPage extends StatefulWidget {
  const new({required this.places, required this.onOpened, super.key, this.onAddFarm, this.onSignOut, this.prepare});

  final FarmMembershipRepository places;

  /// Loads the farm's records (downloads them on a new or reinstalled
  /// phone) before it opens.
  final Future<void> Function(String tenantId)? prepare;
  final ValueChanged<FarmMembership> onOpened;
  final VoidCallback? onAddFarm;

  /// Back to sign-in, e.g. to use another account.
  final VoidCallback? onSignOut;

  @override
  State<FarmPickerPage> createState() => _FarmPickerPageState();
}

class _FarmPickerPageState extends State<FarmPickerPage> {
  late final Future<List<FarmMembership>> _load = widget.places.myPlaces().then((r) => r.data ?? const []);

  FarmMembership? _opening;

  Future<void> _open(FarmMembership m) async {
    if (_opening != null) return;
    setState(() => _opening = m);
    final result = await widget.places.open(m.tenantId);
    if (result.isSuccess) await widget.prepare?.call(m.tenantId);
    if (!mounted) return;
    setState(() => _opening = null);
    if (result.isSuccess) widget.onOpened(m);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<List<FarmMembership>>(
      future: _load,
      builder: (context, snapshot) {
        final places = snapshot.data ?? const <FarmMembership>[];
        final opening = _opening;
        if (opening != null) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(context.space.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FarmTapLoader(size: context.sizes.loaderSize),
                    context.space.gapXl,
                    Text(
                      l10n.gettingFarmReady(opening.name),
                      textAlign: TextAlign.center,
                      style: context.text.titleLarge,
                    ),
                    context.space.gapXs,
                    Text(
                      l10n.gettingFarmReadySub,
                      textAlign: TextAlign.center,
                      style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return SplitAuthLayout(
          animation: FarmTapAnimations.welcome,
          tagline: l10n.brandTagline,
          description: l10n.brandBody,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthHeading(title: l10n.chooseFarmTitle, subtitle: l10n.chooseFarmSubtitle(places.length)),
              context.space.gapLg,
              if (!snapshot.hasData && snapshot.connectionState != ConnectionState.done)
                const FarmTapPageLoader()
              else if (places.isNotEmpty)
                ListCard(
                  children: [for (final p in places) _PlaceTile(place: p, onTap: () => _open(p))],
                ),
              context.space.gapLg,
              FarmTapButton(
                label: l10n.addAnotherFarm,
                icon: Symbols.add_rounded,
                kind: ButtonKind.outlined,
                onPressed: widget.onAddFarm,
              ),
              if (widget.onSignOut != null) ...[
                context.space.gapSm,
                FarmTapButton(
                  label: l10n.signOutLabel,
                  icon: Symbols.logout_rounded,
                  kind: ButtonKind.text,
                  onPressed: widget.onSignOut,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PlaceTile extends StatelessWidget {
  const new({required this.place, required this.onTap});

  final FarmMembership place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final role = switch (place.role) {
      PlaceRole.owner => l10n.roleOwner,
      PlaceRole.manager => l10n.roleManager,
      PlaceRole.clerk => l10n.roleClerk,
      PlaceRole.worker => l10n.roleWorker,
    };
    final today = context.clock.today();
    final (status, badge, tone) = switch (place.subscription.state(today)) {
      SubscriptionState.active ||
      SubscriptionState.grace => (l10n.statusActive, l10n.statusActive, FarmTapTone.success),
      SubscriptionState.trial => (
        l10n.trialDaysShort(place.subscription.trialDaysLeft(today)),
        l10n.statusTrial,
        FarmTapTone.gold,
      ),
      SubscriptionState.readOnly => (l10n.statusReadOnly, l10n.statusReadOnly, FarmTapTone.neutral),
    };
    return RecordTile(
      leading: place.kind == PlaceKind.dairyFarm
          ? CowAvatar(avatarIndex: place.avatarIndex)
          : IconBubble(icon: Symbols.storefront_rounded, tone: FarmTapTone.gold, size: context.sizes.avatarMd),
      title: place.name,
      subtitle: [place.place, role, status].join(' · '),
      badge: StatusBadge(label: badge, tone: tone),
      onTap: onTap,
    );
  }
}
