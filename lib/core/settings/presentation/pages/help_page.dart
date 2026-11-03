// N03 Help & support: WhatsApp, call or SMS the FarmTap team.
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

/// The FarmTap support line (WhatsApp, calls and SMS).
const supportPhone = '+256793128137';

/// "+256 793 128 137".
String get supportPhoneDisplay =>
    '${supportPhone.substring(0, 4)} ${supportPhone.substring(4, 7)} ${supportPhone.substring(7, 10)} ${supportPhone.substring(10)}';

class HelpPage extends StatelessWidget {
  const new({super.key, this.open = _launch});

  /// Opens a link outside the app; false when the phone cannot.
  final Future<bool> Function(Uri) open;

  static Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Future<void> go(Uri uri) async {
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (!await open(uri)) messenger?.showSnackBar(SnackBar(content: Text(l10n.helpOpenFailed)));
    }

    RecordTile row(IconData icon, FarmTapTone tone, String title, String subtitle, Uri uri) => RecordTile(
      leading: IconBubble(icon: icon, tone: tone, size: context.sizes.bubbleMd),
      title: title,
      subtitle: subtitle,
      onTap: () => go(uri),
    );
    return AdaptiveScaffold(
      title: l10n.helpSupport,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.helpIntro, style: context.text.bodyMedium),
          context.space.gapLg,
          ListCard(
            children: [
              row(
                Symbols.chat_rounded,
                FarmTapTone.primary,
                l10n.helpWhatsapp,
                l10n.helpWhatsappSub,
                Uri.parse('https://wa.me/${supportPhone.substring(1)}'),
              ),
              row(
                Symbols.call_rounded,
                FarmTapTone.info,
                l10n.helpCall,
                supportPhoneDisplay,
                Uri.parse('tel:$supportPhone'),
              ),
              row(
                Symbols.sms_rounded,
                FarmTapTone.gold,
                l10n.helpSms,
                supportPhoneDisplay,
                Uri.parse('sms:$supportPhone'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
