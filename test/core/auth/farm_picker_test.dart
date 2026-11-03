import 'package:farm_tap/core/auth/domain/entities/account_user.dart';
import 'package:farm_tap/core/auth/presentation/pages/farm_picker_page.dart';
import 'package:farm_tap/core/error/failure.dart';
import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/tenancy/domain/farm_membership.dart';
import 'package:farm_tap/core/tenancy/domain/farm_membership_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

class _Places implements FarmMembershipRepository {
  new(this.places, {this.limit = defaultFarmLimit, this.last});

  /// null: no network and nothing saved on the phone.
  final List<FarmMembership>? places;
  final int limit;
  String? last;
  final opened = <String>[];

  @override
  Future<Result<List<FarmMembership>>> myPlaces() async =>
      places == null ? const Result.failure(NetworkFailure('no-places-offline')) : Result.success(places!);

  @override
  Future<Result<void>> open(String tenantId) async {
    opened.add(tenantId);
    last = tenantId;
    return const Result.success(null);
  }

  @override
  Future<String?> lastOpened() async => last;

  @override
  Future<int> farmLimit() async => limit;
}

DateTime _day(int offset) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day + offset);
}

final _dairy = FarmMembership(
  tenantId: 'vickie',
  name: 'Vickie Farm',
  place: 'Mbarara',
  village: 'Kashari',
  kind: PlaceKind.dairyFarm,
  role: PlaceRole.owner,
  herdSize: 42,
  subscription: Subscription(trialStartedAt: _day(-2), trialEndsAt: _day(5)),
);

final _poultry = FarmMembership(
  tenantId: 'eggs',
  name: 'Kazo Layers',
  place: 'Kazo',
  kind: PlaceKind.dairyFarm,
  role: PlaceRole.manager,
  sector: Sector.poultry,
  herdSize: 300,
  subscription: Subscription(paidUntil: _day(30)),
);

const _victor = AccountUser(id: 'u1', name: 'Victor Mubangizi', email: 'farmtap.ug@gmail.com');

void main() {
  testWidgets('a returning person goes straight into the farm they used last', (tester) async {
    final repo = _Places([_dairy, _poultry], last: 'eggs');
    FarmMembership? opened;
    await pumpFarmTap(
      tester,
      FarmPickerPage(places: repo, account: _victor, autoOpen: true, onOpened: (f) => opened = f),
    );
    await tester.pump();
    expect(find.text('Welcome back, Victor'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 50));
    expect(repo.opened, ['eggs']);
    expect(opened?.name, 'Kazo Layers');
    expect(find.text('Choose a farm'), findsNothing);
  });

  testWidgets('one farm opens by itself after signing in', (tester) async {
    final repo = _Places([_dairy]);
    FarmMembership? opened;
    await pumpFarmTap(
      tester,
      FarmPickerPage(places: repo, account: _victor, autoOpen: true, onOpened: (f) => opened = f),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(opened?.tenantId, 'vickie');
  });

  testWidgets('switch farm: rich cards, no free "Add another farm"', (tester) async {
    final repo = _Places([_dairy, _poultry]);
    await pumpFarmTap(tester, FarmPickerPage(places: repo, account: _victor, onOpened: (_) {}, onAddFarm: () {}));
    await tester.pump();
    expect(find.text('Welcome back, Victor'), findsOneWidget);
    expect(find.text('You can open 2 farms. Pick the one to work on.'), findsOneWidget);
    // Dairy farm card: kind, place, herd, role, trial.
    expect(find.text('Dairy farm'), findsOneWidget);
    expect(find.text('Kashari, Mbarara'), findsOneWidget);
    expect(find.text('42 cows'), findsOneWidget);
    expect(find.text('You: Owner'), findsOneWidget);
    expect(find.textContaining('of 7 days left'), findsOneWidget);
    // Poultry farm: its own words.
    expect(find.text('Poultry'), findsOneWidget);
    expect(find.text('300 birds'), findsOneWidget);
    expect(find.text('You: Manager'), findsOneWidget);
    expect(find.textContaining('Paid until'), findsOneWidget);
    // Owns one farm, limit one: the multi-farm option stays hidden.
    expect(find.text('Add another farm'), findsNothing);
    expect(find.text('Signed in as farmtap.ug@gmail.com'), findsOneWidget);
    expect(repo.opened, isEmpty);

    await tester.tap(find.text('Open farm').first);
    await tester.pump(const Duration(milliseconds: 50));
    expect(repo.opened, ['vickie']);
  });

  testWidgets('a multi-farm plan shows "Add another farm"', (tester) async {
    await pumpFarmTap(tester, FarmPickerPage(places: _Places([_dairy], limit: 2), onOpened: (_) {}, onAddFarm: () {}));
    await tester.pump();
    expect(find.text('Add another farm'), findsOneWidget);
  });

  testWidgets('no farm yet: a personal set-up screen', (tester) async {
    var setUp = false;
    await pumpFarmTap(
      tester,
      FarmPickerPage(
        places: _Places(const []),
        account: _victor,
        autoOpen: true,
        onOpened: (_) {},
        onAddFarm: () => setUp = true,
      ),
    );
    await tester.pump();
    expect(find.text('Welcome, Victor'), findsOneWidget);
    expect(find.text('Choose a farm'), findsNothing);
    await tester.tap(find.text('Set up my farm'));
    expect(setUp, isTrue);
  });

  testWidgets('a new phone with no internet says so instead of "set up a farm"', (tester) async {
    await pumpFarmTap(tester, FarmPickerPage(places: _Places(null), autoOpen: true, onOpened: (_) {}));
    await tester.pump();
    expect(find.text("Can't load your farm"), findsOneWidget);
    expect(find.text('Set up my farm'), findsNothing);
  });
}
