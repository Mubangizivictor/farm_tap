// Photos for animals, treatments, receipts and staff cards.
//
// A photo is taken or picked, made small (about 100 KB) and saved on the
// phone first, so it shows at once and offline. A record keeps only its key
// ("photos/<id>.jpg"). When Firebase Storage is switched on for the project
// (it needs the paid Blaze plan) the photos upload by themselves to
// tenants/<farm>/photos/<id>.jpg and the farm's other phones download them.
// Until then they wait on this phone and nothing breaks.
import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class PhotoStore {
  new _();

  static final PhotoStore instance = PhotoStore._();

  static const _pendingKey = 'photos.pending';

  /// Longest side after shrinking, in pixels; JPEG quality.
  static const _maxSide = 1280;
  static const _quality = 70;

  /// The open farm; photos upload under it.
  String Function() tenantId = () => '';

  /// Each animal's photo key by animal id, kept by the herd so every cow
  /// avatar in the app (milk, health, breeding) shows her photo.
  final Map<String, String> animalPhotos = {};

  Directory? _dir;
  final Map<String, Future<String?>> _urls = {};
  bool _uploading = false;

  Future<Directory> _photosDir() async {
    final d = _dir ??= Directory('${(await getApplicationDocumentsDirectory()).path}/photos');
    if (!d.existsSync()) d.createSync(recursive: true);
    return d;
  }

  static String _name(String key) => key.split('/').last;

  /// Takes ([camera]) or picks a photo; returns its key, or null when the
  /// person backs out.
  Future<String?> capture({required bool camera}) async {
    final picked = await ImagePicker().pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: _maxSide.toDouble(),
      maxHeight: _maxSide.toDouble(),
    );
    if (picked == null) return null;
    final key = 'photos/${const Uuid().v4()}.jpg';
    final out = File('${(await _photosDir()).path}/${_name(key)}');
    Uint8List bytes;
    try {
      bytes =
          await FlutterImageCompress.compressWithFile(
            picked.path,
            minWidth: _maxSide,
            minHeight: _maxSide,
            quality: _quality,
          ) ??
          await picked.readAsBytes();
    } on Object {
      bytes = await picked.readAsBytes();
    }
    await out.writeAsBytes(bytes, flush: true);
    await _queue(key);
    unawaited(uploadPending());
    return key;
  }

  /// The photo on this phone, if it is here.
  Future<File?> localFile(String key) async {
    if (kIsWeb) return null;
    final f = File('${(await _photosDir()).path}/${_name(key)}');
    return f.existsSync() ? f : null;
  }

  /// A download link for a photo taken on another phone (null while it has
  /// not uploaded, or Storage is not switched on).
  Future<String?> remoteUrl(String key) => _urls[key] ??= () async {
    final t = tenantId();
    if (Firebase.apps.isEmpty || t.isEmpty) return null;
    try {
      return await FirebaseStorage.instance.ref('tenants/$t/${_storagePath(key)}').getDownloadURL();
    } on Object {
      unawaited(_urls.remove(key)); // try again next time it is shown
      return null;
    }
  }();

  static String _storagePath(String key) => 'photos/${_name(key)}';

  Future<void> _queue(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final t = tenantId();
    await prefs.setStringList(_pendingKey, [...?prefs.getStringList(_pendingKey), '$t|$key']);
  }

  /// Sends photos still on this phone only. Safe to call often: at start,
  /// after each sync, after each new photo. Stops quietly when offline or
  /// when Storage is not switched on yet; they are tried again later.
  Future<void> uploadPending() async {
    if (_uploading || kIsWeb || Firebase.apps.isEmpty) return;
    _uploading = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final pending = [...?prefs.getStringList(_pendingKey)];
      final left = <String>[];
      for (final entry in pending) {
        final sep = entry.indexOf('|');
        final tenant = entry.substring(0, sep);
        final key = entry.substring(sep + 1);
        final file = await localFile(key);
        if (file == null) continue; // deleted from the phone: nothing to send
        if (tenant.isEmpty) {
          left.add(entry);
          continue;
        }
        try {
          await FirebaseStorage.instance
              .ref('tenants/$tenant/${_storagePath(key)}')
              .putFile(file, SettableMetadata(contentType: 'image/jpeg'));
        } on Object {
          left.add(entry);
        }
      }
      await prefs.setStringList(_pendingKey, left);
    } finally {
      _uploading = false;
    }
  }

  /// Photos waiting to upload (Settings can show this).
  Future<int> pendingCount() async => (await SharedPreferences.getInstance()).getStringList(_pendingKey)?.length ?? 0;
}
