import 'package:farm_tap/core/error/failure.dart';
import 'package:farm_tap/core/error/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('Success should contain data and be isSuccess', () {
      const result = Result.success('test');
      expect(result.isSuccess, true);
      expect(result.isFailure, false);
      expect(result.data, 'test');
      expect(result.failure, null);
    });

    test('Failure should contain failure and be isFailure', () {
      const failure = CacheFailure('error');
      const result = Result<String>.failure(failure);
      expect(result.isSuccess, false);
      expect(result.isFailure, true);
      expect(result.data, null);
      expect(result.failure, failure);
    });
  });
}
