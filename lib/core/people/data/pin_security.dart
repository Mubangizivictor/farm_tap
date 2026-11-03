import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Staff PINs are never stored as typed (decision 0014 §6). PBKDF2 with
/// HMAC-SHA256 and a random salt per person, checked on the phone so unlock
/// works with no network. Stored as `pbkdf2-sha256$<iterations>$<salt>$<hash>`.
class PinHasher {
  const new({this.iterations = 20000, this._random});

  /// Tuned to stay well under a second on a low-end Android phone.
  final int iterations;
  final Random? _random;

  static const _prefix = 'pbkdf2-sha256';

  String hash(String pin) {
    final r = _random ?? Random.secure();
    final salt = Uint8List.fromList(List.generate(16, (_) => r.nextInt(256)));
    final key = _pbkdf2(utf8.encode(pin), salt, iterations);
    return '$_prefix\$$iterations\$${base64Encode(salt)}\$${base64Encode(key)}';
  }

  bool verify(String pin, String stored) {
    final parts = stored.split(r'$');
    if (parts.length != 4 || parts[0] != _prefix) return false;
    final rounds = int.tryParse(parts[1]);
    if (rounds == null || rounds < 1) return false;
    final salt = base64Decode(parts[2]);
    final expected = base64Decode(parts[3]);
    final actual = _pbkdf2(utf8.encode(pin), salt, rounds);
    return _sameBytes(actual, expected);
  }

  /// One 32-byte block is enough for a 32-byte key (RFC 8018 §5.2).
  static List<int> _pbkdf2(List<int> password, List<int> salt, int rounds) {
    final mac = Hmac(sha256, password);
    var u = mac.convert([...salt, 0, 0, 0, 1]).bytes;
    final out = List<int>.of(u);
    for (var i = 1; i < rounds; i++) {
      u = mac.convert(u).bytes;
      for (var j = 0; j < out.length; j++) {
        out[j] ^= u[j];
      }
    }
    return out;
  }

  /// Same time whatever the input, so timing gives nothing away.
  static bool _sameBytes(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

/// Wrong-PIN lockout (UX_SPEC C04): after [maxTries] wrong PINs that person
/// is locked for [lockFor]. Time comes from the injected clock.
class PinLockout {
  new({required this.now, this.maxTries = 5, this.lockFor = const Duration(minutes: 5)});

  final DateTime Function() now;
  final int maxTries;
  final Duration lockFor;
  final _wrong = <String, int>{};
  final _lockedUntil = <String, DateTime>{};

  bool isLocked(String personId) {
    final until = _lockedUntil[personId];
    if (until == null) return false;
    if (now().isBefore(until)) return true;
    _lockedUntil.remove(personId);
    _wrong.remove(personId);
    return false;
  }

  /// Returns tries left; 0 means now locked.
  int recordWrong(String personId) {
    final wrong = (_wrong[personId] ?? 0) + 1;
    _wrong[personId] = wrong;
    if (wrong >= maxTries) {
      _lockedUntil[personId] = now().add(lockFor);
      return 0;
    }
    return maxTries - wrong;
  }

  void reset(String personId) {
    _wrong.remove(personId);
    _lockedUntil.remove(personId);
  }
}
