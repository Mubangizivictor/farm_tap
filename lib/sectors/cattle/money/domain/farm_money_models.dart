// Money & reports (L01-L03). Expenses come only from core/money; income
// only from the milk sales records; litres from the milk records. Profit,
// cost per litre and feed per litre are calculated, never stored.
import 'package:farm_tap/core/money/domain/money_models.dart';

/// How L01/L02 group expense categories.
enum ExpenseGroup { feed, drugsVet, wages, transport, fuel, other }

extension ExpenseGroupOf on ExpenseCategory {
  ExpenseGroup get group => switch (this) {
    ExpenseCategory.feed => ExpenseGroup.feed,
    ExpenseCategory.vet || ExpenseCategory.breeding => ExpenseGroup.drugsVet,
    ExpenseCategory.wages => ExpenseGroup.wages,
    ExpenseCategory.transport => ExpenseGroup.transport,
    ExpenseCategory.fuel => ExpenseGroup.fuel,
    ExpenseCategory.equipment || ExpenseCategory.other => ExpenseGroup.other,
  };
}

extension ExpenseGroupCategory on ExpenseGroup {
  /// The category an L02 entry is saved under.
  ExpenseCategory get category => switch (this) {
    ExpenseGroup.feed => ExpenseCategory.feed,
    ExpenseGroup.drugsVet => ExpenseCategory.vet,
    ExpenseGroup.wages => ExpenseCategory.wages,
    ExpenseGroup.transport => ExpenseCategory.transport,
    ExpenseGroup.fuel => ExpenseCategory.fuel,
    ExpenseGroup.other => ExpenseCategory.other,
  };
}

/// One calendar month to date.
class MonthMoney {
  const new({
    required this.month,
    required this.milkIncome,
    required this.litresProduced,
    required this.litresSold,
    required this.expenses,
  });

  final DateTime month;

  /// Sum of the month's milk sales.
  final int milkIncome;
  final double litresProduced;
  final double litresSold;

  /// This month's expenses, newest first.
  final List<Expense> expenses;

  int get income => milkIncome;
  int get totalExpenses => expenses.fold(0, (s, e) => s + e.amount);
  int get profit => income - totalExpenses;

  Map<ExpenseGroup, int> get byGroup {
    final m = <ExpenseGroup, int>{};
    for (final e in expenses) {
      m[e.category.group] = (m[e.category.group] ?? 0) + e.amount;
    }
    return m;
  }

  int? _perLitre(int amount) => litresProduced > 0 ? (amount / litresProduced).round() : null;

  /// All expenses / litres produced this month.
  int? get costPerLitre => _perLitre(totalExpenses);

  /// Feed only (the I01 figure).
  int? get feedPerLitre => _perLitre(byGroup[ExpenseGroup.feed] ?? 0);
}
