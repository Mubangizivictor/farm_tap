// FarmTap AI engine: feed and stores (decision 0025). Hand port of
// shared/aiStock.ts.
import 'dart:math' as math;

import 'package:farm_tap/core/ai/ai_core.dart';
import 'package:farm_tap/core/ai/ai_data.dart';

/// The phone's built-in feeds. Custom feeds use their feedTypes record.
const builtInFeeds = <String, ({String name, String unit})>{
  'dairyMeal': (name: 'Dairy meal', unit: 'kg'),
  'maizeBran': (name: 'Maize bran', unit: 'kg'),
  'mineralLick': (name: 'Mineral lick', unit: 'kg'),
  'silage': (name: 'Silage', unit: 'kg'),
  'napierGrass': (name: 'Napier grass', unit: 'kg'),
  'hay': (name: 'Hay', unit: 'bales'),
  'cottonSeedCake': (name: 'Cotton seed cake', unit: 'kg'),
  'brewersWaste': (name: "Brewers' waste", unit: 'kg'),
};

class HeavyDay {
  const new(this.day, this.amount, this.usual);
  final String day;
  final double amount;
  final double usual;
}

class FeedView {
  const new({
    required this.feed,
    required this.name,
    required this.unit,
    required this.left,
    required this.perDay,
    required this.daysLeft,
    required this.runsOut,
    required this.lowAt,
    required this.bought30,
    required this.spent30,
    required this.heavyDays,
    required this.hasCount,
  });
  final String feed;
  final String name;
  final String unit;
  final double left;
  final double perDay;
  final int? daysLeft;
  final String? runsOut;
  final double? lowAt;
  final double bought30;
  final double spent30;
  final List<HeavyDay> heavyDays;
  final bool hasCount;
}

String _s(Object? v) => v is String ? v : '';

List<FeedView> feedViews(FarmData d) {
  final day = today(d);
  final keys = <String>{};
  for (final m in alive(d.stockMoves)) {
    final f = m.str('feed');
    if (f != null && f.isNotEmpty) keys.add(f);
  }
  for (final u in alive(d.feedUses)) {
    final f = u.str('feed');
    if (f != null && f.isNotEmpty) keys.add(f);
  }
  final types = {for (final t in alive(d.feedTypes)) t.id: t};
  return [
    for (final feed in keys)
      () {
        final t = types[feed];
        final built = builtInFeeds[feed];
        final name = built?.name ?? t?.str('name') ?? feed;
        final unit = built?.unit ?? t?.str('unit') ?? 'kg';
        final moves = alive(d.stockMoves).where((m) => m.str('feed') == feed).toList();
        final counts = stableSort(moves.where((m) => m.str('kind') == 'count'), (a, b) {
          final c = (recDay(b, 'at') ?? '').compareTo(recDay(a, 'at') ?? '');
          return c != 0 ? c : _s(b.body['at']).compareTo(_s(a.body['at']));
        });
        final last = counts.isEmpty ? null : counts.first;
        final from = last == null ? '' : _s(last.body['at']);
        var left = last != null ? num0(last.body['amount']) : 0.0;
        for (final m in moves) {
          if (m.str('kind') == 'purchase' && _s(m.body['at']).compareTo(from) > 0) left += num0(m.body['amount']);
        }
        final uses = alive(d.feedUses).where((u) => u.str('feed') == feed).toList();
        for (final u in uses) {
          if (_s(u.body['at']).compareTo(from) > 0) left -= num0(u.body['amount']);
        }
        final byDay = <String, double>{};
        for (final u in uses) {
          final ud = recDay(u, 'at');
          if (ud != null) byDay[ud] = (byDay[ud] ?? 0) + num0(u.body['amount']);
        }
        final recent = byDay.entries
            .where((e) => e.key.compareTo(addDays(day, -14)) > 0 && e.key.compareTo(day) <= 0)
            .toList();
        final perDay = recent.isNotEmpty ? sum(recent.map((e) => e.value)) / 14 : 0.0;
        final daysLeft = perDay > 0 ? (math.max(0, left) / perDay).floor() : null;
        final from30 = addDays(day, -29);
        final bought = moves
            .where((m) => m.str('kind') == 'purchase' && (recDay(m, 'at') ?? '').compareTo(from30) >= 0)
            .toList();
        final heavy = <HeavyDay>[];
        for (final e in recent) {
          final hist = byDay.entries
              .where((h) => h.key.compareTo(e.key) < 0 && h.key.compareTo(addDays(e.key, -30)) >= 0)
              .map((h) => h.value)
              .toList();
          final z = robustZ(e.value, hist, minPoints: 10);
          if (z != null && z >= 3) {
            hist.sort();
            heavy.add(HeavyDay(e.key, round1(e.value), round1(hist.isNotEmpty ? hist[hist.length ~/ 2] : 0)));
          }
        }
        return FeedView(
          feed: feed,
          name: name,
          unit: unit,
          left: round1(left),
          perDay: round1(perDay),
          daysLeft: daysLeft,
          runsOut: daysLeft != null ? addDays(day, daysLeft) : null,
          lowAt: t?.body['lowAt'] != null ? num0(t!.body['lowAt']) : null,
          bought30: round1(sum(bought.map((m) => num0(m.body['amount'])))),
          spent30: jsRound(sum(bought.map((m) => num0(m.body['amount']) * num0(m.body['pricePerUnit'])))),
          heavyDays: heavy,
          hasCount: last != null,
        );
      }(),
  ];
}

class FeedEconomics {
  const new({
    required this.feedSpend30,
    required this.litres30,
    required this.costPerLitre,
    required this.animals,
    required this.costPerAnimalDay,
    required this.litresPer1000,
  });
  final double feedSpend30;
  final double litres30;
  final double? costPerLitre;
  final int animals;
  final double? costPerAnimalDay;
  final double? litresPer1000;
}

FeedEconomics feedEconomics(FarmData d) {
  final day = today(d);
  final from = addDays(day, -29);
  final exp = alive(d.expenses)
      .where(
        (e) =>
            e.str('category') == 'feed' &&
            (recDay(e, 'at') ?? '').compareTo(from) >= 0 &&
            (recDay(e, 'at') ?? '').compareTo(day) <= 0,
      )
      .toList();
  final spend = exp.isNotEmpty ? sum(exp.map((e) => num0(e.body['amount']))) : sum(feedViews(d).map((f) => f.spent30));
  final litres = sum(milkDays(d, 30).map((x) => x.litres));
  final animals = alive(d.animals).where(isActive).length;
  return FeedEconomics(
    feedSpend30: jsRound(spend),
    litres30: round1(litres),
    costPerLitre: litres > 0 && spend > 0 ? jsRound(spend / litres) : null,
    animals: animals,
    costPerAnimalDay: animals > 0 && spend > 0 ? jsRound(spend / animals / 30) : null,
    litresPer1000: spend > 0 ? round1((litres / spend) * 1000) : null,
  );
}

class DrugView {
  const new({
    required this.id,
    required this.name,
    required this.stock,
    required this.unit,
    required this.reorderAt,
    required this.used30,
  });
  final String id;
  final String name;
  final double? stock;
  final String unit;
  final double? reorderAt;
  final int used30;
}

List<DrugView> drugViews(FarmData d) {
  final from = addDays(today(d), -29);
  return [
    for (final s in alive(d.stockItems).where((s) => s.str('kind') == 'drug'))
      DrugView(
        id: s.id,
        name: (s.str('name')?.trim().isNotEmpty ?? false) ? s.str('name')!.trim() : 'Drug',
        stock: s.body['stock'] == null ? null : num0(s.body['stock']),
        unit: s.str('unit') ?? '',
        reorderAt: s.body['reorderAt'] != null
            ? num0(s.body['reorderAt'])
            : s.body['lowAt'] != null
            ? num0(s.body['lowAt'])
            : null,
        used30: alive(d.treatments)
            .where((t) => t.str('drugId') == s.id && (recDay(t, 'given') ?? '').compareTo(from) >= 0)
            .length,
      ),
  ];
}

List<Finding> feedFindings(FarmData d) {
  final day = today(d);
  final out = <Finding>[];
  for (final f in feedViews(d)) {
    final link = [Link(f.name, '/feeds/')];
    if (f.daysLeft != null && f.daysLeft! <= 7) {
      out.add(
        Finding(
          id: 'feed-runout-${f.feed}-$day',
          module: 'feed',
          severity: f.daysLeft! <= 2
              ? Severity.critical
              : f.daysLeft! <= 4
              ? Severity.high
              : Severity.medium,
          title: f.daysLeft == 0
              ? '${f.name} has run out'
              : '${f.name} runs out in about ${plural(f.daysLeft!, 'day')}',
          why:
              '${jsNum(f.left)} ${f.unit} left${f.hasCount ? '' : ' (no stock count yet, from purchases and feedings only)'}; the herd uses about ${jsNum(f.perDay)} ${f.unit} a day (last 14 days).',
          action:
              'Buy ${f.name.toLowerCase()} before ${fmtDay(f.runsOut!)}. About ${(f.perDay * 14).ceil()} ${f.unit} covers two weeks.',
          method: Method.calculated,
          links: link,
          subjects: [f.feed],
        ),
      );
    } else if (f.lowAt != null && f.left <= f.lowAt!) {
      out.add(
        Finding(
          id: 'feed-low-${f.feed}-$day',
          module: 'feed',
          severity: Severity.medium,
          title: '${f.name} is below your reorder level',
          why: '${jsNum(f.left)} ${f.unit} left; you asked to be warned at ${jsNum(f.lowAt!)} ${f.unit}.',
          action: 'Buy ${f.name.toLowerCase()} soon.',
          method: Method.calculated,
          links: link,
          subjects: [f.feed],
        ),
      );
    }
    if (f.left < 0) {
      out.add(
        Finding(
          id: 'feed-negative-${f.feed}-$day',
          module: 'inventory',
          severity: Severity.low,
          title: '${f.name}: more fed than bought',
          why:
              'Feedings since the last count add up to more than the stock (${jsNum(f.left)} ${f.unit}). A purchase may be missing.',
          action: 'Count what is in the store and record the count.',
          method: Method.calculated,
          links: link,
          subjects: [f.feed],
        ),
      );
    }
    for (final h in f.heavyDays) {
      out.add(
        Finding(
          id: 'feed-heavy-${f.feed}-${h.day}',
          module: 'feed',
          severity: Severity.low,
          title: 'Much more ${f.name.toLowerCase()} fed on ${fmtDay(h.day)}',
          why: '${jsNum(h.amount)} ${f.unit} recorded, against a usual ${jsNum(h.usual)} ${f.unit} a day.',
          action: 'Check the entry was typed correctly; if it was, check for waste or theft.',
          method: Method.statistical,
          links: link,
          subjects: [f.feed],
        ),
      );
    }
  }
  final e = feedEconomics(d);
  final all = milkDays(d, 8);
  final last7 = all.sublist(0, all.length - 1).where((x) => x.recorded).map((x) => x.litres).toList();
  if (e.costPerLitre != null && last7.length >= 3) {
    final sale = alive(d.milkSales).where((s) => (recDay(s) ?? '').compareTo(addDays(day, -29)) >= 0).toList();
    final price = sale.isNotEmpty
        ? sum(sale.map((s) => num0(s.body['litres']) * num0(s.body['pricePerLitre']))) /
              math.max(1, sum(sale.map((s) => num0(s.body['litres']))))
        : null;
    if (price != null && price != 0 && e.costPerLitre! >= price * 0.6) {
      out.add(
        Finding(
          id: 'feed-cost-litre-${day.substring(0, 7)}',
          module: 'finance',
          severity: e.costPerLitre! >= price ? Severity.high : Severity.medium,
          title: 'Feed costs ${fmtUgx(e.costPerLitre!)} per litre',
          why:
              'Last 30 days: ${fmtUgx(e.feedSpend30)} on feed for ${fmtL(e.litres30)}. Milk sold for about ${fmtUgx(price)} a litre (${jsRound((e.costPerLitre! / price) * 100).toInt()}% of the price).',
          action: 'Feed the most to the cows giving the most milk, and check bought feed against home-grown fodder.',
          method: Method.calculated,
          links: const [Link('Money', '/money/')],
        ),
      );
    }
  }
  return out;
}

List<Finding> drugFindings(FarmData d) {
  final day = today(d);
  return [
    for (final x in drugViews(d).where((x) => x.stock != null && x.reorderAt != null && x.stock! <= x.reorderAt!))
      Finding(
        id: 'drug-low-${x.id}-$day',
        module: 'inventory',
        severity: x.stock == 0 ? Severity.high : Severity.medium,
        title: x.stock == 0 ? '${x.name} is out of stock' : '${x.name} is low',
        why:
            '${jsNum(x.stock!)} ${x.unit} left; reorder level ${jsNum(x.reorderAt!)} ${x.unit}.${x.used30 > 0 ? ' Used in ${plural(x.used30, 'treatment')} in the last 30 days.' : ''}',
        action: 'Buy more from your drug shop or vet.',
        method: Method.calculated,
        links: const [Link('Drug stock', '/health/')],
        subjects: [x.id],
      ),
  ];
}
