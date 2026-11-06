// FarmTap AI: which layer answers a question (decision 0028). Hand port of
// shared/aiRoute.ts.
//
//   records (layer 1): plain look-ups in the farm's records
//   insight (layer 2): calculations, statistics and rules
//   ai      (layer 3): needs an AI model to reason or explain
//
// Layers 1 and 2 never call a model and never use the daily allowance.
import 'package:farm_tap/core/ai/ai_access.dart';
import 'package:farm_tap/core/ai/ai_assistant.dart';
import 'package:farm_tap/core/ai/ai_data.dart';
import 'package:farm_tap/core/ai/ai_insights.dart';

enum Layer { records, insight, ai }

enum RouteReason { empty, tooLong, files, reasoning, matched, unknown }

class AiRoute {
  const new(this.layer, this.reason, this.answer);
  final Layer layer;
  final RouteReason reason;

  /// The built-in answer when one exists (also sent to the AI as facts).
  final Answer? answer;
}

const _recordIntents = {'herdSize', 'withdrawal', 'pregnant'};

final _reasoning = RegExp(
  r'\b(why|explain\w*|recommend\w*|advi[cs]e\w*|suggest\w*|improv\w*|cause[sd]?|causing|reasons?|symptoms?|interpret\w*|help me understand|what does .+ mean|tips?|best way|how (can|could|do|should) (i|we) (increase|reduce|improve|fix|stop|prevent|treat|raise|boost|get)|should i (sell|buy|cull|keep|change|switch)|is it (good|bad|normal|safe)|what (might|could) be)\b',
  caseSensitive: false,
);

/// Built-in answer: the extra insights first, then the original assistant.
Answer answerInternally(String question, FarmData d, {required String role, required AiConfig cfg}) {
  final extra = askInsight(question, d, seesMoney: seesMoney(role));
  if (extra != null) {
    return Answer(
      intent: extra.intent,
      ok: extra.ok,
      text: extra.text,
      bullets: extra.bullets,
      links: extra.links,
      method: extra.method,
    );
  }
  return ask(question, d, role: role, cfg: cfg);
}

/// Picks the layer. Quick and offline.
AiRoute classify(
  String question,
  FarmData d, {
  required String role,
  required AiConfig cfg,
  int files = 0,
  int? maxChars,
}) {
  final q = question.trim();
  if (q.isEmpty && files == 0) return const AiRoute(Layer.insight, RouteReason.empty, null);
  if (maxChars != null && q.length > maxChars) return const AiRoute(Layer.ai, RouteReason.tooLong, null);
  final a = q.isEmpty ? null : answerInternally(q, d, role: role, cfg: cfg);
  final known = a != null && a.intent != 'unknown' && a.intent != 'empty' ? a : null;
  if (files > 0) return AiRoute(Layer.ai, RouteReason.files, known);
  if (_reasoning.hasMatch(q)) return AiRoute(Layer.ai, RouteReason.reasoning, known);
  if (known != null) {
    return AiRoute(_recordIntents.contains(known.intent) ? Layer.records : Layer.insight, RouteReason.matched, known);
  }
  return const AiRoute(Layer.ai, RouteReason.unknown, null);
}

String workingText(Layer layer, {bool model = false}) => switch (layer) {
  Layer.records => 'Checking your farm records...',
  Layer.insight => 'Analysing production data...',
  Layer.ai => model ? 'Preparing your AI response...' : 'Checking your farm records...',
};

String layerLabel(Layer layer) => layer == Layer.ai
    ? 'AI-generated: check important advice with your vet or adviser'
    : 'Calculated from your farm records';
