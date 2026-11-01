import 'package:farm_tap/app/router/routes.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignInPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: context.space.sheet,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Image.asset(
                  FarmTapAssets.byBrightness(
                    context,
                    FarmTapAssets.signInLogoLight,
                    FarmTapAssets.signInLogoDark,
                  ),
                  width: 200,
                ),
              ),
              const Spacer(),
              TextField(
                decoration: InputDecoration(
                  labelText: l10n.phone,
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              context.space.gapLg,
              TextField(
                decoration: InputDecoration(
                  labelText: l10n.pin,
                  prefixIcon: const Icon(Icons.lock),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
              ),
              context.space.gapXxl,
              FilledButton(
                onPressed: () => context.go(AppRoutes.home),
                child: Text(l10n.signIn),
              ),
              context.space.gapLg,
              OutlinedButton.icon(
                onPressed: () => context.go(AppRoutes.home),
                icon: const Icon(Icons.nfc),
                label: Text(l10n.tapCard),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
