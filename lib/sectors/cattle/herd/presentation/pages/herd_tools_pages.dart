// E04 add animal, E05 scan ear tag, E09 head count, E10 print QR labels.
import 'dart:async';

import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/core/utils/formats.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/entities/animal.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/herd_models.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/herd_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// ---------------------------------------------------------------- E04

enum _Sex { female, bull, calf }

/// E04 — add an animal. Asks "Discard changes?" when left with input.
class AddAnimalPage extends StatefulWidget {
  const new({required this.repo, required this.onSaved, super.key, this.now});

  final HerdRepository repo;
  final ValueChanged<Animal> onSaved;

  /// Overrides the clock (goldens).
  final DateTime? now;

  @override
  State<AddAnimalPage> createState() => _AddAnimalPageState();
}

class _AddAnimalPageState extends State<AddAnimalPage> {
  final _tag = TextEditingController();
  final _name = TextEditingController();
  final _national = TextEditingController();
  String? _breed;
  DateTime? _born;
  _Sex _sex = _Sex.female;
  Animal? _mother;
  String? _tagError;
  List<Animal> _mothers = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final tag = (await widget.repo.nextTag()).data;
    final rows = (await widget.repo.rows()).data ?? const <HerdRow>[];
    if (!mounted) return;
    setState(() {
      if (tag != null && _tag.text.isEmpty) _tag.text = tag;
      _mothers = [
        for (final r in rows)
          if (r.animal.sex == AnimalSex.female) r.animal,
      ];
    });
  }

  bool get _dirty => _name.text.isNotEmpty || _breed != null || _born != null || _national.text.isNotEmpty;

  @override
  void dispose() {
    _tag.dispose();
    _name.dispose();
    _national.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = widget.now ?? context.clock.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _born ?? now,
      firstDate: DateTime(now.year - 25),
      lastDate: now,
    );
    if (picked != null) setState(() => _born = picked);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _tagError = _tag.text.trim().isEmpty ? l10n.tagRequired : null);
    if (_tagError != null) return;
    final now = widget.now ?? context.clock.now();
    final animal = Animal(
      id: 'animal-${_tag.text.trim()}',
      tenantId: '',
      tagNumber: _tag.text.trim(),
      name: _name.text.trim(),
      sex: _sex == _Sex.bull ? AnimalSex.male : AnimalSex.female,
      breed: _breed ?? '',
      dateOfBirth: _born ?? now,
      status: AnimalStatus.active,
      govIdTag: _national.text.trim().isEmpty ? null : _national.text.trim(),
      createdAt: now,
      updatedAt: now,
      createdBy: 'staff',
      updatedBy: 'staff',
      deviceId: 'device',
      syncStatus: SyncStatus.pending,
      dairyStatus: switch (_sex) {
        _Sex.female => DairyStatus.heifer,
        _Sex.bull => DairyStatus.bull,
        _Sex.calf => DairyStatus.calf,
      },
      motherTag: _mother?.tagNumber,
    );
    await widget.repo.addAnimal(animal);
    if (!mounted) return;
    FarmTapToast.show(context, message: l10n.animalSaved(animal.name.isEmpty ? animal.tagNumber : animal.name));
    widget.onSaved(animal);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = FarmTapFormat(Localizations.localeOf(context).toLanguageTag());
    final breed = FarmTapSelectField<String>(
      label: l10n.breedLabel,
      options: widget.repo.breeds,
      labelOf: (b) => b,
      value: _breed,
      onChanged: (b) => setState(() => _breed = b),
    );
    final born = Semantics(
      button: true,
      label: l10n.dobLabel,
      value: _born == null ? null : f.dayMonth(_born!),
      excludeSemantics: true,
      child: InkWell(
        onTap: _pickDate,
        borderRadius: context.radii.input,
        child: InputDecorator(
          isEmpty: _born == null,
          decoration: InputDecoration(
            labelText: l10n.dobLabel,
            suffixIcon: Icon(Symbols.calendar_month_rounded, size: context.sizes.iconMd),
          ),
          child: Text(_born == null ? '' : '${f.dayMonth(_born!)} ${_born!.year}', style: context.text.bodyLarge),
        ),
      ),
    );
    return DiscardGuard(
      dirty: _dirty,
      child: AdaptiveScaffold(
        title: l10n.addAnimal2,
        showNavigation: false,
        floatingActionButton: FarmTapFab(label: l10n.saveAnimal, icon: Symbols.check_rounded, onPressed: _save),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= context.sizes.gridPaired;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PhotoBox(label: l10n.addPhoto),
                    context.space.gapLg,
                    Expanded(
                      child: Column(
                        children: [
                          FarmTapTextField(
                            label: l10n.tagNumberLabel,
                            icon: Symbols.badge_rounded,
                            controller: _tag,
                            error: _tagError,
                            textInputAction: TextInputAction.next,
                          ),
                          context.space.gapLg,
                          FarmTapTextField(
                            label: l10n.nameLabel,
                            icon: Symbols.pets_rounded,
                            controller: _name,
                            textInputAction: TextInputAction.done,
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                context.space.gapLg,
                if (wide)
                  Row(
                    children: [
                      Expanded(child: breed),
                      context.space.gapLg,
                      Expanded(child: born),
                    ],
                  )
                else ...[
                  breed,
                  context.space.gapLg,
                  born,
                ],
                context.space.gapLg,
                Text(l10n.sexLabel, style: context.text.titleSmall),
                context.space.gapSm,
                SegmentedTabs<_Sex>(
                  options: [
                    TabOption(value: _Sex.female, label: l10n.sexCowHeifer),
                    TabOption(value: _Sex.bull, label: l10n.kindBull),
                    TabOption(value: _Sex.calf, label: l10n.kindCalf),
                  ],
                  selected: _sex,
                  onChanged: (s) => setState(() => _sex = s),
                ),
                context.space.gapLg,
                FarmTapTextField(
                  label: l10n.nationalTagLabel,
                  icon: Symbols.qr_code_rounded,
                  controller: _national,
                  onChanged: (_) => setState(() {}),
                ),
                context.space.gapLg,
                FarmTapSelectField<Animal>(
                  label: l10n.motherOptional,
                  icon: Symbols.pets_rounded,
                  options: _mothers,
                  labelOf: (a) => '${a.name} · ${a.tagNumber}',
                  value: _mother,
                  onChanged: (a) => setState(() => _mother = a),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// "Add photo" box beside the tag and name fields.
class _PhotoBox extends StatelessWidget {
  const new({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final height = context.sizes.inputHeight * 2 + context.space.lg;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: context.status.card,
        shape: RoundedRectangleBorder(
          borderRadius: context.radii.card,
          side: BorderSide(color: context.colors.outlineVariant, width: context.sizes.borderThin),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {},
          child: SizedBox(
            width: context.sizes.photoPreview * 0.68,
            height: height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconBubble(icon: Symbols.photo_camera_rounded, size: context.sizes.bubbleLg),
                context.space.gapSm,
                Text(label, style: context.text.labelMedium?.copyWith(color: context.colors.primary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- E05

/// E05 — scan the QR code on an ear tag. UI phase: the viewfinder without
/// the live camera (P03 asks for the camera permission first).
class ScanTagPage extends StatelessWidget {
  const new({required this.onTypeTag, super.key});

  final VoidCallback onTypeTag;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final on = context.status.onViewfinder;
    return AdaptiveScaffold(
      title: l10n.scanTag,
      showNavigation: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: context.isCompact ? context.sizes.viewfinderAspect : context.sizes.viewfinderAspectWide,
            child: Container(
              decoration: BoxDecoration(color: context.status.viewfinder, borderRadius: context.radii.dialog),
              padding: EdgeInsets.all(context.space.xl),
              child: Column(
                children: [
                  Text(
                    l10n.pointAtQr,
                    textAlign: TextAlign.center,
                    style: context.text.titleSmall?.copyWith(color: on),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: context.space.xl),
                      child: const _ScanFrame(),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: l10n.torch,
                        onPressed: () {},
                        icon: Icon(Symbols.flash_on_rounded, color: on, size: context.sizes.iconLg),
                      ),
                      context.space.gapXl,
                      IconButton(
                        tooltip: l10n.typeTagInstead,
                        onPressed: onTypeTag,
                        icon: Icon(Symbols.dialpad_rounded, color: on, size: context.sizes.iconLg),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          context.space.gapLg,
          FarmTapButton(
            label: l10n.typeTagInstead,
            icon: Symbols.dialpad_rounded,
            kind: ButtonKind.outlined,
            onPressed: onTypeTag,
          ),
        ],
      ),
    );
  }
}

/// Four corner brackets and a gold scan line.
class _ScanFrame extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FramePainter(
        corner: context.status.viewfinderAccent,
        line: context.status.brandGold,
        stroke: context.sizes.scanFrameStroke,
        arm: context.sizes.scanFrameArm,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _FramePainter extends CustomPainter {
  new({required this.corner, required this.line, required this.stroke, required this.arm});

  final Color corner;
  final Color line;
  final double stroke;
  final double arm;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final rect = Rect.fromCenter(center: size.center(Offset.zero), width: side, height: side);
    final p = Paint()
      ..color = corner
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke;
    for (final (o, dx, dy) in [
      (rect.topLeft, 1.0, 1.0),
      (rect.topRight, -1.0, 1.0),
      (rect.bottomLeft, 1.0, -1.0),
      (rect.bottomRight, -1.0, -1.0),
    ]) {
      canvas
        ..drawLine(o, o + Offset(arm * dx, 0), p)
        ..drawLine(o, o + Offset(0, arm * dy), p);
    }
    canvas.drawLine(
      Offset(rect.left + arm / 2, rect.center.dy),
      Offset(rect.right - arm / 2, rect.center.dy),
      Paint()
        ..color = line
        ..strokeWidth = stroke / 1.5,
    );
  }

  @override
  bool shouldRepaint(_FramePainter old) => old.corner != corner || old.line != line;
}

// ---------------------------------------------------------------- E09

/// E09 — head count by group, and this month's changes.
class HeadCountPage extends StatelessWidget {
  const new({required this.repo, super.key});

  final HerdRepository repo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<HerdCounts?>(
      future: repo.counts().then((r) => r.data),
      builder: (context, snapshot) {
        final c = snapshot.data;
        Widget change(String label, int n) => Row(
          children: [
            Expanded(child: Text(label, style: context.text.bodySmall)),
            Text(
              n > 0
                  ? '+$n'
                  : n < 0
                  ? '$n'
                  : '0',
              style: context.text.titleSmall,
            ),
          ],
        );
        return AdaptiveScaffold(
          title: l10n.headCount,
          body: c == null
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HeroCard(label: l10n.totalAnimals, value: '${c.total}', animation: FarmTapAnimations.cowGrazing),
                    context.space.gapLg,
                    MetricStrip(
                      children: [
                        MetricCard(icon: Symbols.water_drop_rounded, label: l10n.milkingCows, value: '${c.milking}'),
                        MetricCard(
                          icon: Symbols.hourglass_rounded,
                          label: l10n.dryCows,
                          value: '${c.dry}',
                          tone: FarmTapTone.gold,
                        ),
                        MetricCard(
                          icon: Symbols.favorite_rounded,
                          label: l10n.statusPregnant,
                          value: '${c.pregnant}',
                          tone: FarmTapTone.info,
                        ),
                        MetricCard(
                          icon: Symbols.pets_rounded,
                          label: l10n.heifers,
                          value: '${c.heifers}',
                          tone: FarmTapTone.gold,
                        ),
                        MetricCard(icon: Symbols.pets_rounded, label: l10n.calves, value: '${c.calves}'),
                        MetricCard(
                          icon: Symbols.pets_rounded,
                          label: l10n.bulls,
                          value: '${c.bulls}',
                          tone: FarmTapTone.info,
                        ),
                      ],
                    ),
                    context.space.gapLg,
                    FarmTapCard(
                      children: [
                        Text(l10n.thisMonth, style: context.text.titleMedium),
                        change(l10n.bornCount, c.bornThisMonth),
                        change(l10n.bought, c.boughtThisMonth),
                        change(l10n.sold, -c.soldThisMonth),
                        change(l10n.died, -c.diedThisMonth),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------- E10

/// What an ear-tag QR code encodes.
String animalQrData(String tag) => 'farmtap:animal:$tag';

/// E10 — printable QR ear-tag labels: real, scannable codes. 2 columns on
/// phones, 4 wider; Print / Share PDF use the printing package.
class QrLabelsPage extends StatelessWidget {
  const new({required this.repo, super.key});

  final HerdRepository repo;

  Future<List<Animal>> _animals() async => [for (final r in (await repo.rows()).data ?? const <HerdRow>[]) r.animal];

  static Future<pw.Document> _pdf(List<Animal> animals) async {
    final doc = pw.Document()
      ..addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (_) => pw.Wrap(
            spacing: FarmTapPrint.labelGap,
            runSpacing: FarmTapPrint.labelGap,
            children: [
              for (final a in animals)
                pw.Container(
                  width: FarmTapPrint.labelWidth,
                  padding: const pw.EdgeInsets.all(FarmTapPrint.labelPadding),
                  decoration: pw.BoxDecoration(border: pw.Border.all(width: FarmTapPrint.labelBorder)),
                  child: pw.Row(
                    children: [
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: animalQrData(a.tagNumber),
                        width: FarmTapPrint.labelQr,
                        height: FarmTapPrint.labelQr,
                      ),
                      pw.SizedBox(width: FarmTapPrint.labelInnerGap),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(a.tagNumber, style: FarmTapPrint.tag),
                          pw.Text(a.name, style: FarmTapPrint.small),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    return doc;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<List<Animal>>(
      future: _animals(),
      builder: (context, snapshot) {
        final animals = snapshot.data ?? const <Animal>[];
        return AdaptiveScaffold(
          title: l10n.printLabels,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FarmTapBanner(
                tone: FarmTapTone.info,
                icon: Symbols.info_rounded,
                title: l10n.labelsSelected(animals.length),
                message: l10n.labelsHint,
              ),
              context.space.gapLg,
              FarmTapCard(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final cols = c.maxWidth >= FarmTapBreakpoints.table ? 4 : 2;
                    return ResponsiveGrid(
                      minItemWidth: (c.maxWidth - context.space.md * (cols - 1)) / cols,
                      maxColumns: cols,
                      spacing: context.space.md,
                      children: [for (final a in animals) _QrLabel(animal: a)],
                    );
                  },
                ),
              ),
              context.space.gapLg,
              ButtonPair(
                forceRow: true,
                first: FarmTapButton(
                  label: l10n.sharePdf,
                  icon: Symbols.share_rounded,
                  kind: ButtonKind.outlined,
                  onPressed: animals.isEmpty
                      ? null
                      : () async => await Printing.sharePdf(
                          bytes: await (await _pdf(animals)).save(),
                          filename: 'farmtap-ear-tags.pdf',
                        ),
                ),
                second: FarmTapButton(
                  label: l10n.print,
                  icon: Symbols.print_rounded,
                  onPressed: animals.isEmpty
                      ? null
                      : () => Printing.layoutPdf(onLayout: (_) async => await (await _pdf(animals)).save()),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QrLabel extends StatelessWidget {
  const new({required this.animal});

  final Animal animal;

  @override
  Widget build(BuildContext context) {
    final size = context.sizes.qrLabel;
    // The label is printed on white sticker paper: draw it on the light theme.
    return Theme(
      data: FarmTapTheme.light,
      child: Builder(
        builder: (context) => Container(
          padding: EdgeInsets.all(context.space.md),
          decoration: BoxDecoration(
            color: context.status.card,
            borderRadius: context.radii.chip,
            border: Border.all(color: context.colors.outlineVariant, width: context.sizes.borderThin),
          ),
          child: Row(
            children: [
              Semantics(
                image: true,
                label: animal.tagNumber,
                child: SvgPicture.string(
                  pw.Barcode.qrCode().toSvg(animalQrData(animal.tagNumber), width: size, height: size),
                  width: size,
                  height: size,
                ),
              ),
              context.space.gapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        animal.tagNumber,
                        style: context.textStyles.tagNumber.copyWith(color: context.colors.primary),
                      ),
                    ),
                    Text(animal.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Type tag number instead" (E05): resolves to the animal with that tag.
Future<Animal?> showTypeTagSheet(BuildContext context, HerdRepository repo) =>
    showAdaptiveSheet<Animal>(context, builder: (_) => _TypeTagSheet(repo: repo));

class _TypeTagSheet extends StatefulWidget {
  const new({required this.repo});

  final HerdRepository repo;

  @override
  State<_TypeTagSheet> createState() => _TypeTagSheetState();
}

class _TypeTagSheetState extends State<_TypeTagSheet> {
  final _tag = TextEditingController(text: 'FT-');
  String? _error;

  @override
  void dispose() {
    _tag.dispose();
    super.dispose();
  }

  Future<void> _find() async {
    final l10n = AppLocalizations.of(context);
    final found = (await widget.repo.findByTag(_tag.text.trim().toUpperCase())).data;
    if (!mounted) return;
    if (found == null) {
      setState(() => _error = l10n.noMatches);
    } else {
      Navigator.of(context).pop(found);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetTitle(l10n.typeTagInstead),
        context.space.gapLg,
        FarmTapTextField(
          label: l10n.tagNumberLabel,
          icon: Symbols.badge_rounded,
          controller: _tag,
          error: _error,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _find(),
        ),
        context.space.gapLg,
        FarmTapButton(label: l10n.next, icon: Symbols.check_rounded, onPressed: _find),
      ],
    );
  }
}
