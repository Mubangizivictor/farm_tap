import 'dart:async';
import 'dart:io';

import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/media/photo_store.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/adaptive_sheet.dart';
import 'package:farm_tap/core/ui/icon_bubble.dart';
import 'package:farm_tap/core/ui/tone.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Asks "Take photo" or "Choose from phone" and saves the photo; returns
/// its key, or null when the person backs out. [canRemove] adds "Remove"
/// (returns an empty string).
Future<String?> pickPhoto(BuildContext context, {bool canRemove = false}) async {
  final l10n = AppLocalizations.of(context);
  final choice = await showAdaptiveSheet<int>(
    context,
    builder: (sheet) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetTitle(l10n.addPhoto),
        sheet.space.gapMd,
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const IconBubble(icon: Symbols.photo_camera_rounded),
          title: Text(l10n.takePhoto),
          onTap: () => Navigator.of(sheet).pop(0),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const IconBubble(icon: Symbols.photo_library_rounded, tone: FarmTapTone.info),
          title: Text(l10n.choosePhoto),
          onTap: () => Navigator.of(sheet).pop(1),
        ),
        if (canRemove)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const IconBubble(icon: Symbols.delete_rounded, tone: FarmTapTone.danger),
            title: Text(l10n.removePhoto),
            onTap: () => Navigator.of(sheet).pop(2),
          ),
      ],
    ),
  );
  if (choice == null) return null;
  if (choice == 2) return '';
  try {
    return await PhotoStore.instance.capture(camera: choice == 0);
  } on Object {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.photoFailed)));
    }
    return null;
  }
}

/// Shows a saved photo by its key: from this phone, else downloaded; while
/// neither is there, [placeholder].
class StoredPhoto extends StatefulWidget {
  const new({required this.photoKey, required this.placeholder, super.key, this.fit = BoxFit.cover});

  final String photoKey;
  final Widget placeholder;
  final BoxFit fit;

  @override
  State<StoredPhoto> createState() => _StoredPhotoState();
}

class _StoredPhotoState extends State<StoredPhoto> {
  File? _file;
  String? _url;

  @override
  void initState() {
    super.initState();
    unawaited(_find());
  }

  @override
  void didUpdateWidget(StoredPhoto old) {
    super.didUpdateWidget(old);
    if (old.photoKey != widget.photoKey) {
      _file = null;
      _url = null;
      unawaited(_find());
    }
  }

  Future<void> _find() async {
    final key = widget.photoKey;
    if (key.startsWith('http')) {
      setState(() => _url = key);
      return;
    }
    final file = await PhotoStore.instance.localFile(key);
    if (!mounted || key != widget.photoKey) return;
    if (file != null) {
      setState(() => _file = file);
      return;
    }
    final url = await PhotoStore.instance.remoteUrl(key);
    if (mounted && key == widget.photoKey && url != null) setState(() => _url = url);
  }

  @override
  Widget build(BuildContext context) {
    final f = _file;
    if (f != null) {
      return Image.file(f, fit: widget.fit, errorBuilder: (_, _, _) => widget.placeholder);
    }
    final u = _url;
    if (u != null) {
      return Image.network(u, fit: widget.fit, errorBuilder: (_, _, _) => widget.placeholder);
    }
    return widget.placeholder;
  }
}
