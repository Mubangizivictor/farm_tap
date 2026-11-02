// Workers (K01-K06). Attendance, task, advance and wage-payment records are
// the single source: who is in, days worked, balances owed and the wage
// expenses in core/money are all calculated from them.
import 'package:farm_tap/core/people/domain/staff_member.dart';

/// One clock-in (and later clock-out) by card.
class AttendanceRecord {
  const new({required this.id, required this.staffId, required this.inAt, this.outAt});

  final String id;
  final String staffId;
  final DateTime inAt;
  final DateTime? outAt;

  AttendanceRecord clockOut(DateTime at) => AttendanceRecord(id: id, staffId: staffId, inAt: inAt, outAt: at);
}

/// K01 / K04 row: a staff member and today's attendance.
class StaffToday {
  const new({required this.staff, this.record});

  final StaffMember staff;

  /// Today's latest record; null when not in today.
  final AttendanceRecord? record;

  bool get isIn => record != null && record!.outAt == null;

  /// The vet visits; they are not on the shift roll (K01 chips, K04).
  bool get onShift => staff.role != StaffRole.vet;
}

/// K05.
class FarmTask {
  const new({
    required this.id,
    required this.title,
    required this.staffId,
    required this.due,
    required this.when,
    this.photoNeeded = false,
    this.doneAt,
  });

  final String id;
  final String title;
  final String staffId;
  final DateTime due;

  /// "before 10:00", "after evening milking" (worded by the farm).
  final String when;
  final bool photoNeeded;
  final DateTime? doneAt;

  bool get done => doneAt != null;
  bool overdue(DateTime now) => !done && due.isBefore(now);

  FarmTask withDone(DateTime? at) =>
      FarmTask(id: id, title: title, staffId: staffId, due: due, when: when, photoNeeded: photoNeeded, doneAt: at);
}

enum PayKind { advance, wage }

/// Money given to a worker; each one is a wage expense in core/money.
class StaffPayment {
  const new({required this.id, required this.staffId, required this.kind, required this.amount, required this.at});

  final String id;
  final String staffId;
  final PayKind kind;
  final int amount;
  final DateTime at;
}

/// K06 row, calculated for one month.
class WageLine {
  const new({required this.staff, required this.wage, required this.advances, required this.paid});

  final StaffMember staff;
  final int wage;
  final int advances;
  final int paid;

  int get toPay => wage - advances - paid;
}

/// K06 header and rows.
class WagesSummary {
  const new({required this.month, required this.lines});

  final DateTime month;
  final List<WageLine> lines;

  int get wages => lines.fold(0, (s, l) => s + l.wage);
  int get advances => lines.fold(0, (s, l) => s + l.advances);
}
