import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/buttons.dart';
import 'package:farm_tap/core/ui/icon_bubble.dart';
import 'package:farm_tap/core/ui/tone.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Compact: bottom sheet (top radius 28, c1, 36x5 handle at 12, content
/// padding 24 starting 36 from the top). Wider: the same content in a 560
/// dialog with a close (x) icon. Tap scrim or back closes it unless
/// [dismissible] is false (read-back needs a choice).
Future<T?> showAdaptiveSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool dismissible = true,
  AlignmentGeometry? dialogAlignment,
}) {
  if (context.isCompact) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      isDismissible: dismissible,
      enableDrag: dismissible,
      builder: (sheetContext) => PopScope(
        canPop: dismissible,
        child: SheetFrame(child: builder(sheetContext)),
      ),
    );
  }
  return showDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    builder: (dialogContext) => PopScope(
      canPop: dismissible,
      child: Dialog(
        alignment: dialogAlignment,
        child: SheetDialogFrame(showClose: dismissible, child: builder(dialogContext)),
      ),
    ),
  );
}

/// Bottom-sheet body with the drag handle. Public so goldens can show a
/// sheet state without opening a route.
class SheetFrame extends StatelessWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final handleTop = context.space.md;
    final contentTop = context.space.xxl + context.space.xs; // 36
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: handleTop),
          Center(
            child: Container(
              width: context.sizes.sheetHandleWidth,
              height: context.sizes.sheetHandleHeight,
              decoration: BoxDecoration(color: context.colors.outline, borderRadius: context.radii.badge),
            ),
          ),
          SizedBox(height: contentTop - handleTop - context.sizes.sheetHandleHeight),
          Padding(padding: EdgeInsets.fromLTRB(context.space.xl, 0, context.space.xl, context.space.xl), child: child),
        ],
      ),
    );
  }
}

/// Wide-screen frame for sheet content: 560 wide, padding 24, close (x).
class SheetDialogFrame extends StatelessWidget {
  const new({required this.child, super.key, this.showClose = true});

  final Widget child;
  final bool showClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: context.sizes.dialogMaxWidth),
      child: Stack(
        children: [
          SingleChildScrollView(padding: context.space.sheet, child: child),
          if (showClose)
            Positioned(
              top: context.space.sm,
              right: context.space.sm,
              child: IconButton(
                tooltip: l10n.close,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: Icon(Symbols.close_rounded, color: context.colors.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

/// Sheet / dialog title row: titleLarge with an optional subtitle.
class SheetTitle extends StatelessWidget {
  const new(this.title, {super.key, this.subtitle, this.center = false});

  final String title;
  final String? subtitle;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final align = center ? TextAlign.center : TextAlign.start;
    return Column(
      crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, textAlign: align, style: context.text.titleLarge),
        if (subtitle != null) ...[
          context.space.gapXs,
          Text(
            subtitle!,
            textAlign: align,
            style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

/// Confirmation content: centred IconBubble 64 (or [visual], e.g. an
/// animation 150), centred title titleLarge, message bodyMedium, then
/// full-width stacked buttons 10 apart. The primary action is named by its
/// verb ("Record death", never "OK").
class FarmTapDialog extends StatelessWidget {
  const new({
    required this.title,
    required this.primaryLabel,
    super.key,
    this.icon,
    this.visual,
    this.message,
    this.tone = FarmTapTone.warning,
    this.primaryIcon,
    this.secondaryLabel,
    this.onPrimary,
    this.onSecondary,
    this.primaryKind = ButtonKind.filled,
    this.child,
  });

  final IconData? icon;

  /// Replaces the icon bubble (e.g. FarmTapAnimationView).
  final Widget? visual;
  final String title;
  final String? message;
  final FarmTapTone tone;
  final String primaryLabel;
  final IconData? primaryIcon;
  final String? secondaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;

  /// danger for death / close session / sign out.
  final ButtonKind primaryKind;

  /// Optional extra content between message and buttons.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      explicitChildNodes: true,
      scopesRoute: true,
      namesRoute: true,
      label: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: visual ?? IconBubble(icon: icon ?? Symbols.info_rounded, tone: tone, size: context.sizes.bubbleXl),
          ),
          context.space.gapLg,
          Text(title, textAlign: TextAlign.center, style: context.text.titleLarge),
          if (message != null) ...[
            context.space.gapSm,
            Text(
              message!,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ],
          if (child != null) ...[context.space.gapLg, child!],
          context.space.gapXl,
          FarmTapButton(
            label: primaryLabel,
            icon: primaryIcon,
            kind: primaryKind,
            onPressed: onPrimary ?? () => Navigator.of(context).pop(true),
          ),
          if (secondaryLabel != null) ...[
            SizedBox(height: context.space.keyGap),
            FarmTapButton(
              label: secondaryLabel!,
              kind: ButtonKind.outlined,
              onPressed: onSecondary ?? () => Navigator.of(context).pop(false),
            ),
          ],
        ],
      ),
    );
  }
}

/// Dialog frame: 400 wide (screen - 32 on phones), radius 28, c1, padding 24.
class DialogFrame extends StatelessWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Dialog(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: context.sizes.dialogWidth),
      child: SingleChildScrollView(padding: context.space.sheet, child: child),
    ),
  );
}

/// Shows a [FarmTapDialog] centred on every width. Resolves to true when the
/// primary action is taken.
Future<bool> showFarmTapDialog(
  BuildContext context, {
  required String title,
  required String primaryLabel,
  IconData? icon,
  Widget? visual,
  String? message,
  String? secondaryLabel,
  IconData? primaryIcon,
  FarmTapTone tone = FarmTapTone.warning,
  ButtonKind primaryKind = ButtonKind.filled,
  bool dismissible = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: dismissible,
    builder: (dialogContext) => DialogFrame(
      child: FarmTapDialog(
        icon: icon,
        visual: visual,
        title: title,
        message: message,
        tone: tone,
        primaryLabel: primaryLabel,
        primaryIcon: primaryIcon,
        secondaryLabel: secondaryLabel,
        primaryKind: primaryKind,
      ),
    ),
  );
  return result ?? false;
}
