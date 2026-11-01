import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/animation_view.dart';
import 'package:farm_tap/core/ui/buttons.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Animation + title + one action. Every empty list uses this (P01).
class EmptyState extends StatelessWidget {
  const new({
    required this.title,
    super.key,
    this.message,
    this.animation = FarmTapAnimations.emptyHerd,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  final String title;
  final String? message;
  final FarmTapAnimation animation;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => _StateBody(
    animation: animation,
    title: title,
    message: message,
    actionLabel: actionLabel,
    actionIcon: actionIcon,
    onAction: onAction,
  );
}

/// Confused cow + "Try again". Data on the phone is safe (P02).
class ErrorState extends StatelessWidget {
  const new({super.key, this.title, this.message, this.onRetry});

  final String? title;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _StateBody(
      animation: FarmTapAnimations.errorConfused,
      title: title ?? l10n.errorDefaultTitle,
      message: message ?? l10n.errorDefaultBody,
      actionLabel: onRetry == null ? null : l10n.tryAgain,
      actionIcon: Symbols.refresh_rounded,
      onAction: onRetry,
    );
  }
}

class _StateBody extends StatelessWidget {
  const new({
    required this.animation,
    required this.title,
    this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  final FarmTapAnimation animation;
  final String title;
  final String? message;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: context.space.screen,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: context.sizes.centeredMaxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FarmTapAnimationView(animation: animation),
              context.space.gapLg,
              Text(title, textAlign: TextAlign.center, style: context.text.headlineSmall),
              if (message != null) ...[
                context.space.gapSm,
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ],
              if (actionLabel != null) ...[
                context.space.gapXl,
                FarmTapButton(label: actionLabel!, icon: actionIcon, onPressed: onAction, expand: false),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
