// The ID card of one person (decision 0015 §3): front and back, print on a
// card printer or A4, download as PDF. Staff (K07) and farmers (G14).
import 'dart:async';

import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/people/presentation/id_card_pdf.dart';
import 'package:farm_tap/core/people/presentation/widgets/id_card.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/core/utils/formats.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:printing/printing.dart';

/// The words on a printed card, in the app's language.
IdCardWords idCardWords(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final f = FarmTapFormat(Localizations.localeOf(context).toLanguageTag());
  return IdCardWords(
    staff: l10n.idCardStaff,
    supplier: l10n.idCardSupplier,
    department: l10n.departmentLabel,
    idNumber: l10n.idNumberLabel,
    phone: l10n.phoneLabel,
    emergency: l10n.emergencyLabel,
    village: l10n.villageLabel,
    nin: l10n.ninLabel,
    memberSince: l10n.memberSinceLabel,
    issued: l10n.issuedLabel,
    ifFound: l10n.idCardIfFound,
    validNote: l10n.idCardValidNote,
    scanMe: l10n.idCardScanMe,
    date: (d) => '${d.day} ${f.monthShort(d)} ${d.year}',
  );
}

/// "Card-0142-Twinomujuni-Amos.pdf".
String idCardFileName(IdCardData d) =>
    'Card-${d.cardNumber ?? d.personCode}-${d.name.replaceAll(RegExp('[^A-Za-z0-9]+'), '-')}.pdf';

Future<void> printIdCards(BuildContext context, List<IdCardData> cards) async {
  if (cards.isEmpty) return;
  final words = idCardWords(context);
  await Printing.layoutPdf(
    name: cards.length == 1 ? idCardFileName(cards.first) : 'FarmTap-cards.pdf',
    onLayout: (_) => cards.length == 1 ? IdCardPdf.single(cards.first, words) : IdCardPdf.sheet(cards, words),
  );
}

Future<void> shareIdCards(BuildContext context, List<IdCardData> cards, {bool sheet = false}) async {
  if (cards.isEmpty) return;
  final words = idCardWords(context);
  final bytes = cards.length == 1 && !sheet
      ? await IdCardPdf.single(cards.first, words)
      : await IdCardPdf.sheet(cards, words);
  await Printing.sharePdf(bytes: bytes, filename: cards.length == 1 ? idCardFileName(cards.first) : 'FarmTap-cards.pdf');
}

class IdCardPage extends StatefulWidget {
  const new({required this.load, super.key, this.onGiveCard, this.onPhoto});

  /// The card to show; null while the person is not found.
  final Future<IdCardData?> Function() load;

  /// No card yet: give one (opens assign card); completes when done.
  final Future<void> Function()? onGiveCard;

  /// Take or change the photo; completes when saved.
  final Future<void> Function()? onPhoto;

  @override
  State<IdCardPage> createState() => _IdCardPageState();
}

class _IdCardPageState extends State<IdCardPage> {
  late Future<IdCardData?> _card = widget.load();
  bool _back = false;

  void _reload() => setState(() {
    _card = widget.load();
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AdaptiveScaffold(
      title: l10n.idCardTitle,
      showNavigation: false,
      body: FutureBuilder<IdCardData?>(
        future: _card,
        builder: (context, snapshot) {
          final d = snapshot.data;
          if (d == null) return const FarmTapPageLoader();
          final give = widget.onGiveCard;
          final photo = widget.onPhoto;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.sizes.keypadMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: () => setState(() => _back = !_back),
                      child: AnimatedSwitcher(
                        duration: context.motion.normal,
                        child: IdCardView(key: ValueKey(_back), data: d, back: _back),
                      ),
                    ),
                  ),
                  context.space.gapMd,
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(value: false, label: Text(l10n.idCardFront), icon: const Icon(Symbols.badge_rounded)),
                      ButtonSegment(value: true, label: Text(l10n.idCardBack), icon: const Icon(Symbols.flip_rounded)),
                    ],
                    selected: {_back},
                    onSelectionChanged: (v) => setState(() => _back = v.first),
                  ),
                  context.space.gapLg,
                  if (d.cardNumber == null) ...[
                    FarmTapBanner(
                      tone: FarmTapTone.gold,
                      icon: Symbols.contactless_rounded,
                      title: l10n.idCardNoCardTitle,
                      message: l10n.idCardNoCardBody,
                    ),
                    context.space.gapMd,
                    if (give != null)
                      FarmTapButton(
                        label: l10n.assignCardRow,
                        icon: Symbols.contactless_rounded,
                        large: true,
                        onPressed: () async {
                          await give();
                          if (mounted) _reload();
                        },
                      ),
                  ] else ...[
                    FarmTapButton(
                      label: l10n.printCard,
                      icon: Symbols.print_rounded,
                      large: true,
                      onPressed: () => unawaited(printIdCards(context, [d])),
                    ),
                    context.space.gapSm,
                    FarmTapButton(
                      label: l10n.downloadCardPdf,
                      icon: Symbols.download_rounded,
                      kind: ButtonKind.outlined,
                      onPressed: () => unawaited(shareIdCards(context, [d])),
                    ),
                    context.space.gapSm,
                    FarmTapButton(
                      label: l10n.printOnA4,
                      icon: Symbols.grid_view_rounded,
                      kind: ButtonKind.outlined,
                      onPressed: () => unawaited(shareIdCards(context, [d], sheet: true)),
                    ),
                  ],
                  if (photo != null) ...[
                    context.space.gapSm,
                    Center(
                      child: TextAction(
                        label: (d.photo ?? '').isEmpty ? l10n.addPhoto : l10n.changePhoto,
                        icon: Symbols.photo_camera_rounded,
                        onPressed: () async {
                          await photo();
                          if (mounted) _reload();
                        },
                      ),
                    ),
                  ],
                  context.space.gapMd,
                  Text(
                    l10n.idCardPrintHelp,
                    textAlign: TextAlign.center,
                    style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
