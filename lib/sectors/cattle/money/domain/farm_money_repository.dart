import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/money/domain/money_models.dart';
import 'package:farm_tap/sectors/cattle/money/domain/farm_money_models.dart';

/// L01 overview and L02 add expense, over core/money and the milk records.
abstract interface class FarmMoneyRepository {
  /// This calendar month to date.
  Future<Result<MonthMoney>> month();

  /// L02: saved in core/money.
  Future<Result<Expense>> addExpense({required ExpenseGroup group, required int amount, String? note});
}
