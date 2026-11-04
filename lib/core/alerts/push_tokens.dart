import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Lets the server's daily reminder job reach this phone (decision 0024):
/// the phone's push token is kept at users/{uid}/devices/{deviceId}. Push
/// itself only goes out once the server job is switched on; until then the
/// phone shows its own reminders (FarmReminders).
class PushTokens {
  new({required this.deviceId, this.db, this.messaging});

  final String deviceId;
  final FirebaseFirestore? db;
  final FirebaseMessaging? messaging;
  StreamSubscription<String>? _refresh;

  Future<void> register(String uid) async {
    if (kIsWeb || uid.isEmpty || !(Platform.isAndroid || Platform.isIOS)) return;
    try {
      final m = messaging ?? FirebaseMessaging.instance;
      if (Platform.isIOS) await m.requestPermission();
      // The server sends to FCM tokens, so keep the token API for now.
      // ignore: deprecated_member_use
      final token = await m.getToken();
      if (token != null) await _save(uid, token);
      await _refresh?.cancel();
      // Same reason: token refreshes, not installation ids.
      // ignore: deprecated_member_use
      _refresh = m.onTokenRefresh.listen((t) => unawaited(_save(uid, t)));
    } on Object catch (e) {
      // No Play services, no network, or push not set up: reminders still
      // show from the phone itself.
      debugPrint('Push token not saved: $e');
    }
  }

  Future<void> _save(String uid, String token) =>
      (db ?? FirebaseFirestore.instance).doc('users/$uid/devices/$deviceId').set({
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'app': 'farmtap',
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// Signing out: this phone stops getting the account's reminders.
  Future<void> forget(String uid) async {
    await _refresh?.cancel();
    if (kIsWeb || uid.isEmpty) return;
    try {
      await (db ?? FirebaseFirestore.instance).doc('users/$uid/devices/$deviceId').delete();
    } on Object {
      // Offline: the server drops tokens that stop working.
    }
  }
}
