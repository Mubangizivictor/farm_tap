import 'package:farm_tap/core/theme/theme.dart';
import 'package:flutter/material.dart';

/// Cow photo, or one of the cartoon cow avatars when the farm has no photo.
/// The cartoon is picked from [animalId] so the same cow always looks the same.
class CowAvatar extends StatelessWidget {
  const new({
    super.key,
    this.photoUrl,
    this.animalId,
    this.isCalf = false,
    this.size,
    this.ring = false,
    this.semanticLabel,
  });

  final String? photoUrl;

  /// Used to pick the cartoon avatar (hash of the id).
  final String? animalId;
  final bool isCalf;
  final double? size;

  /// Green ring, used on read-back and detail screens.
  final bool ring;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final dimension = size ?? context.sizes.avatarLg;
    final url = photoUrl;
    final cartoon = isCalf
        ? FarmTapAssets.calfAvatar
        : animalId == null
        ? FarmTapAssets.cowAvatar(0)
        : FarmTapAssets.cowAvatarFor(animalId!);
    final fallback = Image.asset(
      cartoon,
      width: dimension,
      height: dimension,
      fit: BoxFit.cover,
      excludeFromSemantics: true,
      errorBuilder: (_, _, _) =>
          Icon(Icons.pets_rounded, size: dimension * 0.5, color: context.colors.onSurfaceVariant),
    );
    return Semantics(
      label: semanticLabel,
      image: true,
      child: Container(
        width: dimension,
        height: dimension,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.colors.surfaceContainerHigh,
          border: ring ? Border.all(color: context.colors.primary, width: context.sizes.borderThick * 1.5) : null,
        ),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        child: url == null
            ? fallback
            : Image.network(
                url,
                width: dimension,
                height: dimension,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}

/// Initials in a green-ringed circle ("MT", "TA").
class PersonAvatar extends StatelessWidget {
  const new({required this.name, super.key, this.size, this.ring = true, this.onTap});

  final String name;
  final double? size;
  final bool ring;
  final VoidCallback? onTap;

  static String initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final dimension = size ?? context.sizes.avatarMd;
    final avatar = Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.colors.primaryContainer,
        border: ring ? Border.all(color: context.colors.primary, width: context.sizes.borderThick) : null,
      ),
      alignment: Alignment.center,
      child: Text(
        initialsOf(name),
        style: (dimension >= context.sizes.avatarXl ? context.text.headlineMedium : context.text.titleMedium)?.copyWith(
          color: context.colors.onPrimaryContainer,
          fontWeight: FarmTapWeights.bold,
        ),
      ),
    );
    if (onTap == null) {
      return Semantics(
        label: name,
        child: ExcludeSemantics(child: avatar),
      );
    }
    return Semantics(
      label: name,
      button: true,
      child: InkResponse(
        onTap: onTap,
        radius: dimension,
        child: ExcludeSemantics(child: avatar),
      ),
    );
  }
}
