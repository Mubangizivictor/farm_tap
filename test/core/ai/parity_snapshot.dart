// Parity snapshot of the Dart AI engine (lib/core/ai) in the same shape as
// tools/ai_parity/snapshot.mjs makes from the shared TypeScript engine
// (decision 0025). Pure Dart, so it also runs without Flutter.
import 'package:farm_tap/core/ai/ai_access.dart';
import 'package:farm_tap/core/ai/ai_assistant.dart';
import 'package:farm_tap/core/ai/ai_chat.dart';
import 'package:farm_tap/core/ai/ai_core.dart';
import 'package:farm_tap/core/ai/ai_data.dart';
import 'package:farm_tap/core/ai/ai_herd.dart';
import 'package:farm_tap/core/ai/ai_milk.dart';
import 'package:farm_tap/core/ai/ai_money.dart';
import 'package:farm_tap/core/ai/ai_photo.dart';
import 'package:farm_tap/core/ai/ai_reports.dart';
import 'package:farm_tap/core/ai/ai_risk.dart';
import 'package:farm_tap/core/ai/ai_stock.dart';
import 'package:farm_tap/core/ai/ai_vet.dart';

typedef Json = Map<String, Object?>;

String _sev(Severity s) => s.name;
String _method(Method m) => m.name;

List<Object?> _links(List<Link> ls) => [
  for (final l in ls) [l.label, l.href],
];

Json _finding(FindingWithState f) => {
  'id': f.finding.id,
  'module': f.finding.module,
  'severity': _sev(f.finding.severity),
  'title': f.finding.title,
  'why': f.finding.why,
  'action': f.finding.action,
  'method': _method(f.finding.method),
  'links': _links(f.finding.links),
  'subjects': f.finding.subjects,
  'state': f.state,
};

Json _answer(Answer a) => {
  'intent': a.intent,
  'ok': a.ok,
  'text': a.text,
  'bullets': a.bullets,
  'links': _links(a.links),
  'method': _method(a.method),
};

Json _forecast(Forecast f) => {
  'ok': f.ok,
  'reason': f.reason,
  'daysUsed': f.daysUsed,
  'next7': [
    for (final n in f.next7) [n.day, n.litres, n.low, n.high],
  ],
  'total7': f.total7,
  'total30': f.total30,
  'trendPerDay': f.trendPerDay,
  'confidence': f.confidence,
  'method': f.method,
};

Json _breedingState(BreedingState b) => {
  'servedDay': b.servedDay,
  'confirmed': b.confirmed,
  'pregnant': b.pregnant,
  'due': b.due,
  'checkDue': b.checkDue,
  'lastHeat': b.lastHeat,
  'nextHeat': b.nextHeat,
  'calvedDay': b.calvedDay,
  'daysInMilk': b.daysInMilk,
  'servicesSinceCalving': b.servicesSinceCalving,
  'failedServices': b.failedServices,
};

Json _vaccine(VaccineDue v) => {
  'vaccine': v.vaccine,
  'animalIds': v.animalIds,
  'due': v.due,
  'overdueDays': v.overdueDays,
  'doseId': v.doseId,
};

Json _month(MonthMoney m) => {
  'month': m.month,
  'spent': m.spent,
  'milkSales': m.milkSales,
  'otherIncome': m.otherIncome,
  'income': m.income,
  'net': m.net,
  'litres': m.litres,
  'costPerLitre': m.costPerLitre,
  'byCategory': [
    for (final c in m.byCategory) {'category': c.category, 'amount': c.amount},
  ],
};

Json _health(AnimalHealth h) => {
  'animalId': h.animalId,
  'name': h.name,
  'treatments90': h.treatments90,
  'conditions': [
    for (final c in h.conditions) {'condition': c.condition, 'times': c.times, 'last': c.last},
  ],
  'lastTreatment': h.lastTreatment,
  'inWithdrawal': h.inWithdrawal,
  'safeFrom': h.safeFrom,
  'followUp': h.followUp,
  'vaccinesDue': h.vaccinesDue.map(_vaccine).toList(),
  'milkChangePct': h.milkChangePct,
  'breeding': _breedingState(h.breeding),
  'attention': h.attention,
};

const questions = <String>[
  ...suggestedQuestions,
  'milk yesterday',
  'milk in the last 10 days',
  'how much milk last week',
  'profit this month',
  'what is our cost per litre',
  'how many cows do we have',
  'which animals are in withdrawal',
  'what feed is running out',
  'tell me a joke',
  '',
];

const reportTexts = <String>[
  'milk report',
  'milk report for last month',
  'health report last 30 days',
  'profit this month',
  'expenses last month',
  'feed report',
  'breeding report',
  'quality report',
  'inventory',
  'overall performance last week',
  'something unrelated',
];

Json? _report(String text, String day, String role, FarmData d) {
  final req = parseReportRequest(text, day, role);
  if (req == null) return null;
  final r = buildReport(req.kind, req.period, d);
  return {
    'kind': req.kind,
    'period': {'from': req.period.from, 'to': req.period.to, 'label': req.period.label},
    'report': {
      'kind': r.kind,
      'title': r.title,
      'period': {'from': r.period.from, 'to': r.period.to, 'label': r.period.label},
      'summary': r.summary,
      'columns': r.columns,
      'rows': r.rows,
    },
  };
}

/// Everything the phone engine says about one farm.
Json snapshot(FarmData d) {
  final cfg = defaultAiConfig;
  final out = <String, Object?>{};
  for (final role in const ['owner', 'clerk', 'worker']) {
    out['findings_$role'] = allFindings(d, role: role, cfg: cfg).map(_finding).toList();
    out['asks_$role'] = [for (final q in questions) _answer(ask(q, d, role: role, cfg: cfg))];
  }
  final owner = out['findings_owner']! as List<Object?>;
  final states = <String, AlertState>{
    if (owner.isNotEmpty) (owner[0]! as Json)['id']! as String: const AlertState(status: 'acknowledged'),
    if (owner.length > 1) (owner[1]! as Json)['id']! as String: const AlertState(status: 'resolved'),
  };
  out['findings_states'] = allFindings(d, role: 'owner', cfg: cfg, states: states).map(_finding).toList();
  final s = milkSummary(d);
  out['milkSummary'] = {
    'today': s.today,
    'yesterday': s.yesterday,
    'todayRecorded': s.todayRecorded,
    'avg7': s.avg7,
    'avgPrev7': s.avgPrev7,
    'weekChangePct': s.weekChangePct,
    'recordedDays30': s.recordedDays30,
    'monthToDate': s.monthToDate,
    'lastMonthSameDays': s.lastMonthSameDays,
  };
  out['chatFacts'] = [
    for (final a in d.animals)
      [
        a.id,
        animalFacts(
          animalHealth(d, a.id),
          sex: a.str('sex'),
          dairyStatus: a.str('dairyStatus'),
          dateOfBirth: a.str('dateOfBirth'),
          day: today(d),
        ),
      ],
  ];
  out['herdForecast'] = _forecast(herdForecast(d));
  out['cowForecasts'] = [
    for (final a in d.animals) [a.id, _forecast(cowForecast(d, a.id))],
  ];
  out['cowTrends'] = [
    for (final c in cowTrends(d))
      [c.animalId, c.name, c.recent, c.before, c.changePct, c.daysRecent, c.daysBefore, c.daysInMilk],
  ];
  out['anomalies'] = [
    for (final a in milkAnomalies(d)) [a.day, a.litres, a.usual, a.z],
  ];
  final b = milkBalance(d);
  out['balance'] = {
    'days': b.days,
    'produced': b.produced,
    'sold': b.sold,
    'homeUse': b.homeUse,
    'discarded': b.discarded,
    'unaccounted': b.unaccounted,
  };
  out['batches'] = [
    for (final v in batchViews(d))
      [
        v.id,
        v.litres,
        v.place,
        v.collectedAt,
        v.useBy,
        v.hoursLeft,
        v.state,
        v.readings,
        v.highest,
        v.warm,
        v.unverified,
        v.status,
      ],
  ];
  out['breaches'] = [
    for (final t in temperatureBreaches(d)) [t.id, t.place, t.tempC, t.at, t.limit],
  ];
  final q = qualitySummary(d);
  out['quality'] = {
    'deliveries': q.deliveries,
    'litres': q.litres,
    'rejected': q.rejected,
    'rejectedLitres': q.rejectedLitres,
    'notTested': q.notTested,
    'byFarmer': [
      for (final f in q.byFarmer)
        {'farmerId': f.farmerId, 'deliveries': f.deliveries, 'rejected': f.rejected, 'rate': f.rate},
    ],
  };
  out['feedViews'] = [
    for (final f in feedViews(d))
      {
        'feed': f.feed,
        'name': f.name,
        'unit': f.unit,
        'left': f.left,
        'perDay': f.perDay,
        'daysLeft': f.daysLeft,
        'runsOut': f.runsOut,
        'lowAt': f.lowAt,
        'bought30': f.bought30,
        'spent30': f.spent30,
        'heavyDays': [
          for (final h in f.heavyDays) {'day': h.day, 'amount': h.amount, 'usual': h.usual},
        ],
        'hasCount': f.hasCount,
      },
  ];
  final e = feedEconomics(d);
  out['feedEconomics'] = {
    'feedSpend30': e.feedSpend30,
    'litres30': e.litres30,
    'costPerLitre': e.costPerLitre,
    'animals': e.animals,
    'costPerAnimalDay': e.costPerAnimalDay,
    'litresPer1000': e.litresPer1000,
  };
  out['drugs'] = [
    for (final x in drugViews(d))
      {'id': x.id, 'name': x.name, 'stock': x.stock, 'unit': x.unit, 'reorderAt': x.reorderAt, 'used30': x.used30},
  ];
  out['months'] = monthsBack(d, 5).map(_month).toList();
  final c = cashForecast(d);
  out['cash'] = {
    'ok': c.ok,
    'reason': c.reason,
    'month': c.month,
    'income': c.income,
    'spent': c.spent,
    'net': c.net,
    'monthsUsed': c.monthsUsed,
    'method': c.method,
  };
  out['unusual'] = [
    for (final u in unusualExpenses(d))
      {'id': u.id, 'category': u.category, 'amount': u.amount, 'usual': u.usual, 'at': u.at},
  ];
  out['vaccines'] = vaccinesDue(d).map(_vaccine).toList();
  final ci = calvingInterval(d);
  out['calving'] = {'avgDays': ci.avgDays, 'intervals': ci.intervals};
  out['health'] = [
    for (final a in d.animals) [a.id, _health(animalHealth(d, a.id))],
  ];
  final day = today(d);
  out['breeding'] = [
    for (final a in d.animals) [a.id, _breedingState(breedingState(a.id, d.breeding, day))],
  ];
  final reports = <String, Object?>{};
  for (final role in const ['owner', 'worker']) {
    for (final t in reportTexts) {
      reports['$role|$t'] = _report(t, day, role, d);
    }
  }
  out['reports'] = reports;
  return out;
}

Json _vet(VetResult r) => {
  'risk': _sev(r.risk),
  'fever': r.fever,
  'redFlags': r.redFlags,
  'possible': [
    for (final p in r.possible)
      {'key': p.key, 'name': p.name, 'matched': p.matched, 'notifiable': p.notifiable, 'advice': p.advice},
  ],
  'callVet': r.callVet,
  'steps': r.steps,
  'disclaimer': r.disclaimer,
};

List<Json> vetSnapshot(List<Object?> cases) {
  final out = <Json>[];
  for (final raw in cases) {
    final c = (raw! as Map).cast<String, Object?>();
    out.add(
      _vet(
        assess(
          VetInput(
            signs: (c['signs']! as List).cast<String>(),
            tempC: (c['tempC'] as num?)?.toDouble(),
            daysSinceCalving: (c['daysSinceCalving'] as num?)?.toInt(),
            days: (c['days'] as num?)?.toInt(),
          ),
        ),
      ),
    );
  }
  return out;
}

Json? _photo(PhotoResult? r) => r == null
    ? null
    : {
        'usable': r.usable,
        'summary': r.summary,
        'signs': [
          for (final s in r.signs) {'what': s.what, 'where': s.where, 'certainty': s.certainty},
        ],
        'possible': [
          for (final c in r.possible) {'name': c.name, 'why': c.why},
        ],
        'risk': r.risk.name,
        'callVet': r.callVet,
        'report': r.report,
        'steps': r.steps,
        'retake': r.retake,
        'questions': r.questions,
        'removed': r.removed,
        'disclaimer': r.disclaimer,
      };

/// The photo reader on the same model replies as the web engine.
List<Json?> photoSnapshot(List<Object?> cases) {
  final out = <Json?>[];
  for (final raw in cases) {
    final c = (raw! as Map).cast<String, Object?>();
    out.add(_photo(readPhotoReply(c['reply']! as String, photoCheckByKey(c['check']! as String)!)));
  }
  return out;
}

/// The chat reader, animal finder, prompt and saved record, on the web engine's cases.
Json chatSnapshot(List<Object?> replyCases, List<Object?> mentionCases) {
  final replies = <Json>[];
  for (final raw in replyCases) {
    final c = (raw! as Map).cast<String, Object?>();
    final r = readChatReply(c['text']! as String, c['asked']! as String);
    replies.add({
      'text': r.text,
      'removed': r.removed,
      'health': r.health,
      'risk': r.risk.name,
      'callVet': r.callVet,
      'report': r.report,
    });
  }
  final mentions = <Object?>[];
  for (final raw in mentionCases) {
    final c = (raw! as Map).cast<String, Object?>();
    final animals = [
      for (final a in c['animals']! as List)
        Mentionable((a as List)[0]! as String, name: a[1] as String?, tag: a[2] as String?),
    ];
    mentions.add(findAnimalMention(c['message']! as String, animals));
  }
  return {
    'replies': replies,
    'mentions': mentions,
    'prompt': buildChatPrompt(
      message: ' Animal 1  is not\neating ',
      facts: ['A.', 'B.'],
      calculated: 'Milk today: 40 L',
      fileKinds: ['photo', 'pdf'],
    ),
    'body': chatAssessmentBody(
      'bella',
      ' is she  ok? ',
      readChatReply('Watch her closely.', 'is she ok?'),
      ['photo'],
      'm',
      '2026-11-06T09:00:00',
    ),
  };
}

/// The catalog and the prompts, in the same shape as the web engine.
List<List<Object?>> photoCatalog() => [
  for (final c in photoChecks) [c.key, c.label, c.kind.name, c.how, c.focus],
];

List<String> photoPrompts() => [
  for (final c in photoChecks) buildPhotoPrompt(c, note: ' Is it  serious?\n', animal: 'cow', daysSinceCalving: 12),
];

// ---------------------------------------------------------------- Compare

Object? _clean(Object? v) {
  if (v is Map) {
    return {
      for (final e in v.entries)
        if (e.value != null) '${e.key}': _clean(e.value),
    };
  }
  if (v is List) return v.map(_clean).toList();
  return v;
}

/// Differences between two snapshots (empty = the same). A missing key and a
/// null are the same; numbers match within a tiny tolerance.
List<String> diff(Object? expected, Object? actual, [String path = r'$']) {
  final a = _clean(expected);
  final b = _clean(actual);
  final out = <String>[];
  void walk(Object? x, Object? y, String p) {
    if (x is Map && y is Map) {
      for (final k in {...x.keys, ...y.keys}) {
        if (!x.containsKey(k)) {
          out.add('$p.$k: only on the phone: ${y[k]}');
        } else if (!y.containsKey(k)) {
          out.add('$p.$k: missing on the phone (web: ${x[k]})');
        } else {
          walk(x[k], y[k], '$p.$k');
        }
      }
    } else if (x is List && y is List) {
      if (x.length != y.length) out.add('$p: length ${x.length} on the web, ${y.length} on the phone');
      for (var i = 0; i < x.length && i < y.length; i++) {
        walk(x[i], y[i], '$p[$i]');
      }
    } else if (x is num && y is num) {
      if ((x - y).abs() > 1e-9 * (1 + x.abs())) out.add('$p: web $x, phone $y');
    } else if (x != y) {
      out.add('$p: web "$x", phone "$y"');
    }
  }

  walk(a, b, path);
  return out;
}
