// Farm reminders (decision 0024): the same rules as shared/alerts.ts, which
// the server's daily job uses. The ids match, so a reminder the phone shows
// or queues is never sent a second time by the server.
//
// Keep this file and shared/alerts.ts in step; test/core/alerts covers the
// same cases as functions/src/launch.test.ts.

class FarmAlert {
  const new({required this.id, required this.kind, required this.title, required this.body, this.staffIds = const []});

  /// kind-yyyy-mm-dd-subject.
  final String id;

  /// duty | vaccination | calving | pregnancyCheck | heat | trial | plan
  final String kind;
  final String title;
  final String body;

  /// Staff ids it is for; empty = the owner and managers.
  final List<String> staffIds;

  /// The SMS / WhatsApp text.
  String text(String farmName) {
    final t = 'FarmTap $farmName: $title. $body';
    return t.length > 300 ? t.substring(0, 300) : t;
  }
}

class AlertSettings {
  const new({
    this.duties = true,
    this.vaccinations = true,
    this.calving = true,
    this.trial = true,
    this.push = true,
    this.sms = false,
    this.whatsapp = true,
    this.hour = 6,
  });

  factory fromBody(Map<String, Object?>? b) {
    bool v(String k, {required bool d}) => b?[k] is bool ? b![k]! as bool : d;
    final h = b?['hour'];
    return AlertSettings(
      duties: v('duties', d: true),
      vaccinations: v('vaccinations', d: true),
      calving: v('calving', d: true),
      trial: v('trial', d: true),
      push: v('push', d: true),
      sms: v('sms', d: false),
      whatsapp: v('whatsapp', d: true),
      hour: h is num && h >= 0 && h <= 23 ? h.round() : 6,
    );
  }

  final bool duties;
  final bool vaccinations;
  final bool calving;
  final bool trial;
  final bool push;
  final bool sms;
  final bool whatsapp;
  final int hour;

  AlertSettings copyWith({
    bool? duties,
    bool? vaccinations,
    bool? calving,
    bool? trial,
    bool? push,
    bool? sms,
    bool? whatsapp,
    int? hour,
  }) => AlertSettings(
    duties: duties ?? this.duties,
    vaccinations: vaccinations ?? this.vaccinations,
    calving: calving ?? this.calving,
    trial: trial ?? this.trial,
    push: push ?? this.push,
    sms: sms ?? this.sms,
    whatsapp: whatsapp ?? this.whatsapp,
    hour: hour ?? this.hour,
  );

  Map<String, Object?> toBody() => {
    'duties': duties,
    'vaccinations': vaccinations,
    'calving': calving,
    'trial': trial,
    'push': push,
    'sms': sms,
    'whatsapp': whatsapp,
    'hour': hour,
  };
}

/// One record as the rules need it.
class AlertRec {
  const new(this.id, this.body, {this.isDeleted = false});
  final String id;
  final Map<String, Object?> body;
  final bool isDeleted;
}

class AlertInput {
  const new({
    required this.today,
    this.duties = const [],
    this.absences = const [],
    this.vaccinations = const [],
    this.breeding = const [],
    this.animals = const [],
    this.staffNames = const {},
    this.trialEndsAt,
    this.paidUntil,
    this.settings = const AlertSettings(),
  });

  /// yyyy-mm-dd, Kampala.
  final String today;
  final List<AlertRec> duties;
  final List<AlertRec> absences;
  final List<AlertRec> vaccinations;
  final List<AlertRec> breeding;
  final List<AlertRec> animals;
  final Map<String, String> staffNames;
  final String? trialEndsAt;
  final String? paidUntil;
  final AlertSettings settings;
}

const gestationDays = 283;
const heatCycleDays = 21;
const pregnancyCheckDays = 60;

String? dayOf(Object? iso) =>
    iso is String && RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(iso) ? iso.substring(0, 10) : null;
DateTime _utc(String day) =>
    DateTime.utc(int.parse(day.substring(0, 4)), int.parse(day.substring(5, 7)), int.parse(day.substring(8, 10)));
String addDays(String day, int n) => _utc(day).add(Duration(days: n)).toIso8601String().substring(0, 10);
int daysBetween(String from, String to) => (_utc(to).difference(_utc(from)).inHours / 24).round();

/// 0 = Sunday, like the web.
int _weekday(String day) => _utc(day).weekday % 7;

const dutyNames = {
  'milking': 'Milking',
  'feeding': 'Feeding',
  'health': 'Animal health',
  'cleaning': 'Cleaning the shed',
  'grazing': 'Grazing and water',
  'security': 'Night watch',
  'collection': 'Taking milk to the centre',
  'manager': 'In charge of the farm',
};
const _shiftNames = {
  'morning': 'morning',
  'afternoon': 'afternoon',
  'evening': 'evening',
  'night': 'night',
  'allDay': 'all day',
};

String _plural(int n, String word) => '$n $word${n == 1 ? '' : 's'}';
String? _str(Object? v) => v is String && v.trim().isNotEmpty ? v.trim() : null;

String _animalName(List<AlertRec> animals, String? id) {
  final a = animals.where((x) => x.id == id).firstOrNull;
  if (a == null) return 'A cow';
  final name = _str(a.body['name']);
  final tag = _str(a.body['tagNumber']);
  if (name != null && tag != null) return '$name ($tag)';
  return name ?? (tag != null ? 'Tag $tag' : 'A cow');
}

/// Everything due today, in a stable order (shared/alerts.ts alertsFor).
List<FarmAlert> alertsFor(AlertInput input) {
  final today = input.today;
  final s = input.settings;
  final out = <FarmAlert>[];
  List<AlertRec> alive(List<AlertRec> rs) => rs.where((r) => !r.isDeleted).toList();

  if (s.duties) {
    final away = <String>{
      for (final a in alive(input.absences))
        if (dayOf(a.body['from']) case final from?)
          if (from.compareTo(today) <= 0 && today.compareTo(dayOf(a.body['to']) ?? from) <= 0) '${a.body['staffId']}',
    };
    for (final d in alive(input.duties)) {
      final days = [
        for (final x in (d.body['days'] as List?) ?? const [])
          if (x is num) x.toInt(),
      ];
      if (days.isNotEmpty && !days.contains(_weekday(today))) continue;
      final staffId = '${d.body['staffId'] ?? ''}';
      final standIn = _str(d.body['standInId']);
      String? who = staffId;
      var covering = false;
      if (away.contains(staffId)) {
        who = standIn != null && !away.contains(standIn) ? standIn : null;
        covering = who != null;
      }
      final activity = '${d.body['activity'] ?? ''}';
      final job = activity == 'other' ? (_str(d.body['label']) ?? 'Farm duty') : (dutyNames[activity] ?? activity);
      final shift = _shiftNames[d.body['shift'] ?? 'allDay'] ?? '';
      if (who == null) {
        out.add(
          FarmAlert(
            id: 'duty-$today-${d.id}-nobody',
            kind: 'duty',
            title: 'Nobody on ${job.toLowerCase()} today',
            body:
                '${input.staffNames[staffId] ?? 'The person on duty'} is away and there is no stand-in. Choose someone in the duty roster.',
          ),
        );
        continue;
      }
      final name = input.staffNames[who] ?? '';
      out.add(
        FarmAlert(
          id: 'duty-$today-${d.id}',
          kind: 'duty',
          title: '$job today${shift.isNotEmpty ? ', $shift' : ''}',
          body: covering
              ? '${name.isEmpty ? 'You' : name}: you stand in for ${input.staffNames[staffId] ?? 'a colleague'} today (${job.toLowerCase()}).'
              : '${name.isEmpty ? 'You' : name}: you are on ${job.toLowerCase()} today${shift.isNotEmpty ? ' ($shift)' : ''}.',
          staffIds: [who],
        ),
      );
    }
  }

  if (s.vaccinations) {
    final vs = alive(input.vaccinations);
    for (final v in vs) {
      final due = dayOf(v.body['nextDue']);
      if (due == null) continue;
      final gap = daysBetween(today, due);
      if (gap > 1 || gap < -7) continue;
      final vaccine = '${v.body['vaccine'] ?? ''}';
      final later = vs.any(
        (o) => o.id != v.id && o.body['vaccine'] == vaccine && (dayOf(o.body['nextDue']) ?? '').compareTo(due) > 0,
      );
      if (later) continue;
      final ids = (v.body['animalIds'] as List?) ?? const [];
      final who = ids.isNotEmpty ? _plural(ids.length, 'animal') : 'the whole herd';
      out.add(
        FarmAlert(
          id: 'vaccination-$today-${v.id}',
          kind: 'vaccination',
          title: gap < 0
              ? '$vaccine is overdue'
              : gap == 0
              ? '$vaccine is due today'
              : '$vaccine is due tomorrow',
          body: 'Vaccinate $who${gap < 0 ? ' (due ${_plural(-gap, 'day')} ago)' : ''}. Call the vet if you need one.',
        ),
      );
    }
  }

  if (s.calving) {
    final events = alive(input.breeding)
      ..sort((a, c) => (dayOf(c.body['at']) ?? '').compareTo(dayOf(a.body['at']) ?? ''));
    final ids = <String>[];
    for (final e in events) {
      final id = _str(e.body['animalId']);
      if (id != null && !ids.contains(id)) ids.add(id);
    }
    for (final id in ids) {
      final a = input.animals.where((x) => x.id == id).firstOrNull;
      final status = _str(a?.body['status']);
      if (a != null && (a.isDeleted || (status != null && status != 'active'))) continue;
      final mine = events.where((e) => e.body['animalId'] == id).toList();
      final served = mine
          .where((e) => (e.body['type'] == 'ai' || e.body['type'] == 'service') && e.body['kind'] != 'heat')
          .firstOrNull;
      final calved = mine.where((e) => e.body['type'] == 'calving').firstOrNull;
      final heat = mine.where((e) => e.body['type'] == 'service' && e.body['kind'] == 'heat').firstOrNull;
      final servedDay = served == null ? null : dayOf(served.body['at']);
      final open =
          served != null &&
              servedDay != null &&
              (calved == null || (dayOf(calved.body['at']) ?? '').compareTo(servedDay) < 0)
          ? served
          : null;
      final check = open == null
          ? null
          : events.where((e) => e.body['type'] == 'pregnancyCheck' && e.body['serviceId'] == open.id).firstOrNull;
      final result = check == null ? null : check.body['pregnant'] == true; // null = not checked yet
      final name = _animalName(input.animals, id);
      if (open != null && servedDay != null && result != false) {
        final due = addDays(servedDay, gestationDays);
        final gap = daysBetween(today, due);
        if (gap == 7 || gap == 1 || gap == 0 || (gap < 0 && gap >= -3)) {
          out.add(
            FarmAlert(
              id: 'calving-$today-$id',
              kind: 'calving',
              title: gap > 0
                  ? '$name calves in ${_plural(gap, 'day')}'
                  : gap == 0
                  ? '$name is due to calve today'
                  : '$name was due to calve ${_plural(-gap, 'day')} ago',
              body: gap > 1
                  ? 'Move her to the calving place and prepare clean bedding.'
                  : 'Check on her often today. Call the vet if calving is difficult.',
            ),
          );
        }
        if (result == null && daysBetween(servedDay, today) == pregnancyCheckDays) {
          out.add(
            FarmAlert(
              id: 'pregnancyCheck-$today-$id',
              kind: 'pregnancyCheck',
              title: 'Pregnancy check for $name',
              body: 'It is $pregnancyCheckDays days since she was served. Ask the vet to check her.',
            ),
          );
        }
        continue;
      }
      final candidates = [
        if (heat != null) dayOf(heat.body['at']),
        if (result == false) servedDay,
        if (calved != null) dayOf(calved.body['at']),
      ].whereType<String>().toList()..sort();
      final last = candidates.lastOrNull;
      if (last != null && daysBetween(last, today) > 0 && daysBetween(last, today) % heatCycleDays == 0) {
        out.add(
          FarmAlert(
            id: 'heat-$today-$id',
            kind: 'heat',
            title: '$name may come on heat today',
            body: 'Watch her this morning and evening. Record the heat and call the AI technician.',
          ),
        );
      }
    }
  }

  if (s.trial) {
    final paid = dayOf(input.paidUntil);
    final trial = dayOf(input.trialEndsAt);
    final paidAhead = paid != null && paid.compareTo(today) > 0;
    final ends = paidAhead ? paid : (trial != null && trial.compareTo(today) > 0 && paid == null ? trial : null);
    if (ends != null) {
      final left = daysBetween(today, ends);
      if (left == 3 || left == 1) {
        final isTrial = ends == trial && !paidAhead;
        out.add(
          FarmAlert(
            id: '${isTrial ? 'trial' : 'plan'}-$today',
            kind: isTrial ? 'trial' : 'plan',
            title: isTrial
                ? 'Free trial ends in ${_plural(left, 'day')}'
                : 'FarmTap plan ends in ${_plural(left, 'day')}',
            body: 'Choose a plan and pay to keep recording. Your records stay safe.',
          ),
        );
      }
    }
  }
  return out;
}
