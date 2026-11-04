import 'dart:async';
import 'dart:io';

/// True when the Firebase host resolves within 5 seconds.
Future<bool> internetReachable() async {
  try {
    const wait = Duration(seconds: 5); // theme-guard: ignore (network timing, not UI)
    final found = await InternetAddress.lookup('firestore.googleapis.com').timeout(wait);
    return found.isNotEmpty && found.first.rawAddress.isNotEmpty;
  } on SocketException {
    return false;
  } on TimeoutException {
    return false;
  }
}
