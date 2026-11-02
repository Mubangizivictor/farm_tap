// Money (CORE-18): expenses are the single source for every cost the app
// shows (feed cost on I01, L01 overview, L02 add expense, P&L).

enum ExpenseCategory { feed, vet, breeding, wages, transport, equipment, other }

class Expense {
  const new({
    required this.id,
    required this.category,
    required this.amount,
    required this.at,
    this.note,
    this.sourceId,
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
}
