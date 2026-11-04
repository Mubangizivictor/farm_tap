import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/money/domain/money_models.dart';
import 'package:farm_tap/core/money/domain/money_repository.dart';
import 'package:farm_tap/core/sync/record_journal.dart';
import 'package:farm_tap/core/utils/clock.dart';

/// UI phase: in-memory expenses. Feature fakes (feed purchases, AI services,
/// wages) add theirs through [addExpense], so every total has one source.
/// Two expenses entered directly on L02 are seeded here, unless
/// `withSamples` is false (real data).
class FakeMoneyRepository implements MoneyRepository, Restorable {
  new(this.clock, {this.journal, this.withSamples = true}) {
    if (!withSamples) return;
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
  final bool withSamples;
  final List<Expense> _expenses = [];
  final List<Income> _incomes = [];
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
  Future<void> restore() async {
    final j = journal;
    if (j == null) return;
    // Real data: the open farm's records only (another farm may have been
    // open before, and removed expenses must go).
    if (!withSamples) {
      _expenses.clear();
      _incomes.clear();
    }
    for (final r in await j.load('expenses')) {
      if (_expenses.any((e) => e.id == r.id)) continue;
      final b = r.body;
      _expenses.add(
        Expense(
          id: r.id,
          // The web may add categories later; an unknown one shows as Other.
          category: ExpenseCategory.values.asNameMap()[b['category']] ?? ExpenseCategory.other,
          amount: (b['amount']! as num).round(),
          at: DateTime.parse(b['at']! as String),
          note: b['note'] as String?,
          sourceId: b['sourceId'] as String?,
          photo: b['photo'] as String?,
        ),
      );
    }
    for (final r in await j.load('income')) {
      if (_incomes.any((e) => e.id == r.id)) continue;
      final b = r.body;
      _incomes.add(
        Income(
          id: r.id,
          source: IncomeSource.values.asNameMap()[b['source']] ?? IncomeSource.other,
          amount: (b['amount']! as num).round(),
          at: DateTime.parse(b['at']! as String),
          note: b['note'] as String?,
          sourceId: b['sourceId'] as String?,
        ),
      );
    }
  }

  @override
  Future<Result<void>> deleteExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
    await journal?.remove('expenses', id);
    return const Result.success(null);
  }

  @override
  Future<Result<List<Income>>> incomes({DateTime? from, DateTime? to}) async => Result.success(
    _incomes.where((e) => (from == null || !e.at.isBefore(from)) && (to == null || e.at.isBefore(to))).toList()
      ..sort((a, b) => b.at.compareTo(a.at)),
  );

  @override
  Future<Result<Income>> addIncome({
    required IncomeSource source,
    required int amount,
    DateTime? at,
    String? note,
    String? sourceId,
  }) async {
    final e = Income(
      id: journal?.newId() ?? 'income-${_next++}',
      source: source,
      amount: amount,
      at: at ?? clock.now(),
      note: note,
      sourceId: sourceId,
    );
    _incomes.add(e);
    await journal?.add('income', {
      'source': source.name,
      'amount': amount,
      'at': e.at.toIso8601String(),
      'note': note,
      'sourceId': sourceId,
    }, id: e.id);
    return Result.success(e);
  }

  @override
  Future<Result<Expense>> addExpense({
    required ExpenseCategory category,
    required int amount,
    DateTime? at,
    String? note,
    String? sourceId,
    String? photo,
  }) async {
    final e = Expense(
      id: journal?.newId() ?? 'expense-${_next++}',
      category: category,
      amount: amount,
      at: at ?? clock.now(),
      note: note,
      sourceId: sourceId,
      photo: photo,
    );
    _expenses.add(e);
    await journal?.add('expenses', {
      'category': category.name,
      'amount': amount,
      'at': e.at.toIso8601String(),
      'note': note,
      'sourceId': sourceId,
      'photo': photo,
    }, id: e.id);
    return Result.success(e);
  }
}
