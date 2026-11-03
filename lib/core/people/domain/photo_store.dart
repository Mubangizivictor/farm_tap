import 'dart:typed_data';

import 'package:farm_tap/core/error/result.dart';

/// A person's photo as saved: the small copy that lives in their record and
/// the full one in cloud storage (decision 0015 §2).
class PersonPhoto {
  const new({required this.thumb, this.url});

  /// Base64 JPEG, about 320 px wide: prints on the ID card and syncs with
  /// the record, so it works on the free plan.
  final String thumb;

  /// Full photo in Firebase Storage; null until Storage is switched on (the
  /// upload waits on the phone and is tried again).
  final String? url;
}

/// Saves photos of staff and milk suppliers.
abstract interface class PhotoStore {
  /// Shrinks [bytes] (a camera or gallery JPEG) and uploads the full photo
  /// when cloud storage is available.
  Future<Result<PersonPhoto>> save({required String personId, required Uint8List bytes});

  /// Uploads photos that were saved while storage was off or the phone was
  /// offline. Returns the person ids that now have a [PersonPhoto.url].
  Future<Map<String, String>> retryPending();
}
