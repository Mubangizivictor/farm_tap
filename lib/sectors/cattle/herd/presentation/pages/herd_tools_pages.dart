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
import 'package:uuid/uuid.dart';

// ---------------------------------------------------------------- E04

enum _Sex { female, bull, calf }

/// What a cow or heifer is doing now (E04 "Status").
enum _CowStatus { milking, dry, heifer }

/// E04 — add an animal, or edit one ([initial]). Asks "Discard changes?"
/// when left with input.
class AddAnimalPage extends StatefulWidget {
  const new({required this.repo, required this.onSaved, super.key, this.now, this.initial});

  final HerdRepository repo;
  final ValueChanged<Animal> onSaved;

  /// Overrides the clock (goldens).
  final DateTime? now;

  /// Edit mode: the animal as saved.
  final Animal? initial;

  @override
  State<AddAnimalPage> createState() => _AddAnimalPageState();
}

class _AddAnimalPageState extends State<AddAnimalPage> {
  late final Animal? _initial = widget.initial;
  late final _tag = TextEditingController(text: _initial?.tagNumber);
  late final _name = TextEditingController(text: _initial?.name);
  late final _national = TextEditingController(text: _initial?.govIdTag);
  late String? _breed = (_initial?.breed ?? '').isEmpty ? null : _initial!.breed;
  late String? _group = _initial?.group;
  late DateTime? _born = _initial?.dateOfBirth;
  late String? _photo = _initial?.photo;
  late _Sex _sex = switch (_initial) {
    null => _Sex.female,
    final a when a.dairyStatus == DairyStatus.calf => _Sex.calf,
    final a when a.sex == AnimalSex.male => _Sex.bull,
    _ => _Sex.female,
  };
  late _CowStatus _status = switch (_initial?.dairyStatus) {
    DairyStatus.dry => _CowStatus.dry,
    DairyStatus.heifer => _CowStatus.heifer,
    null => _CowStatus.milking,
    _ => _CowStatus.milking,
  };
  Animal? _mother;
  String? _tagError;
  bool _saving = false;
  List<Animal> _mothers = const [];

  bool get _editing => _initial != null;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final tag = _editing ? null : (await widget.repo.nextTag()).data;
    final rows = (await widget.repo.rows()).data ?? const <HerdRow>[];
    if (!mounted) return;
    setState(() {
      if (tag != null && _tag.text.isEmpty) _tag.text = tag;
      _mothers = [
        for (final r in rows)
          if (r.animal.sex == AnimalSex.female && r.animal.id != _initial?.id) r.animal,
      ];
      final motherTag = _initial?.motherTag;
      if (motherTag != null) _mother = _mothers.where((m) => m.tagNumber == motherTag).firstOrNull;
    });
  }

  bool get _dirty => _editing
      ? _name.text != _initial!.name || _tag.text != _initial.tagNumber || _photo != _initial.photo
      : _name.text.isNotEmpty || _breed != null || _born != null || _national.text.isNotEmpty || _photo != null;

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

  Future<void> _pickPhoto() async {
    final key = await pickPhoto(context, canRemove: _photo != null);
    if (key == null || !mounted) return;
    setState(() => _photo = key.isEmpty ? null : key);
  }

  DairyStatus get _dairyStatus => switch (_sex) {
    _Sex.bull => DairyStatus.bull,
    _Sex.calf => DairyStatus.calf,
    _Sex.female => switch (_status) {
      _CowStatus.milking => DairyStatus.milking,
      _CowStatus.dry => DairyStatus.dry,
      _CowStatus.heifer => DairyStatus.heifer,
    },
  };

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final tag = _tag.text.trim();
    setState(() => _tagError = tag.isEmpty ? l10n.tagRequired : null);
    if (_tagError != null || _saving) return;
    setState(() => _saving = true);
    final now = widget.now ?? context.clock.now();
    final national = _national.text.trim();
    final initial = _initial;
    Animal animal;
    if (initial != null) {
      animal = initial.copyWith(
        tagNumber: tag,
        name: _name.text.trim(),
        sex: _sex == _Sex.bull ? AnimalSex.male : AnimalSex.female,
        breed: _breed ?? '',
        dateOfBirth: _born,
        govIdTag: national,
        // A treated or pregnant cow keeps that status unless changed here.
        dairyStatus: _dairyStatus == DairyStatus.milking && initial.sex == AnimalSex.female
            ? (initial.dairyStatus == DairyStatus.pregnant ? DairyStatus.pregnant : DairyStatus.milking)
            : _dairyStatus,
        group: _group,
        motherTag: _mother?.tagNumber,
        photo: _photo,
        clearPhoto: _photo == null,
      );
      final ok = (await widget.repo.updateAnimal(animal)).data ?? false;
      if (!mounted) return;
      if (!ok) {
        setState(() {
          _saving = false;
          _tagError = l10n.tagTaken(tag);
        });
        return;
      }
    } else {
      if ((await widget.repo.findByTag(tag)).data != null) {
        if (!mounted) return;
        setState(() {
          _saving = false;
          _tagError = l10n.tagTaken(tag);
        });
        return;
      }
      animal = Animal(
        id: const Uuid().v4(),
        tenantId: '',
        tagNumber: tag,
        name: _name.text.trim(),
        sex: _sex == _Sex.bull ? AnimalSex.male : AnimalSex.female,
        breed: _breed ?? '',
        dateOfBirth: _born ?? now,
        status: AnimalStatus.active,
        govIdTag: national.isEmpty ? null : national,
        createdAt: now,
        updatedAt: now,
        createdBy: 'staff',
        updatedBy: 'staff',
        deviceId: 'device',
        syncStatus: SyncStatus.pending,
        dairyStatus: _dairyStatus,
        group: _group,
        motherTag: _mother?.tagNumber,
        photo: _photo,
      );
      await widget.repo.addAnimal(animal);
    }
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
      picker: (c) => showSearchPicker(c, title: l10n.breedLabel, options: widget.repo.breeds, selected: _breed),
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
        title: _editing ? l10n.editAnimal : l10n.addAnimal2,
        showNavigation: false,
        floatingActionButton: FarmTapFab(
          label: l10n.saveAnimal,
          icon: Symbols.check_rounded,
          onPressed: _saving ? null : _save,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= context.sizes.gridPaired;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PhotoBox(
                      label: _photo == null ? l10n.addPhoto : l10n.changePhoto,
                      photo: _photo,
                      onTap: _pickPhoto,
                    ),
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
                            onChanged: (_) => setState(() => _tagError = null),
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
                if (_sex == _Sex.female) ...[
                  context.space.gapLg,
                  Text(l10n.statusNow, style: context.text.titleSmall),
                  context.space.gapSm,
                  SegmentedTabs<_CowStatus>(
                    options: [
                      TabOption(value: _CowStatus.milking, label: l10n.statusMilking),
                      TabOption(value: _CowStatus.dry, label: l10n.statusDry),
                      TabOption(value: _CowStatus.heifer, label: l10n.statusHeifer),
                    ],
                    selected: _status,
                    onChanged: (s) => setState(() => _status = s),
                  ),
                ],
                context.space.gapLg,
                FarmTapSelectField<String>(
                  label: l10n.groupLabel,
                  icon: Symbols.fence_rounded,
                  options: widget.repo.groups,
                  labelOf: (g) => g,
                  value: _group,
                  onChanged: (g) => setState(() => _group = g),
                  picker: (c) =>
                      showSearchPicker(c, title: l10n.groupLabel, options: widget.repo.groups, selected: _group),
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

/// "Add photo" box beside the tag and name fields; shows the photo once
/// taken.
class _PhotoBox extends StatelessWidget {
  const new({required this.label, required this.onTap, this.photo});

  final String label;
  final String? photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final height = context.sizes.inputHeight * 2 + context.space.lg;
    final empty = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconBubble(icon: Symbols.photo_camera_rounded, size: context.sizes.bubbleLg),
        context.space.gapSm,
        Text(label, style: context.text.labelMedium?.copyWith(color: context.colors.primary)),
      ],
    );
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
          onTap: onTap,
          child: SizedBox(
            width: context.sizes.photoPreview * 0.68,
            height: height,
            child: photo == null ? empty : StoredPhoto(photoKey: photo!, placeholder: empty),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- E05

/// The animal tag in a scanned code: our printed labels hold
/// "farmtap:animal:FT-014"; any other QR is read as the tag itself.
String tagFromQr(String code) {
  const prefix = 'farmtap:animal:';
  final c = code.trim();
  return c.startsWith(prefix) ? c.substring(prefix.length) : c;
}

/// E05 — scan the QR code on an ear tag with the camera. The animal found
/// goes to [onAnimal]; an unknown code says so and keeps scanning.
class ScanTagPage extends StatefulWidget {
  const new({required this.onTypeTag, super.key, this.repo, this.onAnimal});

  final VoidCallback onTypeTag;
  final HerdRepository? repo;
  final ValueChanged<Animal>? onAnimal;

  @override
  State<ScanTagPage> createState() => _ScanTagPageState();
}

class _ScanTagPageState extends State<ScanTagPage> {
  bool _busy = false;

  Future<void> _found(String code) async {
    final repo = widget.repo;
    if (repo == null || _busy) return;
    setState(() => _busy = true);
    final tag = tagFromQr(code);
    final animal = (await repo.findByTag(tag)).data;
    if (!mounted) return;
    setState(() => _busy = false);
    if (animal == null) {
      FarmTapToast.show(
        context,
        message: AppLocalizations.of(context).noAnimalWithTag(tag),
        tone: FarmTapTone.warning,
        icon: Symbols.search_off_rounded,
      );
      return;
    }
    widget.onAnimal?.call(animal);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AdaptiveScaffold(
      title: l10n.scanTag,
      showNavigation: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QrScanView(
            prompt: l10n.pointAtQr,
            paused: _busy,
            onCode: _found,
            extraAction: IconButton(
              tooltip: l10n.typeTagInstead,
              onPressed: widget.onTypeTag,
              icon: Icon(Symbols.dialpad_rounded, color: context.status.onViewfinder, size: context.sizes.iconLg),
            ),
          ),
          context.space.gapLg,
          FarmTapButton(
            label: l10n.typeTagInstead,
            icon: Symbols.dialpad_rounded,
            kind: ButtonKind.outlined,
            onPressed: widget.onTypeTag,
          ),
        ],
      ),
    );
  }
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
                      fillLastRow: false,
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
