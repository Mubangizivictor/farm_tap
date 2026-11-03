// Take or choose a person's photo (decision 0015 §2): camera or gallery,
// shrunk on the phone and saved through the PhotoStore.
import 'dart:async';

import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/people/domain/photo_store.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Asks camera or gallery, then saves the photo for [personId]. Null when
/// the person cancelled or the photo could not be read.
Future<PersonPhoto?> takePersonPhoto(BuildContext context, PhotoStore store, String personId) async {
  final l10n = AppLocalizations.of(context);
  final source = await showAdaptiveSheet<ImageSource>(
    context,
    builder: (sheet) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(l10n.photoSheetTitle, subtitle: l10n.photoSheetBody),
        sheet.space.gapLg,
        FarmTapButton(
          label: l10n.takePhoto,
          icon: Symbols.photo_camera_rounded,
          large: true,
          onPressed: () => Navigator.of(sheet).pop(ImageSource.camera),
        ),
        sheet.space.gapSm,
        FarmTapButton(
          label: l10n.chooseFromGallery,
          icon: Symbols.photo_library_rounded,
          kind: ButtonKind.outlined,
          onPressed: () => Navigator.of(sheet).pop(ImageSource.gallery),
        ),
      ],
    ),
  );
  if (source == null) return null;
  try {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1080,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.front,
    );
    if (picked == null) return null;
    final saved = await store.save(personId: personId, bytes: await picked.readAsBytes());
    if (!context.mounted) return saved.data;
    FarmTapToast.show(
      context,
      message: saved.data == null
          ? l10n.photoNotSaved
          : saved.data!.url == null
          ? l10n.photoSavedLocal
          : l10n.photoSaved,
    );
    return saved.data;
  } on Object {
    if (context.mounted) FarmTapToast.show(context, message: l10n.photoNotSaved);
    return null;
  }
}
