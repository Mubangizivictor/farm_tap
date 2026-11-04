// Money (CORE-18): expenses are the single source for every cost the app
// shows (feed cost on I01, L01 overview, L02 add expense, P&L).

enum ExpenseCategory { feed, vet, breeding, wages, transport, fuel, equipment, other }

class Expense {
  const new({
    required this.id,
    required this.category,
    required this.amount,
    required this.at,
    this.note,
    this.sourceId,
    this.photo,
  });

  final String id;
  final ExpenseCategory category;

  /// UGX.
  final int amount;
  final DateTime at;
  final String? note;

  /// The record that created it (a feed purchase id), or null when entered
  /// on L02 directly.
  final String? sourceId;

  /// Receipt photo key (PhotoStore), if one was taken.
  final String? photo;
}

/// Where money other than milk sales came from.
enum IncomeSource { animalSale, manure, calfSale, hire, other }

/// Farm income that is not a milk sale (milk sales live in the milk records).
class Income {
  const new({required this.id, required this.source, required this.amount, required this.at, this.note, this.sourceId});

  final String id;
  final IncomeSource source;

  /// UGX.
  final int amount;
  final DateTime at;
  final String? note;

  /// The record that created it (an animal sold), if any.
  final String? sourceId;
}
