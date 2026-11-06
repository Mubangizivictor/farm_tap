import 'package:farm_tap/core/auth/data/fake/fake_auth_repository.dart';
import 'package:farm_tap/core/auth/domain/entities/account_user.dart';
import 'package:farm_tap/core/auth/domain/staff_login_repository.dart';
import 'package:farm_tap/core/error/failure.dart';
import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/people/domain/staff_member.dart';
import 'package:farm_tap/core/tenancy/domain/farm_membership.dart';

/// Demo build and tests: staff logins kept in memory. Amos (701 220 318)
/// signs in to Rwemera Dairy Farm with PIN 1234 and must choose his own.
class FakeStaffLoginRepository implements StaffLoginRepository {
  new({this.auth, this.farm, bool withSamples = true}) {
    if (withSamples) {
      _logins['701220318'] = const _Login(
        tenantId: 'farm-rwemera',
        staffId: 'staff-ta',
        name: 'Twinomujuni Amos',
        pin: '1234',
        mustChange: true,
        role: StaffRole.herdsman,
      );
    }
  }

  /// Signs the worker in (the demo's fake account sign-in).
  final FakeAuthRepository? auth;

  /// The farm a worker opens (demo: the owner's sample farm).
  final FarmMembership? Function(String tenantId)? farm;

  final _logins = <String, _Login>{};
  _Login? _current;
  String? _currentPhone;

  /// The farm of the signed-in worker, as their only place (A07).
  FarmMembership? get currentPlace {
    final c = _current;
    if (c == null || auth?.currentUser?.id != 'staff-${c.staffId}') return null;
    final f = farm?.call(c.tenantId);
    if (f == null) return null;
    return FarmMembership(
      tenantId: f.tenantId,
      name: f.name,
      place: f.place,
      kind: f.kind,
      role: switch (c.role) {
        StaffRole.manager => PlaceRole.manager,
        StaffRole.clerk => PlaceRole.clerk,
        _ => PlaceRole.worker,
      },
      subscription: f.subscription,
      avatarIndex: f.avatarIndex,
      staffId: c.staffId,
    );
  }

  @override
  Future<Result<void>> createLogin({
    required String tenantId,
    required String staffId,
    required String name,
    required String phone,
    required String pin,
    required StaffRole role,
  }) async {
    final digits = ugPhoneDigits(phone);
    if (digits == null) return const Result.failure(ValidationFailure('phone'));
    final old = _logins[digits];
    if (old != null && old.tenantId != tenantId) {
      return const Result.failure(ValidationFailure(StaffLoginError.otherFarm));
    }
    _logins[digits] = _Login(tenantId: tenantId, staffId: staffId, name: name, pin: pin, mustChange: true, role: role);
    return const Result.success(null);
  }

  @override
  Future<Result<StaffSignIn>> signIn({required String phone, required String pin}) async {
    final digits = ugPhoneDigits(phone);
    final login = digits == null ? null : _logins[digits];
    if (login == null || login.pin != pin) return const Result.failure(ValidationFailure(StaffLoginError.wrong));
    _current = login;
    _currentPhone = digits;
    auth?.signInAs(
      AccountUser(
        id: 'staff-${login.staffId}',
        name: login.name,
        email: 'p${digits}v1@staff.farmtap.app',
        emailVerified: true,
      ),
    );
    return Result.success(
      StaffSignIn(mustChangePin: login.mustChange, tenantId: login.tenantId, staffId: login.staffId),
    );
  }

  @override
  Future<Result<void>> changePin(String newPin) async {
    final c = _current;
    final phone = _currentPhone;
    if (c == null || phone == null) return const Result.failure(PermissionFailure('not-staff'));
    _current = _logins[phone] = _Login(
      tenantId: c.tenantId,
      staffId: c.staffId,
      name: c.name,
      pin: newPin,
      mustChange: false,
      role: c.role,
    );
    return const Result.success(null);
  }
}

class _Login {
  const new({
    required this.tenantId,
    required this.staffId,
    required this.name,
    required this.pin,
    required this.mustChange,
    required this.role,
  });

  final String tenantId;
  final String staffId;
  final String name;
  final String pin;
  final bool mustChange;
  final StaffRole role;
}
