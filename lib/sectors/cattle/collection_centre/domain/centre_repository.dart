import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/sectors/cattle/collection_centre/domain/centre_models.dart';

abstract interface class CentreRepository {
  Future<Result<CentreDay>> today();
  Future<Result<List<CentreFarmer>>> farmers();
  Future<Result<FarmerCounts>> counts();
  Future<Result<CentreFarmer?>> farmer(String id);
  Future<Result<CentreFarmer?>> farmerByCard(String card);
  Future<Result<CentreFarmer>> addFarmer({
    required String name,
    required String phone,
    required String village,
    String? card,
  });

  /// Saves a delivery (after the read-back). Undo removes it again.
  Future<Result<Delivery>> recordDelivery(String farmerId, double litres, {QualityTest test});
  Future<Result<void>> undoDelivery(String deliveryId);

  /// G12: failed test, the milk is not paid.
  Future<Result<void>> rejectDelivery(String farmerId, double litres, RejectReason reason, {String? note});

  /// G08: needs the manager PIN. False when the PIN is wrong.
  Future<Result<bool>> closeSession(String pin);

  Future<Result<PaymentPeriod>> payments();
  Future<Result<FarmerStatement>> statement(String farmerId);
  Future<Result<SmsPreview>> smsPreview();

  /// Queues the week's statements to farmers; returns how many.
  Future<Result<int>> sendStatements();
  Future<Result<void>> payOut(PayMethod method);
  Future<Result<Reconciliation>> reconciliation();
  Future<Result<void>> saveReconciliation(String explanation);
}
