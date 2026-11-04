import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/sectors/cattle/workers/domain/workers_models.dart';

/// Attendance, tasks and wages. Home reads who is in and a worker's tasks
/// from here.
abstract interface class WorkersRepository {
  /// Every staff member with today's attendance (K01, K04).
  Future<Result<List<StaffToday>>> today();

  /// K04: the card's owner clocks in, or out if already in. Null when no
  /// one has this card.
  Future<Result<StaffToday?>> clockByCard(String cardNumber);

  /// Clocks [staffId] in, or out if already in (scan station, decision
  /// 0016). [method]: card, qr or typed.
  Future<Result<StaffToday?>> clockStaff(String staffId, {String method});

  /// The worker's clock-ins this month, newest first (My page, activity).
  Future<Result<List<AttendanceRecord>>> attendanceThisMonth(String staffId);

  /// Advances and wages paid to the worker, newest first.
  Future<Result<List<StaffPayment>>> paymentsOf(String staffId);

  /// K02: milk records this worker saved this month.
  Future<Result<int>> milkRecordsThisMonth(String staffId);

  /// K02: days with a clock-in this month.
  Future<Result<int>> daysThisMonth(String staffId);

  Future<Result<List<FarmTask>>> tasks();
  Future<Result<FarmTask>> addTask({
    required String title,
    required String staffId,
    required DateTime due,
    required String when,
  });
  Future<Result<void>> setTaskDone(String taskId, {required bool done});

  /// K06 for the current month.
  Future<Result<WagesSummary>> wages();

  /// K06: records the payment and its wage expense in core/money.
  Future<Result<StaffPayment>> pay(String staffId, {required PayKind kind, required int amount});
}
