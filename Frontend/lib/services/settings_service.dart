import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class SettingsService {
  final String apiKey = dotenv.env['BIBLE_KEY'] ?? '';
  Future<Map<String, dynamic>?> fetchUserSettings(String token) async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/user/settings'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return null;
    }
  }

  Future<void> updateUserSettings(
    String token,
    int primaryColor,
    int highlightColor,
    bool darkMode,
    bool publicProfile,
    String translationId,
    String translationName,
  ) async {
    var payload = json.encode({
      'primary_color': primaryColor,
      'highlight_color': highlightColor,
      'dark_mode': darkMode,
      'public_profile': publicProfile,
      'translation_id': translationId,
      'translation_name': translationName,
    });
    final response =
        await http.post(Uri.parse('http://10.0.2.2:8080/user/settings'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: payload);

    if (response.statusCode != 200) {
      print('Failed to update user settings: ${response.body}');
    }
  }

  Future<void> saveColor(MaterialColor color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('primaryColor', color.value);
  }

  Future<void> saveHighlightColor(MaterialColor color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highlightColor', color.value);
  }

  Future<MaterialColor> loadColor() async {
    final prefs = await SharedPreferences.getInstance();
    int? colorValue = prefs.getInt('primaryColor');
    return _parseColor(colorValue ?? 0xFF000000);
  }

  Future<MaterialColor> loadHighlightColor() async {
    final prefs = await SharedPreferences.getInstance();
    int? colorValue = prefs.getInt('highlightColor');
    return _parseColor(colorValue ?? 0xFFFF0000);
  }

  Future<void> saveThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', themeMode.toString());
  }

  Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    String? themeModeString = prefs.getString('themeMode');
    return themeModeString != null
        ? ThemeMode.values
            .firstWhere((mode) => mode.toString() == themeModeString)
        : ThemeMode.dark;
  }

  Future<void> saveTranslation(
      String translationId, String translationName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('translationId', translationId);
    await prefs.setString('translationName', translationName);
  }

  Future<Map<String, String>> loadTranslation() async {
    final prefs = await SharedPreferences.getInstance();
    String? translationId = prefs.getString('translationId');
    String? translationName = prefs.getString('translationName');
    return {
      'id': translationId ?? 'bba9f40183526463-01',
      'name': translationName ?? 'Berean Standard Bible',
    };
  }

  MaterialColor _parseColor(int colorValue) {
    return MaterialColor(colorValue, {
      50: Color(colorValue).withOpacity(0.1),
      100: Color(colorValue).withOpacity(0.2),
      200: Color(colorValue).withOpacity(0.3),
      300: Color(colorValue).withOpacity(0.4),
      400: Color(colorValue).withOpacity(0.5),
      500: Color(colorValue).withOpacity(0.6),
      600: Color(colorValue).withOpacity(0.7),
      700: Color(colorValue).withOpacity(0.8),
      800: Color(colorValue).withOpacity(0.9),
      900: Color(colorValue),
    });
  }

  Future<List<dynamic>> fetchTranslations() async {
    final response = await http.get(
      Uri.parse('https://api.scripture.api.bible/v1/bibles'),
      headers: {'api-key': apiKey},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to load translations');
    }
  }
}
