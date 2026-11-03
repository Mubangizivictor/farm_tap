import 'dart:math';

import 'package:farm_tap/core/error/failure.dart';
import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/people/domain/card_registry.dart';
import 'package:farm_tap/core/sync/record_journal.dart';

/// The farm's cards, saved as `nfcCards` records (id = card number) so every
/// farm phone knows who holds which card, offline (decision 0016 §1).
class LocalCardRegistry implements CardRegistry, Restorable {
  new({
    required this.now,
    this.journal,
    this.tenantId,
    Random? random,
    List<IdCardRecord> seed = const [],
    List<String> blankStock = const [],
  }) : _random = random ?? Random.secure(),
       _blank = [...blankStock] {
    for (final c in seed) {
      _cards[c.number] = c;
    }
  }

  final DateTime Function() now;
  final RecordJournal? journal;

  /// The open farm (QR codes from another farm are refused); null skips it.
  final String Function()? tenantId;
  final Random _random;
  final Map<String, IdCardRecord> _cards = {};

  /// Pre-printed blank cards in stock (handed out before random numbers).
  final List<String> _blank;

  static const collection = 'nfcCards';

  /// Sample cards (demo build); a number already in the register is kept.
  void seed(Iterable<IdCardRecord> sample) {
    for (final c in sample) {
      _cards.putIfAbsent(c.number, () => c);
    }
  }

  @override
  Future<void> restore() async {
    final j = journal;
    if (j == null) return;
    for (final r in await j.load(collection)) {
      final c = fromBody(r.id, r.body);
      if (c != null) _cards[c.number] = c;
    }
    _blank.removeWhere(_cards.containsKey);
  }

  static IdCardRecord? fromBody(String number, Map<String, Object?> b) {
    final holder = b['personId'] as String?;
    if (holder == null) return null;
    DateTime? date(Object? v) => v is String ? DateTime.tryParse(v) : null;
    return IdCardRecord(
      number: number,
      chipId: b['chipId'] as String?,
      holderId: holder,
      holderKind: b['personType'] == 'farmer' ? CardHolderKind.farmer : CardHolderKind.staff,
      holderName: b['personName'] as String? ?? '',
      status: CardStatus.values.asNameMap()[b['status']] ?? CardStatus.active,
      issuedAt: date(b['issuedAt']),
      endedAt: date(b['endedAt']),
    );
  }

  static Map<String, Object?> toBody(IdCardRecord c) => {
    'personId': c.holderId,
    'personType': c.holderKind.name,
    'personName': c.holderName,
    'status': c.status.name,
    'chipId': c.chipId,
    'issuedAt': c.issuedAt?.toIso8601String(),
    'endedAt': c.endedAt?.toIso8601String(),
  };

  Future<void> _save(IdCardRecord c) async {
    _cards[c.number] = c;
    await journal?.put(collection, c.number, toBody(c));
  }

  /// "142", "FT 0142" -> "0142"; null when it is not a typed number.
  static String? _number(String s) {
    final t = s.trim();
    if (!RegExp(r'^[A-Za-z ]*\d{1,4}$').hasMatch(t)) return null;
    return t.replaceAll(RegExp(r'\D'), '').padLeft(4, '0');
  }

  /// What was read, as (card number, chip id); exactly one is set.
  (String?, String?) _parse(String scanned) {
    final qr = CardQr.decode(scanned);
    if (qr != null) return (qr.$2, null);
    final n = _number(scanned);
    if (n != null) return (n, null);
    return (null, scanned.trim().toUpperCase());
  }

  bool _otherFarm(String scanned) {
    final qr = CardQr.decode(scanned);
    final t = tenantId?.call();
    return qr != null && t != null && t.isNotEmpty && qr.$1 != t;
  }

  IdCardRecord? _find(String scanned) {
    final (number, chip) = _parse(scanned);
    if (number != null) return _cards[number];
    return _cards.values.where((c) => c.chipId == chip).firstOrNull;
  }

  @override
  Future<Result<IdCardRecord?>> lookup(String scanned) async {
    if (_otherFarm(scanned)) return const Result.failure(ValidationFailure(CardIssueError.otherFarm));
    return Result.success(_find(scanned));
  }

  @override
  Future<Result<IdCardRecord?>> activeCardOf(String holderId) async =>
      Result.success(_cards.values.where((c) => c.holderId == holderId && c.active).firstOrNull);

  @override
  Future<Result<List<IdCardRecord>>> historyOf(String holderId) async =>
      Result.success(_newestFirst(_cards.values.where((c) => c.holderId == holderId)));

  @override
  Future<Result<List<IdCardRecord>>> cards() async => Result.success(_newestFirst(_cards.values));

  static List<IdCardRecord> _newestFirst(Iterable<IdCardRecord> cards) {
    final epoch = DateTime(2000);
    return [...cards]..sort((a, b) => (b.issuedAt ?? epoch).compareTo(a.issuedAt ?? epoch));
  }

  /// A pre-printed blank card if any, else a random free number 1000-9999.
  String _freeNumber() {
    final blank = _blank.where((n) => !_cards.containsKey(n)).firstOrNull;
    if (blank != null) return blank;
    while (true) {
      final n = (1000 + _random.nextInt(9000)).toString();
      if (!_cards.containsKey(n)) return n;
    }
  }

  /// The next card number to print (a blank in stock, else a new one).
  String nextNumber() => _freeNumber();

  /// The next pre-printed blank card in stock, or null when none is left.
  String? nextBlank() => _blank.where((n) => !_cards.containsKey(n)).firstOrNull;

  @override
  Future<Result<IdCardRecord>> issue({
    required String holderId,
    required CardHolderKind kind,
    required String holderName,
    String? scanned,
    bool replace = false,
  }) async {
    if (scanned != null && _otherFarm(scanned)) {
      return const Result.failure(ValidationFailure(CardIssueError.otherFarm));
    }
    final existing = scanned == null ? null : _find(scanned);
    if (existing != null) {
      if (existing.status == CardStatus.lost) return const Result.failure(ValidationFailure(CardIssueError.lost));
      if (existing.active && existing.holderId == holderId) return Result.success(existing);
      if (existing.active) {
        return Result.failure(ValidationFailure('${CardIssueError.taken}:${existing.holderName}'));
      }
    }
    final current = _cards.values.where((c) => c.holderId == holderId && c.active).firstOrNull;
    if (current != null && !replace) return const Result.failure(ValidationFailure(CardIssueError.hasCard));
    final at = now();
    if (current != null) await _save(current.ended(CardStatus.lost, at));
    final String number;
    String? chip;
    if (existing != null) {
      number = existing.number;
      chip = existing.chipId;
    } else if (scanned == null) {
      number = _freeNumber();
    } else {
      final (n, c) = _parse(scanned);
      number = n ?? _freeNumber();
      chip = c;
    }
    final card = IdCardRecord(
      number: number,
      chipId: chip,
      holderId: holderId,
      holderKind: kind,
      holderName: holderName,
      status: CardStatus.active,
      issuedAt: at,
    );
    _blank.remove(number);
    await _save(card);
    return Result.success(card);
  }

  @override
  Future<Result<IdCardRecord>> revoke(String number, CardStatus why) async {
    final c = _cards[number];
    if (c == null) return const Result.failure(ValidationFailure('card-unknown'));
    if (!c.active) return Result.success(c);
    final ended = c.ended(why == CardStatus.active ? CardStatus.returned : why, now());
    await _save(ended);
    return Result.success(ended);
  }

  /// Keeps the holder's name on their cards current after a rename.
  Future<void> renameHolder(String holderId, String name) async {
    for (final c in [..._cards.values.where((c) => c.holderId == holderId && c.holderName != name)]) {
      await _save(
        IdCardRecord(
          number: c.number,
          chipId: c.chipId,
          holderId: c.holderId,
          holderKind: c.holderKind,
          holderName: name,
          status: c.status,
          issuedAt: c.issuedAt,
          endedAt: c.endedAt,
        ),
      );
    }
  }
}
