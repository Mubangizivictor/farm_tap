// Section E — herd (E01-E10), 8 goldens per screen + small screens.
// flutter test --update-goldens test/goldens/e_herd_test.dart
import 'package:farm_tap/core/tenancy/tenant_provider.dart';
import 'package:farm_tap/sectors/cattle/herd/data/fake/fake_herd_repository.dart';
import 'package:farm_tap/sectors/cattle/herd/presentation/pages/animal_detail_page.dart';
import 'package:farm_tap/sectors/cattle/herd/presentation/pages/herd_list_page.dart';
import 'package:farm_tap/sectors/cattle/herd/presentation/pages/herd_tools_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_deps.dart';
import '../helpers/screen_golden.dart';
import '../helpers/shell_wrap.dart';

void main() {
  final clock = FixedClock();
  final today = clock.now();
  FakeHerdRepository repo() => FakeHerdRepository(clock: clock, tenantProvider: InMemoryTenantProvider());

  Widget list() => inShell(
    HerdListPage(repo: repo(), onAnimal: (_) {}, onAdd: () {}, onScan: () {}, today: today),
    current: '/herd',
  );

  Widget detail() => inShell(
    AnimalDetailPage(repo: repo(), animalId: 'animal-FT-022', onEvent: (_) {}, today: today),
    current: '/herd',
    parent: '/herd',
  );

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  screenGoldens('E01_herd_list', (_) => list());

  screenGoldens(
    'E02_herd_filter_sheet',
    (_) => list(),
    act: (tester, _) async {
      await tester.tap(find.byTooltip('Filter'));
      await settle(tester);
      await tester.tap(find.text('Milking').last);
      await tester.tap(find.text('Pregnant').last);
      await tester.tap(find.text('Milk').last);
      await tester.pump();
    },
  );

  screenGoldens('E03_animal_detail', (_) => detail());

  screenGoldens(
    'E04_add_animal',
    (_) => inShell(AddAnimalPage(repo: repo(), onSaved: (_) {}, now: today), current: '/herd', parent: '/herd'),
    act: (tester, _) async {
      await tester.enterText(find.byType(TextField).at(1), 'Kyakuhaire');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
    },
  );

  screenGoldens(
    'E05_scan_qr',
    (_) => inShell(ScanTagPage(onTypeTag: () {}), current: '/herd', parent: '/herd'),
  );

  screenGoldens(
    'E06_record_event_sheet',
    (_) => detail(),
    act: (tester, _) async {
      await tester.tap(find.text('Record'));
      await settle(tester);
    },
  );

  screenGoldens(
    'E07_calf_born',
    (_) => detail(),
    act: (tester, _) async {
      await tester.tap(find.text('Record'));
      await settle(tester);
      await tester.tap(find.text('Calving'));
      await settle(tester);
    },
  );

  screenGoldens(
    'E08_confirm_death',
    (_) => detail(),
    act: (tester, _) async {
      await tester.tap(find.text('Record'));
      await settle(tester);
      await tester.tap(find.text('Died'));
      await settle(tester);
    },
  );

  screenGoldens('E09_head_count', (_) => inShell(HeadCountPage(repo: repo()), current: '/herd', parent: '/herd'));

  screenGoldens('E10_print_qr_labels', (_) => inShell(QrLabelsPage(repo: repo()), current: '/herd', parent: '/herd'));
}
