import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/departure.dart';

class TransitService {
  static const String baseUrl = 'https://api.irail.be';

  Future<List<Departure>> getDepartures(String station) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/liveboard/?station=$station&format=json&lang=en'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final departures = data['departures']['departure'] as List;
        return departures.map((d) => Departure.fromJson(d)).toList();
      } else {
        throw Exception('Failed to load departures');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}