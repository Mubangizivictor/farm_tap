import 'dart:async';

import 'package:farm_tap/app/router/routes.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashPage extends StatefulWidget {
  const new({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    unawaited(_navigateToNext());
  }

  Future<void> _navigateToNext() async {
    await Future<void>.delayed(const FarmTapMotion().splash);
    if (mounted) {
      context.go(AppRoutes.signIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          FarmTapAssets.byBrightness(
            context,
            FarmTapAssets.splashAnimationLightWebp,
            FarmTapAssets.splashAnimationDarkWebp,
          ),
          width: 200,
        ),
      ),
    );
  }
}
