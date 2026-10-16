/// Runtime configuration for the Google Gemini integration.
///
/// Never commit a real API key to source control. Supply it when running or
/// building the app with:
/// `--dart-define=GEMINI_API_KEY=your_key_here`
class GeminiConfig {
  GeminiConfig._();

  static const String apiKey = String.fromEnvironment('GEMINI_API_KEY');

  static String requireApiKey() {
    if (apiKey.trim().isEmpty) {
      throw StateError(
        'Bloom AI is not configured. Start the app with '
        '--dart-define=GEMINI_API_KEY=your_key_here.',
      );
    }
    return apiKey;
  }
}
