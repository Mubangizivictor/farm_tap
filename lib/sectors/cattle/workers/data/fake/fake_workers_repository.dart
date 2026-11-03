import 'dart:async';

import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/money/domain/money_models.dart';
import 'package:farm_tap/core/money/domain/money_repository.dart';
import 'package:farm_tap/core/people/domain/staff_directory.dart';
import 'package:farm_tap/core/people/domain/staff_member.dart';
import 'package:farm_tap/core/sync/record_journal.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/sectors/cattle/milk/domain/milk_repository.dart';
import 'package:farm_tap/sectors/cattle/workers/domain/workers_models.dart';
import 'package:farm_tap/sectors/cattle/workers/domain/workers_repository.dart';

/// UI phase: every worker clocked in on each earlier day this month; today
/// Tom 6:02, Amos 5:45, Joy 6:10 and Rita 6:30 are in (4 of 6). Advances
/// this month: Amos 120,000, Peter 80,000, Rita 40,000 (wage expenses).
/// With [withSamples] false (real data) it starts empty.
class FakeWorkersRepository implements WorkersRepository, Restorable {
  new(this.clock, this.directory, this.money, this.milk, {this.journal, this.withSamples = true}) {
    if (!withSamples) return;
    final now = clock.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime at(int h, int m, [int daysAgo = 0]) =>
        today.subtract(Duration(days: daysAgo)).add(Duration(hours: h, minutes: m));
    const shifts = {
      'staff-mt': (6, 2),
      'staff-ta': (5, 45),
      'staff-aj': (6, 10),
      'staff-np': (6, 20),
      'staff-kr': (6, 30),
    };
    for (var d = today.day - 1; d >= 1; d--) {
      for (final e in shifts.entries) {
        _attendance.add(
          AttendanceRecord(
            id: 'att-${_next++}',
            staffId: e.key,
            inAt: at(e.value.$1, e.value.$2, d),
            outAt: at(17, 30, d),
          ),
        );
      }
    }
    for (final id in ['staff-mt', 'staff-ta', 'staff-aj', 'staff-kr']) {
      final (h, m) = shifts[id]!;
      _attendance.add(AttendanceRecord(id: 'att-${_next++}', staffId: id, inAt: at(h, m)));
    }
    _tasks.addAll([
      FarmTask(
        id: 'task-heifers',
        title: 'Move heifers to paddock 3',
        staffId: 'staff-ta',
        due: at(10, 0),
        when: 'before 10:00',
        doneAt: at(6, 30),
      ),
      FarmTask(
        id: 'task-clean',
        title: 'Clean milking area',
        staffId: 'staff-kr',
        due: at(19, 0),
        when: 'after evening milking',
      ),
      FarmTask(
        id: 'task-trough',
        title: 'Fix water trough',
        staffId: 'staff-np',
        due: at(17, 0),
        when: 'photo when done',
        photoNeeded: true,
      ),
      FarmTask(
        id: 'task-meal',
        title: 'Collect dairy meal from town',
        staffId: 'staff-mt',
        due: at(6, 0),
        when: 'today',
      ),
      FarmTask(id: 'task-fence', title: 'Repair paddock fence', staffId: 'staff-np', due: at(12, 0, -3), when: 'Tue'),
    ]);
    for (final (id, amount, daysAgo) in [('staff-ta', 120000, 4), ('staff-np', 80000, 3), ('staff-kr', 40000, 2)]) {
      unawaited(
        _record(
          StaffPayment(id: 'pay-${_next++}', staffId: id, kind: PayKind.advance, amount: amount, at: at(9, 0, daysAgo)),
        ),
      );
    }
  }

  /// Monthly wages (the vet is paid per visit, not on the wage sheet).
  static const monthlyWage = {
    'staff-mt': 400000,
    'staff-ta': 300000,
    'staff-aj': 300000,
    'staff-np': 260000,
    'staff-kr': 260000,
  };

  final Clock clock;

  /// False in real-data mode.
  final bool withSamples;

  /// Saves records on the phone for sync (decision 0014); null in tests.
  final RecordJournal? journal;
  final StaffDirectory directory;
  final MoneyRepository money;

  /// Milk records carry recordedBy (K02 count).
  final MilkRepository milk;
  final List<AttendanceRecord> _attendance = [];
  final List<FarmTask> _tasks = [];
  final List<StaffPayment> _payments = [];
  var _next = 1;

  DateTime get _today {
    final n = clock.now();
    return DateTime(n.year, n.month, n.day);
  }

  Future<List<StaffMember>> _staff() async => (await directory.staff()).data ?? const [];

  AttendanceRecord? _todayRecord(String staffId) =>
      _attendance.where((a) => a.staffId == staffId && !a.inAt.isBefore(_today)).lastOrNull;

  @override
  Future<Result<List<StaffToday>>> today() async =>
      Result.success([for (final s in await _staff()) StaffToday(staff: s, record: _todayRecord(s.id))]);

  @override
  Future<Result<StaffToday?>> clockByCard(String cardNumber) async {
    final card = cardNumber.padLeft(4, '0');
    final s = (await _staff()).where((m) => m.cardNumber == card).firstOrNull;
    if (s == null) return const Result.success(null);
    final now = clock.now();
    final open = _todayRecord(s.id);
    if (open != null && open.outAt == null) {
      _attendance[_attendance.indexOf(open)] = open.clockOut(now);
    } else {
      _attendance.add(AttendanceRecord(id: 'att-${_next++}', staffId: s.id, inAt: now));
    }
    return Result.success(StaffToday(staff: s, record: _todayRecord(s.id)));
  }

  @override
  Future<Result<int>> milkRecordsThisMonth(String staffId) =>
      milk.recordCount(staffId, from: DateTime(_today.year, _today.month));

  @override
  Future<Result<int>> daysThisMonth(String staffId) async {
    final monthStart = DateTime(_today.year, _today.month);
    final days = {
      for (final a in _attendance)
        if (a.staffId == staffId && !a.inAt.isBefore(monthStart)) DateTime(a.inAt.year, a.inAt.month, a.inAt.day),
    };
    return Result.success(days.length);
  }

  @override
  Future<Result<List<FarmTask>>> tasks() async => Result.success(List.unmodifiable(_tasks));

  /// Wage expenses come back through the money repository.
  @override
  Future<void> restore() async {
    final j = journal;
    if (j == null) return;
    for (final r in await j.load('tasks')) {
      final b = r.body;
      final done = b['doneAt'] as String?;
      final t = FarmTask(
        id: r.id,
        title: b['title']! as String,
        staffId: b['staffId']! as String,
        due: DateTime.parse(b['due']! as String),
        when: b['when']! as String,
        doneAt: done == null ? null : DateTime.parse(done),
      );
      final i = _tasks.indexWhere((x) => x.id == r.id);
      if (i >= 0) {
        _tasks[i] = t;
      } else {
        _tasks.add(t);
      }
    }
    for (final r in await j.load('wages')) {
      if (_payments.any((p) => p.id == r.id)) continue;
      final b = r.body;
      _payments.add(
        StaffPayment(
          id: r.id,
          staffId: b['staffId']! as String,
          kind: PayKind.values.byName(b['kind']! as String),
          amount: b['amount']! as int,
          at: DateTime.parse(b['at']! as String),
        ),
      );
    }
  }

  @override
  Future<Result<FarmTask>> addTask({
    required String title,
    required String staffId,
    required DateTime due,
    required String when,
  }) async {
    final t = FarmTask(id: journal?.newId() ?? 'task-${_next++}', title: title, staffId: staffId, due: due, when: when);
    _tasks.add(t);
    await journal?.add('tasks', _taskBody(t), id: t.id);
    return Result.success(t);
  }

  @override
  Future<Result<void>> setTaskDone(String taskId, {required bool done}) async {
    final i = _tasks.indexWhere((t) => t.id == taskId);
    if (i >= 0) {
      _tasks[i] = _tasks[i].withDone(done ? clock.now() : null);
      await journal?.put('tasks', taskId, _taskBody(_tasks[i]));
    }
    return const Result.success(null);
  }

  static Map<String, Object?> _taskBody(FarmTask t) => {
    'title': t.title,
    'staffId': t.staffId,
    'due': t.due.toIso8601String(),
    'when': t.when,
    'doneAt': t.doneAt?.toIso8601String(),
  };

  @override
  Future<Result<WagesSummary>> wages() async {
    final month = DateTime(_today.year, _today.month);
    int sum(String id, PayKind k) =>
        _payments.where((p) => p.staffId == id && p.kind == k && !p.at.isBefore(month)).fold(0, (s, p) => s + p.amount);
    return Result.success(
      WagesSummary(
        month: month,
        lines: [
          for (final s in await _staff())
            if (monthlyWage[s.id] case final wage?)
              WageLine(staff: s, wage: wage, advances: sum(s.id, PayKind.advance), paid: sum(s.id, PayKind.wage)),
        ],
      ),
    );
  }

  @override
  Future<Result<StaffPayment>> pay(String staffId, {required PayKind kind, required int amount}) async {
    final p = StaffPayment(
      id: journal?.newId() ?? 'pay-${_next++}',
      staffId: staffId,
      kind: kind,
      amount: amount,
      at: clock.now(),
    );
    await journal?.add('wages', {
      'staffId': staffId,
      'kind': kind.name,
      'amount': amount,
      'at': p.at.toIso8601String(),
    }, id: p.id);
    await _record(p);
    return Result.success(p);
  }

  Future<void> _record(StaffPayment p) async {
    _payments.add(p);
    final name = (await _staff()).where((s) => s.id == p.staffId).firstOrNull?.name ?? '';
    await money.addExpense(
      category: ExpenseCategory.wages,
      amount: p.amount,
      at: p.at,
      note: '$name · ${p.kind.name}',
      sourceId: p.id,
    );
  }
}
