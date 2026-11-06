// The phone's chat call to Google Gemini through Firebase AI Logic (decision
// 0027). The Firebase project holds the key, the app holds none, and App
// Check proves the request comes from the real FarmTap app. Everything the
// model sends back goes through readChatReply() before a farmer sees it.
//
// Answers use Google Search (grounding) so general farming questions get
// current, sourced replies. If Google Search is not allowed for the model the
// question is asked again without it. The Google Search details are read with
// dynamic access on purpose: the field names differ between firebase_ai
// versions and a missing one must never break the answer.
// ignore_for_file: avoid_dynamic_calls
import 'package:farm_tap/core/ai/ai_chat.dart';
import 'package:firebase_ai/firebase_ai.dart';

class GeminiChatAnalyzer implements ChatAnalyzer {
  const new();

  @override
  Future<ChatAnswer> ask({
    required String system,
    required List<ChatTurn> history,
    required String prompt,
    required List<ChatPart> files,
    required String model,
  }) async {
    final contents = <Content>[
      for (final h in history)
        if (h.fromUser) Content('user', [TextPart(h.text)]) else Content.model([TextPart(h.text)]),
      Content('user', [TextPart(prompt), for (final f in files) InlineDataPart(f.mime, f.bytes)]),
    ];
    Future<GenerateContentResponse> run({required bool search}) {
      final m = FirebaseAI.googleAI().generativeModel(
        model: model,
        systemInstruction: Content.system(system),
        generationConfig: GenerationConfig(temperature: 0.4, maxOutputTokens: 1500),
        tools: search ? [Tool.googleSearch()] : null,
      );
      return m.generateContent(contents).timeout(const Duration(seconds: 90));
    }

    try {
      var searched = true;
      GenerateContentResponse res;
      try {
        res = await run(search: true);
      } on Object catch (e) {
        final f = chatFailureOf('$e');
        if (f == ChatFailure.network || f == ChatFailure.appCheck || f == ChatFailure.busy) rethrow;
        searched = false;
        res = await run(search: false);
      }
      String? text;
      try {
        text = res.text;
      } on Object catch (e) {
        throw ChatException(ChatFailure.blocked, '$e');
      }
      if (text == null || text.trim().isEmpty) {
        throw const ChatException(ChatFailure.unreadable, 'The model sent an empty answer.');
      }
      return ChatAnswer(text, searched ? _grounding(res) : null);
    } on ChatException {
      rethrow;
    } on Object catch (e) {
      final msg = '$e';
      throw ChatException(chatFailureOf(msg), msg.length > 600 ? msg.substring(0, 600) : msg);
    }
  }

  ChatGrounding? _grounding(GenerateContentResponse res) {
    try {
      final dynamic meta = (res.candidates.first as dynamic).groundingMetadata;
      if (meta == null) return null;
      final chunks = <({String? title, String? uri})>[];
      for (final dynamic c in (meta.groundingChunks as List<dynamic>? ?? const <dynamic>[])) {
        final dynamic web = c.web;
        if (web != null) chunks.add((title: web.title as String?, uri: web.uri as String?));
      }
      final queries = [for (final dynamic q in (meta.webSearchQueries as List<dynamic>? ?? const <dynamic>[])) '$q'];
      final dynamic entry = meta.searchEntryPoint;
      return ChatGrounding(
        queries: queries.take(4).toList(),
        sources: cleanSources(chunks),
        suggestionsHtml: entry == null ? null : entry.renderedContent as String?,
      );
    } on Object {
      return null;
    }
  }
}
