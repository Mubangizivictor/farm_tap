// A dirty form asks "Discard changes?" however the user tries to leave.
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

class _Opener extends StatelessWidget {
  const new({required this.open});

  final void Function(BuildContext) open;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: TextButton(onPressed: () => open(context), child: const Text('open'))));
}

void _openPage(BuildContext context) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => const DiscardGuard(
      dirty: true,
      child: Scaffold(body: Center(child: Text('form'))),
    ),
  ),
);

void _openSheet(BuildContext context) => showAdaptiveSheet<void>(
  context,
  builder: (_) => const DiscardGuard(dirty: true, child: SizedBox(height: 300, child: Text('sheet form'))),
);

void main() {
  testWidgets('page: Android system back asks', (tester) async {
    await pumpFarmTap(tester, const _Opener(open: _openPage));
    await tester.tap(find.text('open'));
    await _settle(tester);
    await tester.binding.handlePopRoute();
    await _settle(tester);
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await _settle(tester);
    expect(find.text('form'), findsNothing);
  });

  testWidgets('page: iOS edge swipe asks', (tester) async {
    await pumpFarmTap(tester, const _Opener(open: _openPage));
    await tester.tap(find.text('open'));
    await _settle(tester);
    await tester.dragFrom(const Offset(5, 300), const Offset(300, 0));
    await _settle(tester);
    expect(find.text('form'), findsOneWidget);
    expect(find.text('Discard changes?'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('sheet: scrim tap asks', (tester) async {
    await pumpFarmTap(tester, const _Opener(open: _openSheet));
    await tester.tap(find.text('open'));
    await _settle(tester);
    await tester.tapAt(const Offset(20, 20));
    await _settle(tester);
    expect(find.text('Discard changes?'), findsOneWidget);
  });

  testWidgets('sheet: drag down asks', (tester) async {
    await pumpFarmTap(tester, const _Opener(open: _openSheet));
    await tester.tap(find.text('open'));
    await _settle(tester);
    await tester.fling(find.text('sheet form'), const Offset(0, 500), 2000);
    await _settle(tester);
    expect(find.text('sheet form'), findsOneWidget);
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await _settle(tester);
    expect(find.text('sheet form'), findsNothing);
  });

  testWidgets('sheet: Android back asks', (tester) async {
    await pumpFarmTap(tester, const _Opener(open: _openSheet));
    await tester.tap(find.text('open'));
    await _settle(tester);
    await tester.binding.handlePopRoute();
    await _settle(tester);
    expect(find.text('Discard changes?'), findsOneWidget);
  });

  testWidgets('dialog (wide): close X and scrim ask', (tester) async {
    await pumpFarmTap(tester, const _Opener(open: _openSheet), size: const Size(1280, 800));
    await tester.tap(find.text('open'));
    await _settle(tester);
    await tester.tap(find.byTooltip('Close'));
    await _settle(tester);
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await _settle(tester);
    await tester.tapAt(const Offset(20, 20));
    await _settle(tester);
    expect(find.text('Discard changes?'), findsOneWidget);
  });
}
