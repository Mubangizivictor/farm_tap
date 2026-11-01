import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/sectors/cattle/home/domain/home_models.dart';

abstract interface class HomeRepository {
  Future<Result<HomeSummary>> summary();

  /// Most urgent first.
  Future<Result<List<Attention>>> attention();

  Future<Result<WorkerDay>> workerDay(String staffId);

  Future<Result<void>> setTaskDone(String taskId, {required bool done});
}
