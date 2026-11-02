import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/money/domain/money_models.dart';
import 'package:farm_tap/core/money/domain/money_repository.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/sectors/cattle/milk/domain/milk_models.dart';
import 'package:farm_tap/sectors/cattle/milk/domain/milk_repository.dart';
import 'package:farm_tap/sectors/cattle/money/domain/farm_money_models.dart';
import 'package:farm_tap/sectors/cattle/money/domain/farm_money_repository.dart';

/// Reads core/money (expenses) and the milk records and sales (litres,
/// income); it keeps no totals of its own.
class FakeFarmMoneyRepository implements FarmMoneyRepository {
  new(this.clock, this.money, this.milk);

  final Clock clock;
  final MoneyRepository money;
  final MilkRepository milk;

  @override
  Future<Result<MonthMoney>> month() async {
    final now = clock.now();
    final start = DateTime(now.year, now.month);
    final sales = (await milk.salesSince(start)).data ?? const <MilkSale>[];
    return Result.success(
      MonthMoney(
        month: start,
        milkIncome: sales.fold(0, (s, x) => s + x.amount),
        litresSold: sales.fold(0, (s, x) => s + x.litres),
        litresProduced: (await milk.trend(TrendRange.month)).data?.total ?? 0,
        expenses: (await money.expenses(from: start)).data ?? const <Expense>[],
      ),
    );
  }

  @override
  Future<Result<Expense>> addExpense({required ExpenseGroup group, required int amount, String? note}) =>
      money.addExpense(category: group.category, amount: amount, note: note);
}
