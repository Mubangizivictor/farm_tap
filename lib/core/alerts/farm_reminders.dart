import 'dart:async';
import 'dart:io' show Platform;

import 'package:farm_tap/core/alerts/alert_rules.dart';
import 'package:farm_tap/core/sms/sms_outbox.dart';
import 'package:farm_tap/core/sync/domain/sync_record.dart';
import 'package:farm_tap/core/sync/record_journal.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Who is using the phone, for picking which reminders to show.
class ReminderViewer {
  const new({required this.farmName, this.staffId, this.manages = true, this.trialEndsAt, this.paidUntil});

  final String farmName;

  /// The unlocked worker; null for the owner's or a manager's own account.
  final String? staffId;

  /// Owners and managers see every reminder and queue messages for workers.
  final bool manages;
  final DateTime? trialEndsAt;
  final DateTime? paidUntil;
}

/// Farm reminders on the phone (decision 0024).
///
/// The phone works out today's reminders from its own records (the same
/// rules as the server, lib/core/alerts/alert_rules.dart), shows them as
/// notifications once, and, on an owner's or manager's phone, puts a
/// WhatsApp or SMS for each worker in "Messages to send" (free, sent from
/// the phone, decision 0015). Message ids match the server's (`alert-<id>`),
/// so when the server job is switched on nothing is sent twice.
class FarmReminders {
  new({required this.journal, required this.clock, this.outbox, this.prefs, this._plugin});

  final RecordJournal journal;
  final Clock clock;
  final SmsOutbox? outbox;
  final SharedPreferences? prefs;
  FlutterLocalNotificationsPlugin? _plugin;
  bool _ready = false;

  static const channelId = 'farm_reminders';
  static const _shownKey = 'reminders.shown';

  Future<List<AlertRec>> _load(String c) async {
    try {
      return [for (final SyncRecord r in await journal.load(c)) AlertRec(r.id, r.body, isDeleted: r.isDeleted)];
    } on Object {
      return const [];
    }
  }

  Future<AlertSettings> settings() async {
    final s = (await _load('settings')).where((r) => r.id == 'alerts').firstOrNull;
    return AlertSettings.fromBody(s?.body);
  }

  Future<void> saveSettings(AlertSettings s) => journal.put('settings', 'alerts', s.toBody());

  /// Everything due today for the farm.
  Future<List<FarmAlert>> today(ReminderViewer v, {AlertSettings? override}) async {
    final r = await Future.wait([
      _load('duties'),
      _load('absences'),
      _load('vaccinations'),
      _load('breedingEvents'),
      _load('animals'),
      _load('staff'),
    ]);
    final s = override ?? await settings();
    String? iso(DateTime? d) => d?.toIso8601String();
    return alertsFor(
      AlertInput(
        today: _day(clock.now()),
        duties: r[0],
        absences: r[1],
        vaccinations: r[2],
        breeding: r[3],
        animals: r[4],
        staffNames: {for (final x in r[5]) x.id: '${x.body['name'] ?? ''}'},
        trialEndsAt: iso(v.trialEndsAt),
        paidUntil: iso(v.paidUntil),
        settings: s,
      ),
    );
  }

  /// The reminders this person should see.
  List<FarmAlert> forViewer(List<FarmAlert> all, ReminderViewer v) =>
      v.manages ? all : all.where((a) => a.staffIds.contains(v.staffId)).toList();

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<bool> _init() async {
    if (_ready) return true;
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return false;
    try {
      _plugin ??= FlutterLocalNotificationsPlugin();
      await _plugin!.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _ready = true;
    } on Object catch (e) {
      debugPrint('Reminders not available: $e');
    }
    return _ready;
  }

  /// Asks to show notifications (Android 13+, iOS). Returns true when allowed.
  Future<bool> askPermission() async {
    if (!await _init()) return false;
    try {
      final android = _plugin!.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) return await android.requestNotificationsPermission() ?? false;
      final ios = _plugin!.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    } on Object {
      return false;
    }
  }

  /// Runs after the farm opens and after each sync: shows today's new
  /// reminders once (after the farm's reminder hour) and queues messages.
  Future<void> run(ReminderViewer v) async {
    final s = await settings();
    if (clock.now().hour < s.hour) return;
    final all = await today(v, override: s);
    final mine = forViewer(all, v);
    if (s.push) await _show(mine);
    if (v.manages && (s.whatsapp || s.sms)) await _queue(all, v, s);
  }

  Future<void> _show(List<FarmAlert> alerts) async {
    if (alerts.isEmpty || !await _init()) return;
    final shown = {...?prefs?.getStringList(_shownKey)};
    for (final a in alerts) {
      if (shown.contains(a.id)) continue;
      try {
        await _plugin!.show(
          id: a.id.hashCode & 0x7fffffff,
          title: a.title,
          body: a.body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              channelId,
              'Farm reminders',
              channelDescription: 'Duties, vaccinations, calving and your plan',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          payload: a.kind,
        );
        shown.add(a.id);
      } on Object catch (e) {
        debugPrint('Reminder not shown: $e');
      }
    }
    // Keep only the last two weeks of ids.
    final cutoff = _day(clock.now().subtract(const Duration(days: 14)));
    final keep = shown.where((id) {
      final m = RegExp(r'(\d{4}-\d{2}-\d{2})').firstMatch(id);
      return m == null || m.group(1)!.compareTo(cutoff) >= 0;
    }).toList();
    await prefs?.setStringList(_shownKey, keep);
  }

  Future<void> _queue(List<FarmAlert> alerts, ReminderViewer v, AlertSettings s) async {
    final box = outbox;
    if (box == null) return;
    final staff = await _load('staff');
    for (final a in alerts) {
      if (a.staffIds.isEmpty) continue;
      final person = staff.where((x) => x.id == a.staffIds.first).firstOrNull;
      final phone = '${person?.body['phone'] ?? ''}';
      if (phone.trim().isEmpty) continue;
      final id = 'alert-${a.id}';
      if (await box.find(id) != null) continue;
      await box.queue(
        to: phone,
        text: a.text(v.farmName),
        kind: s.whatsapp ? 'whatsapp' : 'sms',
        id: id,
        name: '${person?.body['name'] ?? ''}',
      );
    }
  }
}
