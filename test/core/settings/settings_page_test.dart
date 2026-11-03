import 'package:farm_tap/core/settings/app_settings_cubit.dart';
import 'package:farm_tap/core/settings/presentation/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('choosing Dark and turning sounds off is kept', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final cubit = AppSettingsCubit();
    addTearDown(cubit.close);
    var signedOut = false;
    await pumpFarmTap(
      tester,
      BlocProvider.value(
        value: cubit,
        child: SettingsPage(
          name: 'Victor',
          email: 'v@farm.ug',
          role: 'Owner',
          farmName: 'Rwemera Dairy',
          onSignOut: () => signedOut = true,
        ),
      ),
    );
    expect(find.text('Rwemera Dairy'), findsOneWidget);

    await tester.tap(find.text('Dark'));
    await tester.tap(find.text('Sounds'));
    await tester.pump();
    expect(cubit.state.themeMode, ThemeMode.dark);
    expect(cubit.state.soundsEnabled, isFalse);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));

    final again = AppSettingsCubit();
    addTearDown(again.close);
    await tester.runAsync(again.load);
    expect(again.state, const AppSettings(soundsEnabled: false, themeMode: ThemeMode.dark));

    await tester.tap(find.text('Sign out'));
    expect(signedOut, isTrue);
  });
}
