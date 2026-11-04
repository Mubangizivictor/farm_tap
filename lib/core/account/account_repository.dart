// The person's own account (decision 0024): their profile photo, and
// closing the account. Closing works at once for the person, but the
// records are kept for 90 days so FarmTap support can bring them back. The
// same writes as the web (webapp/src/lib/account.ts) and the same rules.

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Days support can still restore a closed account.
const accountHoldDays = 90;

/// A closed account: when, and the last day it can be restored.
class AccountClosure {
  const new({this.at});

  final DateTime? at;

  DateTime? get restoreBy => at?.add(const Duration(days: accountHoldDays));
}

class AccountProfile {
  const new({this.closed, this.photo});

  /// Null while the account is open.
  final AccountClosure? closed;

  /// The small saved copy (base64 JPEG, no data: prefix), for avatars.
  final String? photo;
}

/// Turns a stored picture (`data:image/jpeg;base64,...` or plain base64)
/// into the base64 the avatars read.
String? photoBase64(Object? v) {
  if (v is! String || v.isEmpty) return null;
  final i = v.indexOf('base64,');
  return i >= 0 ? v.substring(i + 7) : v;
}

abstract interface class AccountRepository {
  Future<AccountProfile> profile(String uid);

  /// Saves a small picture (already shrunk JPEG bytes) as the person's photo.
  Future<String?> savePhoto(String uid, Uint8List jpeg);
  Future<void> removePhoto(String uid);

  /// Closes the account and every farm it owns. Returns the farms closed.
  Future<List<String>> close({required String uid, required String email, required String name, String reason = ''});
}

class FirebaseAccountRepository implements AccountRepository {
  new({this.db, this.storage});

  final FirebaseFirestore? db;
  final FirebaseStorage? storage;

  FirebaseFirestore get _db => db ?? FirebaseFirestore.instance;

  DateTime? _date(Object? v) => v is Timestamp ? v.toDate() : null;

  @override
  Future<AccountProfile> profile(String uid) async {
    final d = (await _db.doc('users/$uid').get()).data() ?? const <String, Object?>{};
    final deletion = d['deletion'];
    final photo = d['photo'];
    return AccountProfile(
      closed: deletion is Map ? AccountClosure(at: _date(deletion['at'])) : null,
      photo: photo is Map ? photoBase64(photo['thumb']) : null,
    );
  }

  @override
  Future<String?> savePhoto(String uid, Uint8List jpeg) async {
    final thumb = 'data:image/jpeg;base64,${base64Encode(jpeg)}';
    String? url;
    try {
      // Works once cloud storage is switched on (Blaze); the small copy is
      // enough until then.
      final ref = (storage ?? FirebaseStorage.instance).ref('profiles/$uid/photo.jpg');
      await ref
          .putData(jpeg, SettableMetadata(contentType: 'image/jpeg'))
          .timeout(const Duration(seconds: 20)); // theme-guard: ignore
      url = await ref.getDownloadURL();
    } on Object catch (e) {
      debugPrint('Profile photo kept on the account only: $e');
    }
    await _db.doc('users/$uid').update({
      'photo': {'thumb': thumb, 'url': url, 'updatedAt': FieldValue.serverTimestamp()},
    });
    return photoBase64(thumb);
  }

  @override
  Future<void> removePhoto(String uid) => _db.doc('users/$uid').update({'photo': FieldValue.delete()});

  @override
  Future<List<String>> close({
    required String uid,
    required String email,
    required String name,
    String reason = '',
  }) async {
    final user = (await _db.doc('users/$uid').get()).data() ?? const <String, Object?>{};
    final farms = <String>{
      for (final m in (user['memberships'] as List?) ?? const [])
        if (m is Map && m['role'] == 'owner' && m['tenantId'] is String) m['tenantId'] as String,
    }.toList();
    final b = _db.batch()
      ..set(_db.doc('deletionRequests/$uid'), {
        'uid': uid,
        'email': email,
        'name': name,
        'reason': reason.length > 1000 ? reason.substring(0, 1000) : reason,
        'status': 'closed',
        'closedAt': FieldValue.serverTimestamp(),
        'farms': farms,
        'source': 'phone',
        'confirmed': true,
      })
      ..update(_db.doc('users/$uid'), {
        'deletion': {'at': FieldValue.serverTimestamp(), 'requestId': uid},
      });
    for (final t in farms) {
      b.update(_db.doc('tenants/$t'), {
        'closure': {'at': FieldValue.serverTimestamp(), 'by': uid, 'requestId': uid},
      });
    }
    await b.commit();
    return farms;
  }
}

/// The demo app and tests: everything in memory.
class FakeAccountRepository implements AccountRepository {
  new({this.now});

  final DateTime Function()? now;
  AccountClosure? closed;
  String? photo;
  String? reason;

  @override
  Future<AccountProfile> profile(String uid) async => AccountProfile(closed: closed, photo: photo);

  @override
  Future<String?> savePhoto(String uid, Uint8List jpeg) async => photo = base64Encode(jpeg);

  @override
  Future<void> removePhoto(String uid) async => photo = null;

  @override
  Future<List<String>> close({
    required String uid,
    required String email,
    required String name,
    String reason = '',
  }) async {
    this.reason = reason;
    closed = AccountClosure(at: now?.call() ?? DateTime(2026, 11, 7));
    return const [];
  }
}
