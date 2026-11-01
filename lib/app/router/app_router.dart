// The app's routes (docs/design/ROUTES.md). Detail and form screens are
// nested under their parent and opened with push; go only for top-level
// jumps. Every page is wrapped in RouteInfo(parent) so its back arrow works
// even after a deep link or a web refresh.
import 'dart:async';

import 'package:farm_tap/app/router/routes.dart';
import 'package:farm_tap/app/session/session_controller.dart';
import 'package:farm_tap/app/shell/app_shell.dart';
import 'package:farm_tap/app/shell/pending_section.dart';
import 'package:farm_tap/core/auth/presentation/pages/check_email_page.dart';
import 'package:farm_tap/core/auth/presentation/pages/email_sign_in_page.dart';
import 'package:farm_tap/core/auth/presentation/pages/email_sign_up_page.dart';
import 'package:farm_tap/core/auth/presentation/pages/farm_picker_page.dart';
import 'package:farm_tap/core/auth/presentation/pages/forgot_password_page.dart';
import 'package:farm_tap/core/auth/presentation/pages/sign_in_page.dart';
import 'package:farm_tap/core/auth/presentation/pages/splash_page.dart';
import 'package:farm_tap/core/onboarding/domain/farm_setup.dart';
import 'package:farm_tap/core/onboarding/domain/onboarding_repository.dart';
import 'package:farm_tap/core/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:farm_tap/core/onboarding/presentation/pages/choice_steps.dart';
import 'package:farm_tap/core/onboarding/presentation/pages/form_steps.dart';
import 'package:farm_tap/core/onboarding/presentation/pages/waitlist_and_done.dart';
import 'package:farm_tap/core/settings/app_settings_cubit.dart';
import 'package:farm_tap/core/tenancy/domain/farm_membership_repository.dart';
import 'package:farm_tap/core/ui/gallery/ui_gallery_page.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

typedef PageBuilder = Widget Function(BuildContext context, GoRouterState state);

/// A route whose page knows its parent (null = root screen).
GoRoute page(
  String path, {
  required String? parent,
  required PageBuilder builder,
  List<RouteBase> routes = const [],
  GlobalKey<NavigatorState>? parentNavigatorKey,
}) => GoRoute(
  path: path,
  parentNavigatorKey: parentNavigatorKey,
  // Build inside the page route, so the context handed to the page's
  // callbacks has a Navigator (sheets, dialogs) as well as the router.
  pageBuilder: (context, state) => _material(
    state,
    RouteInfo(
      parent: parent,
      child: Builder(builder: (pageContext) => builder(pageContext, state)),
    ),
  ),
  routes: routes,
);

/// Always a MaterialPage: its route uses the theme's page transitions, so
/// iOS gets the Cupertino slide with the edge swipe-back gesture. (Left to
/// itself go_router can fall back to a custom transition page without it.)
Page<void> _material(GoRouterState state, Widget child) =>
    MaterialPage<void>(key: state.pageKey, name: state.name, restorationId: state.pageKey.value, child: child);

GoRouter buildRouter({
  required SessionController session,
  required FarmMembershipRepository places,
  required OnboardingRepository onboarding,
  String? initialLocation,
}) {
  final rootKey = GlobalKey<NavigatorState>();
  final auth = session.auth;
  final setup = OnboardingCubit();

  // Roots of the shell branches; filled in section by section.
  final sectionRoots = <String, PageBuilder>{};
  final sectionChildren = <String, List<RouteBase>>{};

  GoRoute section(String path) => GoRoute(
    path: path,
    pageBuilder: (context, state) => _material(
      state,
      Builder(
        builder: (context) => RouteInfo(
          parent: sectionParent(context, path),
          child: (sectionRoots[path] ?? (c, _) => PendingSection(title: path.substring(1)))(context, state),
        ),
      ),
    ),
    routes: sectionChildren[path] ?? const [],
  );

  return GoRouter(
    navigatorKey: rootKey,
    // flutter run --dart-define=START_ROUTE=/dev/gallery opens a screen directly.
    initialLocation: initialLocation ?? const String.fromEnvironment('START_ROUTE', defaultValue: AppRoutes.splash),
    refreshListenable: session,
    redirect: (context, state) => _guard(session, state.matchedLocation),
    routes: [
      // ---- A: launch and account ----
      page(
        AppRoutes.splash,
        parent: null,
        builder: (context, state) => SplashPage(onDone: () => context.go(AppRoutes.signIn)),
      ),
      page(
        AppRoutes.signIn,
        parent: null,
        builder: (context, state) => SignInPage(
          auth: auth,
          onSignedIn: () => context.go(AppRoutes.farmPicker),
          onEmail: () => context.push(AppRoutes.emailSignIn),
        ),
        routes: [
          page(
            'email',
            parent: AppRoutes.signIn,
            builder: (context, state) => EmailSignInPage(
              auth: auth,
              onSignedIn: () => context.go(AppRoutes.farmPicker),
              onForgotPassword: () => context.push(AppRoutes.forgotPassword),
              onCreateAccount: () => context.push(AppRoutes.signUp),
            ),
            routes: [
              page(
                'sign-up',
                parent: AppRoutes.emailSignIn,
                builder: (context, state) => EmailSignUpPage(
                  auth: auth,
                  onCreated: (email) =>
                      context.go(Uri(path: AppRoutes.checkEmail, queryParameters: {'email': email}).toString()),
                ),
              ),
              page(
                'forgot',
                parent: AppRoutes.emailSignIn,
                builder: (context, state) => ForgotPasswordPage(auth: auth),
              ),
            ],
          ),
        ],
      ),
      page(
        AppRoutes.checkEmail,
        parent: null,
        builder: (context, state) => CheckEmailPage(
          auth: auth,
          email: state.uri.queryParameters['email'] ?? auth.currentUser?.email ?? '',
          onContinue: () => context.go(AppRoutes.setupLanguage),
        ),
      ),
      page(
        AppRoutes.farmPicker,
        parent: null,
        builder: (context, state) => FarmPickerPage(
          places: places,
          onOpened: (farm) {
            session.openFarm(farm);
            context.go(AppRoutes.home);
          },
          onAddFarm: () {
            setup.reset();
            unawaited(context.push(AppRoutes.setupLanguage));
          },
        ),
      ),

      // ---- B: onboarding (each step pushes the next; back = previous step) ----
      page(
        AppRoutes.setupLanguage,
        parent: null,
        builder: (context, state) => OnboardLanguagePage(
          cubit: setup,
          onLanguage: (code) => context.read<AppSettingsCubit>().setLanguage(code),
          onContinue: () => context.push(AppRoutes.setupSector),
        ),
      ),
      page(
        AppRoutes.setupSector,
        parent: AppRoutes.setupLanguage,
        builder: (context, state) => OnboardSectorPage(
          cubit: setup,
          onContinue: () => context.push(AppRoutes.setupDairyType),
          onComingSoon: (sector) async {
            final name = await showWaitlistSheet(context, sector: sector, repo: onboarding);
            if (name == null || !context.mounted) return;
            unawaited(
              context.push(
                Uri(
                  path: AppRoutes.setupWaitlistDone,
                  queryParameters: {'sector': sector.name, 'name': name},
                ).toString(),
              ),
            );
          },
        ),
      ),
      page(
        AppRoutes.setupWaitlistDone,
        parent: AppRoutes.setupSector,
        builder: (context, state) => WaitlistDonePage(
          sector: Sector.values.asNameMap()[state.uri.queryParameters['sector']] ?? Sector.poultry,
          name: state.uri.queryParameters['name'] ?? '',
          onDone: () => popOrGo(context, AppRoutes.setupSector),
        ),
      ),
      page(
        AppRoutes.setupDairyType,
        parent: AppRoutes.setupSector,
        builder: (context, state) =>
            OnboardDairyTypePage(cubit: setup, onContinue: () => context.push(AppRoutes.setupFarm)),
      ),
      page(
        AppRoutes.setupFarm,
        parent: AppRoutes.setupDairyType,
        builder: (context, state) => OnboardFarmDetailsPage(
          cubit: setup,
          districts: onboarding.districts,
          onContinue: () => context.push(AppRoutes.setupContacts),
        ),
      ),
      page(
        AppRoutes.setupContacts,
        parent: AppRoutes.setupFarm,
        builder: (context, state) =>
            OnboardContactsPage(cubit: setup, onContinue: () => context.push(AppRoutes.setupRole)),
      ),
      page(
        AppRoutes.setupRole,
        parent: AppRoutes.setupContacts,
        builder: (context, state) =>
            OnboardRolePage(cubit: setup, onContinue: () => context.push(AppRoutes.setupStaff)),
      ),
      page(
        AppRoutes.setupStaff,
        parent: AppRoutes.setupRole,
        builder: (context, state) => OnboardFirstStaffPage(cubit: setup, onDone: () => context.go(AppRoutes.setupDone)),
      ),
      page(
        AppRoutes.setupDone,
        parent: null,
        builder: (context, state) => FarmReadyPage(
          setup: setup.state,
          repo: onboarding,
          onStart: (farm) {
            session.openFarm(farm);
            setup.reset();
            context.go(AppRoutes.home);
          },
        ),
      ),

      // ---- Main shell: one branch per section ----
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell, session: session),
        branches: [
          for (final path in shellBranches) StatefulShellBranch(routes: [section(path)]),
        ],
      ),

      // ---- Dev ----
      GoRoute(path: AppRoutes.uiGallery, pageBuilder: (context, state) => _material(state, const UiGalleryPage())),
    ],
  );
}

/// Redirect guards (ROUTES.md "Guards").
String? _guard(SessionController session, String location) {
  if (location == AppRoutes.splash || location.startsWith('/dev')) return null;
  if (!session.signedIn) return location.startsWith(AppRoutes.signIn) ? null : AppRoutes.signIn;
  if (location.startsWith(AppRoutes.signIn)) return session.hasFarm ? AppRoutes.home : AppRoutes.farmPicker;
  final settingUp =
      location.startsWith(AppRoutes.farmPicker) ||
      location.startsWith(AppRoutes.setup) ||
      location.startsWith(AppRoutes.checkEmail);
  if (!session.hasFarm) return settingUp ? null : AppRoutes.farmPicker;
  if (session.locked && !location.startsWith(AppRoutes.unlock)) return AppRoutes.unlock;
  return null;
}
