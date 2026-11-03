import 'package:equatable/equatable.dart';

enum PlaceKind { dairyFarm, collectionCentre }

enum PlaceRole { owner, manager, clerk, worker }

/// Length of the free trial for a new farm (owner's decision, 3 Nov 2026).
const freeTrialDays = 7;

/// What the farm may do today. Calculated from [Subscription], never stored.
enum SubscriptionState { trial, active, grace, readOnly }

/// The farm's subscription document (ROADMAP 3.2): only dates are stored;
/// days left, grace and read-only are calculated against the clock.
class Subscription extends Equatable {
  const new({this.trialStartedAt, this.trialEndsAt, this.paidUntil});

  /// Day the free trial started (end of onboarding).
  final DateTime? trialStartedAt;

  /// First day without the free trial ([freeTrialDays] after onboarding).
  final DateTime? trialEndsAt;

  /// First day not covered by the last payment.
  final DateTime? paidUntil;

  /// An overdue payment gets 7 days' grace before read-only.
  static const graceDays = 7;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  static int _daysBetween(DateTime today, DateTime end) {
    final left = _day(end).difference(_day(today)).inDays;
    return left < 0 ? 0 : left;
  }

  SubscriptionState state(DateTime today) {
    final t = _day(today);
    final paid = paidUntil;
    if (paid != null) {
      if (t.isBefore(_day(paid))) return SubscriptionState.active;
      if (t.isBefore(_day(paid).add(const Duration(days: graceDays)))) return SubscriptionState.grace;
      return SubscriptionState.readOnly;
    }
    final trial = trialEndsAt;
    // Trial ends unpaid -> read-only straight away (no grace).
    if (trial != null && t.isBefore(_day(trial))) return SubscriptionState.trial;
    return SubscriptionState.readOnly;
  }

  /// "Free trial · 9 days left" (0 once ended).
  int trialDaysLeft(DateTime today) => trialEndsAt == null ? 0 : _daysBetween(today, trialEndsAt!);

  /// Days left before an overdue farm turns read-only.
  int graceDaysLeft(DateTime today) =>
      paidUntil == null ? 0 : _daysBetween(today, _day(paidUntil!).add(const Duration(days: graceDays)));

  /// Trial length in days and how many are used ("5 of 7").
  int get trialLength => trialStartedAt == null || trialEndsAt == null
      ? freeTrialDays
      : _day(trialEndsAt!).difference(_day(trialStartedAt!)).inDays;

  int trialDaysUsed(DateTime today) => trialLength - trialDaysLeft(today);

  bool readOnly(DateTime today) => state(today) == SubscriptionState.readOnly;

  /// Trial days left while trialing, else null (banner and sidebar card hide).
  int? trialBanner(DateTime today) => state(today) == SubscriptionState.trial ? trialDaysLeft(today) : null;

  @override
  List<Object?> get props => [trialStartedAt, trialEndsAt, paidUntil];
}

/// A farm or collection centre the account can open (A07).
class FarmMembership extends Equatable {
  const new({
    required this.tenantId,
    required this.name,
    required this.place,
    required this.kind,
    required this.role,
    required this.subscription,
    this.avatarIndex = 1,
  });

  final String tenantId;
  final String name;

  /// District or village: "Mbarara", "Kashari".
  final String place;
  final PlaceKind kind;
  final PlaceRole role;
  final Subscription subscription;
  final int avatarIndex;

  @override
  List<Object?> get props => [tenantId, name, place, kind, role, subscription, avatarIndex];
}
