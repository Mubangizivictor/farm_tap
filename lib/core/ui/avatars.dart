import 'dart:convert';
import 'dart:typed_data';

import 'package:farm_tap/core/media/photo_store.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/photo_widgets.dart';
import 'package:farm_tap/core/ui/tone.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Cow photo, or one of the cartoon cow avatars when the farm has no photo,
/// on a surfaceContainer circle. [avatarIndex] (1-6) picks the cartoon;
/// otherwise it is derived from [animalId] so the same cow always looks the same.
class CowAvatar extends StatelessWidget {
  const new({
    super.key,
    this.photoUrl,
    this.animalId,
    this.avatarIndex,
    this.isCalf = false,
    this.size,
    this.ring = false,
    this.semanticLabel,
  });

  final String? photoUrl;
  final String? animalId;
  final int? avatarIndex;
  final bool isCalf;

  /// Defaults to `context.sizes.avatarMd` (48).
  final double? size;

  /// 3 dp primary ring (read-back, detail headers).
  final bool ring;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final dimension = size ?? context.sizes.avatarMd;
    final url = photoUrl ?? (animalId == null ? null : PhotoStore.instance.animalPhotos[animalId]);
    final index = avatarIndex;
    final cartoon = isCalf
        ? FarmTapAssets.calfAvatar
        : index != null
        ? FarmTapAssets.cowAvatar(index - 1)
        : animalId == null
        ? FarmTapAssets.cowAvatar(0)
        : FarmTapAssets.cowAvatarFor(animalId!);
    final fallback = Image.asset(
      cartoon,
      fit: BoxFit.cover,
      excludeFromSemantics: true,
      errorBuilder: (_, _, _) =>
          Icon(Symbols.pets_rounded, size: dimension * 0.5, color: context.colors.onSurfaceVariant),
    );
    return Semantics(
      label: semanticLabel,
      image: true,
      child: Container(
        width: dimension,
        height: dimension,
        padding: ring ? EdgeInsets.all(context.sizes.avatarRing) : EdgeInsets.zero,
        decoration: BoxDecoration(shape: BoxShape.circle, color: ring ? context.colors.primary : null),
        child: Container(
          decoration: BoxDecoration(shape: BoxShape.circle, color: context.colors.surfaceContainer),
          clipBehavior: Clip.antiAlias,
          child: url == null || url.isEmpty ? fallback : StoredPhoto(photoKey: url, placeholder: fallback),
        ),
      ),
    );
  }
}

/// Initials in a coloured circle ("MT", "TA"). Initials are titleSmall at 36%
/// of the size. [tone] picks the container: primary (default), gold or info.
class PersonAvatar extends StatelessWidget {
  const new({
    required this.name,
    super.key,
    this.size,
    this.ring = false,
    this.ringColor,
    this.tone = FarmTapTone.primary,
    this.initials,
    this.onTap,
    this.photo,
  });

  final String name;

  /// The person's photo (base64 JPEG from their record); initials when null.
  final String? photo;

  static final _decoded = <String, Uint8List>{};

  /// Decodes a base64 photo once; null when it is not a picture.
  static Uint8List? photoBytes(String? photo) {
    if (photo == null || photo.isEmpty) return null;
    final hit = _decoded[photo];
    if (hit != null) return hit;
    try {
      final bytes = base64Decode(photo);
      if (_decoded.length > 64) _decoded.remove(_decoded.keys.first);
      return _decoded[photo] = bytes;
    } on FormatException {
      return null;
    }
  }

  /// Defaults to `context.sizes.avatarSm` (40).
  final double? size;

  /// 3 dp primary ring (staff avatar in the top bar).
  final bool ring;

  /// Ring colour instead of primary (danger on a wrong PIN, C04).
  final Color? ringColor;
  final FarmTapTone tone;

  /// Overrides the initials derived from [name].
  final String? initials;
  final VoidCallback? onTap;

  static String initialsOf(String name) {
    final parts = name
        .replaceAll(RegExp(r'^(Dr\.?)\s+'), '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final dimension = size ?? context.sizes.avatarSm;
    final colors = tone.of(context);
    final bytes = photoBytes(photo);
    final avatar = Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.container,
        border: ring ? Border.all(color: ringColor ?? context.colors.primary, width: context.sizes.avatarRing) : null,
      ),
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      child: bytes != null
          ? Image.memory(bytes, width: dimension, height: dimension, fit: BoxFit.cover, gaplessPlayback: true)
          : Text(
              initials ?? initialsOf(name),
              style: FarmTapTextStyles.initials(
                context.text.titleSmall!,
                dimension,
                context.sizes.initialsFraction,
              ).copyWith(color: colors.onContainer),
            ),
    );
    if (onTap == null) {
      return Semantics(
        label: name,
        child: ExcludeSemantics(child: avatar),
      );
    }
    // At least a 48 dp tap area around small avatars.
    final target = dimension < context.sizes.touchTarget ? context.sizes.touchTarget : dimension;
    return Semantics(
      label: name,
      button: true,
      child: InkResponse(
        onTap: onTap,
        radius: target / 2,
        child: SizedBox.square(
          dimension: target,
          child: Center(child: ExcludeSemantics(child: avatar)),
        ),
      ),
    );
  }
}
