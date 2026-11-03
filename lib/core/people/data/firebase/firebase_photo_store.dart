import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:farm_tap/core/error/failure.dart';
import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/people/domain/photo_store.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Photos on Firebase (decision 0015 §2).
///
/// - A 320 px copy goes into the person's record (free, offline, prints).
/// - The full photo goes to Storage at `tenants/{t}/people/{id}.jpg`.
///   While Storage is not switched on (Spark plan), or the phone is offline,
///   the upload fails quietly: the photo waits in the app's folder and
///   [retryPending] sends it later. Switching Storage on is the only step left.
class FirebasePhotoStore implements PhotoStore {
  new({required this.tenantId, required this.prefs, FirebaseStorage? storage}) : _storage = storage;

  final String Function() tenantId;
  final SharedPreferences prefs;
  final FirebaseStorage? _storage;

  FirebaseStorage get _bucket => _storage ?? FirebaseStorage.instance;

  static const _pendingKey = 'photos.pending';

  /// Thumbnail and full photo sizes (pixels, JPEG quality).
  static const thumbWidth = 320;
  static const thumbQuality = 70;
  static const fullWidth = 1080;
  static const fullQuality = 82;

  /// An upload that takes longer is left for [retryPending].
  static const _uploadLimit = Duration(seconds: 30); // theme-guard: ignore

  String _path(String tenant, String personId) => 'tenants/$tenant/people/$personId.jpg';

  @override
  Future<Result<PersonPhoto>> save({required String personId, required Uint8List bytes}) async {
    try {
      final thumb = await _shrink(bytes, thumbWidth, thumbQuality);
      final full = await _shrink(bytes, fullWidth, fullQuality);
      final tenant = tenantId();
      final url = await _upload(tenant, personId, full);
      if (url == null) await _keepForLater(tenant, personId, full);
      return Result.success(PersonPhoto(thumb: base64Encode(thumb), url: url));
    } on Object catch (e) {
      debugPrint('Photo save failed: $e');
      return Result.failure(UnexpectedFailure('$e'));
    }
  }

  static Future<Uint8List> _shrink(Uint8List bytes, int width, int quality) async {
    try {
      final out = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: width,
        minHeight: width,
        quality: quality,
      );
      return out.isEmpty ? bytes : out;
    } on Object {
      return bytes;
    }
  }

  Future<String?> _upload(String tenant, String personId, Uint8List full) async {
    if (tenant.isEmpty) return null;
    try {
      final ref = _bucket.ref(_path(tenant, personId));
      await ref.putData(full, SettableMetadata(contentType: 'image/jpeg')).timeout(_uploadLimit);
      return await ref.getDownloadURL();
    } on Object catch (e) {
      // Storage not switched on yet, no network, or no permission.
      debugPrint('Photo upload waiting: $e');
      return null;
    }
  }

  Future<File> _file(String tenant, String personId) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/photos/$tenant-$personId.jpg');
  }

  Map<String, String> _pending() {
    final raw = prefs.getString(_pendingKey);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map).map((k, v) => MapEntry(k as String, v as String));
  }

  Future<void> _keepForLater(String tenant, String personId, Uint8List full) async {
    if (tenant.isEmpty) return;
    final f = await _file(tenant, personId);
    await f.parent.create(recursive: true);
    await f.writeAsBytes(full, flush: true);
    final pending = _pending()..['$tenant/$personId'] = f.path;
    await prefs.setString(_pendingKey, jsonEncode(pending));
  }

  @override
  Future<Map<String, String>> retryPending() async {
    final pending = _pending();
    if (pending.isEmpty) return const {};
    final done = <String, String>{};
    for (final e in [...pending.entries]) {
      final slash = e.key.indexOf('/');
      final tenant = e.key.substring(0, slash);
      final personId = e.key.substring(slash + 1);
      // Another farm's photo goes up when that farm is open (its record
      // gets the link then).
      if (tenant != tenantId()) continue;
      final f = File(e.value);
      if (!f.existsSync()) {
        pending.remove(e.key);
        continue;
      }
      final url = await _upload(tenant, personId, await f.readAsBytes());
      if (url == null) break; // Still off or offline: try again next time.
      pending.remove(e.key);
      done[personId] = url;
      await f.delete();
    }
    await prefs.setString(_pendingKey, jsonEncode(pending));
    return done;
  }
}
