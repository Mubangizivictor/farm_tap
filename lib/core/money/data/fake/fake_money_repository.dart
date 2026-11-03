import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/money/domain/money_models.dart';
import 'package:farm_tap/core/money/domain/money_repository.dart';
import 'package:farm_tap/core/sync/record_journal.dart';
import 'package:farm_tap/core/utils/clock.dart';

/// UI phase: in-memory expenses. Feature fakes (feed purchases, AI services,
/// wages) add theirs through [addExpense], so every total has one source.
/// Two expenses entered directly on L02 are seeded here.
class FakeMoneyRepository implements MoneyRepository {
  new(this.clock, {this.journal}) {
    final now = clock.now();
    final today = DateTime(now.year, now.month, now.day);
    _expenses.addAll([
      Expense(
        id: 'expense-${_next++}',
        category: ExpenseCategory.fuel,
        amount: 45000,
        at: today.subtract(const Duration(days: 3, hours: -10)),
        note: 'Diesel — generator',
      ),
      Expense(
        id: 'expense-${_next++}',
        category: ExpenseCategory.vet,
        amount: 60000,
        at: today.subtract(const Duration(days: 1, hours: -11)),
        note: 'Vet visit — Kasheshe',
      ),
    ]);
  }

  final Clock clock;

  /// Saves records on the phone for sync (decision 0014); null in tests.
  final RecordJournal? journal;
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
      id: journal?.newId() ?? 'expense-${_next++}',
      category: category,
      amount: amount,
      at: at ?? clock.now(),
      note: note,
      sourceId: sourceId,
    );
    _expenses.add(e);
    await journal?.add('expenses', {
      'category': category.name,
      'amount': amount,
      'at': e.at.toIso8601String(),
      'note': note,
      'sourceId': sourceId,
    }, id: e.id);
    return Result.success(e);
  }
}
