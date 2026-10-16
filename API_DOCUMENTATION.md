# API Integration — Gemini (Bloom AI Chatbot)

## API name

**Google Gemini API** (Generative Language API) — powers the "Bloom AI"
chatbot already present in the app ([bloom_ai_fab.dart](lib/features/home/presentation/bloom_ai_fab.dart) /
[chatbot_screen.dart](lib/features/home/presentation/chatbot_screen.dart)).
Before this integration, Bloom AI's replies were hardcoded `if`/`else`
string matching with no real intelligence or external data. It now calls
Gemini for real, generated responses.

## API endpoints used

Base URL: `https://generativelanguage.googleapis.com/v1beta`

| Endpoint | Purpose |
|---|---|
| `GET /models/{model}?key={apiKey}` | Confirms the API key and model are reachable; returns the model's display name, shown in the chat header ("Powered by …"). |
| `POST /models/{model}:generateContent?key={apiKey}` | Sends the full conversation so far and returns Gemini's generated reply. |

Model used: `gemini-flash-lite-latest`.

## Request methods implemented

Both implemented in [lib/core/gemini_service.dart](lib/core/gemini_service.dart):

- **GET** — `GeminiService.fetchActiveModel()`, called once when the chat
  screen opens (`initState`). Parses the JSON response's `name` and
  `displayName` fields.
- **POST** — `GeminiService.sendMessage(history, userContext: ...)`, called
  every time the user sends a message. Sends a JSON body:
  ```json
  {
    "contents": [
      { "role": "user", "parts": [{ "text": "How can I ease nausea?" }] },
      { "role": "model", "parts": [{ "text": "..." }] }
    ],
    "systemInstruction": {
      "parts": [{ "text": "You are Bloom AI... User data from BabyBloom:\nName: Jane\nApp mode: Pregnancy\nCurrently 18 weeks pregnant.\nDue date: 2026-11-02." }]
    }
  }
  ```
  and parses the reply out of `candidates[0].content.parts[*].text`.

## Features added through API integration

- Real, dynamically generated chatbot replies instead of hardcoded keyword
  matching — Bloom AI can now answer anything, not just the 4–5 phrases it
  used to recognize.
- **Responses grounded in the user's own Supabase data.**
  [lib/core/bloom_ai_context.dart](lib/core/bloom_ai_context.dart) queries
  the signed-in user's `profiles`, `app_settings`, `daily_logs` (via
  `CyclePrediction`), and `baby_profiles` rows (whichever apply to their
  current `AppSession.mode`) and folds a short summary — name, cycle day /
  fertile window, pregnancy week / due date, or baby's name and age — into
  the system prompt sent with every message. Bloom AI answers using real
  data instead of guessing or asking the user to repeat what's already
  saved in the app.
- **Scoped to three topics.** The system prompt in
  `_bloomSystemPrompt` restricts Bloom AI to family planning (cycles,
  fertility, contraception, factors affecting conception), pregnancy, and
  baby care — any other question is politely declined and redirected back
  to those topics instead of being answered.
- The chat header shows which Gemini model is live ("Powered by Gemini 2.0
  Flash"), or a connection-issue message if the GET check fails —
  demonstrates the app is actually talking to a live external service.
- The full conversation history is sent with every request (Gemini is
  stateless per call), so replies stay contextual across turns.
- A system prompt keeps Bloom AI's persona, topic scope, and tone
  consistent with the rest of the app, and reminds users it isn't a
  medical professional.

## Loading and error handling

- **Loading**: the existing animated "typing" bubble (`_botTyping`) now
  reflects the real in-flight POST request instead of a fixed
  `Future.delayed`. A second message is blocked while one is in flight.
- **Invalid / failed responses**: `GeminiService` throws a `GeminiException`
  with a human-readable message for: network failures, non-200 HTTP status
  (parses the Gemini error JSON's `error.message`), safety-blocked prompts
  (`promptFeedback.blockReason`), and empty responses. The chat screen
  catches this and shows it as a distinct red-tinted bubble (with a
  ⚠️ icon instead of ✨) instead of crashing or silently failing.
- If the GET model check fails on screen load (e.g. bad API key), the
  header shows "Connection issue — check your API key" but the screen still
  loads normally rather than blocking the user.

## Setup

The API key is not committed to the repo. Paste it into
[lib/core/gemini_config.dart](lib/core/gemini_config.dart):

```dart
static const String apiKey = 'PASTE_YOUR_GEMINI_API_KEY_HERE';
```

Get a free key at https://aistudio.google.com/apikey.

**Note on security**: like the Supabase key, this is embedded in the client
app — acceptable for this class project, but a production app would proxy
Gemini calls through a backend so the key never ships to end users.
## Sample JSON response

The Gemini `generateContent` endpoint returns JSON similar to this. The app
parses `candidates[0].content.parts[0].text` and displays that text as the
Bloom AI reply in the chat screen.

```json
{
  "candidates": [
    {
      "content": {
        "role": "model",
        "parts": [
          {
            "text": "Small, frequent meals and sipping fluids may help with nausea. Contact your healthcare provider if you cannot keep fluids down."
          }
        ]
      },
      "finishReason": "STOP"
    }
  ]
}
```

## Week 5 requirement checklist

| Requirement | BabyBloom implementation |
|---|---|
| External API | Google Gemini Generative Language API |
| HTTP GET | Fetches the active model when the Bloom AI chat opens |
| HTTP POST | Sends conversation JSON to generate a Bloom AI response |
| JSON processing | Decodes model metadata and generated-response JSON |
| UI display | Shows model status, loading/typing state, and generated replies in Bloom AI chat |
| Errors/loading | Handles network, invalid-response, safety, and HTTP errors without crashing |
