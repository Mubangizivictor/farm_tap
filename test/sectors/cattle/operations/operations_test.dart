import 'package:farm_tap/core/account/account_repository.dart';
import 'package:farm_tap/core/account/presentation/account_pages.dart';
import 'package:farm_tap/core/alerts/farm_reminders.dart';
import 'package:farm_tap/core/alerts/presentation/reminders_page.dart';
import 'package:farm_tap/core/billing/billing_repository.dart';
import 'package:farm_tap/core/billing/presentation/locked_page.dart';
import 'package:farm_tap/core/billing/presentation/subscription_page.dart';
import 'package:farm_tap/core/people/data/fake/fake_staff_access_repository.dart';
import 'package:farm_tap/core/sync/data/memory_record_store.dart';
import 'package:farm_tap/core/sync/record_journal.dart';
import 'package:farm_tap/core/tenancy/domain/farm_membership.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/core/utils/id_generator.dart';
import 'package:farm_tap/sectors/cattle/operations/data/operations_repository.dart';
import 'package:farm_tap/sectors/cattle/operations/domain/operations_models.dart';
import 'package:farm_tap/sectors/cattle/operations/presentation/pages/contacts_page.dart';
import 'package:farm_tap/sectors/cattle/operations/presentation/pages/feed_store_page.dart';
import 'package:farm_tap/sectors/cattle/operations/presentation/pages/roster_page.dart';
import 'package:farm_tap/sectors/cattle/operations/presentation/pages/vaccinations_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

class _Clock extends Clock {
  @override
  DateTime now() => DateTime(2026, 11, 9, 7);
}

RecordJournal _journal(Clock clock) => RecordJournal(
  store: MemoryRecordStore(),
  clock: clock,
  ids: UuidGenerator(),
  deviceId: 'phone-a',
  tenantId: () => 'farm-1',
  actor: () => 'owner',
);

/// Contacts, roster, feeds store, vaccinations, reminders, paying and
/// closing the account on the phone (decision 0024).
void main() {
  final clock = _Clock();

  Future<OperationsRepository> seeded() async {
    final journal = _journal(clock);
    final repo = OperationsRepository(journal: journal, clock: clock);
    await repo.saveContact(
      const FarmContact(
        id: '',
        name: 'Dr. Mugisha Andrew',
        kind: ContactKind.vet,
        phone: '0772 451 908',
        org: 'Mbarara Vet Clinic',
      ),
    );
    await repo.saveContact(
      const FarmContact(id: '', name: 'Buyer Only', kind: ContactKind.buyer, phone: '0701 000 111', showWorkers: false),
    );
    await repo.saveDuty(
      const Duty(
        id: '',
        activity: DutyActivity.milking,
        staffId: 'staff-ta',
        standInId: 'staff-mt',
        days: [1],
        shift: DutyShift.morning,
      ),
    );
    await repo.addAbsence(
      Absence(id: '', staffId: 'staff-ta', from: DateTime(2026, 11, 8), to: DateTime(2026, 11, 10)),
    );
    await repo.saveFeedType(const FeedType(id: '', name: 'Dairy meal', unit: 'kg', lowAt: 50));
    await repo.countFeed(repo.feedTypes.first.id, 40);
    await repo.addVaccination(
      Vaccination(
        id: '',
        vaccine: 'Lumpy skin',
        given: DateTime(2026, 5, 10),
        nextDue: DateTime(2026, 11, 10),
        cost: 45000,
      ),
    );
    return repo;
  }

  test('saves and reloads every kind; stand-in covers; feed low; vaccine expense linked', () async {
    final repo = await seeded();
    expect(repo.contacts.map((c) => c.name), ['Buyer Only', 'Dr. Mugisha Andrew']);
    final today = repo.dutiesOn(DateTime(2026, 11, 9));
    expect(today, hasLength(1));
    expect(today.first.staffId, 'staff-mt');
    expect(today.first.covering, isTrue);
    expect(repo.dutiesOn(DateTime(2026, 11, 10)), isEmpty);
    expect(repo.stock.first.amount, 40);
    expect(repo.stock.first.low, isTrue);
    expect(repo.upcoming.single.vaccine, 'Lumpy skin');
    final expenses = await repo.journal.load('expenses');
    expect(expenses.single.body['sourceType'], 'vaccination');
    expect(expenses.single.body['amount'], 45000);
    await repo.removeVaccination(repo.vaccinations.single.id);
    expect((await repo.journal.load('expenses')).where((e) => !e.isDeleted), isEmpty);
  });

  test('reminders on the phone follow the same rules', () async {
    final repo = await seeded();
    final reminders = FarmReminders(journal: repo.journal, clock: clock);
    final all = await reminders.today(const ReminderViewer(farmName: 'Rwemera'));
    expect(all.map((a) => a.kind), containsAll(['duty', 'vaccination']));
    final duty = all.firstWhere((a) => a.kind == 'duty');
    expect(duty.staffIds, ['staff-mt']);
    final worker = reminders.forViewer(all, const ReminderViewer(farmName: 'R', staffId: 'staff-mt', manages: false));
    expect(worker.map((a) => a.kind), ['duty']);
  });

  group('screens fit a small phone with large text', () {
    const small = Size(360, 740);
    Future<void> fits(WidgetTester tester, Widget page) async {
      for (final scale in [1.0, 1.3]) {
        await pumpFarmTap(
          tester,
          ClockScope(clock: clock, child: page),
          size: small,
          textScale: scale,
        );
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);
      }
    }

    testWidgets('contacts, roster, feeds, vaccinations', (tester) async {
      final repo = await tester.runAsync(seeded);
      await fits(tester, ContactsPage(repo: repo!, canEdit: true));
      expect(find.text('Dr. Mugisha Andrew'), findsOneWidget);
      await fits(tester, ContactsPage(repo: repo, canEdit: false));
      expect(find.text('Buyer Only'), findsNothing);
      await fits(tester, RosterPage(repo: repo, staff: FakeStaffAccessRepository(), canEdit: true));
      await fits(tester, FeedStorePage(repo: repo, canEdit: true, onRecordFeeding: () {}));
      expect(find.text('Dairy meal'), findsWidgets);
      await fits(tester, VaccinationsPage(repo: repo, canEdit: true));
      expect(find.text('Lumpy skin'), findsWidgets);
    });

    testWidgets('reminders, pay, locked, delete, closed', (tester) async {
      final repo = await tester.runAsync(seeded);
      await fits(
        tester,
        RemindersPage(
          reminders: FarmReminders(journal: repo!.journal, clock: clock),
          viewer: const ReminderViewer(farmName: 'Rwemera'),
          onMessages: () {},
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      await fits(
        tester,
        SubscriptionPage(
          repo: FakeBillingRepository(),
          tenantId: 'farm-1',
          farmName: 'Rwemera Dairy',
          subscription: Subscription(trialStartedAt: DateTime(2026, 10, 30), trialEndsAt: DateTime(2026, 11, 13)),
          canPay: true,
          onPaid: (_) {},
        ),
      );
      await fits(
        tester,
        LockedPage(
          farmName: 'Rwemera Dairy',
          wasPaid: false,
          manages: true,
          onPay: () {},
          onView: () {},
          onSwitchFarm: () {},
          onSignOut: () {},
        ),
      );
      await fits(tester, DeleteAccountPage(ownsFarms: true, onClose: (_) async {}));
      await fits(
        tester,
        ClosedAccountPage(
          closure: AccountClosure(at: DateTime(2026, 11, 7)),
          onSignOut: () {},
        ),
      );
      expect(find.textContaining('2027'), findsOneWidget);
    });
  });

  test('a phone payment goes through after the prompt is accepted', () async {
    final billing = FakeBillingRepository();
    final r = await billing.start(
      tenantId: 't',
      plan: samplePlans.first,
      periods: 1,
      method: 'mtn',
      phone: '256772451908',
    );
    expect(r.status, PayStatus.pending);
    expect((await billing.check(tenantId: 't', paymentId: r.paymentId!)).status, PayStatus.pending);
    expect((await billing.check(tenantId: 't', paymentId: r.paymentId!)).status, PayStatus.paid);
    expect(msisdn('0772 451 908'), '256772451908');
    expect(msisdn('0612 000 000'), isNull);
  });

  test('closing the account keeps a 90-day restore date', () async {
    final account = FakeAccountRepository(now: () => DateTime(2026, 11, 7));
    await account.close(uid: 'u', email: 'a@b.ug', name: 'A', reason: 'test');
    final p = await account.profile('u');
    expect(p.closed?.restoreBy, DateTime(2027, 2, 5));
    expect(photoBase64('data:image/jpeg;base64,QUJD'), 'QUJD');
  });
}
