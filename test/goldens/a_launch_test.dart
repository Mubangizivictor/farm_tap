// Section A — launch and account (A01-A07), 8 goldens per screen.
// flutter test --update-goldens test/goldens/a_launch_test.dart
// python3 tool/compare_mockups.py A01 A02 A03 A04 A05 A06 A07
import 'package:farm_tap/core/auth/data/fake/fake_auth_repository.dart';
import 'package:farm_tap/core/auth/presentation/pages/check_email_page.dart';
import 'package:farm_tap/core/auth/presentation/pages/email_sign_in_page.dart';
import 'package:farm_tap/core/auth/presentation/pages/email_sign_up_page.dart';
import 'package:farm_tap/core/auth/presentation/pages/farm_picker_page.dart';
import 'package:farm_tap/core/auth/presentation/pages/forgot_password_page.dart';
import 'package:farm_tap/core/auth/presentation/pages/sign_in_page.dart';
import 'package:farm_tap/core/auth/presentation/pages/splash_page.dart';
import 'package:farm_tap/core/tenancy/data/fake/fake_farm_membership_repository.dart';
import 'package:farm_tap/core/tenancy/tenant_provider.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/screen_golden.dart';

const _email = 'muhwezi.robert@gmail.com';

void main() {
  final auth = FakeAuthRepository();

  screenGoldens('A01_splash', (_) => const SplashPage());

  screenGoldens('A02_sign_in', (_) => SignInPage(auth: auth, onSignedIn: () {}, onEmail: () {}, showApple: true));

  screenGoldens(
    'A03_email_sign_in',
    (_) => EmailSignInPage(auth: auth, onSignedIn: () {}, onForgotPassword: () {}, onCreateAccount: () {}),
    act: (tester, _) async {
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), _email);
      await tester.enterText(fields.at(1), 'secret-pass');
      await tester.pump();
    },
  );

  screenGoldens(
    'A04_email_sign_up',
    (_) => EmailSignUpPage(auth: auth, onCreated: (_) {}),
    act: (tester, _) async {
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Muhwezi Robert');
      await tester.enterText(fields.at(1), 'muhwezi.robert@gmail');
      await tester.enterText(fields.at(2), 'secret12');
      // Leaving the fields runs the inline validation.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
    },
  );

  screenGoldens(
    'A05_forgot_password',
    (_) => ForgotPasswordPage(auth: auth, initialEmail: _email),
    act: (tester, _) async {
      await tester.tap(find.byType(FarmTapButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    },
  );

  screenGoldens('A06_check_email', (_) => CheckEmailPage(auth: auth, email: _email, onContinue: () {}));

  screenGoldens(
    'A07_farm_picker',
    (_) => FarmPickerPage(
      places: FakeFarmMembershipRepository(InMemoryTenantProvider()),
      onOpened: (_) {},
      onAddFarm: () {},
    ),
  );
}
