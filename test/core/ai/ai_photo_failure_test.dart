// Photo Check (decision 0026): errors from the model call are sorted into
// plain failures the farmer can understand.
import 'package:farm_tap/core/ai/ai_photo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('photoFailureOf sorts errors by what they say', () {
    expect(photoFailureOf(const PhotoAnalyzeException(PhotoFailure.unreadable)), PhotoFailure.unreadable);
    expect(photoFailureOf(Exception('App Check token invalid')), PhotoFailure.appCheck);
    expect(photoFailureOf(Exception('403 permission denied')), PhotoFailure.appCheck);
    expect(photoFailureOf(Exception('429 RESOURCE_EXHAUSTED quota')), PhotoFailure.busy);
    expect(photoFailureOf(Exception('503 overloaded')), PhotoFailure.busy);
    expect(photoFailureOf(Exception('SocketException: failed host lookup')), PhotoFailure.network);
  });
}
