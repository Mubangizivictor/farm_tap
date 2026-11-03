import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/money/domain/money_models.dart';

/// Expenses and income other than milk sales. Feature repositories that spend money
/// (feed purchases, drugs, wages) record it here; nothing keeps its own total.
abstract interface class MoneyRepository {
  /// Expenses in [from, to), newest first; optionally one category.
  Future<Result<List<Expense>>> expenses({DateTime? from, DateTime? to, ExpenseCategory? category});

  Future<Result<Expense>> addExpense({
    required ExpenseCategory category,
    required int amount,
    DateTime? at,
    String? note,
    String? sourceId,
    String? photo,
  });

  /// Removes an expense entered by mistake (kept in the audit trail).
  Future<Result<void>> deleteExpense(String id);

  /// Income other than milk sales in [from, to), newest first.
  Future<Result<List<Income>>> incomes({DateTime? from, DateTime? to});

  Future<Result<Income>> addIncome({
    required IncomeSource source,
    required int amount,
    DateTime? at,
    String? note,
    String? sourceId,
  });
}
