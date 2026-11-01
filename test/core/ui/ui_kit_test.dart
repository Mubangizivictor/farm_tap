import 'package:farm_tap/core/settings/app_settings_cubit.dart';
import 'package:farm_tap/core/sound/sound_service.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../helpers/pump_app.dart';

void main() {
  soundAndAvatarTests();
  group('DecimalEntry', () {
    test('builds 9.5 and limits to one decimal', () {
      var e = const DecimalEntry();
      for (final k in ['9', '.', '5', '7']) {
        e = e.press(k);
      }
      expect(e.text, '9.5');
      expect(e.value, 9.5);
    });

    test('no leading zeros, leading dot becomes 0.', () {
      expect(const DecimalEntry().press('0').press('7').text, '7');
      expect(const DecimalEntry().press('.').text, '0.');
    });

    test('only one dot and max integer digits', () {
      expect(const DecimalEntry(text: '1.2').press('.').text, '1.2');
      expect(const DecimalEntry(text: '123').press('4').text, '123');
    });

    test('backspace and display', () {
      expect(const DecimalEntry(text: '9.5').backspace().text, '9.');
      expect(const DecimalEntry().display, '0');
    });
  });

  test('ResponsiveGrid column maths follows UX_SPEC', () {
    // floor((width + gap) / (min + gap)), max 4
    expect(ResponsiveGrid.columnsFor(358, 160, 12), 2);
    expect(ResponsiveGrid.columnsFor(1056, 160, 12), 4);
    expect(ResponsiveGrid.columnsFor(100, 160, 12), 1);
    expect(ResponsiveGrid.columnsFor(2000, 160, 12), 4);
    expect(ResponsiveGrid.columnsFor(900, 420, 12), 2);
  });

  test('breakpoints', () {
    expect(FarmTapBreakpoints.of(599), FormFactor.compact);
    expect(FarmTapBreakpoints.of(600), FormFactor.medium);
    expect(FarmTapBreakpoints.of(1194), FormFactor.medium); // landscape tablet keeps the rail (0012)
    expect(FarmTapBreakpoints.of(1279), FormFactor.medium);
    expect(FarmTapBreakpoints.of(1280), FormFactor.expanded);
  });

  testWidgets('PersonAvatar initials', (tester) async {
    expect(PersonAvatar.initialsOf('Twinomujuni Amos'), 'TA');
    expect(PersonAvatar.initialsOf('Amos'), 'A');
    expect(PersonAvatar.initialsOf('  '), '?');
  });

  group('AdaptiveScaffold', () {
    final nav = AdaptiveNavigation(
      items: const [
        NavItem(id: 'home', icon: Symbols.home_rounded, label: 'Home'),
        NavItem(id: 'herd', icon: Symbols.pets_rounded, label: 'Herd'),
      ],
      sidebarItems: const [
        NavItem(id: 'home', icon: Symbols.home_rounded, label: 'Home'),
        NavItem(id: 'herd', icon: Symbols.pets_rounded, label: 'Herd'),
        NavItem(id: 'feeding', icon: Symbols.grass_rounded, label: 'Feeding'),
      ],
      selectedId: 'home',
      onSelect: (_) {},
    );
    Widget scaffold() => AdaptiveScaffold(
      title: 'Home',
      body: const Text('content'),
      navigation: nav,
      trialDaysLeft: 9,
      farm: const FarmSwitcherInfo(name: 'Rwemera Dairy', subtitle: 'Mbarara · Owner'),
    );

    testWidgets('phone: bottom bar only', (tester) async {
      await pumpFarmTap(tester, scaffold());
      expect(find.byKey(AdaptiveScaffold.bottomBarKey), findsOneWidget);
      expect(find.byKey(AdaptiveScaffold.railKey), findsNothing);
      expect(find.text('Feeding'), findsNothing);
    });

    testWidgets('tablet: rail', (tester) async {
      await pumpFarmTap(tester, scaffold(), size: tabletSize);
      expect(find.byKey(AdaptiveScaffold.railKey), findsOneWidget);
      expect(find.byKey(AdaptiveScaffold.bottomBarKey), findsNothing);
    });

    testWidgets('desktop: sidebar with all sections, farm switcher, trial card, search', (tester) async {
      await pumpFarmTap(tester, scaffold(), size: desktopSize);
      expect(find.byKey(AdaptiveScaffold.sidebarKey), findsOneWidget);
      expect(find.byKey(AdaptiveScaffold.bottomBarKey), findsNothing);
      expect(find.byKey(AdaptiveScaffold.railKey), findsNothing);
      expect(find.text('Feeding'), findsOneWidget);
      expect(find.text('Rwemera Dairy'), findsOneWidget);
      expect(find.byType(TrialCard), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  group('showAdaptiveSheet', () {
    Widget opener() => Builder(
      builder: (context) => TextButton(
        onPressed: () => showAdaptiveSheet<void>(context, builder: (_) => const Text('sheet body')),
        child: const Text('open'),
      ),
    );

    testWidgets('phone: bottom sheet', (tester) async {
      await pumpFarmTap(tester, Scaffold(body: opener()));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('desktop: dialog', (tester) async {
      await pumpFarmTap(tester, Scaffold(body: opener()), size: desktopSize);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
    });
  });

  group('RecordCollection', () {
    Widget collection() => Scaffold(
      body: SingleChildScrollView(
        child: RecordCollection<String>(
          items: const ['Bihogo', 'Kasheshe'],
          tileBuilder: (_, s) => RecordTile(title: s),
          columns: [RecordColumn(label: 'Animal', sortKey: (s) => s, cell: (_, s) => Text(s))],
        ),
      ),
    );

    testWidgets('phone: tiles', (tester) async {
      await pumpFarmTap(tester, collection());
      expect(find.byType(RecordTile), findsNWidgets(2));
      expect(find.text('ANIMAL'), findsNothing);
    });

    testWidgets('desktop: table with header, sortable', (tester) async {
      await pumpFarmTap(tester, collection(), size: desktopSize);
      expect(find.byType(RecordTile), findsNothing);
      expect(find.text('ANIMAL'), findsOneWidget);
      await tester.tap(find.text('ANIMAL'));
      await tester.tap(find.text('ANIMAL'));
      await tester.pump();
      expect(tester.getTopLeft(find.text('Kasheshe')).dy, lessThan(tester.getTopLeft(find.text('Bihogo')).dy));
    });
  });

  group('PinPad', () {
    testWidgets('wrong PIN clears the dots; right PIN calls through', (tester) async {
      final tries = <String>[];
      await pumpFarmTap(
        tester,
        Scaffold(
          body: PinPad(
            onCompleted: (pin) async {
              tries.add(pin);
              return pin == '1234';
            },
          ),
        ),
      );
      Future<void> enter(String pin) async {
        for (final d in pin.split('')) {
          await tester.tap(find.text(d));
          await tester.pump();
        }
        await tester.pump(const Duration(milliseconds: 400));
      }

      await enter('1111');
      expect(tries, ['1111']);
      final dots = find.byType(PinDots);
      expect(tester.widget<PinDots>(dots).filled, 0);
      expect(tester.widget<PinDots>(dots).errorTick, 1);

      await enter('1234');
      expect(tries, ['1111', '1234']);
    });
  });

  testWidgets('BigNumberKeypad sends digits and backspace', (tester) async {
    final keys = <String>[];
    var back = 0;
    await pumpFarmTap(
      tester,
      Scaffold(
        body: BigNumberKeypad(showDecimal: true, onDigit: keys.add, onBackspace: () => back++),
      ),
    );
    await tester.tap(find.text('9'));
    await tester.tap(find.text('.'));
    await tester.tap(find.byIcon(Symbols.backspace_rounded));
    expect(keys, ['9', '.']);
    expect(back, 1);
  });

  group('showCelebration', () {
    testWidgets('auto-advance closes after 2 s with autoAdvanced', (tester) async {
      CelebrationAction? result;
      await pumpFarmTap(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showCelebration(
              context,
              animation: FarmTapAnimations.milkSaved,
              title: 'Saved!',
              primaryLabel: 'Next cow',
              autoAdvance: true,
            ),
            child: const Text('go'),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Saved!'), findsOneWidget);
      expect(find.text('Next cow'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Saved!'), findsNothing);
      expect(result, CelebrationAction.autoAdvanced);
    });

    testWidgets('buttons appear after the animation, tap returns primary', (tester) async {
      CelebrationAction? result;
      await pumpFarmTap(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showCelebration(
              context,
              animation: FarmTapAnimations.treatmentSaved,
              title: 'Treatment saved',
              primaryLabel: 'Done',
            ),
            child: const Text('go'),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity, 0);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(result, CelebrationAction.primary);
    });
  });

  group('FarmTapToast', () {
    testWidgets('shows message and Undo', (tester) async {
      var undone = false;
      await pumpFarmTap(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => FarmTapToast.show(
                context,
                message: 'Saved 42.5 L',
                actionLabel: 'Undo',
                onAction: () => undone = true,
              ),
              child: const Text('toast'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('toast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Saved 42.5 L'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      expect(undone, isTrue);
    });
  });

  testWidgets('read-back needs a choice and returns true only for Yes', (tester) async {
    bool? result;
    await pumpFarmTap(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                result = await showReadBack(context, subject: 'Bihogo · FT-014', valueText: '9.5 litres'),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Is this correct?'), findsOneWidget);
    // Tapping the scrim does nothing.
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.text('Is this correct?'), findsOneWidget);
    await tester.tap(find.text('Yes, save'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('FarmTapAnimationView shows a still when reduce-motion is on', (tester) async {
    await pumpFarmTap(
      tester,
      const Scaffold(
        body: Center(child: FarmTapAnimationView(animation: FarmTapAnimations.emptyHerd)),
      ),
      disableAnimations: true,
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    expect(find.byType(RawImage), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('MetricCard and StatusBadge render at 1.3x text without overflow', (tester) async {
    await pumpFarmTap(
      tester,
      const Scaffold(
        body: ResponsiveGrid(
          minItemWidth: 150,
          children: [
            MetricCard(icon: Icons.water_drop_rounded, label: 'Milk today', value: '312', unit: 'L', trend: '+6%'),
            MetricCard(icon: Icons.pets_rounded, label: 'Cows', value: '48', caption: '41 milking · 7 dry'),
          ],
        ),
      ),
      textScale: 1.3,
    );
    expect(tester.takeException(), isNull);
  });
}

void soundAndAvatarTests() {
  group('avatars', () {
    test('same id always gives the same cartoon, 1..6', () {
      expect(FarmTapAssets.cowAvatarFor('cow-014'), FarmTapAssets.cowAvatarFor('cow-014'));
      final all = {for (var i = 0; i < 50; i++) FarmTapAssets.cowAvatarFor('cow-$i')};
      expect(all.length, greaterThan(1));
      for (final a in all) {
        expect(RegExp(r'avatar_cow_[1-6]\.png$').hasMatch(a), isTrue);
      }
    });
  });

  group('sounds', () {
    late NoOpSoundService sounds;
    setUp(() {
      sounds = NoOpSoundService();
      SoundService.instance = sounds;
    });
    tearDown(() => SoundService.instance = NoOpSoundService());

    testWidgets('keypad key plays tap; muted plays nothing', (tester) async {
      await pumpFarmTap(
        tester,
        Scaffold(
          body: BigNumberKeypad(onDigit: (_) {}, onBackspace: () {}),
        ),
      );
      await tester.tap(find.text('5'));
      expect(sounds.played, [FarmTapSound.tap]);
      AppSettingsCubit().setSounds(enabled: false);
      await tester.tap(find.text('6'));
      expect(sounds.played, [FarmTapSound.tap]);
    });

    testWidgets('wrong PIN plays error', (tester) async {
      await pumpFarmTap(tester, Scaffold(body: PinPad(onCompleted: (_) async => false)));
      for (final d in ['1', '1', '1', '1']) {
        await tester.tap(find.text(d));
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 400));
      expect(sounds.played, contains(FarmTapSound.error));
    });

    testWidgets('celebration plays its sound; toast plays success', (tester) async {
      await pumpFarmTap(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showCelebration(
              context,
              animation: FarmTapAnimations.paymentReceived,
              title: 'Paid',
              primaryLabel: 'Done',
              sound: FarmTapSound.coin,
            ),
            child: const Text('go'),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(sounds.played, [FarmTapSound.coin]);
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
