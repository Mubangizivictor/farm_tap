import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/sectors/cattle/health/domain/health_models.dart';

/// Treatments, drugs and the health calendar. Other features (milk, herd,
/// home) read withdrawal from here so every screen agrees.
abstract interface class TreatmentRepository {
  /// Every treatment record, newest first.
  Future<Result<List<TreatmentRecord>>> treatments();

  /// Records whose milk is not for sale at [now].
  Future<Result<List<TreatmentRecord>>> withdrawals(DateTime now);

  /// The record blocking this animal's milk at [now], if any.
  Future<Result<TreatmentRecord?>> withdrawalFor(String animalId, DateTime now);

  Future<Result<List<Drug>>> drugs();
  Future<Result<List<TreatableAnimal>>> animals();
  Future<Result<TreatmentRecord>> addTreatment(NewTreatment input);
  Future<Result<List<HealthTask>>> schedule();
  Future<Result<void>> addTask(HealthTask task);

  /// H05: a dipping, deworming or vaccination job was done.
  Future<Result<void>> setTaskDone(String taskId, {required bool done});
  Future<Result<Drug>> addDrug({required String name, required double stock, required int withdrawalDays});

  /// H04 "Bought more": adds to the stock; a [price] is a vet expense.
  Future<Result<void>> restockDrug(String drugId, {required double amount, int? price});

  /// H04 "Count": what is on the shelf now.
  Future<Result<void>> setDrugStock(String drugId, double stock);
  List<String> get vets;
}
