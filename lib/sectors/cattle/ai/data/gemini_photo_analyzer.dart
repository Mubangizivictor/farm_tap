// The phone's call to Google Gemini through Firebase AI Logic (decision
// 0026). The Firebase project holds the key, the app holds none, and App
// Check proves the request comes from the real FarmTap app. Everything the
// model sends back goes through readPhotoReply() before a farmer sees it.
import 'dart:typed_data';

import 'package:farm_tap/core/ai/ai_photo.dart';
import 'package:firebase_ai/firebase_ai.dart';

class GeminiPhotoAnalyzer implements PhotoAnalyzer {
  const new();

  @override
  Future<String> analyze({
    required Uint8List bytes,
    required String mime,
    required String prompt,
    required String system,
    required String model,
  }) async {
    try {
      final m = FirebaseAI.googleAI().generativeModel(
        model: model,
        systemInstruction: Content.system(system),
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.2,
          maxOutputTokens: 1500,
        ),
      );
      final res = await m
          .generateContent([
            Content.multi([TextPart(prompt), InlineDataPart(mime, bytes)]),
          ])
          .timeout(const Duration(seconds: 60));
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
