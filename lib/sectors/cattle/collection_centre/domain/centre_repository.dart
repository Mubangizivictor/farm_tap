import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/people/domain/card_registry.dart';
import 'package:farm_tap/core/people/domain/photo_store.dart';
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

  /// Gives the farmer a card ([scanned]: number, chip id or QR; null = a
  /// new number). One holder per card (decision 0016); with [replace] the
  /// farmer's old card is marked lost.
  Future<Result<CentreFarmer>> assignCard(String farmerId, String? scanned, {bool replace = false});

  /// Ends the farmer's card: lost or returned.
  Future<Result<CentreFarmer>> revokeCard(String farmerId, CardStatus why);

  Future<Result<List<IdCardRecord>>> cardHistory(String farmerId);

  Future<Result<CentreFarmer>> setPhoto(String farmerId, PersonPhoto photo);

  /// The farmer's latest deliveries, newest first (scan station, G07).
  Future<Result<List<Delivery>>> deliveriesOf(String farmerId, {int limit = 10});

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

  /// G07 edit: name, phone, village and SMS receipts (the card stays).
  Future<Result<CentreFarmer>> updateFarmer(
    String farmerId, {
    required String name,
    required String phone,
    required String village,
    required bool smsReceipts,
  });

  /// What the centre pays farmers per litre (G09 payments, statements).
  double get pricePerLitre;
  Future<Result<void>> setPricePerLitre(double ugx);
}
