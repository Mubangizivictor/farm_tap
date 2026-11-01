import 'package:farm_tap/app/di/injection.dart';
import 'package:farm_tap/app/router/routes.dart';
import 'package:farm_tap/core/auth/domain/auth_repository.dart';
import 'package:farm_tap/core/auth/presentation/pages/check_email_page.dart';
import 'package:farm_tap/core/auth/presentation/pages/email_sign_in_page.dart';
import 'package:farm_tap/core/auth/presentation/pages/email_sign_up_page.dart';
import 'package:farm_tap/core/auth/presentation/pages/farm_picker_page.dart';
import 'package:farm_tap/core/auth/presentation/pages/forgot_password_page.dart';
import 'package:farm_tap/core/auth/presentation/pages/sign_in_page.dart';
import 'package:farm_tap/core/auth/presentation/pages/splash_page.dart';
import 'package:farm_tap/core/tenancy/domain/farm_membership_repository.dart';
import 'package:farm_tap/core/ui/gallery/ui_gallery_page.dart';
import 'package:farm_tap/presentation/home/pages/home_page.dart';
import 'package:farm_tap/sectors/cattle/herd/presentation/pages/add_animal_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

AuthRepository get _auth => getIt<AuthRepository>();

final appRouter = GoRouter(
  // flutter run --dart-define=START_ROUTE=/dev/gallery opens a screen directly.
  initialLocation: const String.fromEnvironment('START_ROUTE', defaultValue: AppRoutes.splash),
  navigatorKey: _rootNavigatorKey,
  routes: [
    // A01: signed in -> farm picker (C01 staff unlock replaces this in section C).
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) =>
          SplashPage(onDone: () => context.go(_auth.currentUser == null ? AppRoutes.signIn : AppRoutes.farmPicker)),
    ),
    GoRoute(
      path: AppRoutes.signIn,
      builder: (context, state) => SignInPage(
        auth: _auth,
        onSignedIn: () => context.go(AppRoutes.farmPicker),
        onEmail: () => context.push(AppRoutes.emailSignIn),
      ),
    ),
    GoRoute(
      path: AppRoutes.emailSignIn,
      builder: (context, state) => EmailSignInPage(
        auth: _auth,
        onSignedIn: () => context.go(AppRoutes.farmPicker),
        onForgotPassword: () => context.push(AppRoutes.forgotPassword),
        onCreateAccount: () => context.push(AppRoutes.signUp),
      ),
    ),
    GoRoute(
      path: AppRoutes.signUp,
      builder: (context, state) => EmailSignUpPage(
        auth: _auth,
        onCreated: (email) => context.go(AppRoutes.checkEmail, extra: email),
      ),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (context, state) => ForgotPasswordPage(auth: _auth),
    ),
    GoRoute(
      path: AppRoutes.checkEmail,
      builder: (context, state) => CheckEmailPage(
        auth: _auth,
        email: state.extra as String? ?? _auth.currentUser?.email ?? '',
        // B01 onboarding replaces this target in section B.
        onContinue: () => context.go(AppRoutes.farmPicker),
      ),
    ),
    GoRoute(
      path: AppRoutes.farmPicker,
      builder: (context, state) =>
          FarmPickerPage(places: getIt<FarmMembershipRepository>(), onOpened: (_) => context.go(AppRoutes.home)),
    ),
    GoRoute(path: AppRoutes.home, builder: (context, state) => const HomePage()),
    GoRoute(path: AppRoutes.uiGallery, builder: (context, state) => const UiGalleryPage()),
    GoRoute(path: AppRoutes.addAnimal, builder: (context, state) => const AddAnimalPage()),
  ],
);
