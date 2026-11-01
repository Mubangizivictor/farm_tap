import 'package:farm_tap/core/auth/data/fake/fake_auth_repository.dart';
import 'package:farm_tap/core/auth/presentation/pages/email_sign_up_page.dart';
import 'package:farm_tap/core/auth/presentation/pages/sign_in_page.dart';
import 'package:farm_tap/core/tenancy/tenant_provider.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/sectors/cattle/health/data/fake/fake_treatment_repository.dart';
import 'package:farm_tap/sectors/cattle/herd/data/fake/fake_herd_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  test('fake herd is seeded with the 8 sample cows', () async {
    final repo = FakeHerdRepository(
      clock: SystemClock(),
      tenantProvider: InMemoryTenantProvider(),
      treatments: FakeTreatmentRepository(SystemClock()),
    );
    final first = await repo.watchAnimals().first;
    expect(first.data!.map((a) => a.tagNumber), contains('FT-014'));
    expect(first.data, hasLength(8));
  });

  testWidgets('A02 offers Google, Apple and email only — no phone sign-in', (tester) async {
    var signedIn = false;
    await pumpFarmTap(
      tester,
      SignInPage(auth: FakeAuthRepository(), onSignedIn: () => signedIn = true, onEmail: () {}, showApple: true),
    );
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Continue with email'), findsOneWidget);
    expect(find.textContaining('Phone'), findsNothing);
    await tester.tap(find.text('Continue with Google'));
    await tester.pump();
    expect(signedIn, isTrue);
  });

  testWidgets('A04 validates inline and needs the terms box', (tester) async {
    String? created;
    await pumpFarmTap(tester, EmailSignUpPage(auth: FakeAuthRepository(), onCreated: (e) => created = e));
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), 'muhwezi.robert@gmail');
    await tester.enterText(fields.at(2), 'short');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.tap(find.byType(FarmTapButton));
    await tester.pump();
    expect(find.text('Check the email — it looks incomplete.'), findsOneWidget);
    expect(find.text('Use at least 8 characters.'), findsOneWidget);
    expect(find.text('Tick the box to agree first.'), findsOneWidget);
    expect(created, isNull);

    await tester.enterText(fields.at(0), 'Muhwezi Robert');
    await tester.enterText(fields.at(1), 'muhwezi.robert@gmail.com');
    await tester.enterText(fields.at(2), 'secret123');
    await tester.tap(find.byType(Checkbox));
    await tester.tap(find.byType(FarmTapButton));
    await tester.pump();
    expect(created, 'muhwezi.robert@gmail.com');
  });
}
