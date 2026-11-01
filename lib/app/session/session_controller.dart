import 'dart:async';

import 'package:farm_tap/core/auth/domain/auth_repository.dart';
import 'package:farm_tap/core/tenancy/domain/farm_membership.dart';
import 'package:flutter/foundation.dart';

/// What the router guards look at (docs/design/ROUTES.md, "Guards"):
/// signed in? which farm is open? is the farm phone locked? trial ended?
class SessionController extends ChangeNotifier {
  new({required this.auth}) {
    _sub = auth.userChanges.listen((user) {
      if (user == null) _farm = null;
      notifyListeners();
    });
  }

  final AuthRepository auth;
  late final StreamSubscription<Object?> _sub;
  FarmMembership? _farm;
  bool _locked = false;

  bool get signedIn => auth.currentUser != null;
  FarmMembership? get farm => _farm;
  bool get hasFarm => _farm != null;

  /// Collection-centre tenants get the centre bottom bar (G01...).
  bool get isCentre => _farm?.kind == PlaceKind.collectionCentre;

  /// Farm phone needs a staff card + PIN (C01) before records can be made.
  bool get locked => _locked;

  /// Trial ended and not paid: screens show the read-only state (M05).
  bool get readOnly => _farm?.subscription == SubscriptionState.readOnly;

  void openFarm(FarmMembership farm) {
    _farm = farm;
    notifyListeners();
  }

  void lock() {
    _locked = true;
    notifyListeners();
  }

  void unlock() {
    _locked = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    _farm = null;
    _locked = false;
    await auth.signOut();
  }

  @override
  void dispose() {
    unawaited(_sub.cancel());
    super.dispose();
  }
}
