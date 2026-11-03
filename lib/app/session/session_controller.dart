import 'dart:async';

import 'package:farm_tap/core/auth/domain/auth_repository.dart';
import 'package:farm_tap/core/people/domain/staff_member.dart';
import 'package:farm_tap/core/tenancy/domain/farm_membership.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:flutter/foundation.dart';

/// What the router guards look at (docs/design/ROUTES.md, "Guards"):
/// signed in? which farm is open? is the farm phone locked? trial ended?
class SessionController extends ChangeNotifier {
  /// [trialClock]: never goes back in time (decision 0014 §7); defaults to
  /// [clock].
  new({required this.auth, required this.clock, Clock? trialClock}) : trialClock = trialClock ?? clock {
    _sub = auth.userChanges.listen((user) {
      if (user == null) _farm = null;
      notifyListeners();
    });
  }

  final AuthRepository auth;
  final Clock clock;
  final Clock trialClock;
  late final StreamSubscription<Object?> _sub;
  FarmMembership? _farm;
  bool _locked = false;
  StaffMember? _staff;

  bool get signedIn => auth.currentUser != null;
  FarmMembership? get farm => _farm;
  bool get hasFarm => _farm != null;

  /// Collection-centre tenants get the centre bottom bar (G01...).
  bool get isCentre => _farm?.kind == PlaceKind.collectionCentre;

  /// Farm phone needs a staff card + PIN (C01) before records can be made.
  bool get locked => _locked;

  /// Worker who unlocked the phone (null = the account owner / manager).
  StaffMember? get staff => _staff;

  /// Trial ended (or grace ran out) and not paid: read-only state (M05).
  bool get readOnly => _farm?.subscription.readOnly(trialClock.today()) ?? false;

  /// Calculated against the clock; null when not trialing (no banner).
  int? get trialDaysLeft => _farm?.subscription.trialBanner(trialClock.today());

  SubscriptionState? get subscriptionState => _farm?.subscription.state(trialClock.today());

  void openFarm(FarmMembership farm) {
    _farm = farm;
    notifyListeners();
  }

  void lock() {
    _locked = true;
    _staff = null;
    notifyListeners();
  }

  /// [staff] null = unlocked by the signed-in owner.
  void unlock([StaffMember? staff]) {
    _locked = false;
    _staff = staff;
    notifyListeners();
  }

  Future<void> signOut() async {
    _farm = null;
    _locked = false;
    _staff = null;
    await auth.signOut();
  }

  @override
  void dispose() {
    unawaited(_sub.cancel());
    super.dispose();
  }
}
