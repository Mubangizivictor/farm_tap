import 'dart:async';

import 'package:farm_tap/core/account/account_repository.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/settings/presentation/pages/help_page.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

/// The public site: legal pages and the account deletion page (Google Play
/// and the App Store link to the same addresses).
const farmTapSite = 'https://farmtap.victorbee.com';
final Uri privacyUrl = Uri.parse('$farmTapSite/privacy/');
final Uri termsUrl = Uri.parse('$farmTapSite/terms/');
final Uri deleteAccountUrl = Uri.parse('$farmTapSite/delete-account/');

Future<void> openSite(Uri uri) async {
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Object {
    // No browser: nothing else to do.
  }
}

/// Closing the account (decision 0024). First what happens, then a
/// confirmation (tick + type DELETE), then it closes at once. Everything is
/// kept for 90 days so support can bring it back; after that it is erased.
class DeleteAccountPage extends StatefulWidget {
  const new({required this.ownsFarms, required this.onClose, super.key});

  /// The account owns at least one farm (it closes with the account).
  final bool ownsFarms;

  /// Closes the account with the reason given; throws when it failed.
  final Future<void> Function(String reason) onClose;

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  bool _understood = false;
  bool _confirming = false;
  bool _busy = false;
  String? _error;
  final _typed = TextEditingController();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _typed.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    final l10n = AppLocalizations.of(context);
    if (_typed.text.trim().toUpperCase() != 'DELETE') {
      setState(() => _error = l10n.deleteTypeNeeded);
      return;
    }
    final sure = await showFarmTapDialog(
      context,
      icon: Symbols.delete_forever_rounded,
      title: l10n.deleteLastTitle,
      message: l10n.deleteLastBody,
      primaryLabel: l10n.deleteNow,
      primaryKind: ButtonKind.danger,
      secondaryLabel: l10n.deleteKeep,
      tone: FarmTapTone.danger,
    );
    if (!sure || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onClose(_reason.text.trim());
    } on Object {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = l10n.deleteFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final points = [
      (Symbols.logout_rounded, l10n.deleteWhat1),
      if (widget.ownsFarms) (Symbols.home_rounded, l10n.deleteWhat2),
      (Symbols.group_off_rounded, l10n.deleteWhat3),
      (Symbols.money_off_rounded, l10n.deleteWhat4),
      (Symbols.history_rounded, l10n.deleteWhat5),
      (Symbols.delete_forever_rounded, l10n.deleteWhat6),
    ];
    return AdaptiveScaffold(
      title: l10n.deleteTitle,
      showBack: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FarmTapBanner(
            tone: FarmTapTone.danger,
            icon: Symbols.warning_rounded,
            title: l10n.deleteWarnTitle,
            message: l10n.deleteWarnBody,
          ),
          context.space.gapLg,
          ListCard(
            title: l10n.deleteWhatHappens,
            children: [
              for (final (icon, text) in points)
                RecordTile(
                  leading: IconBubble(icon: icon, tone: FarmTapTone.danger, size: context.sizes.bubbleMd),
                  title: text,
                  showChevron: false,
                ),
            ],
          ),
          context.space.gapMd,
          FarmTapCard(
            child: Text(
              l10n.deleteInstead,
              style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ),
          context.space.gapLg,
          if (!_confirming)
            FarmTapButton(
              label: l10n.deleteContinue,
              kind: ButtonKind.danger,
              onPressed: () => setState(() => _confirming = true),
            )
          else ...[
            CheckRow(
              label: l10n.deleteUnderstand,
              value: _understood,
              onChanged: (v) => setState(() => _understood = v),
            ),
            context.space.gapMd,
            FarmTapTextField(
              label: l10n.deleteTypeLabel,
              controller: _typed,
              hint: 'DELETE',
              error: _error,
              onChanged: (_) => setState(() {}),
            ),
            context.space.gapMd,
            FarmTapTextField(label: l10n.deleteReason, controller: _reason),
            context.space.gapLg,
            FarmTapButton(
              label: l10n.deleteNow,
              icon: Symbols.delete_forever_rounded,
              kind: ButtonKind.danger,
              loading: _busy,
              onPressed: _busy || !_understood || _typed.text.trim().isEmpty ? null : _close,
            ),
          ],
          context.space.gapSm,
          FarmTapButton(
            label: l10n.deleteKeep,
            kind: ButtonKind.text,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}

/// Shown instead of the app when the account was closed: when it can still
/// be brought back, and how (FarmTap support).
class ClosedAccountPage extends StatelessWidget {
  const new({required this.closure, required this.onSignOut, super.key});

  final AccountClosure closure;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final by = closure.restoreBy;
    final fmt = MaterialLocalizations.of(context);
    return AdaptiveScaffold(
      showNavigation: false,
      showLogo: true,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: context.sizes.centeredMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              context.space.gapXl,
              Center(
                child: IconBubble(
                  icon: Symbols.person_off_rounded,
                  tone: FarmTapTone.neutral,
                  size: context.sizes.bubbleXl,
                ),
              ),
              context.space.gapLg,
              Text(l10n.closedTitle, textAlign: TextAlign.center, style: context.text.headlineSmall),
              context.space.gapSm,
              Text(
                by == null ? l10n.closedBodySoon : l10n.closedBody(fmt.formatFullDate(by)),
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
              ),
              context.space.gapXl,
              FarmTapButton(
                label: l10n.closedRestore,
                icon: Symbols.chat_rounded,
                onPressed: () => unawaited(openSupportWhatsApp(l10n.closedRestoreMessage)),
              ),
              context.space.gapSm,
              FarmTapButton(
                label: l10n.signOutLabel,
                icon: Symbols.logout_rounded,
                kind: ButtonKind.outlined,
                onPressed: onSignOut,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
