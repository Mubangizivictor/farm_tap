import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/money/domain/money_models.dart';
import 'package:farm_tap/sectors/cattle/money/domain/farm_money_models.dart';

/// L01 overview and L02 add expense, over core/money and the milk records.
abstract interface class FarmMoneyRepository {
  /// The calendar month holding [month] (this month to date when null).
  Future<Result<MonthMoney>> month({DateTime? month});

  /// L02: saved in core/money.
  Future<Result<Expense>> addExpense({
    required ExpenseGroup group,
    required int amount,
    String? note,
    DateTime? at,
    String? photo,
  });

  /// An expense entered by mistake (only ones entered on L02).
  Future<Result<void>> deleteExpense(String id);

  /// "Add income": money in that is not a milk sale.
  Future<Result<Income>> addIncome({required IncomeSource source, required int amount, String? note, DateTime? at});
}
