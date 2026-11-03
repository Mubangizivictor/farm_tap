// Staff and milk-supplier ID cards (decision 0015 §3): the on-screen card,
// drawn like the printed CR80 card (85.6 x 54 mm), front and back.
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/people/domain/card_registry.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/core/utils/formats.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pdf/widgets.dart' as pw;

/// What goes on one ID card. Built from a staff member or a farmer.
class IdCardData {
  const new({
    required this.kind,
    required this.tenantId,
    required this.farmName,
    required this.name,
    required this.personCode,
    this.cardNumber,
    this.job,
    this.department,
    this.phone,
    this.farmPlace,
    this.farmPhone,
    this.emergencyName,
    this.emergencyPhone,
    this.village,
    this.nationalId,
    this.issued,
    this.since,
    this.photo,
  });

  final CardHolderKind kind;
  final String tenantId;
  final String farmName;
  final String? farmPlace;

  /// "If found, please call" on the back.
  final String? farmPhone;
  final String name;

  /// "ST-04217" / "MS-55120".
  final String personCode;

  /// "0142"; null before a card is given (preview only).
  final String? cardNumber;
  final String? job;
  final String? department;
  final String? phone;
  final String? emergencyName;
  final String? emergencyPhone;
  final String? village;
  final String? nationalId;
  final DateTime? issued;
  final DateTime? since;

  /// Base64 JPEG.
  final String? photo;

  String? get qr => cardNumber == null ? null : CardQr.encode(tenantId, cardNumber!);
}

/// One side of the card at any width (it scales like the printed card).
class IdCardView extends StatelessWidget {
  const new({required this.data, super.key, this.back = false, this.width});

  final IdCardData data;

  /// Show the back of the card.
  final bool back;

  /// Defaults to the available width, at most `context.sizes.idCardMaxWidth`.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final max = context.sizes.idCardMaxWidth;
        final w = width ?? (box.maxWidth.isFinite && box.maxWidth < max ? box.maxWidth : max);
        // Drawn at the design width on the light theme (a printed card is
        // always light), then scaled to fit.
        return Semantics(
          image: true,
          label: back ? l10n.idCardBackLabel(data.name) : l10n.idCardFrontLabel(data.name),
          child: SizedBox(
            width: w,
            height: w / context.sizes.idCardAspect,
            child: FittedBox(
              child: Theme(
                data: FarmTapTheme.light,
                child: Builder(
                  builder: (context) => SizedBox(
                    width: max,
                    height: max / context.sizes.idCardAspect,
                    child: back ? _Back(data: data, width: max) : _Front(data: data, width: max),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Shell extends StatelessWidget {
  const new({required this.width, required this.band, required this.child});

  final double width;
  final Widget band;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = context.sizes;
    return Container(
      decoration: BoxDecoration(
        color: context.status.card,
        borderRadius: BorderRadius.all(Radius.circular(width * s.idCardRadius)),
        border: Border.all(color: context.colors.outlineVariant, width: s.borderThin),
        boxShadow: [
          BoxShadow(
            color: context.colors.shadow.withValues(alpha: 0.14),
            offset: Offset(0, context.space.xs),
            blurRadius: context.space.md,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: width * s.idCardBand,
            color: context.colors.primary,
            padding: EdgeInsets.symmetric(horizontal: width * s.idCardPadding),
            child: band,
          ),
          Expanded(
            child: Padding(padding: EdgeInsets.all(width * s.idCardPadding), child: child),
          ),
          Container(height: context.sizes.borderThick * 2, color: context.status.brandGold),
        ],
      ),
    );
  }
}

class _Front extends StatelessWidget {
  const new({required this.data, required this.width});

  final IdCardData data;
  final double width;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = context.sizes;
    final onBand = context.colors.onPrimary;
    final photoW = width * s.idCardPhoto;
    final qrW = width * s.idCardQr;
    final qr = data.qr;
    return _Shell(
      width: width,
      band: Row(
        children: [
          Expanded(
            child: Text(
              data.farmName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.titleSmall?.copyWith(color: onBand, fontWeight: FarmTapWeights.bold),
            ),
          ),
          Text(
            data.kind == CardHolderKind.staff ? l10n.idCardStaff : l10n.idCardSupplier,
            style: context.text.labelSmall?.copyWith(color: onBand, letterSpacing: 1),
          ),
          context.space.gapXs,
          Icon(Symbols.contactless_rounded, color: context.status.brandGold, size: s.iconMd),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: context.radii.chip,
            child: SizedBox(width: photoW, child: _Photo(data: data, width: photoW)),
          ),
          context.space.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleMedium?.copyWith(fontWeight: FarmTapWeights.bold),
                ),
                if ((data.job ?? '').isNotEmpty)
                  Text(
                    data.job!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall?.copyWith(color: context.colors.primary),
                  ),
                if ((data.department ?? '').isNotEmpty)
                  _Field(label: l10n.departmentLabel, value: data.department!),
                const Spacer(),
                _Field(label: l10n.idNumberLabel, value: data.personCode),
                Text(
                  data.cardNumber == null ? '----' : data.cardNumber!,
                  style: context.textStyles.tagNumber.copyWith(color: context.colors.primary, letterSpacing: 2),
                ),
              ],
            ),
          ),
          if (qr != null) ...[
            context.space.gapSm,
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SvgPicture.string(pw.Barcode.qrCode().toSvg(qr, width: qrW, height: qrW), width: qrW, height: qrW),
                Text(l10n.idCardScanMe, style: context.text.labelSmall),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const new({required this.data, required this.width});

  final IdCardData data;
  final double width;

  @override
  Widget build(BuildContext context) {
    final bytes = PersonAvatar.photoBytes(data.photo);
    if (bytes != null) return Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true);
    return ColoredBox(
      color: context.colors.primaryContainer,
      child: Center(
        child: Text(
          PersonAvatar.initialsOf(data.name),
          style: context.text.headlineSmall?.copyWith(color: context.colors.onPrimaryContainer),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const new({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: context.space.xxs),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${label.toUpperCase()}  ',
            style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          TextSpan(
            text: value,
            style: context.text.labelMedium?.copyWith(fontWeight: FarmTapWeights.bold),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  );
}

class _Back extends StatelessWidget {
  const new({required this.data, required this.width});

  final IdCardData data;
  final double width;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = FarmTapFormat(Localizations.localeOf(context).toLanguageTag());
    String date(DateTime d) => '${d.day} ${f.monthShort(d)} ${d.year}';
    final rows = <(String, String)>[
      if ((data.phone ?? '').isNotEmpty) (l10n.phoneLabel, data.phone!),
      if ((data.emergencyName ?? '').isNotEmpty || (data.emergencyPhone ?? '').isNotEmpty)
        (l10n.emergencyLabel, [data.emergencyName, data.emergencyPhone].whereType<String>().join(' · ')),
      if ((data.village ?? '').isNotEmpty) (l10n.villageLabel, data.village!),
      if ((data.nationalId ?? '').isNotEmpty) (l10n.ninLabel, data.nationalId!),
      if (data.since != null) (l10n.memberSinceLabel, date(data.since!)),
      if (data.issued != null) (l10n.issuedLabel, date(data.issued!)),
    ];
    return _Shell(
      width: width,
      band: Row(
        children: [
          Expanded(
            child: Text(
              l10n.idCardIfFound,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelMedium?.copyWith(color: context.colors.onPrimary),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (label, value) in rows) _Field(label: label, value: value),
          const Spacer(),
          Text(
            [data.farmName, data.farmPlace, data.farmPhone].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.labelMedium?.copyWith(fontWeight: FarmTapWeights.bold),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.idCardValidNote,
                  maxLines: 2,
                  style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ),
              Text(
                data.cardNumber ?? '',
                style: context.textStyles.tagNumber.copyWith(color: context.colors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
