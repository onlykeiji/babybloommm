import 'dart:convert';

import 'package:http/http.dart' as http;

import 'gemini_config.dart';

/// Thrown when a Gemini request fails or returns something unusable.
class GeminiException implements Exception {
  GeminiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// A single turn in a Gemini chat, sent as part of the conversation history.
class GeminiTurn {
  const GeminiTurn({required this.role, required this.text});

  /// Either `'user'` or `'model'`.
  final String role;
  final String text;

  Map<String, dynamic> toJson() => {
    'role': role,
    'parts': [
      {'text': text},
    ],
  };
}

/// Minimal info about the Gemini model currently answering.
class GeminiModelInfo {
  const GeminiModelInfo({required this.name, required this.displayName});

  final String name;
  final String displayName;
}

const String _bloomSystemPrompt =
    'You are Bloom AI, a warm, concise assistant inside the BabyBloom app. '
    'You may ONLY discuss these three topics: '
    '(1) family planning — menstrual cycles, ovulation, fertility, '
    "contraception, and factors that can affect a person's ability to "
    'conceive or plan a family; '
    '(2) pregnancy — symptoms, nutrition, physical and emotional changes, '
    'and preparing for birth; '
    '(3) baby care — feeding, sleep, growth, development, and newborn or '
    'infant health. '
    'If the user asks about anything outside these three topics — even if '
    'phrased as a follow-up — politely decline to answer it and steer the '
    'conversation back to family planning, pregnancy, or baby care. Do not '
    'answer the off-topic part of the question, even partially. '
    'A "User data from BabyBloom" section may follow this prompt with real '
    'data pulled from the user\'s account (profile, cycle logs, pregnancy '
    'week, baby profile) — use it to personalize your replies when '
    'relevant, but never invent data that isn\'t given to you and never '
    'read it back verbatim as a list. Keep replies short (2-4 sentences) '
    'and caring. You are not a medical professional — encourage the user '
    'to consult their healthcare provider for anything that sounds '
    'medically concerning.';

/// Talks to the Gemini API (generativelanguage.googleapis.com) for the
/// Bloom AI chatbot: a GET call to confirm the model is reachable, and a
/// POST call per chat turn to generate a reply.
class GeminiService {
  GeminiService._();

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  // 'gemini-2.0-flash' was retired by Google and now 404s on generateContent
  // even though its GET /models lookup still succeeds (which is why the old
  // header kept showing "Gemini 2.0 Flash" while every chat message failed).
  // The '-latest' alias tracks Google's current model instead of a dated
  // snapshot, so this shouldn't go stale the same way again.
  static const String _model = 'gemini-flash-lite-latest';

  /// GET /v1beta/models/{model} — confirms the API key/model are reachable
  /// and returns the model's display name, shown in the chat header.
  static Future<GeminiModelInfo> fetchActiveModel() async {
    final apiKey = GeminiConfig.requireApiKey();
    final uri = Uri.parse('$_baseUrl/models/$_model?key=$apiKey');
    final http.Response response;
    try {
      response = await http.get(uri);
    } catch (e) {
      throw GeminiException('Could not reach Gemini: $e');
    }

    if (response.statusCode != 200) {
      throw GeminiException(_errorMessage(response));
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return GeminiModelInfo(
      name: (body['name'] as String?) ?? _model,
      displayName: (body['displayName'] as String?) ?? _model,
    );
  }

  /// POST /v1beta/models/{model}:generateContent — sends the conversation
  /// so far and returns Gemini's reply text.
  ///
  /// [userContext], when given, is real data pulled from the signed-in
  /// user's BabyBloom account (see `BloomAiContext`) and appended to the
  /// system prompt so replies can be personalized instead of generic.
  static Future<String> sendMessage(
    List<GeminiTurn> history, {
    String? userContext,
  }) async {
    final apiKey = GeminiConfig.requireApiKey();
    final uri = Uri.parse(
      '$_baseUrl/models/$_model:generateContent?key=$apiKey',
    );
    final systemText = (userContext == null || userContext.isEmpty)
        ? _bloomSystemPrompt
        : '$_bloomSystemPrompt\n\nUser data from BabyBloom:\n$userContext';
    final http.Response response;
    try {
      response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': history.map((t) => t.toJson()).toList(),
          'systemInstruction': {
            'parts': [
              {'text': systemText},
            ],
          },
        }),
      );
    } catch (e) {
      throw GeminiException('Could not reach Gemini: $e');
    }

    if (response.statusCode != 200) {
      throw GeminiException(_errorMessage(response));
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = body['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      final blockReason =
          (body['promptFeedback'] as Map<String, dynamic>?)?['blockReason'];
      throw GeminiException(
        blockReason != null
            ? "That message couldn't be answered (reason: $blockReason)."
            : 'Bloom AI could not generate a reply. Please try again.',
      );
    }

    final content = candidates.first['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    final text = parts
        ?.map((p) => (p as Map<String, dynamic>)['text'] as String? ?? '')
        .join()
        .trim();

    if (text == null || text.isEmpty) {
      throw GeminiException('Bloom AI returned an empty reply.');
    }
    return text;
  }

  static String _errorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final message =
          (body['error'] as Map<String, dynamic>?)?['message'] as String?;
      if (message != null && message.isNotEmpty) return message;
    } catch (_) {
      // Fall through to the generic message below.
    }
    return 'Gemini API error (HTTP ${response.statusCode}).';
  }
}
