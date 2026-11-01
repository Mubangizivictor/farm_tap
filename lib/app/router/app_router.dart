import 'package:farm_tap/app/router/routes.dart';
import 'package:farm_tap/core/ui/gallery/ui_gallery_page.dart';
import 'package:farm_tap/presentation/auth/pages/sign_in_page.dart';
import 'package:farm_tap/presentation/home/pages/home_page.dart';
import 'package:farm_tap/presentation/splash/pages/splash_page.dart';
import 'package:farm_tap/sectors/cattle/herd/presentation/pages/add_animal_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  // flutter run --dart-define=START_ROUTE=/dev/gallery opens a screen directly.
  initialLocation: const String.fromEnvironment('START_ROUTE', defaultValue: AppRoutes.splash),
  navigatorKey: _rootNavigatorKey,
  routes: [
    GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashPage()),
    GoRoute(path: AppRoutes.signIn, builder: (context, state) => const SignInPage()),
    GoRoute(path: AppRoutes.home, builder: (context, state) => const HomePage()),
    GoRoute(path: AppRoutes.uiGallery, builder: (context, state) => const UiGalleryPage()),
    GoRoute(path: AppRoutes.addAnimal, builder: (context, state) => const AddAnimalPage()),
  ],
);
