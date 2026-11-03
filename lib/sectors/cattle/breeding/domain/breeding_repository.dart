import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/sectors/cattle/breeding/domain/breeding_models.dart';

/// Heat, service, pregnancy checks and calvings. Herd counts and home alerts
/// read pregnancies from here so every screen agrees.
abstract interface class BreedingRepository {
  Future<Result<BreedingSummary>> summary();

  Future<Result<List<BreedingAnimal>>> animals();

  /// J02. An AI or natural service with a cost records its expense in the
  /// money repository.
  Future<Result<ServiceRecord>> recordService({
    required String animalId,
    required ServiceKind kind,
    required DateTime at,
    String? straw,
    String? bull,
    String? technician,
    int? cost,
  });

  /// J03 when [pregnant].
  Future<Result<Pregnancy?>> recordCheck({required String serviceId, required bool pregnant, String? by});

  /// E07 (herd): the calf is born; ends the pregnancy.
  Future<Result<void>> recordCalving(String animalId, {required DateTime at});

  List<String> get technicians;

  /// Semen straws used before, newest first (J02 pick list; custom allowed).
  List<String> get straws;

  /// The last AI cost entered, to prefill J02; null before the first one.
  int? get lastAiCost;

  /// Who a pregnancy check is saved as: the vet in samples, else the person
  /// using the phone.
  String get checker;
}
