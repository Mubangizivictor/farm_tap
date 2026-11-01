// The app's routes (docs/design/ROUTES.md). Detail and form screens are
// nested under their parent and opened with push; go only for top-level
// jumps. Every page is wrapped in RouteInfo(parent) so its back arrow works
// even after a deep link or a web refresh.
import 'dart:async';

import 'package:farm_tap/app/router/app_dependencies.dart';
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
import 'package:farm_tap/core/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:farm_tap/core/onboarding/presentation/pages/choice_steps.dart';
import 'package:farm_tap/core/onboarding/presentation/pages/form_steps.dart';
import 'package:farm_tap/core/onboarding/presentation/pages/waitlist_and_done.dart';
import 'package:farm_tap/core/people/presentation/pages/unlock_pages.dart';
import 'package:farm_tap/core/settings/app_settings_cubit.dart';
import 'package:farm_tap/core/ui/gallery/ui_gallery_page.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/sectors/cattle/collection_centre/presentation/pages/centre_collect_pages.dart';
import 'package:farm_tap/sectors/cattle/collection_centre/presentation/pages/centre_farmers_pay_pages.dart';
import 'package:farm_tap/sectors/cattle/health/presentation/pages/health_pages.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/herd_models.dart';
import 'package:farm_tap/sectors/cattle/herd/presentation/pages/animal_detail_page.dart';
import 'package:farm_tap/sectors/cattle/herd/presentation/pages/herd_list_page.dart';
import 'package:farm_tap/sectors/cattle/herd/presentation/pages/herd_tools_pages.dart';
import 'package:farm_tap/sectors/cattle/home/presentation/pages/alerts_page.dart';
import 'package:farm_tap/sectors/cattle/home/presentation/pages/home_page.dart';
import 'package:farm_tap/sectors/cattle/milk/presentation/pages/milk_pages.dart';
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

GoRouter buildRouter(AppDependencies deps, {String? initialLocation}) {
  final session = deps.session;
  final places = deps.places;
  final onboarding = deps.onboarding;
  final staffAccess = deps.staffAccess;
  final rootKey = GlobalKey<NavigatorState>();
  final auth = session.auth;
  final setup = OnboardingCubit();

  // Roots of the shell branches; filled in section by section.
  final sectionRoots = <String, PageBuilder>{
    AppRoutes.home: (context, state) => session.isCentre
        ? CentreHomePage(
            repo: deps.centre,
            centreName: session.farm?.name ?? '',
            onRefresh: deps.sync.sync,
            onTapCard: () => context.go(AppRoutes.collect),
            onSeeAll: () => context.go(AppRoutes.farmers),
            onTool: (tool) => switch (tool) {
              CentreTool.dispatch => unawaited(context.push(AppRoutes.centreReconcile)),
              _ => context.go(AppRoutes.collect),
            },
          )
        : HomePage(
            repo: deps.home,
            farmName: session.farm?.name ?? '',
            ownerName: session.auth.currentUser?.name ?? '',
            staff: session.staff,
            trialDaysLeft: session.trialDaysLeft,
            onRefresh: deps.sync.sync,
            onLock: () {
              session.lock();
              context.go(AppRoutes.unlock);
            },
            onOpen: (target) => _openFromHome(context, target),
          ),
  };
  sectionRoots[AppRoutes.herd] = (context, state) => HerdListPage(
    repo: deps.herd,
    onAnimal: (a) => context.push(AppRoutes.herdAnimal(a.id)),
    onAdd: () => context.push(AppRoutes.herdAdd),
    onScan: () => context.push(AppRoutes.herdScan),
  );
  sectionRoots[AppRoutes.milk] = (context, state) => MilkTodayPage(
    repo: deps.milk,
    onRecord: () => context.push(AppRoutes.milkRecord),
    onTool: (i) => context.push([AppRoutes.milkTotal, AppRoutes.milkUse, AppRoutes.milkSales, AppRoutes.milkTrends][i]),
  );
  sectionRoots[AppRoutes.collect] = (context, state) => ReceiveMilkPage(
    repo: deps.centre,
    savedDeliveryId: state.uri.queryParameters['saved'],
    onFarmer: (farmer) => context.push(AppRoutes.collectFarmer(farmer.id)),
  );
  sectionRoots[AppRoutes.farmers] = (context, state) => CentreFarmersPage(
    repo: deps.centre,
    onFarmer: (farmer) => context.push(AppRoutes.centreFarmer(farmer.id)),
    onAdd: () => unawaited(showAddFarmerSheet(context, deps.centre)),
  );
  sectionRoots[AppRoutes.pay] = (context, state) => CentrePaymentsPage(
    repo: deps.centre,
    onSendSms: () => context.push(AppRoutes.paySms),
    onPaymentSheet: () => context.push(AppRoutes.payFarmers),
    onFarmer: (farmer) => context.go(AppRoutes.centreFarmer(farmer.id)),
  );
  sectionRoots[AppRoutes.health] = (context, state) => HealthHomePage(
    repo: deps.treatments,
    onOpen: (target) => context.push(switch (target) {
      HealthTarget.treatment => AppRoutes.healthTreatment,
      HealthTarget.calendar => AppRoutes.healthSchedule,
      HealthTarget.drugs => AppRoutes.healthDrugs,
      HealthTarget.withdrawal => AppRoutes.healthWithdrawal,
    }),
  );
  String recorder() => session.staff?.greetingName ?? (session.auth.currentUser?.name.split(' ').first ?? '');
  final sectionChildren = <String, List<RouteBase>>{
    AppRoutes.milk: [
      page(
        'record',
        parent: AppRoutes.milk,
        builder: (context, state) => PickCowPage(
          repo: deps.milk,
          onCow: (cow, {required notForSale}) => context.push(AppRoutes.milkCow(cow.id, notForSale: notForSale)),
          onScan: () => context.go(AppRoutes.herdScan),
        ),
        routes: [
          page(
            ':cowId',
            parent: AppRoutes.milkRecord,
            builder: (context, state) => MilkKeypadPage(
              repo: deps.milk,
              cowId: state.pathParameters['cowId']!,
              notForSale: state.uri.queryParameters['nfs'] == '1',
              recorderName: recorder(),
              // After a save the stack resets to F02, with the next cow on top.
              onDone: (next, nextCow) => context.go(
                next == MilkSaveNext.nextCow && nextCow != null ? AppRoutes.milkCow(nextCow.id) : AppRoutes.milk,
              ),
            ),
          ),
        ],
      ),
      page(
        'herd-total',
        parent: AppRoutes.milk,
        builder: (context, state) => QuickTotalPage(repo: deps.milk, onSaved: () => popOrGo(context, AppRoutes.milk)),
      ),
      page(
        'use',
        parent: AppRoutes.milk,
        builder: (context, state) => MilkUsePage(repo: deps.milk, onSaved: () => popOrGo(context, AppRoutes.milk)),
      ),
      page(
        'sales',
        parent: AppRoutes.milk,
        builder: (context, state) => MilkSalesPage(repo: deps.milk),
      ),
      page(
        'trends',
        parent: AppRoutes.milk,
        builder: (context, state) => MilkTrendsPage(repo: deps.milk),
      ),
    ],
    AppRoutes.herd: [
      page(
        'add',
        parent: AppRoutes.herd,
        builder: (context, state) => AddAnimalPage(repo: deps.herd, onSaved: (_) => popOrGo(context, AppRoutes.herd)),
      ),
      page(
        'scan',
        parent: AppRoutes.herd,
        builder: (context, state) => ScanTagPage(
          onTypeTag: () async {
            final animal = await showTypeTagSheet(context, deps.herd);
            if (animal != null && context.mounted) {
              context.pushReplacement(AppRoutes.herdAnimal(animal.id));
            }
          },
        ),
      ),
      page(
        'count',
        parent: AppRoutes.herd,
        builder: (context, state) => HeadCountPage(repo: deps.herd),
      ),
      page(
        'labels',
        parent: AppRoutes.herd,
        builder: (context, state) => QrLabelsPage(repo: deps.herd),
      ),
      page(
        ':animalId',
        parent: AppRoutes.herd,
        builder: (context, state) => AnimalDetailPage(
          repo: deps.herd,
          animalId: state.pathParameters['animalId']!,
          onLabels: () => context.push(AppRoutes.herdLabels),
          onGone: () => popOrGo(context, AppRoutes.herd),
          onEvent: (kind) => context.go(switch (kind) {
            HerdEventKind.milk => AppRoutes.milk,
            HerdEventKind.treatment => '${AppRoutes.healthTreatment}?animal=${state.pathParameters['animalId']}',
            HerdEventKind.heat => AppRoutes.breeding,
            _ => AppRoutes.money,
          }),
        ),
      ),
    ],
    AppRoutes.collect: [
      page(
        ':farmerId',
        parent: AppRoutes.collect,
        builder: (context, state) => DeliveryKeypadPage(
          repo: deps.centre,
          farmerId: state.pathParameters['farmerId']!,
          // After a save the stack resets to G02, which shows the Undo toast.
          onSaved: (delivery) => context.go(AppRoutes.collectSaved(delivery.id)),
          onRejected: () => context.go(AppRoutes.collect),
        ),
      ),
    ],
    AppRoutes.farmers: [
      page(
        ':farmerId',
        parent: AppRoutes.farmers,
        builder: (context, state) => CentreFarmerPage(repo: deps.centre, farmerId: state.pathParameters['farmerId']!),
      ),
    ],
    AppRoutes.pay: [
      page(
        'sheet',
        parent: AppRoutes.pay,
        builder: (context, state) => PayFarmersPage(repo: deps.centre, onDone: () => popOrGo(context, AppRoutes.pay)),
      ),
      page(
        'sms',
        parent: AppRoutes.pay,
        builder: (context, state) =>
            SmsStatementsPage(repo: deps.centre, onSent: () => popOrGo(context, AppRoutes.pay)),
      ),
    ],
    AppRoutes.health: [
      page(
        'treatment',
        parent: AppRoutes.health,
        builder: (context, state) => AddTreatmentPage(
          repo: deps.treatments,
          animalId: state.uri.queryParameters['animal'],
          onScan: () => context.go(AppRoutes.herdScan),
          // "Add another" starts a fresh form; Done returns to Health.
          onDone: (another) =>
              another ? context.pushReplacement(AppRoutes.healthTreatment) : popOrGo(context, AppRoutes.health),
        ),
      ),
      page(
        'drugs',
        parent: AppRoutes.health,
        builder: (context, state) => DrugStockPage(repo: deps.treatments),
      ),
      page(
        'schedule',
        parent: AppRoutes.health,
        builder: (context, state) => HealthCalendarPage(repo: deps.treatments),
      ),
      page(
        'withdrawal',
        parent: AppRoutes.health,
        builder: (context, state) =>
            WithdrawalListPage(repo: deps.treatments, onAnimal: (id) => context.go(AppRoutes.herdAnimal(id))),
      ),
    ],
    AppRoutes.home: [
      page(
        'reconcile',
        parent: AppRoutes.home,
        builder: (context, state) => ReconcilePage(repo: deps.centre, onSaved: () => popOrGo(context, AppRoutes.home)),
      ),
      page(
        'alerts',
        parent: AppRoutes.home,
        builder: (context, state) => AlertsPage(repo: deps.home),
      ),
    ],
  };

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

      // ---- C: staff unlock on the farm phone ----
      page(
        AppRoutes.unlock,
        parent: null,
        builder: (context, state) => TapCardPage(
          farmName: session.farm?.name ?? '',
          access: staffAccess,
          onCard: (card) => context.push(Uri(path: AppRoutes.unlockPin, queryParameters: {'card': card}).toString()),
          onTypeNumber: () => context.push(AppRoutes.unlockNumber),
          onOwnerSignIn: () {
            session.unlock();
            context.go(AppRoutes.home);
          },
          onSwitchFarm: () => context.go(AppRoutes.farmPicker),
        ),
        routes: [
          page(
            'number',
            parent: AppRoutes.unlock,
            builder: (context, state) => CardNumberPage(
              access: staffAccess,
              onFound: (staff) =>
                  context.push(Uri(path: AppRoutes.unlockPin, queryParameters: {'card': staff.cardNumber}).toString()),
            ),
          ),
          page(
            'pin',
            parent: AppRoutes.unlock,
            builder: (context, state) => FutureBuilder(
              future: staffAccess.findByCard(state.uri.queryParameters['card'] ?? ''),
              builder: (context, snapshot) {
                final staff = snapshot.data?.data;
                if (staff == null) return const SizedBox.shrink();
                return StaffPinPage(
                  staff: staff,
                  access: staffAccess,
                  onUnlocked: (s) {
                    session.unlock(s);
                    context.go(AppRoutes.home);
                  },
                  onNotMe: () => popOrGo(context, AppRoutes.unlock),
                );
              },
            ),
          ),
        ],
      ),

      // ---- Main shell: one branch per section ----
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell, session: session, sync: deps.sync),
        branches: [
          for (final path in shellBranches) StatefulShellBranch(routes: [section(path)]),
        ],
      ),

      // ---- Dev ----
      GoRoute(path: AppRoutes.uiGallery, pageBuilder: (context, state) => _material(state, const UiGalleryPage())),
    ],
  );
}

/// Home tiles and cards: push within a tab, or switch to another section.
void _openFromHome(BuildContext context, HomeTarget target) {
  final path = switch (target) {
    HomeTarget.milk => AppRoutes.milk,
    HomeTarget.recordMilk => AppRoutes.milkRecord,
    HomeTarget.herd => AppRoutes.herdCount,
    HomeTarget.health => AppRoutes.health,
    HomeTarget.treatment => AppRoutes.healthTreatment,
    HomeTarget.workers => AppRoutes.workers,
    HomeTarget.tapCard => AppRoutes.collect,
    HomeTarget.feeding => AppRoutes.feeding,
    HomeTarget.breeding => AppRoutes.breeding,
    HomeTarget.report => AppRoutes.health,
    HomeTarget.pay => AppRoutes.settings,
    HomeTarget.alerts => AppRoutes.homeAlerts,
  };
  if (target == HomeTarget.alerts) {
    unawaited(context.push(path));
  } else {
    context.go(path);
  }
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
  final unlocking = location.startsWith(AppRoutes.unlock) || location.startsWith(AppRoutes.farmPicker);
  if (session.locked && !unlocking) return AppRoutes.unlock;
  return null;
}
