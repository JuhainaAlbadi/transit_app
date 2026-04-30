import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static const String _url = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-haiku-4-5-20251001';
  static const String _systemPrompt =
    'You are an AI public transport assistant for Oman and Belgium. '
    'LANGUAGE: Always detect the user language and respond in the exact same language. '
    'DELAYS: When a delay is mentioned or detected, immediately suggest 2-3 alternative routes WITHOUT waiting to be asked. '
    'ROUTES: For each alternative route include: estimated journey time, number of transfers, and why this route is recommended. '
    'CONFIDENCE: If you are unsure about any data, clearly say "Note: This information may not be fully up to date." '
    'STATIONS Oman: Ruwi Bus Station, Seeb Bus Station, Al Khuwair, Sohar Bus Station, Salalah Bus Station. '
    'STATIONS Belgium: Brussels Centraal, Gent-Sint-Pieters, Antwerpen-Centraal. '
    'Keep responses friendly, clear and under 200 words.';

  final List<Map<String, dynamic>> _history = [];

  Future<String> sendMessage(String message) async {
    final apiKey = dotenv.env['ANTHROPIC_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      return 'Error: ANTHROPIC_API_KEY is missing from .env file.';
    }

    _history.add({'role': 'user', 'content': message});

    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'content-type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 1024,
          'system': _systemPrompt,
          'messages': _history,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['content'][0]['text'] as String;
        _history.add({'role': 'assistant', 'content': text});
        return text;
      } else {
        final error = jsonDecode(response.body);
        return 'Error: ${error['error']['message']}';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  void resetChat() {
    _history.clear();
  }
}
