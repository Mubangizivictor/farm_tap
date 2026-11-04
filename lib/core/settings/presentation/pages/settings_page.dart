// N02 Settings: account, farm, appearance (phone / light / dark), sounds.
import 'dart:async';

import 'package:farm_tap/core/account/presentation/account_pages.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/settings/app_settings_cubit.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

class SettingsPage extends StatelessWidget {
  const new({
    required this.name,
    required this.email,
    required this.role,
    required this.farmName,
    required this.onSignOut,
    super.key,
    this.photo,
    this.onPhoto,
    this.onReminders,
    this.onSubscription,
    this.onDeleteAccount,
  });

  /// The person's own picture (base64).
  final String? photo;

  /// Take or choose a profile photo; null hides it (workers on a farm phone).
  final VoidCallback? onPhoto;
  final VoidCallback? onReminders;
  final VoidCallback? onSubscription;

  /// Close the account (decision 0024); null for workers without an account.
  final VoidCallback? onDeleteAccount;

  final String name;
  final String email;

  /// "Owner".
  final String role;
  final String farmName;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Tests may build the page without the app-wide settings.
    final cubit = context.read<AppSettingsCubit?>();
    return AdaptiveScaffold(
      title: l10n.settings,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(l10n.accountTitle),
          context.space.gapSm,
          ListCard(
            children: [
              RecordTile(
                leading: PersonAvatar(name: name, photo: photo, size: context.sizes.avatarMd),
                title: name,
                subtitle: email.isEmpty ? role : '$role · $email',
                trailing: onPhoto == null
                    ? null
                    : IconButton(
                        tooltip: l10n.profilePhoto,
                        icon: Icon(Symbols.photo_camera_rounded, color: context.colors.primary),
                        onPressed: onPhoto,
                      ),
                showChevron: false,
                onTap: onPhoto,
              ),
              if (farmName.isNotEmpty)
                RecordTile(
                  leading: IconBubble(icon: Symbols.home_rounded, size: context.sizes.bubbleMd),
                  title: farmName,
                  subtitle: l10n.farmTitle,
                  showChevron: false,
                ),
            ],
          ),
          if (cubit != null)
            BlocBuilder<AppSettingsCubit, AppSettings>(
              bloc: cubit,
              builder: (context, settings) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  context.space.gapLg,
                  SectionLabel(l10n.appearanceTitle),
                  context.space.gapSm,
                  SegmentedTabs<ThemeMode>(
                    options: [
                      TabOption(value: ThemeMode.system, label: l10n.themeSystem, icon: Symbols.smartphone_rounded),
                      TabOption(value: ThemeMode.light, label: l10n.themeLight, icon: Symbols.light_mode_rounded),
                      TabOption(value: ThemeMode.dark, label: l10n.themeDark, icon: Symbols.dark_mode_rounded),
                    ],
                    selected: settings.themeMode,
                    onChanged: cubit.setTheme,
                  ),
                  context.space.gapXs,
                  Text(l10n.themeHelp, style: context.text.bodySmall),
                  context.space.gapLg,
                  CheckRow(
                    label: l10n.soundsLabel,
                    subtitle: l10n.soundsSub,
                    value: settings.soundsEnabled,
                    onChanged: (v) => cubit.setSounds(enabled: v),
                  ),
                ],
              ),
            ),
          if (onReminders != null || onSubscription != null) ...[
            context.space.gapLg,
            ListCard(
              children: [
                if (onSubscription != null)
                  RecordTile(
                    leading: IconBubble(
                      icon: Symbols.savings_rounded,
                      tone: FarmTapTone.gold,
                      size: context.sizes.bubbleMd,
                    ),
                    title: l10n.subscriptionLabel,
                    onTap: onSubscription,
                  ),
                if (onReminders != null)
                  RecordTile(
                    leading: IconBubble(icon: Symbols.notifications_rounded, size: context.sizes.bubbleMd),
                    title: l10n.remindersTitle,
                    subtitle: l10n.remindersSub,
                    onTap: onReminders,
                  ),
              ],
            ),
          ],
          context.space.gapLg,
          SectionLabel(l10n.legalTitle),
          context.space.gapSm,
          ListCard(
            children: [
              RecordTile(
                leading: IconBubble(icon: Symbols.shield_rounded, tone: FarmTapTone.info, size: context.sizes.bubbleMd),
                title: l10n.privacyPolicy,
                onTap: () => unawaited(openSite(privacyUrl)),
              ),
              RecordTile(
                leading: IconBubble(icon: Symbols.gavel_rounded, tone: FarmTapTone.info, size: context.sizes.bubbleMd),
                title: l10n.termsOfUse,
                onTap: () => unawaited(openSite(termsUrl)),
              ),
              if (onDeleteAccount != null)
                RecordTile(
                  leading: IconBubble(
                    icon: Symbols.delete_forever_rounded,
                    tone: FarmTapTone.danger,
                    size: context.sizes.bubbleMd,
                  ),
                  title: l10n.deleteTitle,
                  subtitle: l10n.deleteSub,
                  onTap: onDeleteAccount,
                ),
            ],
          ),
          context.space.gapLg,
          FarmTapButton(
            label: l10n.signOutLabel,
            icon: Symbols.logout_rounded,
            kind: ButtonKind.danger,
            onPressed: onSignOut,
          ),
        ],
      ),
    );
  }
}
