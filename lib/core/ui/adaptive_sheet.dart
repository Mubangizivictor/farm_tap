import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/breakpoints.dart';
import 'package:farm_tap/core/ui/icon_bubble.dart';
import 'package:farm_tap/core/ui/tone.dart';
import 'package:flutter/material.dart';

/// Bottom sheet on compact widths, centred dialog (max 560 dp) on wider ones.
/// Tap scrim or back closes it unless [dismissible] is false (read-back
/// needs a choice). UX_SPEC sections 1 and 4.
Future<T?> showAdaptiveSheet<T>(BuildContext context, {required WidgetBuilder builder, bool dismissible = true}) {
  if (context.isCompact) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      isDismissible: dismissible,
      enableDrag: dismissible,
      builder: (sheetContext) => PopScope(
        canPop: dismissible,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
          child: Padding(padding: sheetContext.space.sheet.copyWith(top: 0), child: builder(sheetContext)),
        ),
      ),
    );
  }
  return showDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    builder: (dialogContext) => PopScope(
      canPop: dismissible,
      child: Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: dialogContext.sizes.dialogMaxWidth),
          child: SingleChildScrollView(padding: dialogContext.space.sheet, child: builder(dialogContext)),
        ),
      ),
    ),
  );
}

/// Confirmation content: icon in a coloured bubble, plain-language title,
/// the consequence in one sentence, and a primary action named by its verb
/// ("Record death", never "OK").
class FarmTapDialog extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.primaryLabel,
    super.key,
    this.message,
    this.tone = FarmTapTone.warning,
    this.secondaryLabel,
    this.onPrimary,
    this.onSecondary,
    this.destructive = false,
    this.child,
  });

  final IconData icon;
  final String title;
  final String? message;
  final FarmTapTone tone;
  final String primaryLabel;
  final String? secondaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;

  /// Danger-coloured primary button (death, close session, sign out).
  final bool destructive;

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
            child: IconBubble(icon: icon, tone: tone, size: context.sizes.avatarLg, iconSize: context.sizes.iconXl),
          ),
          context.space.gapLg,
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.text.headlineSmall?.copyWith(fontWeight: FarmTapWeights.bold),
          ),
          if (message != null) ...[
            context.space.gapSm,
            Text(
              message!,
              textAlign: TextAlign.center,
              style: context.text.bodyLarge?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ],
          if (child != null) ...[context.space.gapLg, child!],
          context.space.gapXl,
          FilledButton(
            onPressed: onPrimary ?? () => Navigator.of(context).pop(true),
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: context.status.danger,
                    foregroundColor: context.status.onDanger,
                  )
                : null,
            child: Text(primaryLabel),
          ),
          if (secondaryLabel != null) ...[
            context.space.gapSm,
            OutlinedButton(
              onPressed: onSecondary ?? () => Navigator.of(context).pop(false),
              child: Text(secondaryLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shows a [FarmTapDialog] as a centred dialog on every width (full width
/// minus 32 dp on phones). Resolves to true when the primary action is taken.
Future<bool> showFarmTapDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String primaryLabel,
  String? message,
  String? secondaryLabel,
  FarmTapTone tone = FarmTapTone.warning,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: dialogContext.space.xxl, vertical: dialogContext.space.xl),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogContext.sizes.dialogMaxWidth),
        child: SingleChildScrollView(
          padding: dialogContext.space.sheet,
          child: FarmTapDialog(
            icon: icon,
            title: title,
            message: message,
            tone: tone,
            primaryLabel: primaryLabel,
            secondaryLabel: secondaryLabel,
            destructive: destructive,
          ),
        ),
      ),
    ),
  );
  return result ?? false;
}
