import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BibleProvider with ChangeNotifier {
  final String apiKey = dotenv.env['BIBLE_KEY'] ?? '';
  List<dynamic> _translations = [];
  List<dynamic> get translations => _translations;

  Future<void> fetchTranslations() async {
    final response = await http.get(
      Uri.parse('https://api.scripture.api.bible/v1/bibles'),
      headers: {'api-key': apiKey},
    );
    print(response.body);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _translations = data['data'];
      notifyListeners();
    } else {
      throw Exception('Failed to load translations');
    }
  }
}
