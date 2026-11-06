import 'package:farm_tap/core/people/domain/staff_member.dart';

/// The app's sections, as a role sees them (decision 0016 §7).
enum AppSection {
  home,
  herd,
  milk,
  health,
  feeding,
  breeding,
  collect,
  farmers,
  pay,
  workers,
  money,
  reports,
  settings,

  /// The worker's own page: ID card, clock-ins, pay, tasks, PIN.
  me,
}

/// What each kind of worker sees. Owners and managers see everything;
/// everyone else only their work, plus My page. Money, wages, reports,
/// settings and staff stay with owners and managers.
abstract final class StaffPermissions {
  static const Set<AppSection> _all = {...AppSection.values};

  static const _byRole = <StaffRole, Set<AppSection>>{
    StaffRole.manager: _all,
    StaffRole.herdsman: {
      AppSection.home,
      AppSection.herd,
      AppSection.milk,
      AppSection.health,
      AppSection.feeding,
      AppSection.breeding,
      AppSection.collect,
      AppSection.me,
    },
    StaffRole.clerk: {AppSection.home, AppSection.milk, AppSection.collect, AppSection.farmers, AppSection.me},
    StaffRole.worker: {AppSection.home, AppSection.milk, AppSection.feeding, AppSection.me},
    StaffRole.vet: {AppSection.home, AppSection.herd, AppSection.health, AppSection.breeding, AppSection.me},
  };

  /// [role] null = the owner or a manager with their own account.
  static Set<AppSection> sections(StaffRole? role) => role == null ? _all : _byRole[role]!;

  static bool can(StaffRole? role, AppSection s) => sections(role).contains(s);

  /// Add / edit staff, reset PINs, give cards (ROADMAP 7.4).
  static bool managesStaff(StaffRole? role) => role == null || role == StaffRole.manager;
}
