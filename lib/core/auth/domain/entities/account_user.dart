import 'package:equatable/equatable.dart';

/// The signed-in person (Google, Apple or email account). Staff who unlock
/// with an NFC card + PIN are not account users.
class AccountUser extends Equatable {
  const new({required this.id, required this.name, required this.email, this.emailVerified = false});

  final String id;
  final String name;
  final String email;
  final bool emailVerified;

  /// A worker who signed in with phone + PIN (decision 0015 §5).
  bool get isStaffLogin => email.endsWith('@staff.farmtap.app');

  @override
  List<Object?> get props => [id, name, email, emailVerified];
}
