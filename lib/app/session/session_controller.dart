import 'dart:async';

import 'package:farm_tap/core/account/account_repository.dart';
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
      if (user == null) {
        _farm = null;
        _closed = null;
        _photo = null;
      }
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
  AccountClosure? _closed;
  String? _photo;
  bool _viewingLocked = false;

  /// The account was closed (decision 0024): only the closed screen shows.
  AccountClosure? get closed => _closed;

  /// The person's own picture (base64), shown on More and Settings.
  String? get photo => _photo;

  /// Read from the account after signing in, and after a change.
  void setProfile(AccountProfile p) {
    _closed = p.closed;
    _photo = p.photo;
    notifyListeners();
  }

  void setPhoto(String? photo) {
    _photo = photo;
    notifyListeners();
  }

  /// An owner or manager chose "Look at my records" on the locked screen.
  bool get viewingLocked => _viewingLocked;

  void viewLocked() {
    _viewingLocked = true;
    notifyListeners();
  }

  /// After a payment: the new dates unlock the farm straight away.
  void updateSubscription(Subscription s) {
    final f = _farm;
    if (f == null) return;
    _farm = f.withSubscription(s);
    _viewingLocked = false;
    notifyListeners();
  }

  bool get signedIn => auth.currentUser != null;
  FarmMembership? get farm => _farm;
  bool get hasFarm => _farm != null;

  /// Collection-centre tenants get the centre bottom bar (G01...).
  bool get isCentre => _farm?.kind == PlaceKind.collectionCentre;

  /// Farm phone needs a staff card + PIN (C01) before records can be made.
  bool get locked => _locked;

  /// Worker who unlocked the phone (null = the account owner / manager).
  StaffMember? get staff => _staff;

  /// A worker signed in on their own phone with phone + PIN (decision
  /// 0016 §5): never locked, avatar opens My page.
  bool get staffLogin => auth.currentUser?.isStaffLogin ?? false;

  /// Keeps the open worker's details (photo, card) current after an edit.
  void refreshStaff(StaffMember staff) {
    if (_staff?.id != staff.id) return;
    _staff = staff;
    notifyListeners();
  }

  /// Trial ended (or grace ran out) and not paid: read-only state (M05).
  bool get readOnly => _farm?.subscription.readOnly(trialClock.today()) ?? false;

  /// Calculated against the clock; null when not trialing (no banner).
  int? get trialDaysLeft => _farm?.subscription.trialBanner(trialClock.today());

  SubscriptionState? get subscriptionState => _farm?.subscription.state(trialClock.today());

  void openFarm(FarmMembership farm) {
    _farm = farm;
    _viewingLocked = false;
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

  /// Runs before signing out while still signed in (this phone stops
  /// getting the account's reminders).
  Future<void> Function()? beforeSignOut;

  Future<void> signOut() async {
    try {
      await beforeSignOut?.call();
    } on Object {
      // Never blocks signing out.
    }
    _farm = null;
    _locked = false;
    _staff = null;
    _closed = null;
    _photo = null;
    _viewingLocked = false;
    await auth.signOut();
  }

  @override
  void dispose() {
    unawaited(_sub.cancel());
    super.dispose();
  }
}
