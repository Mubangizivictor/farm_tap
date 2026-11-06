// The phone's chat call to Google Gemini through Firebase AI Logic (decision
// 0027). The Firebase project holds the key, the app holds none, and App
// Check proves the request comes from the real FarmTap app. Everything the
// model sends back goes through readChatReply() before a farmer sees it.
import 'package:farm_tap/core/ai/ai_chat.dart';
import 'package:farm_tap/core/ai/ai_photo.dart';
import 'package:firebase_ai/firebase_ai.dart';

class GeminiChatAnalyzer implements ChatAnalyzer {
  const GeminiChatAnalyzer();

  @override
  Future<String> ask({
    required String system,
    required List<ChatTurn> history,
    required String prompt,
    required List<ChatPart> files,
    required String model,
  }) async {
    try {
      final m = FirebaseAI.googleAI().generativeModel(
        model: model,
        systemInstruction: Content.system(system),
        generationConfig: GenerationConfig(temperature: 0.4, maxOutputTokens: 1500),
      );
      final contents = <Content>[
        for (final h in history)
          if (h.fromUser) Content('user', [TextPart(h.text)]) else Content.model([TextPart(h.text)]),
        Content('user', [TextPart(prompt), for (final f in files) InlineDataPart(f.mime, f.bytes)]),
      ];
      final res = await m.generateContent(contents).timeout(const Duration(seconds: 90));
      final text = res.text;
      if (text == null || text.trim().isEmpty) throw const PhotoAnalyzeException(PhotoFailure.unreadable);
      return text;
    } on PhotoAnalyzeException {
      rethrow;
    } on Object catch (e) {
      throw PhotoAnalyzeException(photoFailureOf(e));
    }
  }
}
