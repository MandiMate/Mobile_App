import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SeasonService {
  static const String _activeSeasonUrl =
      'https://mandimatebackend.vercel.app/season/active';
  static const String _startSeasonUrl =
      'https://mandimatebackend.vercel.app/season/start';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token?.isNotEmpty ?? false) return token;

    final userJson = prefs.getString('user');
    if (userJson != null) {
      try {
        final map = jsonDecode(userJson);
        return map['token'] ?? map['accessToken'];
      } catch (_) {}
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getActiveSeason() async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    final resp = await http.get(
      Uri.parse(_activeSeasonUrl),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (resp.statusCode == 200) {
      final body = jsonDecode(resp.body);
      return body['season'];
    } else if (resp.statusCode == 404) {
      return null; // No active season
    } else {
      throw Exception('Error ${resp.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> startSeason(String name) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    final resp = await http.post(
      Uri.parse(_startSeasonUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'name': name}),
    );

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final body = jsonDecode(resp.body);
      return body['season'];
    } else {
      throw Exception('Failed to start season');
    }
  }
}
