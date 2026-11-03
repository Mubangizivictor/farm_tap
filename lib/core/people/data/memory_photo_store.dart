import 'dart:convert';
import 'dart:typed_data';

import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/people/domain/photo_store.dart';

/// Demo build and tests: keeps the picked photo as it is (the picker already
/// shrinks it) and never uploads.
class MemoryPhotoStore implements PersonPhotoStore {
  @override
  Future<Result<PersonPhoto>> save({required String personId, required Uint8List bytes}) async =>
      Result.success(PersonPhoto(thumb: base64Encode(bytes)));

  @override
  Future<Map<String, String>> retryPending() async => const {};
}
