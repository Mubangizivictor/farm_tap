// Section G — collection centre (G01-G13), 8 goldens per screen + small screens.
// flutter test --update-goldens test/goldens/g_collection_test.dart
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/sectors/cattle/collection_centre/data/fake/fake_centre_repository.dart';
import 'package:farm_tap/sectors/cattle/collection_centre/domain/centre_models.dart';
import 'package:farm_tap/sectors/cattle/collection_centre/presentation/pages/centre_collect_pages.dart';
import 'package:farm_tap/sectors/cattle/collection_centre/presentation/pages/centre_farmers_pay_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_deps.dart';
import '../helpers/screen_golden.dart';
import '../helpers/shell_wrap.dart';

void main() {
  final clock = FixedClock();
  final now = clock.now();
  FakeCentreRepository repo() => FakeCentreRepository(clock);

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  Widget shell(Widget page, String current, {String? parent}) =>
      inShell(page, current: current, parent: parent, centre: true);

  Widget home() => shell(
    CentreHomePage(repo: repo(), centreName: 'Kashari Milk Centre', onTapCard: () {}, onTool: (_) {}, onSeeAll: () {}),
    '/home',
  );

  Widget keypad({String farmerId = 'farmer-0142', String litres = '42.5'}) => shell(
    DeliveryKeypadPage(
      repo: repo(),
      farmerId: farmerId,
      onSaved: (_) {},
      onRejected: () {},
      now: now,
      initialLitres: litres,
    ),
    '/collect',
    parent: '/collect',
  );

  Future<void> fromPage<T extends Widget>(WidgetTester tester, Future<void> Function(BuildContext) open) async {
    open(tester.element(find.byType(T))).ignore();
    await settle(tester);
  }

  screenGoldens('G01_centre_home', (_) => home());

  screenGoldens(
    'G02_centre_tap_card',
    (_) => shell(
      ReceiveMilkPage(repo: repo(), onFarmer: (_) {}, now: now),
      '/collect',
      parent: '/home',
    ),
  );

  screenGoldens('G03_centre_delivery_keypad', (_) => keypad());

  screenGoldens(
    'G04_centre_delivery_read_back',
    (_) => keypad(),
    act: (tester, _) async {
      await tester.tap(find.text('Next'));
      await settle(tester);
    },
  );

  screenGoldens(
    'G05_centre_delivery_saved',
    (_) => shell(
      ReceiveMilkPage(repo: repo(), onFarmer: (_) {}, now: now, savedDeliveryId: 'd-4'),
      '/collect',
      parent: '/home',
    ),
    act: (tester, _) => settle(tester),
  );

  screenGoldens(
    'G06_centre_farmers',
    (_) => shell(CentreFarmersPage(repo: repo(), onFarmer: (_) {}, onAdd: () {}), '/farmers'),
  );

  screenGoldens(
    'G07_centre_farmer_detail',
    (_) => shell(
      CentreFarmerPage(repo: repo(), farmerId: 'farmer-0142'),
      '/farmers',
      parent: '/farmers',
    ),
  );

  screenGoldens(
    'G08_centre_close_session',
    (_) => home(),
    act: (tester, _) => fromPage<CentreHomePage>(tester, (context) async {
      final day = (await repo().today()).data!;
      if (!context.mounted) return;
      await showDialog<bool>(
        context: context,
        builder: (_) => DialogFrame(
          child: CloseSessionDialog(repo: repo(), day: day, initialPin: '1'),
        ),
      );
    }),
  );

  screenGoldens(
    'G09_centre_statements',
    (_) => shell(CentrePaymentsPage(repo: repo(), onSendSms: () {}, onPaymentSheet: () {}, onFarmer: (_) {}), '/pay'),
  );

  screenGoldens(
    'G10_centre_payment_sheet',
    (_) => shell(
      PayFarmersPage(repo: repo(), onDone: () {}),
      '/pay',
      parent: '/pay',
    ),
  );

  screenGoldens(
    'G11_centre_sms_preview',
    (_) => shell(
      SmsStatementsPage(repo: repo(), onSent: () {}),
      '/pay',
      parent: '/pay',
    ),
  );

  screenGoldens(
    'G12_centre_quality_test',
    (_) => keypad(farmerId: 'farmer-0113', litres: '26.5'),
    act: (tester, _) => fromPage<DeliveryKeypadPage>(tester, (context) async {
      final farmer = (await repo().farmer('farmer-0113')).data!;
      if (!context.mounted) return;
      await showAdaptiveSheet<void>(
        context,
        builder: (_) => QualityTestSheet(
          farmer: farmer,
          litres: 26.5,
          initialPassed: false,
          initialReason: RejectReason.addedWater,
          initialNote: 'Lactometer 1.024',
        ),
      );
    }),
  );

  screenGoldens(
    'G13_centre_reconciliation',
    (_) => shell(
      ReconcilePage(repo: repo(), onSaved: () {}),
      '/home',
      parent: '/home',
    ),
  );
}
