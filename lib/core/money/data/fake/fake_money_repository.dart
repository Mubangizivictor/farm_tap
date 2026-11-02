import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/money/domain/money_models.dart';
import 'package:farm_tap/core/money/domain/money_repository.dart';
import 'package:farm_tap/core/utils/clock.dart';

/// UI phase: in-memory expenses. Feature fakes (feed purchases) add their
/// sample expenses through [addExpense], so every total has one source.
class FakeMoneyRepository implements MoneyRepository {
  new(this.clock);

  final Clock clock;
  final List<Expense> _expenses = [];
  var _next = 1;

  @override
  Future<Result<List<Expense>>> expenses({DateTime? from, DateTime? to, ExpenseCategory? category}) async {
    final list =
        _expenses
            .where(
              (e) =>
                  (category == null || e.category == category) &&
                  (from == null || !e.at.isBefore(from)) &&
                  (to == null || e.at.isBefore(to)),
            )
            .toList()
          ..sort((a, b) => b.at.compareTo(a.at));
    return Result.success(list);
  }

  @override
  Future<Result<Expense>> addExpense({
    required ExpenseCategory category,
    required int amount,
    DateTime? at,
    String? note,
    String? sourceId,
  }) async {
    final e = Expense(
      id: 'expense-${_next++}',
      category: category,
      amount: amount,
      at: at ?? clock.now(),
      note: note,
      sourceId: sourceId,
    );
    _expenses.add(e);
    return Result.success(e);
  }
}
