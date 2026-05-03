import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'transit_tools.dart';

class ClaudeService {
  static const String _url = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-haiku-4-5-20251001';
  final TransitTools _tools = TransitTools();
  final List<Map<String, dynamic>> _history = [];

  String get _apiKey => dotenv.env['ANTHROPIC_API_KEY'] ?? '';

  static const String _systemPrompt =
      'CRITICAL RULE — LANGUAGE: You MUST reply in the exact same language the user writes in. '
      'If the user writes in English, reply in English only. '
      'If the user writes in Arabic, reply in Arabic only. '
      'Never switch languages under any circumstance. '
      'You are an AI public transport assistant for Oman and Belgium. '
      'TOOLS: You have access to real transit data tools. When users ask about delays, routes, or nearby stops, use the tool results provided in the conversation. '
      'DELAYS: When a delay is mentioned, immediately suggest 2-3 alternative routes WITHOUT waiting to be asked. '
      'ROUTES: For each route include: journey time, number of transfers, crowding level, and why recommended. '
      'CONFIDENCE: If uncertain about data, say "Note: This information may not be fully up to date." '
      'STATIONS Oman: Ruwi Bus Station, Seeb Bus Station, Al Khuwair, Sohar Bus Station, Salalah Bus Station. '
      'STATIONS Belgium: Brussel-Centraal, Gent-Sint-Pieters, Antwerpen-Centraal. '
      'Keep responses friendly, clear and under 200 words.';

  Future<String> sendMessage(String message) async {
    if (_apiKey.isEmpty) return 'Error: ANTHROPIC_API_KEY is missing.';

    final toolData = await _runTools(message);
    
    String fullMessage = message;
    if (toolData != null) {
      fullMessage = '$message\n\n[LIVE TRANSIT DATA]: ${jsonEncode(toolData)}';
    }

    _history.add({'role': 'user', 'content': fullMessage});

    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'content-type': 'application/json',
          'x-api-key': _apiKey,
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

  Future<Map<String, dynamic>?> _runTools(String message) async {
    final lower = message.toLowerCase();

    if (lower.contains('delay') || lower.contains('late') ||
        lower.contains('تأخير') || lower.contains('تأخر')) {
      final station = _extractStation(lower);
      return await _tools.getDelayInfo(station);
    }

    if (lower.contains('route') || lower.contains('how to get') ||
        lower.contains('alternative') || lower.contains('طريق') ||
        lower.contains('كيف أصل')) {
      return await _tools.getAlternativeRoutes('origin', 'destination');
    }

    if (lower.contains('nearby') || lower.contains('nearest') ||
        lower.contains('قريب') || lower.contains('أقرب')) {
      return await _tools.getNearbyStops(23.5880, 58.3829);
    }

    return null;
  }

  String _extractStation(String message) {
    final stations = [
      'Ruwi Bus Station', 'Seeb Bus Station', 'Al Khuwair',
      'Sohar Bus Station', 'Salalah Bus Station',
      'Brussel-Centraal', 'Gent-Sint-Pieters', 'Antwerpen-Centraal',
    ];
    for (final station in stations) {
      if (message.toLowerCase().contains(station.toLowerCase())) {
        return station;
      }
    }
    return 'Ruwi Bus Station';
  }

  void resetChat() => _history.clear();
}