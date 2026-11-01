import 'package:equatable/equatable.dart';

enum PlaceKind { dairyFarm, collectionCentre }

enum PlaceRole { owner, manager, clerk, worker }

enum SubscriptionState { active, trial, readOnly }

/// A farm or collection centre the account can open (A07).
class FarmMembership extends Equatable {
  const new({
    required this.tenantId,
    required this.name,
    required this.place,
    required this.kind,
    required this.role,
    required this.subscription,
    this.trialDaysLeft = 0,
    this.avatarIndex = 1,
  });

  final String tenantId;
  final String name;

  /// District or village: "Mbarara", "Kashari".
  final String place;
  final PlaceKind kind;
  final PlaceRole role;
  final SubscriptionState subscription;
  final int trialDaysLeft;
  final int avatarIndex;

  @override
  List<Object?> get props => [tenantId, name, place, kind, role, subscription, trialDaysLeft, avatarIndex];
}
