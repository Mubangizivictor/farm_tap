import 'package:farm_tap/core/auth/data/fake/fake_staff_login_repository.dart';
import 'package:farm_tap/core/auth/domain/staff_login_repository.dart';
import 'package:farm_tap/core/money/data/fake/fake_money_repository.dart';
import 'package:farm_tap/core/people/data/fake/fake_staff_access_repository.dart';
import 'package:farm_tap/core/people/data/local_card_registry.dart';
import 'package:farm_tap/core/people/domain/card_registry.dart';
import 'package:farm_tap/core/people/domain/staff_member.dart';
import 'package:farm_tap/core/people/domain/staff_permissions.dart';
import 'package:farm_tap/core/sync/data/memory_record_store.dart';
import 'package:farm_tap/core/sync/record_journal.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/core/utils/id_generator.dart';
import 'package:farm_tap/sectors/cattle/health/data/fake/fake_treatment_repository.dart';
import 'package:farm_tap/sectors/cattle/milk/data/fake/fake_milk_repository.dart';
import 'package:farm_tap/sectors/cattle/workers/data/fake/fake_workers_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Decision 0016: one holder per card, QR + 4-digit number, staff phone
/// sign-in, sections by role, attendance saved.
void main() {
  const tenant = 'farm-a';
  final clock = FakeClock();
  late MemoryRecordStore store;

  RecordJournal journal() => RecordJournal(
    store: store,
    clock: clock,
    ids: UuidGenerator(),
    deviceId: 'phone-a',
    tenantId: () => tenant,
    actor: () => 'owner-uid',
  );

  LocalCardRegistry registry([RecordJournal? j]) =>
      LocalCardRegistry(now: clock.now, journal: j, tenantId: () => tenant, blankStock: const ['0207', '0208']);

  setUp(() => store = MemoryRecordStore());

  group('card register', () {
    test('a working card cannot go to a second person, staff or farmer', () async {
      final cards = registry();
      final first = await cards.issue(
        holderId: 'staff-1',
        kind: CardHolderKind.staff,
        holderName: 'Amos',
        scanned: '142',
      );
      expect(first.data?.number, '0142');

      final again = await cards.issue(
        holderId: 'farmer-1',
        kind: CardHolderKind.farmer,
        holderName: 'Kato',
        scanned: '0142',
      );
      expect(again.isSuccess, isFalse);
      expect(again.failure?.message, startsWith(CardIssueError.taken));
      expect(again.failure?.message, contains('Amos'));
    });

    test('a person with a card must replace it, not get a second one', () async {
      final cards = registry();
      await cards.issue(holderId: 'staff-1', kind: CardHolderKind.staff, holderName: 'Amos', scanned: '0142');
      final second = await cards.issue(
        holderId: 'staff-1',
        kind: CardHolderKind.staff,
        holderName: 'Amos',
        scanned: '0300',
      );
      expect(second.failure?.message, CardIssueError.hasCard);

      final replaced = await cards.issue(
        holderId: 'staff-1',
        kind: CardHolderKind.staff,
        holderName: 'Amos',
        scanned: '0300',
        replace: true,
      );
      expect(replaced.data?.number, '0300');
      expect((await cards.lookup('0142')).data?.status, CardStatus.lost);
    });

    test('a returned card can go to someone new; a lost card never can', () async {
      final cards = registry();
      await cards.issue(holderId: 'staff-1', kind: CardHolderKind.staff, holderName: 'Amos', scanned: '0142');
      await cards.revoke('0142', CardStatus.returned);
      final reissued = await cards.issue(
        holderId: 'farmer-1',
        kind: CardHolderKind.farmer,
        holderName: 'Kato',
        scanned: '0142',
      );
      expect(reissued.data?.holderId, 'farmer-1');

      await cards.revoke('0142', CardStatus.lost);
      final lost = await cards.issue(
        holderId: 'staff-2',
        kind: CardHolderKind.staff,
        holderName: 'Peter',
        scanned: '0142',
      );
      expect(lost.failure?.message, CardIssueError.lost);
    });

    test('QR, typed number and printed blanks all find the same card', () async {
      final cards = registry();
      final printed = await cards.issue(holderId: 'staff-1', kind: CardHolderKind.staff, holderName: 'Amos');
      expect(printed.data?.number, '0207');
      expect(cards.nextBlank(), '0208');
      expect((await cards.lookup('207')).data?.holderId, 'staff-1');
      expect((await cards.lookup(CardQr.encode(tenant, '0207'))).data?.holderId, 'staff-1');
      final other = await cards.issue(
        holderId: 'staff-2',
        kind: CardHolderKind.staff,
        holderName: 'Peter',
        scanned: CardQr.encode('farm-b', '0500'),
      );
      expect(other.failure?.message, CardIssueError.otherFarm);
    });

    test('cards survive a restart', () async {
      await registry(journal())
          .issue(holderId: 'staff-1', kind: CardHolderKind.staff, holderName: 'Amos', scanned: '0142');
      final reopened = registry(journal());
      await reopened.restore();
      expect((await reopened.activeCardOf('staff-1')).data?.number, '0142');
    });
  });

  test('QR payload round-trips and rejects other codes', () {
    expect(CardQr.decode(CardQr.encode('farm-a', '42')), ('farm-a', '0042'));
    expect(CardQr.decode('https://example.com'), isNull);
    expect(CardQr.decode('FTID:farm-a:12345'), isNull);
  });

  test('sections by role: workers never see money or staff', () {
    expect(StaffPermissions.can(null, AppSection.money), isTrue);
    expect(StaffPermissions.can(StaffRole.manager, AppSection.workers), isTrue);
    expect(StaffPermissions.can(StaffRole.worker, AppSection.money), isFalse);
    expect(StaffPermissions.can(StaffRole.worker, AppSection.workers), isFalse);
    expect(StaffPermissions.can(StaffRole.clerk, AppSection.collect), isTrue);
    expect(StaffPermissions.can(StaffRole.vet, AppSection.health), isTrue);
    expect(StaffPermissions.can(StaffRole.herdsman, AppSection.me), isTrue);
    expect(StaffPermissions.managesStaff(StaffRole.herdsman), isFalse);
  });

  test('weak PINs are refused', () {
    for (final pin in ['1234', '0000', '1111', '4321']) {
      expect(weakPin(pin), isTrue, reason: pin);
    }
    expect(weakPin('2580'), isFalse);
  });

  group('staff phone sign-in (demo)', () {
    test('starting PIN signs in and must be changed; then the new PIN works', () async {
      final repo = FakeStaffLoginRepository();
      expect((await repo.signIn(phone: '0701 220 318', pin: '9999')).failure?.message, StaffLoginError.wrong);
      final first = await repo.signIn(phone: '0701 220 318', pin: '1234');
      expect(first.data?.mustChangePin, isTrue);
      await repo.changePin('2580');
      expect((await repo.signIn(phone: '+256701220318', pin: '1234')).isSuccess, isFalse);
      expect((await repo.signIn(phone: '701220318', pin: '2580')).data?.mustChangePin, isFalse);
    });

    test('one phone number signs in to one farm only', () async {
      final repo = FakeStaffLoginRepository();
      final r = await repo.createLogin(
        tenantId: 'farm-b',
        staffId: 'staff-x',
        name: 'Someone',
        phone: '0701220318',
        pin: '2580',
        role: StaffRole.worker,
      );
      expect(r.failure?.message, StaffLoginError.otherFarm);
    });
  });

  test('a card clock-in is saved and still there after a restart', () async {
    final staff = FakeStaffAccessRepository(journal: journal());
    FakeWorkersRepository workers(RecordJournal j) => FakeWorkersRepository(
      clock,
      staff,
      FakeMoneyRepository(clock, journal: j, withSamples: false),
      FakeMilkRepository(clock, FakeTreatmentRepository(clock)),
      journal: j,
      withSamples: false,
    );
    final amos = FakeStaffAccessRepository.sample[1];
    await workers(journal()).clockStaff(amos.id);

    final reopened = workers(journal());
    await reopened.restore();
    expect((await reopened.attendanceThisMonth(amos.id)).data, hasLength(1));
  });
}
