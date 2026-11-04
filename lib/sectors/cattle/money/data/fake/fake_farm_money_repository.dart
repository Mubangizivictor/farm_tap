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
  Future<Result<MonthMoney>> month({DateTime? month}) async {
    final at = month ?? clock.now();
    final start = DateTime(at.year, at.month);
    final end = DateTime(at.year, at.month + 1);
    final sales = [
      for (final x in (await milk.salesSince(start)).data ?? const <MilkSale>[])
        if (x.at == null || x.at!.isBefore(end)) x,
    ];
    final records = (await milk.records(from: start)).data ?? const <MilkRecord>[];
    return Result.success(
      MonthMoney(
        month: start,
        milkIncome: sales.fold(0, (s, x) => s + x.amount),
        litresSold: sales.fold(0, (s, x) => s + x.litres),
        litresProduced: records.where((r) => r.at.isBefore(end)).fold(0, (s, r) => s + r.litres),
        expenses: (await money.expenses(from: start, to: end)).data ?? const <Expense>[],
        otherIncome: (await money.incomes(from: start, to: end)).data ?? const <Income>[],
      ),
    );
  }

  @override
  Future<Result<Expense>> addExpense({
    required ExpenseGroup group,
    required int amount,
    String? note,
    DateTime? at,
    String? photo,
  }) => money.addExpense(category: group.category, amount: amount, note: note, at: at, photo: photo);

  @override
  Future<Result<void>> deleteExpense(String id) => money.deleteExpense(id);

  @override
  Future<Result<Income>> addIncome({required IncomeSource source, required int amount, String? note, DateTime? at}) =>
      money.addIncome(source: source, amount: amount, note: note, at: at);
}
