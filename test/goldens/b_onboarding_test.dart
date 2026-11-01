// Section B — onboarding (B01-B10), 8 goldens per screen + small screens.
// flutter test --update-goldens test/goldens/b_onboarding_test.dart
import 'package:farm_tap/core/onboarding/data/fake/fake_onboarding_repository.dart';
import 'package:farm_tap/core/onboarding/domain/farm_setup.dart';
import 'package:farm_tap/core/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:farm_tap/core/onboarding/presentation/pages/choice_steps.dart';
import 'package:farm_tap/core/onboarding/presentation/pages/form_steps.dart';
import 'package:farm_tap/core/onboarding/presentation/pages/waitlist_and_done.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/screen_golden.dart';

/// The mockups' "today": Saturday 7 Nov 2026.
class FixedClock extends Clock {
  @override
  DateTime now() => DateTime(2026, 11, 7, 6, 52);
}

const _sample = FarmSetup(
  farmName: 'Rwemera Dairy Farm',
  district: 'Mbarara',
  village: 'Rwemera, Bubaare',
  herdSize: HerdSize.upTo100,
  whatsapp: '772 451 908',
);

OnboardingCubit _cubit([FarmSetup setup = _sample]) => OnboardingCubit()..update((_) => setup);

void main() {
  final repo = FakeOnboardingRepository(FixedClock());

  screenGoldens('B01_onboard_language', (_) => OnboardLanguagePage(cubit: _cubit(), onContinue: () {}));

  screenGoldens(
    'B02_onboard_sector',
    (_) => OnboardSectorPage(cubit: _cubit(), onContinue: () {}, onComingSoon: (_) {}),
  );

  screenGoldens(
    'B03_onboard_waitlist_sheet',
    (_) => Builder(
      builder: (context) => OnboardSectorPage(
        cubit: _cubit(),
        onContinue: () {},
        onComingSoon: (s) => showWaitlistSheet(context, sector: s, repo: repo),
      ),
    ),
    act: (tester, _) async {
      await tester.tap(find.text('Poultry'));
      await tester.pump(const Duration(milliseconds: 500));
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Kyomugisha Annet');
      await tester.enterText(fields.at(1), '772451908');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
    },
  );

  screenGoldens(
    'B04_onboard_waitlist_done',
    (_) => WaitlistDonePage(sector: Sector.poultry, name: 'Kyomugisha Annet', onDone: () {}),
  );

  screenGoldens('B05_onboard_dairy_type', (_) => OnboardDairyTypePage(cubit: _cubit(), onContinue: () {}));

  screenGoldens(
    'B06_onboard_farm_details',
    (_) => OnboardFarmDetailsPage(cubit: _cubit(), districts: repo.districts, onContinue: () {}),
    act: (tester, _) async {
      await tester.tap(find.text('Rwemera, Bubaare'));
      await tester.pump();
    },
  );

  screenGoldens('B07_onboard_contacts', (_) => OnboardContactsPage(cubit: _cubit(), onContinue: () {}));

  screenGoldens('B08_onboard_role', (_) => OnboardRolePage(cubit: _cubit(), onContinue: () {}));

  screenGoldens(
    'B09_onboard_first_staff',
    (_) => OnboardFirstStaffPage(cubit: _cubit(), onDone: () {}),
    act: (tester, _) async {
      await tester.enterText(find.byType(TextField).first, 'Twinomujuni Amos');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.tap(find.byType(PinDots), warnIfMissed: false);
      // Let the sheet finish sliding up before tapping its keys.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      for (final d in ['1', '2', '3', '4']) {
        await tester.tap(find.text(d).last);
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 500));
    },
  );

  screenGoldens('B10_onboard_trial_started', (_) => FarmReadyPage(setup: _sample, repo: repo, onStart: (_) {}));
}
