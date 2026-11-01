// Semantic colours that Material's ColorScheme doesn't have.
// Use: context.status.success, context.status.withdrawal, context.status.syncPending
// Mapped from the palette for light and dark mode. Change the mapping here.
import 'package:farm_tap/core/theme/tokens/farmtap_palette.dart';
import 'package:flutter/material.dart';

@immutable
class FarmTapSemanticColors extends ThemeExtension<FarmTapSemanticColors> {
  const new({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.danger,
    required this.onDanger,
    required this.dangerContainer,
    required this.onDangerContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.brandGreen,
    required this.brandGold,
    required this.keypadKey,
    required this.onKeypadKey,
    required this.keypadAction,
    required this.onKeypadAction,
    required this.synced,
    required this.syncPending,
    required this.syncFailed,
    required this.withdrawal,
    required this.nfcActive,
    required this.card,
    required this.scrim,
    required this.viewfinder,
    required this.onViewfinder,
    required this.viewfinderAccent,
  });

  /// Saved, paid, healthy, synced.
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;

  /// Due soon, low stock, pending.
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;

  /// Problem, overdue, withdrawal period, deleted.
  final Color danger;
  final Color onDanger;
  final Color dangerContainer;
  final Color onDangerContainer;

  /// Neutral information, tips.
  final Color info;
  final Color onInfo;
  final Color infoContainer;
  final Color onInfoContainer;

  /// Logo posts colour.
  final Color brandGreen;

  /// Logo ring and centre colour.
  final Color brandGold;

  /// Number keypad key background.
  final Color keypadKey;

  /// Number keypad digit colour.
  final Color onKeypadKey;

  /// Keypad confirm key background.
  final Color keypadAction;

  /// Keypad confirm key content.
  final Color onKeypadAction;

  /// Record is synced to the cloud.
  final Color synced;

  /// Record waiting to sync.
  final Color syncPending;

  /// Record failed to sync.
  final Color syncFailed;

  /// Animal under drug withdrawal (milk/meat not for sale).
  final Color withdrawal;

  /// NFC reader is listening.
  final Color nfcActive;

  /// Card background (white in light mode, night200 in dark).
  final Color card;

  /// Modal scrim behind dialogs and sheets (black 42% light / 60% dark).
  final Color scrim;

  /// Camera / scanner viewfinder background (dark in both modes) and its icons.
  final Color viewfinder;
  final Color onViewfinder;

  /// Scan-frame corners on the viewfinder.
  final Color viewfinderAccent;

  static const light = FarmTapSemanticColors(
    success: FarmTapPalette.success600,
    onSuccess: FarmTapPalette.white,
    successContainer: FarmTapPalette.success50,
    onSuccessContainer: FarmTapPalette.success900,
    warning: FarmTapPalette.warning600,
    onWarning: FarmTapPalette.white,
    warningContainer: FarmTapPalette.warning50,
    onWarningContainer: FarmTapPalette.warning900,
    danger: FarmTapPalette.danger600,
    onDanger: FarmTapPalette.white,
    dangerContainer: FarmTapPalette.danger50,
    onDangerContainer: FarmTapPalette.danger950,
    info: FarmTapPalette.blue650,
    onInfo: FarmTapPalette.white,
    infoContainer: FarmTapPalette.blue100,
    onInfoContainer: FarmTapPalette.blue900,
    brandGreen: FarmTapPalette.green700,
    brandGold: FarmTapPalette.gold500,
    keypadKey: FarmTapPalette.white,
    onKeypadKey: FarmTapPalette.ink,
    keypadAction: FarmTapPalette.green700,
    onKeypadAction: FarmTapPalette.white,
    synced: FarmTapPalette.success600,
    syncPending: FarmTapPalette.warning600,
    syncFailed: FarmTapPalette.danger600,
    withdrawal: FarmTapPalette.danger600,
    nfcActive: FarmTapPalette.green700,
    card: FarmTapPalette.white,
    scrim: FarmTapPalette.scrimLight,
    viewfinder: FarmTapPalette.night100,
    onViewfinder: FarmTapPalette.mistSoft,
    viewfinderAccent: FarmTapPalette.green400,
  );

  static const dark = FarmTapSemanticColors(
    success: FarmTapPalette.success300,
    onSuccess: FarmTapPalette.success950,
    successContainer: FarmTapPalette.success800,
    onSuccessContainer: FarmTapPalette.success100,
    warning: FarmTapPalette.warning300,
    onWarning: FarmTapPalette.warning950,
    warningContainer: FarmTapPalette.warning800,
    onWarningContainer: FarmTapPalette.warning100,
    danger: FarmTapPalette.danger300,
    onDanger: FarmTapPalette.danger900,
    dangerContainer: FarmTapPalette.danger800,
    onDangerContainer: FarmTapPalette.danger50,
    info: FarmTapPalette.blue300,
    onInfo: FarmTapPalette.blue950,
    infoContainer: FarmTapPalette.blue800,
    onInfoContainer: FarmTapPalette.blue50,
    brandGreen: FarmTapPalette.green400,
    brandGold: FarmTapPalette.gold300,
    keypadKey: FarmTapPalette.night300,
    onKeypadKey: FarmTapPalette.mist,
    keypadAction: FarmTapPalette.green400,
    onKeypadAction: FarmTapPalette.green950,
    synced: FarmTapPalette.success300,
    syncPending: FarmTapPalette.warning300,
    syncFailed: FarmTapPalette.danger300,
    withdrawal: FarmTapPalette.danger300,
    nfcActive: FarmTapPalette.green400,
    card: FarmTapPalette.night200,
    scrim: FarmTapPalette.scrimDark,
    viewfinder: FarmTapPalette.night0,
    onViewfinder: FarmTapPalette.mist,
    viewfinderAccent: FarmTapPalette.green400,
  );

  @override
  FarmTapSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? danger,
    Color? onDanger,
    Color? dangerContainer,
    Color? onDangerContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? brandGreen,
    Color? brandGold,
    Color? keypadKey,
    Color? onKeypadKey,
    Color? keypadAction,
    Color? onKeypadAction,
    Color? synced,
    Color? syncPending,
    Color? syncFailed,
    Color? withdrawal,
    Color? nfcActive,
    Color? card,
    Color? scrim,
    Color? viewfinder,
    Color? onViewfinder,
    Color? viewfinderAccent,
  }) => FarmTapSemanticColors(
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    successContainer: successContainer ?? this.successContainer,
    onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
    warning: warning ?? this.warning,
    onWarning: onWarning ?? this.onWarning,
    warningContainer: warningContainer ?? this.warningContainer,
    onWarningContainer: onWarningContainer ?? this.onWarningContainer,
    danger: danger ?? this.danger,
    onDanger: onDanger ?? this.onDanger,
    dangerContainer: dangerContainer ?? this.dangerContainer,
    onDangerContainer: onDangerContainer ?? this.onDangerContainer,
    info: info ?? this.info,
    onInfo: onInfo ?? this.onInfo,
    infoContainer: infoContainer ?? this.infoContainer,
    onInfoContainer: onInfoContainer ?? this.onInfoContainer,
    brandGreen: brandGreen ?? this.brandGreen,
    brandGold: brandGold ?? this.brandGold,
    keypadKey: keypadKey ?? this.keypadKey,
    onKeypadKey: onKeypadKey ?? this.onKeypadKey,
    keypadAction: keypadAction ?? this.keypadAction,
    onKeypadAction: onKeypadAction ?? this.onKeypadAction,
    synced: synced ?? this.synced,
    syncPending: syncPending ?? this.syncPending,
    syncFailed: syncFailed ?? this.syncFailed,
    withdrawal: withdrawal ?? this.withdrawal,
    nfcActive: nfcActive ?? this.nfcActive,
    card: card ?? this.card,
    scrim: scrim ?? this.scrim,
    viewfinder: viewfinder ?? this.viewfinder,
    onViewfinder: onViewfinder ?? this.onViewfinder,
    viewfinderAccent: viewfinderAccent ?? this.viewfinderAccent,
  );

  @override
  ThemeExtension<FarmTapSemanticColors> lerp(covariant ThemeExtension<FarmTapSemanticColors>? other, double t) {
    if (other is! FarmTapSemanticColors) return this;
    return FarmTapSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer: Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer: Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      onDangerContainer: Color.lerp(onDangerContainer, other.onDangerContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
      brandGreen: Color.lerp(brandGreen, other.brandGreen, t)!,
      brandGold: Color.lerp(brandGold, other.brandGold, t)!,
      keypadKey: Color.lerp(keypadKey, other.keypadKey, t)!,
      onKeypadKey: Color.lerp(onKeypadKey, other.onKeypadKey, t)!,
      keypadAction: Color.lerp(keypadAction, other.keypadAction, t)!,
      onKeypadAction: Color.lerp(onKeypadAction, other.onKeypadAction, t)!,
      synced: Color.lerp(synced, other.synced, t)!,
      syncPending: Color.lerp(syncPending, other.syncPending, t)!,
      syncFailed: Color.lerp(syncFailed, other.syncFailed, t)!,
      withdrawal: Color.lerp(withdrawal, other.withdrawal, t)!,
      nfcActive: Color.lerp(nfcActive, other.nfcActive, t)!,
      card: Color.lerp(card, other.card, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      viewfinder: Color.lerp(viewfinder, other.viewfinder, t)!,
      onViewfinder: Color.lerp(onViewfinder, other.onViewfinder, t)!,
      viewfinderAccent: Color.lerp(viewfinderAccent, other.viewfinderAccent, t)!,
    );
  }
}
