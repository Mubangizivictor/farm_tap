// The phone's way to the server AI assistant (decision 0028):
// functions/src/ai.ts, region europe-west1. The server checks the person, the
// farm and the daily allowance, picks the model and holds the key.
//
// Called over HTTPS with the Firebase callable protocol ({"data": ...} in,
// {"result": ...} or {"error": ...} out) and the person's ID token, so no new
// package is needed. The answer arrives whole (no streaming on the phone yet).
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:farm_tap/core/ai/ai_quota.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

// Network timeouts, not animation timing.
const _connect = Duration(seconds: 15); // theme-guard: ignore
const _grace = Duration(seconds: 30); // theme-guard: ignore

class ServerChatClient implements AiServerClient {
  const new({this.region = 'europe-west1'});
  final String region;

  Uri _url(String name) => Uri.parse('https://$region-${Firebase.app().options.projectId}.cloudfunctions.net/$name');

  Future<Map<String, Object?>> _call(String name, Map<String, Object?> data, Duration timeout) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw const AiRequestException(AiErrorKind.unavailable);
    final client = HttpClient()..connectionTimeout = _connect;
    try {
      final req = await client.postUrl(_url(name)).timeout(timeout);
      req.headers
        ..contentType = ContentType.json
        ..set(HttpHeaders.authorizationHeader, 'Bearer $token');
      req.write(jsonEncode({'data': data}));
      final res = await req.close().timeout(timeout);
      final body = await res.transform(utf8.decoder).join().timeout(timeout);
      final Object? json;
      try {
        json = jsonDecode(body);
      } on FormatException {
        throw const AiRequestException(AiErrorKind.unavailable);
      }
      final map = json is Map ? json.cast<String, Object?>() : const <String, Object?>{};
      final err = map['error'];
      if (err is Map) {
        final e = err.cast<String, Object?>();
        final details = e['details'];
        final usage = details is Map ? UsageView.fromJson(details['usage']) : null;
        throw AiRequestException(kindOfCallError(e['status'] as String?, details), usage);
      }
      if (res.statusCode != 200) throw const AiRequestException(AiErrorKind.unavailable);
      final result = map['result'];
      return result is Map ? result.cast<String, Object?>() : const {};
    } on AiRequestException {
      rethrow;
    } on TimeoutException {
      throw const AiRequestException(AiErrorKind.timeout);
    } on SocketException {
      throw const AiRequestException(AiErrorKind.network);
    } on HandshakeException {
      throw const AiRequestException(AiErrorKind.network);
    } on HttpException {
      throw const AiRequestException(AiErrorKind.network);
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<ServerAnswer> ask(ServerAsk input, {required Duration timeout}) async {
    final r = await _call('aiAssistant', input.toJson(), timeout + _grace);
    final text = r['text'];
    if (text is! String || text.trim().isEmpty) throw const AiRequestException(AiErrorKind.unavailable);
    final g = r['grounding'];
    return ServerAnswer(
      text: text,
      model: '${r['model'] ?? ''}',
      cached: r['cached'] == true,
      usage: UsageView.fromJson(r['usage']),
      grounding: g is Map ? g.cast<String, Object?>() : null,
    );
  }

  @override
  Future<UsageView?> usage(String tenantId) async {
    try {
      return UsageView.fromJson(await _call('aiUsageNow', {'tenantId': tenantId}, _connect));
    } on Object {
      return null;
    }
  }
}
