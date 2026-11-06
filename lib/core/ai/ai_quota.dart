// FarmTap AI: the daily allowance for AI answers, its settings and the error
// messages (decision 0028). Hand port of the parts of shared/aiQuota.ts the
// phone needs. The server (functions/src/aiServer.ts) is the only place that
// counts; the phone only shows what the server sends back.
import 'dart:math' as math;

import 'package:farm_tap/core/ai/ai_core.dart';

Map<String, Object?> _obj(Object? v) => v is Map ? v.cast<String, Object?>() : const {};
int _intIn(Object? v, int lo, int hi, int d) => v is num && v >= lo && v <= hi ? jsRound(v).toInt() : d;

const defaultTimezone = 'Africa/Kampala';

/// platform/config.ai.assistant, set in Admin > AI Control Centre.
class AssistantConfig {
  const new({
    this.enabled = false,
    this.provider = 'gemini',
    this.model = 'gemini-3.5-flash-lite',
    this.dailyLimit = 10,
    this.warnPct = 80,
    this.timezone = defaultTimezone,
    this.maxChars = 2000,
    this.timeoutMs = 60000,
    this.route = 'client',
  });

  /// AI answers for every farm. Off: built-in answers only.
  final bool enabled;
  final String provider;
  final String model;

  /// Successful AI answers per farm per day, shared by everyone on the farm.
  final int dailyLimit;
  final int warnPct;
  final String timezone;
  final int maxChars;
  final int timeoutMs;

  /// 'server' (limit enforced by the FarmTap server) or 'client' (pilot).
  final String route;
}

const defaultAssistantConfig = AssistantConfig();

/// Reads platform/config.ai. Older configs have no `assistant`: the chat then
/// follows the Photo Check switch and model, as before.
AssistantConfig assistantConfigFrom(Object? ai) {
  final o = _obj(ai);
  final a = _obj(o['assistant']);
  final ph = _obj(o['photo']);
  const d = defaultAssistantConfig;
  String? model(Object? v) => v is String && RegExp(r'^[\w.\-]{3,64}$').hasMatch(v) ? v : null;
  final tz = a['timezone'];
  return AssistantConfig(
    enabled: a['enabled'] is bool
        ? a['enabled']! as bool
        : ph['enabled'] is bool
        ? ph['enabled']! as bool
        : d.enabled,
    provider: a['provider'] == 'gemini' ? 'gemini' : d.provider,
    model: model(a['model']) ?? model(ph['model']) ?? d.model,
    dailyLimit: _intIn(a['dailyLimit'], 0, 1000, d.dailyLimit),
    warnPct: _intIn(a['warnPct'], 50, 100, d.warnPct),
    timezone: tz is String && RegExp(r'^[A-Za-z_]+(/[A-Za-z_+\-]+){0,2}$').hasMatch(tz) ? tz : d.timezone,
    maxChars: _intIn(a['maxChars'], 100, 8000, d.maxChars),
    timeoutMs: _intIn(a['timeoutMs'], 5000, 120000, d.timeoutMs),
    route: a['route'] == 'server' || a['route'] == 'client' ? a['route']! as String : d.route,
  );
}

// ---------------------------------------------------------------- Usage

enum UsageLevel { ok, warn, out }

class UsageView {
  const new({required this.used, required this.limit, required this.remaining, required this.level});
  final int used;
  final int limit;
  final int remaining;
  final UsageLevel level;

  /// From the server's JSON (aiUsageNow, or `usage` on an answer).
  static UsageView? fromJson(Object? v) {
    final o = _obj(v);
    final used = o['used'];
    final limit = o['limit'];
    if (used is! num || limit is! num) return null;
    final warn = o['level'] == 'warn';
    final out = o['level'] == 'out';
    return UsageView(
      used: used.toInt(),
      limit: limit.toInt(),
      remaining: o['remaining'] is num ? (o['remaining']! as num).toInt() : math.max(0, (limit - used).toInt()),
      level: out
          ? UsageLevel.out
          : warn
          ? UsageLevel.warn
          : UsageLevel.ok,
    );
  }
}

UsageView usageView(int used, int limit, int warnPct) {
  final u = used < 0 ? 0 : (used > limit ? limit : used);
  final left = limit - used;
  final remaining = left < 0 ? 0 : left;
  final level = remaining == 0
      ? UsageLevel.out
      : limit > 0 && u / limit * 100 >= warnPct
      ? UsageLevel.warn
      : UsageLevel.ok;
  return UsageView(used: u, limit: limit, remaining: remaining, level: level);
}

/// The 80% and 100% messages, or null below the warning line.
({String title, String message})? usageWarning(UsageView v) {
  switch (v.level) {
    case UsageLevel.warn:
      return (
        title: 'Approaching your daily AI limit',
        message:
            "You're approaching your daily AI limit. You have ${v.remaining} AI ${v.remaining == 1 ? 'response' : 'responses'} remaining today. Farm Tap's built-in intelligence and farm-management features remain unlimited.",
      );
    case UsageLevel.out:
      return (
        title: 'Your daily AI allowance has been reached.',
        message: 'AI-powered responses will be available again after the daily reset at midnight. You can still ask about your records, production, money and alerts: those answers are unlimited.',
      );
    case UsageLevel.ok:
      return null;
  }
}

// ---------------------------------------------------------------- Errors

/// Every way an AI request can end without an answer (Error A to G, plus too many at once).
enum AiErrorKind { limit, unavailable, network, timeout, disabled, invalid, capacity, tooFast }

AiErrorKind? aiErrorKindOf(Object? v) {
  for (final k in AiErrorKind.values) {
    if (k.name == v) return k;
  }
  return null;
}

({String title, String message}) aiErrorText(AiErrorKind kind, {int limit = 10}) {
  switch (kind) {
    case AiErrorKind.limit:
      return (
        title: 'Daily AI limit reached',
        message:
            "You've used all $limit AI-powered responses available to your farm today. Your AI allowance resets at midnight. You can continue using Farm Tap's built-in farm intelligence, analytics and management features without limits.",
      );
    case AiErrorKind.unavailable:
      return (
        title: 'AI temporarily unavailable',
        message: 'Our AI assistant is temporarily unavailable. You can still access your farm records, reports, calculations and automated insights. Please try again later.',
      );
    case AiErrorKind.network:
      return (
        title: 'Connection problem',
        message: "We couldn't connect to the AI service. Check your internet connection and try again. Your AI allowance has not been consumed.",
      );
    case AiErrorKind.timeout:
      return (
        title: 'Request timed out',
        message: 'The AI assistant took too long to respond. Please try again. Your request allowance has not been consumed.',
      );
    case AiErrorKind.disabled:
      return (
        title: 'AI assistant temporarily disabled',
        message: 'The AI assistant is currently unavailable. All other Farm Tap features remain accessible.',
      );
    case AiErrorKind.invalid:
      return (title: 'Unable to process request', message: 'Please rephrase your question and try again.');
    case AiErrorKind.capacity:
      return (
        title: 'AI service capacity reached',
        message: 'Our AI service has temporarily reached its available capacity. Please try again later. Your farm-management tools and built-in intelligence remain available.',
      );
    case AiErrorKind.tooFast:
      return (
        title: 'Too many questions at once',
        message: 'Please wait a minute before asking the AI again. Your AI allowance has not been consumed, and built-in answers stay available.',
      );
  }
}

/// The old in-app chat's failure words as kinds, for the pilot route.
AiErrorKind chatFailureKind(String failure, [String detail = '']) {
  if (failure == 'network') return AiErrorKind.network;
  if (failure == 'busy') {
    return RegExp('timeout|timed out', caseSensitive: false).hasMatch(detail)
        ? AiErrorKind.timeout
        : AiErrorKind.capacity;
  }
  if (failure == 'blocked') return AiErrorKind.invalid;
  return AiErrorKind.unavailable;
}

// ---------------------------------------------------------------- Server assistant (functions/src/ai.ts)

/// What the phone sends to the server assistant. The server picks the model
/// and the instructions; names were already replaced on the phone.
class ServerAsk {
  const new({
    required this.tenantId,
    required this.message,
    required this.facts,
    required this.calculated,
    required this.history,
    required this.files,
    required this.language,
    required this.search,
  });
  final String tenantId;
  final String message;
  final List<String> facts;
  final String? calculated;

  /// role 'user' or 'model', and the text.
  final List<({String role, String text})> history;

  /// mime and base64.
  final List<({String mime, String base64})> files;
  final String? language;
  final bool search;

  Map<String, Object?> toJson() => {
    'tenantId': tenantId,
    'message': message,
    'facts': facts,
    'calculated': calculated,
    'history': [
      for (final h in history) {'role': h.role, 'text': h.text},
    ],
    'files': [
      for (final f in files) {'mime': f.mime, 'base64': f.base64},
    ],
    'language': language,
    'search': search,
  };
}

class ServerAnswer {
  const new({required this.text, required this.model, required this.cached, this.usage, this.grounding});
  final String text;
  final String model;
  final bool cached;
  final UsageView? usage;

  /// The raw grounding map (queries, sources, suggestionsHtml), read by the chat.
  final Map<String, Object?>? grounding;
}

/// A failed server request: [kind] picks the message; [usage] is the server's count when it sent one.
class AiRequestException implements Exception {
  const new(this.kind, [this.usage]);
  final AiErrorKind kind;
  final UsageView? usage;

  @override
  String toString() => 'AiRequestException(${kind.name})';
}

/// The server assistant. The phone's implementation calls the aiAssistant callable over HTTPS.
abstract interface class AiServerClient {
  Future<ServerAnswer> ask(ServerAsk input, {required Duration timeout});
  Future<UsageView?> usage(String tenantId);
}

/// Sorts a callable's error status (e.g. RESOURCE_EXHAUSTED) and details into a kind.
AiErrorKind kindOfCallError(String? status, Object? details) {
  final k = aiErrorKindOf(_obj(details)['kind']);
  if (k != null) return k;
  return switch (status) {
    'DEADLINE_EXCEEDED' => AiErrorKind.timeout,
    'RESOURCE_EXHAUSTED' => AiErrorKind.capacity,
    'INVALID_ARGUMENT' => AiErrorKind.invalid,
    'FAILED_PRECONDITION' => AiErrorKind.disabled,
    _ => AiErrorKind.unavailable,
  };
}
